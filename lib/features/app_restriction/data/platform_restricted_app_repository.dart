// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter/services.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/installed_app.dart';
import '../domain/restricted_app.dart';
import '../domain/restricted_app_repository.dart';

class PlatformRestrictedAppRepository implements RestrictedAppRepository {
  final MethodChannel _channel;
  final SettingsRepository _settingsRepository;

  PlatformRestrictedAppRepository({
    required SettingsRepository settingsRepository,
    MethodChannel? channel,
  })  : _settingsRepository = settingsRepository,
        _channel = channel ??
            const MethodChannel('com.example.earnyourscroll/app_restriction');

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final List<dynamic>? result = await _channel
          .invokeMethod<List<dynamic>>('getInstalledApps')
          .timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => [],
          );

      if (result == null) return [];

      final List<InstalledApp> apps = [];
      for (final item in result) {
        if (item is Map) {
          final packageName = item['packageName'] as String?;
          final name = item['name'] as String?;
          final icon = item['icon'] as Uint8List?;

          if (packageName != null && name != null) {
            apps.add(
              InstalledApp(
                packageName: packageName,
                name: name,
                iconBytes: icon,
              ),
            );
          }
        }
      }
      return apps;
    } on MissingPluginException {
      // Graceful fallback for desktop / test environments
      return [];
    } on PlatformException catch (_) {
      // Permission or platform error handled gracefully
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<String>> getRestrictedPackageNames() async {
    try {
      final settings = await _settingsRepository.getUserSettings();
      return settings.selectedRestrictedApps;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveRestrictedPackageNames(List<String> packageNames) async {
    await _settingsRepository.updateRestrictedApps(packageNames);
  }

  @override
  Future<List<RestrictedApp>> getRestrictedApps() async {
    final installedApps = await getInstalledApps();
    var restrictedPackages = await getRestrictedPackageNames();

    // If installed apps were retrieved, reconcile and clean up uninstalled apps
    if (installedApps.isNotEmpty) {
      final installedPackageSet =
          installedApps.map((app) => app.packageName).toSet();

      final validRestricted = restrictedPackages
          .where((pkg) => installedPackageSet.contains(pkg))
          .toList();

      if (validRestricted.length != restrictedPackages.length) {
        // Prune uninstalled apps from persisted local storage
        await saveRestrictedPackageNames(validRestricted);
        restrictedPackages = validRestricted;
      }
    }

    final restrictedSet = restrictedPackages.toSet();

    return installedApps.map((installed) {
      return RestrictedApp(
        packageName: installed.packageName,
        name: installed.name,
        iconBytes: installed.iconBytes,
        isRestricted: restrictedSet.contains(installed.packageName),
        isInstalled: true,
      );
    }).toList();
  }
}
