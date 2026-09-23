import 'package:flutter/widgets.dart';
import '../../onboarding/domain/permission_repository.dart';
import '../../onboarding/domain/permission_state.dart';
import '../../onboarding/domain/permission_type.dart';
import '../../timer/domain/timer_manager.dart';
import '../../timer/domain/usecases/consume_time_usecase.dart';
import '../domain/enforcement_policy.dart';
import 'restricted_app_manager.dart';
import '../data/native_enforcement_service.dart';

class EnforcementController extends ChangeNotifier with WidgetsBindingObserver {
  final TimerManager _timerManager;
  final RestrictedAppManager _restrictedAppManager;
  final NativeEnforcementService _enforcementService;
  final ConsumeTimeUseCase _consumeTimeUseCase;
  final PermissionRepository _permissionRepository;
  final EnforcementPolicy _policy;

  bool _isNavigatingToBlockedScreen = false;
  
  // Callback that Router will use to navigate
  void Function()? onShowBlockedScreen;

  EnforcementController(
    this._timerManager,
    this._restrictedAppManager,
    this._enforcementService,
    this._consumeTimeUseCase,
    this._permissionRepository, {
    this._policy = const EnforcementPolicy(),
  }) {
    WidgetsBinding.instance.addObserver(this);
    
    // Listen for state changes to sync native service
    _timerManager.addListener(_syncStateToNative);
    _restrictedAppManager.addListener(_syncStateToNative);
    
    // Handle MethodChannel callbacks from native
    _enforcementService.setMethodCallHandler((call) async {
      if (call.method == 'showBlockedScreen') {
        _handleBlockedScreenTrigger();
      }
    });

    _syncStateToNative();
  }

  void _handleBlockedScreenTrigger() {
    if (!_isNavigatingToBlockedScreen && onShowBlockedScreen != null) {
      _isNavigatingToBlockedScreen = true;
      onShowBlockedScreen!();
    }
  }

  void resetBlockedScreenState() {
    _isNavigatingToBlockedScreen = false;
  }

  Future<void> _syncStateToNative() async {
    final restrictedApps = _restrictedAppManager.selectedPackageNames.toList();
    final remainingSeconds = _timerManager.remainingSeconds;
    final usageStatus = await _permissionRepository.checkPermission(
      AppPermissionType.usageAccess,
    );
    final hasUsageAccess = usageStatus == PermissionState.granted;

    if (!_policy.shouldRunService(
      restrictedPackages: restrictedApps,
      hasUsageAccess: hasUsageAccess,
    )) {
      await _enforcementService.stopService();
    } else {
      await _enforcementService.startService(restrictedApps, remainingSeconds);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _timerManager.pauseForBackground();
    } else if (state == AppLifecycleState.resumed) {
      _syncUncommittedTime();
      _timerManager.resumeFromForeground();
    }
  }

  Future<void> _syncUncommittedTime() async {
    // When the app comes to foreground, ask the native service for any time consumed
    final uncommittedTime = await _enforcementService.getUncommittedTime();
    
    if (uncommittedTime > 0) {
      await _consumeTimeUseCase.execute(uncommittedTime);
      await _timerManager.syncExternalTimeUpdate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerManager.removeListener(_syncStateToNative);
    _restrictedAppManager.removeListener(_syncStateToNative);
    _enforcementService.setMethodCallHandler(null);
    super.dispose();
  }
}
