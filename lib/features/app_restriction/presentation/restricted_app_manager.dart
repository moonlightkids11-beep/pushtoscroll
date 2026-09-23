import 'package:flutter/foundation.dart';
import '../domain/restricted_app.dart';
import '../domain/restricted_app_repository.dart';

class RestrictedAppManager extends ChangeNotifier {
  final RestrictedAppRepository _repository;

  List<RestrictedApp> _apps = [];
  Set<String> _selectedPackageNames = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  RestrictedAppManager(this._repository);

  List<RestrictedApp> get apps => _apps;
  Set<String> get selectedPackageNames => _selectedPackageNames;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  int get restrictedCount => _selectedPackageNames.length;
  int get totalAppsCount => _apps.length;

  List<RestrictedApp> get filteredApps {
    if (_searchQuery.trim().isEmpty) {
      return _apps;
    }
    final query = _searchQuery.toLowerCase().trim();
    return _apps.where((app) {
      return app.name.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadApps() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedApps = await _repository.getRestrictedApps();
      _apps = loadedApps;
      _selectedPackageNames = loadedApps
          .where((app) => app.isRestricted)
          .map((app) => app.packageName)
          .toSet();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load installed applications. Please check permissions.';
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> toggleAppRestriction(String packageName) async {
    final isCurrentlyRestricted = _selectedPackageNames.contains(packageName);
    if (isCurrentlyRestricted) {
      _selectedPackageNames.remove(packageName);
    } else {
      _selectedPackageNames.add(packageName);
    }

    _apps = _apps.map((app) {
      if (app.packageName == packageName) {
        return app.copyWith(isRestricted: !isCurrentlyRestricted);
      }
      return app;
    }).toList();

    notifyListeners();

    try {
      await _repository.saveRestrictedPackageNames(_selectedPackageNames.toList());
    } catch (e) {
      _errorMessage = 'Failed to update restricted apps: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> selectAll() async {
    final targets = filteredApps;
    for (final app in targets) {
      _selectedPackageNames.add(app.packageName);
    }

    _apps = _apps.map((app) {
      return app.copyWith(
        isRestricted: _selectedPackageNames.contains(app.packageName),
      );
    }).toList();

    notifyListeners();
    await _repository.saveRestrictedPackageNames(_selectedPackageNames.toList());
  }

  Future<void> clearAll() async {
    final targets = filteredApps;
    for (final app in targets) {
      _selectedPackageNames.remove(app.packageName);
    }

    _apps = _apps.map((app) {
      return app.copyWith(
        isRestricted: _selectedPackageNames.contains(app.packageName),
      );
    }).toList();

    notifyListeners();
    await _repository.saveRestrictedPackageNames(_selectedPackageNames.toList());
  }
}
