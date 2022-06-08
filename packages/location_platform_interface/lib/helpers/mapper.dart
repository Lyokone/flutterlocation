import 'package:location_platform_interface/messages.pigeon.dart';

PermissionStatus permissionStatusFromInt(int permission) {
  switch (permission) {
    case 0:
      return PermissionStatus.granted;
    case 1:
      return PermissionStatus.grantedLimited;
    case 2:
      return PermissionStatus.denied;
    case 3:
      return PermissionStatus.deniedForever;
    default:
      throw Exception('Unknown permission status: $permission');
  }
}
