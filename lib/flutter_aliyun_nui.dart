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
  static Function(String text)? slog;

  static void setSlog(Function(String text) slongFunction) {
    slog = slongFunction;
  }

  static void setRecognizeResultHandler({
    Function(NuiRecognizeResult)? handlerResult,
    Function? onPlayerDrainDataFinish,
    Function(NuiError)? handlerError,
    Function(String)? handlerToast,
  }) {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'onRecognizeResult':
            print('NBSDK ======> onRecognizeResult');
            if (slog != null) {
              slog?.call('onRecognizeResult: ${call.arguments.toString()}');
            }
            if (!recognizeOnReady) {
              print('NBSDK ======> recognize not ready');
              return;
            }

            print('阿里云识别结果:${call.arguments.toString()}');
            handlerResult?.call((NuiRecognizeResult.fromMap(call.arguments)));
            break;
          case 'onPlayerDrainDataFinish':
            onPlayerDrainDataFinish?.call();
            print('NBSDK ======> onPlayerDrainDataFinish');
            slog?.call('NBSDK ======> onPlayerDrainDataFinish');
            List data = call.arguments ?? [];
            print('阿里云播放数据:${data.join('')}');
            break;
          case 'onError':
            print('NBSDK ======> onError');
            print(call.arguments.toString());
            final error = NuiError.fromMap(call.arguments);
            // 240068 token 无效/过期 清空 token 重新启动
            if (error.errorCode == 240068) {
              recognizeOnReady = false;
            }
            handlerError?.call(error);
            break;
          case 'onToast':
            print('NBSDK ======> onToast');
            slog?.call('NBSDK ======> onToast: ${call.arguments.toString()}');
            break;
        }
      } catch (e) {
        slog?.call('NBSDK ======> Error in method call handler: $e');
      }
    });
  }

  static Future<void> initRecognize(NuiConfig config) async {
    slog?.call('NBSDK ======> initRecognize');
    var initResult = await _channel.invokeMethod('initRecognize', config.toRecognizeJson());
    recognizeOnReady = initResult == '0';
  }

  static Future<void> startRecognize(String token) async {
    slog?.call('NBSDK ======> startRecognize');
    await _channel.invokeMethod('startRecognize', {'token': token});
  }

  static Future<void> stopRecognize() async {
    slog?.call('NBSDK ======> stopRecognize');
    await _channel.invokeMethod('stopRecognize');
  }

  static Future<void> startStreamInputTts(NuiConfig config, {bool retry = false}) async {
    try {
      slog?.call('NBSDK ======> startStreamInputTts');
      print('NBSDK ======> startStreamInputTts ');
      print(config.toStreamTtsJson().toString());
      var ret = await _channel.invokeMethod('startStreamInputTts', config.toStreamTtsJson());
      ttsOnReady = ret == 0;
    } catch (e) {
      print('NBSDK ======> startStreamInputTts error: $e');
      slog?.call('NBSDK ======> startStreamInputTts error: $e');
    }
  }

  static Future<void> sendStreamInputTts(String text) async {
    print('NBSDK ======> sendStreamInputTts $text');
    slog?.call('NBSDK ======> sendStreamInputTts $text');
    if (!ttsOnReady) {
      print('NBSDK ======> tts not ready');
      return;
    }
    await _channel.invokeMethod('sendStreamInputTts', {'text': text});
  }

  static Future<void> stopStreamInputTts() async {
    print('NBSDK ======> stopStreamInputTts');
    slog?.call('NBSDK ======> stopStreamInputTts');
    if (!ttsOnReady) {
      print('NBSDK ======> tts not ready');
      return;
    }
    await _channel.invokeMethod('stopStreamInputTts');
    ttsOnReady = false;
  }

  static Future<void> cancelStreamInputTts() async {
    print('NBSDK ======> cancelStreamInputTts');
    slog?.call('NBSDK ======> cancelStreamInputTts');
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
    print('NBSDK ======> release');
    recognizeOnReady = false;
    ttsOnReady = false;
    await _channel.invokeMethod('release');
  }
}
