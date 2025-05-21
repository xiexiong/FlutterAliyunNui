import 'package:flutter/material.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui.dart';

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
    await FlutterAliyunNui.init(deviceId: '660668cf0c874c848fbb467603927ebd');

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

  Future<void> _playText() async {
    FlutterAliyunNui.playText(text: '');
    // 使用示例
    final chunks = ['你好，', '这是', '流式', '语音合成', '测试。'];
    simulateStreamTTS(chunks);
  }

  Future<void> simulateStreamTTS(List<String> textChunks, {int intervalMs = 500}) async {
    for (final chunk in textChunks) {
      await FlutterAliyunNui.playText(text: chunk);
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
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
              onPressed: _playText,
              child: Text('_playText'),
            ),
          ],
        ),
      ),
    );
  }
}
