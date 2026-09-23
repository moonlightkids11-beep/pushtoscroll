import 'app_item.dart';

abstract class AppRestrictionRepository {
  Future<List<AppItem>> getInstalledApps();
  Future<void> setRestrictedApps(List<String> packageNames);
  Future<List<String>> getRestrictedApps();
}
