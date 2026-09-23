import 'dart:typed_data';

class InstalledApp {
  final String packageName;
  final String name;
  final Uint8List? iconBytes;
  final bool isSystemApp;

  const InstalledApp({
    required this.packageName,
    required this.name,
    this.iconBytes,
    this.isSystemApp = false,
  });

  InstalledApp copyWith({
    String? packageName,
    String? name,
    Uint8List? iconBytes,
    bool? isSystemApp,
  }) {
    return InstalledApp(
      packageName: packageName ?? this.packageName,
      name: name ?? this.name,
      iconBytes: iconBytes ?? this.iconBytes,
      isSystemApp: isSystemApp ?? this.isSystemApp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstalledApp &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}
