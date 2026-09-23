import 'dart:typed_data';

class RestrictedApp {
  final String packageName;
  final String name;
  final bool isRestricted;
  final Uint8List? iconBytes;
  final bool isInstalled;

  const RestrictedApp({
    required this.packageName,
    required this.name,
    this.isRestricted = false,
    this.iconBytes,
    this.isInstalled = true,
  });

  RestrictedApp copyWith({
    String? packageName,
    String? name,
    bool? isRestricted,
    Uint8List? iconBytes,
    bool? isInstalled,
  }) {
    return RestrictedApp(
      packageName: packageName ?? this.packageName,
      name: name ?? this.name,
      isRestricted: isRestricted ?? this.isRestricted,
      iconBytes: iconBytes ?? this.iconBytes,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestrictedApp &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          isRestricted == other.isRestricted &&
          isInstalled == other.isInstalled;

  @override
  int get hashCode => Object.hash(packageName, isRestricted, isInstalled);
}
