import 'package:flutter/services.dart';

class NativeEnforcementService {
  final MethodChannel _channel;

  NativeEnforcementService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.example.earnyourscroll/app_restriction');

  Future<void> startService(List<String> restrictedApps, int remainingSeconds) async {
    await _invoke('startEnforcementService', {
      'apps': restrictedApps,
      'time': remainingSeconds,
    });
  }

  Future<void> stopService() async {
    await _invoke('stopEnforcementService');
  }

  Future<void> updateTime(int remainingSeconds) async {
    await _invoke('updateEnforcementTime', {
      'time': remainingSeconds,
    });
  }

  Future<void> updateApps(List<String> restrictedApps) async {
    await _invoke('updateRestrictedApps', {
      'apps': restrictedApps,
    });
  }

  Future<int> getUncommittedTime() async {
    final time = await _invoke<int>('getUncommittedTime');
    return time ?? 0;
  }

  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler(handler);
  }

  Future<T?> _invoke<T>(String method, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
