// lib/flutter_aliyun_nui.dart
library flutter_aliyun_nui;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui.dart';

export 'src/nui_config.dart';
export 'src/nui_event.dart';

class ALNui {
  static const MethodChannel _channel = MethodChannel('flutter_aliyun_nui');
  static bool recognizeOnReady = false;
  static bool ttsOnReady = false;
  static Function(String text)? slog;

  static void setSlog(Function(String text) slongFunction) {
    slog = slongFunction;
  }

  static void setMethodCallHandler({
    Function(NuiRecognizeResult)? recognizeResultHandler,
    Function? playerDrainFinishHandler,
    Function(double)? rmsChangedHandler,
    Function(NuiError)? errorHandler,
    Function(String)? toastHandler,
  }) {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'onRecognizeResult':
            debugPrint('NBSDK ======> onRecognizeResult');
            if (slog != null) {
              slog?.call('onRecognizeResult: ${call.arguments.toString()}');
            }
            if (!recognizeOnReady) {
              debugPrint('NBSDK ======> recognize not ready');
              return;
            }

            debugPrint('阿里云识别结果:${call.arguments.toString()}');
            recognizeResultHandler?.call((NuiRecognizeResult.fromMap(call.arguments)));
            break;
          case 'onPlayerDrainFinish':
            playerDrainFinishHandler?.call();
            debugPrint('NBSDK ======> playerDrainFinishHandler');
            slog?.call('NBSDK ======> playerDrainFinishHandler');
            List data = call.arguments ?? [];
            debugPrint('阿里云播放数据:${data.join('')}');
            break;
          case 'onRmsChanged':
            rmsChangedHandler?.call(call.arguments);
            break;
          case 'onError':
            debugPrint('NBSDK ======> onError');
            debugPrint(call.arguments.toString());
            slog?.call('NBSDK ======> onError:${call.arguments.toString()}');
            final error = NuiError.fromMap(call.arguments);
            // 240068 token 无效/过期 清空 token 重新启动
            if (error.errorCode == 240068) {
              recognizeOnReady = false;
            }

            errorHandler?.call(error);
            break;
          case 'onToast':
            debugPrint('NBSDK ======> onToast');
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
    slog?.call('NBSDK ======> initRecognize initResult:$initResult, is $recognizeOnReady');
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
      debugPrint('NBSDK ======> startStreamInputTts ');
      debugPrint(config.toStreamTtsJson().toString());
      var ret = await _channel.invokeMethod('startStreamInputTts', config.toStreamTtsJson());
      ttsOnReady = ret == 0;
    } catch (e) {
      debugPrint('NBSDK ======> startStreamInputTts error: $e');
      slog?.call('NBSDK ======> startStreamInputTts error: $e');
    }
  }

  static Future<void> sendStreamInputTts(String text) async {
    debugPrint('NBSDK ======> sendStreamInputTts $text');
    slog?.call('NBSDK ======> sendStreamInputTts $text');
    if (!ttsOnReady) {
      debugPrint('NBSDK ======> tts not ready');
      return;
    }
    await _channel.invokeMethod('sendStreamInputTts', {'text': text});
  }

  static Future<void> stopStreamInputTts() async {
    debugPrint('NBSDK ======> stopStreamInputTts');
    slog?.call('NBSDK ======> stopStreamInputTts');
    if (!ttsOnReady) {
      debugPrint('NBSDK ======> tts not ready');
      return;
    }
    await _channel.invokeMethod('stopStreamInputTts');
    ttsOnReady = false;
  }

  static Future<void> cancelStreamInputTts() async {
    debugPrint('NBSDK ======> cancelStreamInputTts');
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
    debugPrint('NBSDK ======> release');
    recognizeOnReady = false;
    ttsOnReady = false;
    await _channel.invokeMethod('release');
  }
}
