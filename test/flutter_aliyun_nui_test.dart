import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui_platform_interface.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAliyunNuiPlatform with MockPlatformInterfaceMixin implements FlutterAliyunNuiPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterAliyunNuiPlatform initialPlatform = FlutterAliyunNuiPlatform.instance;

  test('$MethodChannelFlutterAliyunNui is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAliyunNui>());
  });

  test('getPlatformVersion', () async {});
}
