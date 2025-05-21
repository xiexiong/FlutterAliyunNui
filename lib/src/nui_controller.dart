import 'package:flutter/material.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui.dart';

class AliyunConfig {
  static const appKey = 'K2W2xXRFH90s93gz';
  static const url = 'wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1';
}

class VoiceRecognitionPage extends StatefulWidget {
  @override
  _VoiceRecognitionPageState createState() => _VoiceRecognitionPageState();
}

class _VoiceRecognitionPageState extends State<VoiceRecognitionPage> {
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initNui() async {
    FlutterAliyunNui.setTokenProvider(() async {
      return '6373809de80541a4a433c7fa79e37a2as';
    });
    await FlutterAliyunNui.initRecognize(deviceId: '660668cf0c874c848fbb467603927ebd');

    FlutterAliyunNui.setRecognizeResultHandler((result) {
      setState(() {
        _recognizedText = result.result;
        if (result.isLast) {
          debugPrint('识别完毕,内容为:${result.result}');
        }
      });
    }, (error) {
      debugPrint(error.errorMessage);
    });
  }

  Future<void> _startRecognition() async {
    setState(() {
      _recognizedText = '';
    });
    await FlutterAliyunNui.startRecognize({
      'voice': NuiConfig.defaultVoice,
      'format': NuiConfig.defaultFormat,
      'sample_rate': NuiConfig.defaultSampleRate,
    });
  }

  Future<void> _stopRecognition() async {
    await FlutterAliyunNui.stopRecognize();
  }

  Future<void> startStreamInputTts() async {
    FlutterAliyunNui.setTokenProvider(() async {
      return '6373809de80541a4a433c7fa79e37a2as';
    });
    await FlutterAliyunNui.startStreamInputTts({
      'app_key': AliyunConfig.appKey,
      'device_id': '660668cf0c874c848fbb467603927ebd',
      'url': AliyunConfig.url,
      'format': 'pcm',
      'voice': 'xiaoyun',
      'sample_rate': 16000,
      'speech_rate': 0,
      'pitch_rate': 0,
      'volume': 80,
    });
  }

  Future<void> sendStreamInputTts() async {
    // 使用示例
    final chunks = ['你好，', '这是', '流式', '语音合成', '测试。'];
    await simulateStreamTTS(chunks);
  }

  Future<void> simulateStreamTTS(List<String> textChunks, {int intervalMs = 500}) async {
    for (final chunk in textChunks) {
      await FlutterAliyunNui.sendStreamInputTts({'text': chunk});
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
  }

  Future<void> stopStreamInputTts() async {
    FlutterAliyunNui.stopStreamInputTts();
  }

  @override
  void dispose() {
    FlutterAliyunNui.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 200,
            ),
            Text(
              _recognizedText,
              style: TextStyle(color: Colors.red),
            ),
            ElevatedButton(
              onPressed: _initNui,
              child: Text('Init'),
            ),
            ElevatedButton(
              onPressed: _startRecognition,
              child: Text('Start'),
            ),
            ElevatedButton(
              onPressed: _stopRecognition,
              child: Text('Stop'),
            ),
            ElevatedButton(
              onPressed: startStreamInputTts,
              child: Text('startTts'),
            ),
            ElevatedButton(
              onPressed: sendStreamInputTts,
              child: Text('sendTts'),
            ),
            ElevatedButton(
              onPressed: stopStreamInputTts,
              child: Text('stopTts'),
            ),
          ],
        ),
      ),
    );
  }
}
