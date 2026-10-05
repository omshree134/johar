// Adapted from Safar's lib/services/permissions_service.dart.
// Location/GPS removed (not needed for training); camera logic kept.

import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  PermissionsService._();

  static Future<bool> hasCamera() async => (await Permission.camera.status).isGranted;

  /// Returns true if granted. If permanently denied, opens app settings.
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }
}
