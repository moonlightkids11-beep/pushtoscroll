import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/permission_repository.dart';
import '../domain/permission_state.dart';
import '../domain/permission_type.dart';

class PlatformPermissionRepository implements PermissionRepository {
  static const MethodChannel _channel = MethodChannel('com.example.earnyourscroll/permissions');

  @override
  Future<PermissionState> checkPermission(AppPermissionType permission) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      // Never claim permissions are granted when not on an Android device
      return PermissionState.denied;
    }

    try {
      final String? result = await _channel.invokeMethod<String>(
        'checkPermission',
        {'permission': _permissionToString(permission)},
      );
      return _mapResultToState(result);
    } on PlatformException {
      return PermissionState.denied;
    } catch (_) {
      return PermissionState.denied;
    }
  }

  @override
  Future<PermissionState> requestPermission(AppPermissionType permission) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      // Never claim permissions are granted when not on an Android device
      return PermissionState.denied;
    }

    try {
      final String? result = await _channel.invokeMethod<String>(
        'requestPermission',
        {'permission': _permissionToString(permission)},
      );
      return _mapResultToState(result);
    } on PlatformException {
      return PermissionState.denied;
    } catch (_) {
      return PermissionState.denied;
    }
  }

  @override
  Future<Map<AppPermissionType, PermissionState>> checkAllPermissions() async {
    final results = <AppPermissionType, PermissionState>{};
    for (final type in AppPermissionType.values) {
      results[type] = await checkPermission(type);
    }
    return results;
  }

  String _permissionToString(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.camera:
        return 'camera';
      case AppPermissionType.usageAccess:
        return 'usageAccess';
      case AppPermissionType.accessibility:
        return 'accessibility';
    }
  }

  PermissionState _mapResultToState(String? result) {
    if (result == 'granted') {
      return PermissionState.granted;
    }
    return PermissionState.denied;
  }
}
