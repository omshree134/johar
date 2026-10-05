package app.web.joharorg.johar

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import com.google.ar.core.ArCoreApk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.media.MediaPlayer
import kotlin.math.atan
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private var orientation: OrientationStreamHandler? = null
    private var ambientPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val sensors = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val handler = OrientationStreamHandler(sensors).also { orientation = it }

        MethodChannel(messenger, "johar/ar").setMethodCallHandler { call, result ->
            when (call.method) {
                "checkArCore" -> try {
                    result.success(ArCoreApk.getInstance().checkAvailability(this).name)
                } catch (e: Exception) {
                    result.success("UNKNOWN_ERROR")
                }
                "orientationSource" -> result.success(handler.bestSource())
                "backCameraFov" -> result.success(backCameraLongSideFovDeg())
                "playEmergencySound" -> {
                    val sound = call.argument<String>("sound") ?: "siren"
                    val volume = call.argument<Double>("volume")?.toFloat() ?: 0.35f
                    playAmbientSound(sound, volume)
                    result.success(true)
                }
                "stopEmergencySound" -> {
                    stopAmbientSound()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "johar/orientation").setStreamHandler(handler)
    }

    private fun playAmbientSound(name: String, volume: Float) {
        stopAmbientSound()
        val resId = when (name) {
            "siren" -> resources.getIdentifier("siren", "raw", packageName)
            "gas_hiss" -> resources.getIdentifier("gas_hiss", "raw", packageName)
            "machinery_hum" -> resources.getIdentifier("machinery_hum", "raw", packageName)
            else -> 0
        }
        if (resId != 0) {
            try {
                ambientPlayer = MediaPlayer.create(this, resId)?.apply {
                    isLooping = true
                    setVolume(volume, volume)
                    start()
                }
            } catch (e: Exception) {
                // Audio fallback: silence on errors
            }
        }
    }

    private fun stopAmbientSound() {
        try {
            ambientPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (e: Exception) {
        } finally {
            ambientPlayer = null
        }
    }

    /** Field of view across the long side of the back camera sensor, in degrees. */
    private fun backCameraLongSideFovDeg(): Double? = try {
        val cm = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val id = cm.cameraIdList.firstOrNull {
            cm.getCameraCharacteristics(it).get(CameraCharacteristics.LENS_FACING) ==
                CameraCharacteristics.LENS_FACING_BACK
        }
        if (id == null) null else {
            val ch = cm.getCameraCharacteristics(id)
            val size = ch.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
            val focal = ch.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.firstOrNull()
            if (size == null || focal == null || focal <= 0f) null
            else Math.toDegrees(2.0 * atan(max(size.width, size.height).toDouble() / (2.0 * focal)))
        }
    } catch (e: Exception) {
        null
    }

    override fun onDestroy() {
        orientation?.stop()
        stopAmbientSound()
        super.onDestroy()
    }
}

/**
 * Streams 6 doubles: [fx, fy, fz, ux, uy, uz]
 *   f = direction the back camera looks, u = direction the top of the phone points,
 *   both in world coordinates (x = east, y = north, z = up).
 *
 * Sensor preference:
 *   1. GAME_ROTATION_VECTOR  gyro + accelerometer, no magnetometer. Best choice:
 *                            steel structures and machinery disturb compasses.
 *   2. ROTATION_VECTOR       adds magnetometer; on some phones works without a gyro.
 *   3. Accelerometer + magnetometer, for phones with no gyroscope at all.
 */
class OrientationStreamHandler(private val sm: SensorManager) :
    EventChannel.StreamHandler, SensorEventListener {

    private var sink: EventChannel.EventSink? = null
    private val r = FloatArray(9)
    private var gravity: FloatArray? = null
    private var magnetic: FloatArray? = null

    fun bestSource(): String = when {
        sm.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR) != null -> "gameRotationVector"
        sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR) != null -> "rotationVector"
        sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null &&
            sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null -> "accelMag"
        else -> "none"
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        val rate = SensorManager.SENSOR_DELAY_GAME
        when (bestSource()) {
            "gameRotationVector" ->
                sm.registerListener(this, sm.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR), rate)
            "rotationVector" ->
                sm.registerListener(this, sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR), rate)
            "accelMag" -> {
                sm.registerListener(this, sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), rate)
                sm.registerListener(this, sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), rate)
            }
            else -> events?.error("NO_SENSOR", "No orientation sensor on this phone", null)
        }
    }

    override fun onCancel(arguments: Any?) = stop()

    fun stop() {
        sm.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(e: SensorEvent) {
        when (e.sensor.type) {
            Sensor.TYPE_GAME_ROTATION_VECTOR, Sensor.TYPE_ROTATION_VECTOR ->
                // Some older phones crash if given more than 4 values.
                SensorManager.getRotationMatrixFromVector(r, e.values.copyOf(minOf(4, e.values.size)))
            Sensor.TYPE_MAGNETIC_FIELD -> {
                magnetic = e.values.clone()
                return
            }
            Sensor.TYPE_ACCELEROMETER -> {
                gravity = e.values.clone()
                val g = gravity ?: return
                val m = magnetic ?: return
                if (!SensorManager.getRotationMatrix(r, null, g, m)) return
            }
            else -> return
        }
        // r is row-major; column j holds device axis j in world coordinates.
        // Back camera looks along device -Z; top of the phone is device +Y.
        sink?.success(
            doubleArrayOf(
                -r[2].toDouble(), -r[5].toDouble(), -r[8].toDouble(),
                r[1].toDouble(), r[4].toDouble(), r[7].toDouble(),
            )
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
