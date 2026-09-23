class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

class CacheException extends AppException {
  CacheException(super.message);
}

class PlatformException extends AppException {
  PlatformException(super.message);
}
