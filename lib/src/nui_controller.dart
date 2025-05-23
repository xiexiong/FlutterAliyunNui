import 'package:flutter/material.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui.dart';
import 'dart:async';

class AliyunConfig {
  static const appKey = 'K2W2xXRFH90s93gz';
  static const url = 'wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1';
}

class VoiceRecognitionPage extends StatefulWidget {
  const VoiceRecognitionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VoiceRecognitionPageState createState() => _VoiceRecognitionPageState();
}

class _VoiceRecognitionPageState extends State<VoiceRecognitionPage> {
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initRecognize() async {
    await ALNui.initRecognize(params: {
      'app_key': AliyunConfig.appKey,
      'device_id': '660668cf0c874c848fbb467603927ebd',
      'url': AliyunConfig.url,
      'token': aliToken,
    });
    ALNui.setRecognizeResultHandler(
      handlerResult: (result) {
        setState(() {
          _recognizedText = result.result;
          if (result.isLast) {
            debugPrint('识别完毕,内容为:${result.result}');
          }
        });
      },
      handlerError: (error) {
        debugPrint(error.errorMessage);
      },
    );
  }

  Future<void> _startRecognition() async {
    setState(() {
      _recognizedText = '';
    });
    await ALNui.startRecognize(aliToken);
  }

  Future<void> _stopRecognition() async {
    await ALNui.stopRecognize();
  }

  Future<void> _startStreamInputTts() async {
    await ALNui.startStreamInputTts({
      'app_key': AliyunConfig.appKey,
      'device_id': '660668cf0c874c848fbb467603927ebd',
      'url': AliyunConfig.url,
      'token': aliToken,
      'format': 'pcm',
      'voice': 'xiaoyun',
      'sample_rate': 16000,
      'speech_rate': 0,
      'pitch_rate': 0,
      'volume': 80,
    });
  }

  Future<void> _sendStreamInputTts() async {
    // 使用示例
    final chunks = [
      "唧唧复唧唧，木兰当户织。不闻机杼声，唯闻女叹息。",
      // "问女何所思，问女何所忆。女亦无所思，女亦无所忆。",
      // "昨夜见军帖，可汗大点兵，军书十二卷，卷卷有爷名。",
      // "阿爷无大儿，木兰无长兄，愿为市鞍马，从此替爷征。",
      // "东市买骏马，西市买鞍鞯，南市买辔头，北市买长鞭。旦辞爷娘去，暮宿黄河边，不闻爷娘唤女声，但闻黄河流水鸣溅溅。",
      // "旦辞黄河去，暮至黑山头，不闻爷娘唤女声，但闻燕山胡骑鸣啾啾。万里赴戎机",
      // "关山度若飞。朔气传金柝，寒光照铁衣。将军百战死，壮士十年归。",
      // "归来见天子，天子坐明堂。策勋十二转，赏赐百千强。可汗问所欲，木兰不用尚书郎",
      // "愿驰千里足，送儿还故乡。爷娘闻女来，出郭相扶将；阿姊闻妹来，当户理红妆；小弟闻姊来，磨刀霍霍向猪羊。",
      // "开我东阁门，坐我西阁床。脱我战时袍，著我旧时裳。当窗理云鬓，对镜帖花黄",
      // "出门看火伴，火伴皆惊忙：同行十二年，不知木兰是女郎。",
      // "雄兔脚扑朔，雌兔眼迷离；双兔傍地走，安能辨我是雄雌？",
    ];
    await simulateStreamTTS(chunks);
  }

  Future<void> simulateStreamTTS(List<String> textChunks, {int intervalMs = 10}) async {
    for (final chunk in textChunks) {
      await ALNui.sendStreamInputTts(chunk);
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
  }

  Future<void> _stopStreamInputTts() async {
    ALNui.stopStreamInputTts();
  }

  Future<void> _cancelStreamInputTts() async {
    ALNui.cancelStreamInputTts();
  }

  String get aliToken {
    return 'c15284bd77a9428ea7de51811a66387d';
  }

  @override
  void dispose() {
    ALNui.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 200),
            Text(_recognizedText, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _initRecognize, child: const Text('Init')),
            ElevatedButton(onPressed: _startRecognition, child: const Text('Start')),
            ElevatedButton(onPressed: _stopRecognition, child: const Text('Stop')),
            ElevatedButton(onPressed: _startStreamInputTts, child: const Text('startTts')),
            ElevatedButton(onPressed: _sendStreamInputTts, child: const Text('sendTts')),
            ElevatedButton(onPressed: _stopStreamInputTts, child: const Text('stopTts')),
            ElevatedButton(onPressed: _cancelStreamInputTts, child: const Text('cancelTts')),
          ],
        ),
      ),
    );
  }
}
