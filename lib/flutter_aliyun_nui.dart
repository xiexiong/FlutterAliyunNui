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
  static bool recognizeOnReady = false;
  static Future<String> Function()? _tokenProvider;
  static String _token = '';
  static Map<String, dynamic>? lastStartRecognizeData;
  static int retry = 0;

  static void setRecognizeResultHandler(Function(NuiRecognizeResult) handler, Function(NuiError) nuiError) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecognizeResult':
          handler(NuiRecognizeResult.fromMap(call.arguments));
          lastStartRecognizeData = null;
          break;
        case 'onError':
          final error = NuiError.fromMap(call.arguments);
          // 240068
          if (error.errorCode == 240068 && lastStartRecognizeData != null) {
            _token = '';
            await startRecognize(lastStartRecognizeData!, retry: true);
          }
          nuiError(error);
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
    _token = '';
    while (retry < 3) {
      assert(_tokenProvider != null, 'tokenProvider not set!!!');
      _token = await _tokenProvider!.call();
      if (_token.isNotEmpty) {
        retry = 0;
        return;
      }
      retry++;
    }
  }

  static Future<void> initRecognize({required String deviceId}) async {
    await _getToken();
    if (_token.isNotEmpty) {
      var initResult = await _channel.invokeMethod('initRecognize', {
        'appKey': AliyunConfig.appKey,
        'token': _token,
        'deviceId': deviceId,
        'url': AliyunConfig.url,
      });
      recognizeOnReady = initResult == '0';
      return initResult;
    }
  }

  static Future<void> startRecognize(Map<String, dynamic> params, {bool retry = false}) async {
    if (retry) {
      params['token'] = '6373809de80541a4a433c7fa79e37a2a';
      await _channel.invokeMethod('startRecognize', params);
      return;
    }
    await _getToken();
    if (_token.isNotEmpty) {
      params['token'] = _token;
      lastStartRecognizeData = params;
      await _channel.invokeMethod('startRecognize', params);
    }
  }

  static Future<void> stopRecognize() async {
    await _channel.invokeMethod('stopRecognize');
  }

  static Future<void> release() async {
    await _channel.invokeMethod('release');
  }

  static Future<void> startStreamInputTts(Map<String, dynamic> params, {bool retry = false}) async {
    await _getToken();
    if (_token.isNotEmpty) {
      params['token'] = _token;
      // if (retry) {
      //   params['token'] = '6373809de80541a4a433c7fa79e37a2a';
      // }
      params['token'] = '6373809de80541a4a433c7fa79e37a2a';
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

  static Future<void> pauseTTS() async {
    await _channel.invokeMethod('pauseTTS');
  }

  static Future<void> resumeTTS() async {
    await _channel.invokeMethod('resumeTTS');
  }
}
