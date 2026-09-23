import 'installed_app.dart';
import 'restricted_app.dart';

abstract class RestrictedAppRepository {
  Future<List<InstalledApp>> getInstalledApps();
  Future<List<String>> getRestrictedPackageNames();
  Future<void> saveRestrictedPackageNames(List<String> packageNames);
  Future<List<RestrictedApp>> getRestrictedApps();
}
