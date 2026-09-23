import 'permission_state.dart';
import 'permission_type.dart';

abstract class PermissionRepository {
  Future<PermissionState> checkPermission(AppPermissionType permission);
  Future<PermissionState> requestPermission(AppPermissionType permission);
  Future<Map<AppPermissionType, PermissionState>> checkAllPermissions();
}
