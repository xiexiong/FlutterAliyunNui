import 'dart:io';

import 'package:flutter/services.dart';

import 'flutter_aliyun_nui.dart';

extension ChannelExt on MethodChannel {
  Future<T?> invoke<T>(String method, [dynamic arguments]) {
    ALNui.log(method, arguments);
    if (isSimulator) return Future.value(null);
    return invokeMethod(method, arguments);
  }

  bool get isSimulator {
    if (!Platform.isIOS) return false;
    // iOS 模拟器的设备型号一般以 "x86_64" 或 "arm64" 开头
    return !Platform.isMacOS && (Platform.environment['SIMULATOR_DEVICE_NAME'] != null);
  }
}
