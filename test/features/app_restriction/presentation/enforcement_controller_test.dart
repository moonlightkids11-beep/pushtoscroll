import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:earn_your_scroll/features/app_restriction/presentation/enforcement_controller.dart';
import 'package:earn_your_scroll/features/app_restriction/presentation/restricted_app_manager.dart';
import 'package:earn_your_scroll/features/app_restriction/data/native_enforcement_service.dart';
import 'package:earn_your_scroll/features/onboarding/domain/permission_repository.dart';
import 'package:earn_your_scroll/features/onboarding/domain/permission_state.dart';
import 'package:earn_your_scroll/features/onboarding/domain/permission_type.dart';
import 'package:earn_your_scroll/features/timer/domain/timer_manager.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/consume_time_usecase.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/restricted_app.dart';

class MockTimerManager extends ChangeNotifier implements TimerManager {
  int _remainingSeconds = 0;
  
  @override
  int get remainingSeconds => _remainingSeconds;

  void setRemainingSeconds(int seconds) {
    _remainingSeconds = seconds;
    notifyListeners();
  }

  @override
  Future<void> syncExternalTimeUpdate() async {}
  
  @override
  bool get isRunning => false;
  
  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> start() async {}
  
  @override
  Future<void> stop() async {}

  VoidCallback? pauseHandler;

  @override
  void pauseForBackground() {
    pauseHandler?.call();
  }

  @override
  Future<void> resumeFromForeground() async {}
}

class MockRestrictedAppManager extends ChangeNotifier implements RestrictedAppManager {
  Set<String> _selectedPackageNames = {};
  
  @override
  Set<String> get selectedPackageNames => _selectedPackageNames;
  
  void setPackages(Set<String> pkgs) {
    _selectedPackageNames = pkgs;
    notifyListeners();
  }
  
  @override
  Future<void> loadApps() async {}
  
  @override
  Future<void> toggleAppRestriction(String packageName) async {}
  
  @override
  Future<void> clearAll() async {}
  
  @override
  Future<void> selectAll() async {}
  
  @override
  List<RestrictedApp> get apps => [];

  @override
  List<RestrictedApp> get filteredApps => [];
  
  @override
  bool get isLoading => false;

  @override
  String get searchQuery => '';

  @override
  void setSearchQuery(String query) {}

  @override
  int get restrictedCount => _selectedPackageNames.length;

  @override
  int get totalAppsCount => 0;

  @override
  String? get errorMessage => null;
}

class MockNativeEnforcementService implements NativeEnforcementService {
  bool started = false;
  bool stopped = false;
  List<String> currentApps = [];
  int currentTime = 0;
  int mockUncommittedTime = 0;
  
  @override
  Future<void> startService(List<String> apps, int time) async {
    started = true;
    stopped = false;
    currentApps = apps;
    currentTime = time;
  }

  @override
  Future<void> stopService() async {
    stopped = true;
    started = false;
  }

  @override
  Future<void> updateTime(int time) async {}

  @override
  Future<void> updateApps(List<String> apps) async {}

  @override
  Future<int> getUncommittedTime() async {
    return mockUncommittedTime;
  }

  @override
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {}
}

class MockPermissionRepository implements PermissionRepository {
  PermissionState usageAccess = PermissionState.granted;

  @override
  Future<PermissionState> checkPermission(AppPermissionType permission) async {
    if (permission == AppPermissionType.usageAccess) return usageAccess;
    return PermissionState.granted;
  }

  @override
  Future<PermissionState> requestPermission(AppPermissionType permission) async {
    return checkPermission(permission);
  }

  @override
  Future<Map<AppPermissionType, PermissionState>> checkAllPermissions() async {
    return {
      for (final type in AppPermissionType.values) type: PermissionState.granted,
    };
  }
}

class MockConsumeTimeUseCase implements ConsumeTimeUseCase {
  int consumedTime = 0;
  
  @override
  Future<void> execute(int seconds) async {
    consumedTime += seconds;
  }
}

void main() {
  late MockTimerManager timerManager;
  late MockRestrictedAppManager appManager;
  late MockNativeEnforcementService nativeService;
  late MockConsumeTimeUseCase consumeTimeUseCase;
  late MockPermissionRepository permissionRepository;
  late EnforcementController controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    timerManager = MockTimerManager();
    appManager = MockRestrictedAppManager();
    nativeService = MockNativeEnforcementService();
    consumeTimeUseCase = MockConsumeTimeUseCase();
    permissionRepository = MockPermissionRepository();
    
    controller = EnforcementController(
      timerManager,
      appManager,
      nativeService,
      consumeTimeUseCase,
      permissionRepository,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('Starts service when restricted apps exist', () async {
    appManager.setPackages({'com.example.app'});
    timerManager.setRemainingSeconds(60);
    
    await Future.delayed(Duration.zero);
    
    expect(nativeService.started, isTrue);
    expect(nativeService.currentApps, contains('com.example.app'));
    expect(nativeService.currentTime, 60);
  });

  test('Stops service when no restricted apps exist', () async {
    appManager.setPackages({'com.example.app'});
    await Future.delayed(Duration.zero);
    
    appManager.setPackages({});
    await Future.delayed(Duration.zero);
    
    expect(nativeService.stopped, isTrue);
  });

  test('Does not start service when usage access is missing', () async {
    permissionRepository.usageAccess = PermissionState.denied;
    appManager.setPackages({'com.example.app'});
    timerManager.setRemainingSeconds(60);

    await Future.delayed(Duration.zero);

    expect(nativeService.started, isFalse);
    expect(nativeService.stopped, isTrue);
  });

  test('Starts service with zero remaining time so native can block', () async {
    appManager.setPackages({'com.instagram.android'});
    timerManager.setRemainingSeconds(0);

    await Future.delayed(Duration.zero);

    expect(nativeService.started, isTrue);
    expect(nativeService.currentTime, 0);
  });

  test('Syncs uncommitted time on app resume', () async {
    nativeService.mockUncommittedTime = 15;
    
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    
    await Future.delayed(Duration.zero);
    
    expect(consumeTimeUseCase.consumedTime, 15);
  });

  test('Pauses dart timer when app is backgrounded or hidden', () async {
    var paused = false;
    timerManager.pauseHandler = () => paused = true;

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(paused, isTrue);

    paused = false;
    controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
    expect(paused, isTrue);
  });
}
