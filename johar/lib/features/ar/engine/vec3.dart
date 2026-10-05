import 'dart:math' as math;

double degToRad(double d) => d * math.pi / 180;
double radToDeg(double r) => r * 180 / math.pi;

/// Wraps an angle in degrees into (-180, 180].
double wrapDeg(double d) {
  var a = d % 360;
  if (a > 180) a -= 360;
  if (a <= -180) a += 360;
  return a;
}

/// 3D vector in the scene frame: x = right of the worker's starting direction,
/// y = straight ahead of it, z = up. Units are metres.
class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x, y, z;

  static const forwardAxis = Vec3(0, 1, 0);
  static const upAxis = Vec3(0, 0, 1);

  /// Unit vector for a bearing (degrees clockwise from straight ahead) and an
  /// elevation (degrees above the horizon).
  factory Vec3.direction(double bearingDeg, double elevationDeg) {
    final b = degToRad(bearingDeg), e = degToRad(elevationDeg);
    return Vec3(math.cos(e) * math.sin(b), math.cos(e) * math.cos(b), math.sin(e));
  }

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) => Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(dot(this));

  Vec3 get normalized {
    final l = length;
    return l < 1e-9 ? this : this * (1 / l);
  }

  double get bearingDeg => radToDeg(math.atan2(x, y));
  double get elevationDeg => radToDeg(math.asin((z / (length == 0 ? 1 : length)).clamp(-1.0, 1.0)));

  /// Same vector with its bearing increased by [deg] (rotation about z).
  Vec3 shiftBearing(double deg) {
    final d = degToRad(deg), c = math.cos(d), s = math.sin(d);
    return Vec3(x * c + y * s, -x * s + y * c, z);
  }

  static Vec3 lerp(Vec3 a, Vec3 b, double t) => a + (b - a) * t;

  @override
  String toString() => 'Vec3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${z.toStringAsFixed(3)})';
}

/// Where the phone camera points ([forward]) and which way is "up" on screen.
class Pose {
  const Pose(this.forward, this.up);
  final Vec3 forward;
  final Vec3 up;

  static const initial = Pose(Vec3.forwardAxis, Vec3.upAxis);

  Vec3 get right => forward.cross(up).normalized;

  /// Pose for a camera turned [yawDeg] right and tilted [pitchDeg] up, with no roll.
  factory Pose.fromYawPitch(double yawDeg, double pitchDeg) {
    final f = Vec3.direction(yawDeg, pitchDeg);
    final y = degToRad(yawDeg);
    final rightFlat = Vec3(math.cos(y), -math.sin(y), 0);
    return Pose(f, rightFlat.cross(f).normalized);
  }

  /// Makes forward/up unit length and perpendicular (removes sensor noise).
  Pose orthonormalized() {
    final f = forward.normalized;
    final u = (up - f * up.dot(f)).normalized;
    return Pose(f, u);
  }

  Pose shiftBearing(double deg) => Pose(forward.shiftBearing(deg), up.shiftBearing(deg));
}
