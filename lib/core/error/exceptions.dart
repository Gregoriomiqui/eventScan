class ServerException implements Exception {
  const ServerException(this.message);

  final String message;
}

class NotFoundException implements Exception {
  const NotFoundException(this.message);

  final String message;
}

class NetworkException implements Exception {
  const NetworkException(this.message);

  final String message;
}
