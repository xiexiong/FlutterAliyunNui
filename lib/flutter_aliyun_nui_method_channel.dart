import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_aliyun_nui_platform_interface.dart';

/// An implementation of [FlutterAliyunNuiPlatform] that uses method channels.
class MethodChannelFlutterAliyunNui extends FlutterAliyunNuiPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_aliyun_nui');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
