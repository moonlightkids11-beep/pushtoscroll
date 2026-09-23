class AppItem {
  final String packageName;
  final String name;
  final bool isRestricted;

  const AppItem({
    required this.packageName,
    required this.name,
    this.isRestricted = false,
  });
}
