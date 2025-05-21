// lib/src/nui_event.dart
class NuiRecognizeResult {
  final String result;
  final bool isLast;

  NuiRecognizeResult({required this.result, required this.isLast});

  factory NuiRecognizeResult.fromMap(Map<dynamic, dynamic> map) {
    return NuiRecognizeResult(
      result: map['result'] ?? '',
      isLast: (map['isLast'] ?? 1) == 1,
    );
  }
}

class NuiError {
  final int errorCode;
  final String errorMessage;

  NuiError({required this.errorCode, required this.errorMessage});

  factory NuiError.fromMap(Map<dynamic, dynamic> map) {
    return NuiError(
      errorCode: map['errorCode'] ?? -1,
      errorMessage: map['errorMessage'] ?? 'Unknown error',
    );
  }
}
