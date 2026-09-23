import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../di/providers.dart';
import '../domain/permission_repository.dart';
import '../domain/permission_state.dart';
import '../domain/permission_type.dart';

class PermissionControllerState {
  final Map<AppPermissionType, PermissionState> permissions;
  final bool isLoading;

  const PermissionControllerState({
    required this.permissions,
    this.isLoading = false,
  });

  bool get areAllGranted =>
      permissions[AppPermissionType.camera] == PermissionState.granted &&
      permissions[AppPermissionType.usageAccess] == PermissionState.granted &&
      permissions[AppPermissionType.accessibility] == PermissionState.granted;

  PermissionControllerState copyWith({
    Map<AppPermissionType, PermissionState>? permissions,
    bool? isLoading,
  }) {
    return PermissionControllerState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PermissionController extends Notifier<PermissionControllerState> {
  late final PermissionRepository _repository;

  @override
  PermissionControllerState build() {
    _repository = ref.watch(permissionRepositoryProvider);
    state = PermissionControllerState(
      permissions: {
        for (final type in AppPermissionType.values)
          type: PermissionState.notDetermined,
      },
      isLoading: true,
    );
    _checkInitialPermissions();
    return state;
  }

  Future<void> _checkInitialPermissions() async {
    final results = await _repository.checkAllPermissions();
    state = PermissionControllerState(
      permissions: results,
      isLoading: false,
    );
  }

  Future<void> refreshPermissions() async {
    final results = await _repository.checkAllPermissions();
    state = state.copyWith(permissions: results);
  }

  Future<void> requestPermission(AppPermissionType type) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.requestPermission(type);
    final updated = Map<AppPermissionType, PermissionState>.from(state.permissions);
    updated[type] = result;
    state = state.copyWith(permissions: updated, isLoading: false);
    // Refresh all in case opening settings affected other permissions
    await refreshPermissions();
  }
}

final permissionControllerProvider =
    NotifierProvider<PermissionController, PermissionControllerState>(
  PermissionController.new,
);
