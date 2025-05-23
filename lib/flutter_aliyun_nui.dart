// lib/flutter_aliyun_nui.dart
library flutter_aliyun_nui;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui.dart';

export 'src/nui_config.dart';
export 'src/nui_event.dart';
export 'src/nui_controller.dart';

class ALNui {
  static const MethodChannel _channel = MethodChannel('flutter_aliyun_nui');
  static bool recognizeOnReady = false;
  static bool ttsOnReady = false;

  static void setRecognizeResultHandler({
    Function(NuiRecognizeResult)? handlerResult,
    Function? onPlayerDrainDataFinish,
    Function(NuiError)? handlerError,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecognizeResult':
          print('NBSDK => onRecognizeResult');
          print('阿里云识别结果:${call.arguments.toString()}');
          handlerResult?.call((NuiRecognizeResult.fromMap(call.arguments)));
          break;
        case 'onPlayerDrainDataFinish':
          onPlayerDrainDataFinish?.call();
          print('NBSDK => onPlayerDrainDataFinish');
          print('阿里云播放数据:${call.arguments.toString()}');
          break;
        case 'onError':
          print('NBSDK => onError');
          print(call.arguments.toString());
          final error = NuiError.fromMap(call.arguments);
          // 240068 token 无效/过期 清空 token 重新启动
          if (error.errorCode == 240068) {
            recognizeOnReady = false;
          }
          handlerError?.call(error);
          break;
      }
      return null;
    });
  }

  static Future<void> initRecognize({required Map<String, dynamic> params}) async {
    var initResult = await _channel.invokeMethod('initRecognize', params);
    recognizeOnReady = initResult == '0';
  }

  static Future<void> startRecognize(String token) async {
    await _channel.invokeMethod('startRecognize', {'token': token});
  }

  static Future<void> stopRecognize() async {
    await _channel.invokeMethod('stopRecognize');
  }

  static Future<void> startStreamInputTts(Map<String, dynamic> params, {bool retry = false}) async {
    print('NBSDK => startStreamInputTts');
    print(params.toString());
    int ret = await _channel.invokeMethod('startStreamInputTts', params);
    ttsOnReady = ret == 0;
  }

  static Future<void> sendStreamInputTts(String text) async {
    print('NBSDK => sendStreamInputTts $text');
    await _channel.invokeMethod('sendStreamInputTts', {'text': text});
  }

  static Future<void> stopStreamInputTts() async {
    print('NBSDK => stopStreamInputTts');
    await _channel.invokeMethod('stopStreamInputTts');
    ttsOnReady = false;
  }

  static Future<void> cancelStreamInputTts() async {
    print('NBSDK => cancelStreamInputTts');
    await _channel.invokeMethod('cancelStreamInputTts');
    ttsOnReady = false;
  }

  static Future<bool> isPlaying() async {
    return await _channel.invokeMethod('isPlaying');
  }

  static Future<bool> isPaused() async {
    return await _channel.invokeMethod('isPaused');
  }

  static Future<bool> isStopped() async {
    return await _channel.invokeMethod('isStopped');
  }

  static Future<void> release() async {
    print('NBSDK => release');
    recognizeOnReady = false;
    ttsOnReady = false;
    await _channel.invokeMethod('release');
  }
}
