// lib/flutter_aliyun_nui.dart
library flutter_aliyun_nui;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui.dart';

export 'src/nui_config.dart';
export 'src/nui_event.dart';
export 'src/nui_controller.dart';

class FlutterAliyunNui {
  static const MethodChannel _channel = MethodChannel('flutter_aliyun_nui');
  static Future<String> Function()? _tokenProvider;
  static String _token = '';
  static bool recognizeOnReady = false;

  static void setRecognizeResultHandler({required Function(NuiRecognizeResult) handlerResult, required Function(NuiError) handlerError}) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecognizeResult':
          handlerResult(NuiRecognizeResult.fromMap(call.arguments));
          break;
        case 'onError':
          final error = NuiError.fromMap(call.arguments);
          // 240068 token 无效/过期 清空 token 重新启动
          if (error.errorCode == 240068) {
            _token = '';
            await startRecognize();
          }
          handlerError(error);
          break;
      }
      return null;
    });
  }

  /// 设置获取 token 的方法
  static void setTokenProvider(Future<String> Function() provider) {
    _tokenProvider = provider;
  }

  static Future<void> _getToken() async {
    if (_token.isNotEmpty) return;
    assert(_tokenProvider != null, 'tokenProvider not set!!!');
    _token = await _tokenProvider!.call();
  }

  static Future<void> initRecognize({required Map<String, dynamic> params}) async {
    await _getToken();
    if (_token.isNotEmpty) {
      params['token'] = _token;
      var initResult = await _channel.invokeMethod('initRecognize', params);
      recognizeOnReady = initResult == '0';
      return initResult;
    }
  }

  static Future<void> startRecognize() async {
    await _getToken();
    if (_token.isNotEmpty) {
      await _channel.invokeMethod('startRecognize', {'token': _token});
    }
  }

  static Future<void> stopRecognize() async {
    await _channel.invokeMethod('stopRecognize');
  }

  static Future<void> startStreamInputTts(Map<String, dynamic> params, {bool retry = false}) async {
    await _getToken();
    if (_token.isNotEmpty) {
      params['token'] = _token;
      // if (retry) {
      //   params['token'] = '6373809de80541a4a433c7fa79e37a2a';
      // }
      int ret = await _channel.invokeMethod('startStreamInputTts', params);
      if (ret != 0) {
        startStreamInputTts(params);
      }
    }
  }

  static Future<void> sendStreamInputTts(Map<String, dynamic> params) async {
    await _channel.invokeMethod('sendStreamInputTts', params);
  }

  static Future<void> stopStreamInputTts() async {
    await _channel.invokeMethod('stopStreamInputTts');
  }

  static Future<void> release() async {
    recognizeOnReady = false;
    await _channel.invokeMethod('release');
  }
}
