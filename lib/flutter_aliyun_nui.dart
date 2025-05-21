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
  static bool onReady = false;
  static Future<String> Function()? _tokenProvider;
  static String _token = '';

  /// 设置获取 token 的方法
  static void setTokenProvider(Future<String> Function() provider) {
    _tokenProvider = provider;
  }

  static Future<bool> _getToken() async {
    if (_token.isNotEmpty) return true;
    int retry = 0;
    String token = '';
    while (retry < 3) {
      assert(_tokenProvider != null, 'tokenProvider not set!!!');
      token = await _tokenProvider!.call();
      if (token.isNotEmpty) {
        _token = token;
        return true;
      }
      retry++;
    }
    _token = '';
    return _token.isNotEmpty;
  }

  static Future<String> init({required String deviceId}) async {
    if (await _getToken()) {
      var initResult = await _channel.invokeMethod('init', {
        'appKey': AliyunConfig.appKey,
        'token': _token,
        'deviceId': deviceId,
        'url': AliyunConfig.url,
      });
      onReady = initResult == '0';
      return initResult;
    } else {
      return "获取阿里云 token 失败";
    }
  }

  static Future<void> startRecognize(Map<String, dynamic> params) async {
    params['token'] = _token;
    final result = await _channel.invokeMethod('startRecognize', params);
    if (result != null) {
      await _getToken();
      _token = '6373809de80541a4a433c7fa79e37a2a';
      startRecognize(params);
    }
  }

  static Future<void> stopRecognize() async {
    await _channel.invokeMethod('stopRecognize');
  }

  static Future<void> release() async {
    await _channel.invokeMethod('release');
  }

  static void setRecognizeResultHandler(Function(NuiRecognizeResult) handler, Function(NuiError) nuiError) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecognizeResult':
          handler(NuiRecognizeResult.fromMap(call.arguments));
          break;
        case 'onError':
          final error = NuiError.fromMap(call.arguments);
          nuiError(error);
          break;
      }
      return null;
    });
  }

  static Future<void> pushToTTS() async {
    await _channel.invokeMethod('pushToTTS');
  }

  static Future<void> playText({
    required String text,
  }) async {
    await _channel.invokeMethod('playText', {'text': text});
  }

  static Future<void> stopTTS() async {
    await _channel.invokeMethod('stopTTS');
  }

  static Future<void> pauseTTS() async {
    await _channel.invokeMethod('pauseTTS');
  }

  static Future<void> resumeTTS() async {
    await _channel.invokeMethod('resumeTTS');
  }
}

class AliyunConfig {
  static const appKey = 'K2W2xXRFH90s93gz';
  static const url = 'wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1';
}
