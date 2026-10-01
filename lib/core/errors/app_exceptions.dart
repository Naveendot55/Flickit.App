/// Sealed hierarchy of exceptions for Flickit.
abstract class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

class CameraExceptionWrapper extends AppException {
  const CameraExceptionWrapper(super.message, [super.cause]);
}

class CameraPermissionDeniedException extends AppException {
  const CameraPermissionDeniedException([
    super.message = 'Camera permission was denied',
  ]);
}

class ModelLoadException extends AppException {
  const ModelLoadException(super.message, [super.cause]);
}

class InferenceException extends AppException {
  const InferenceException(super.message, [super.cause]);
}
