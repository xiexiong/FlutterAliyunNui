import 'package:flutter/material.dart';
import 'package:flutter_aliyun_nui/flutter_aliyun_nui.dart';
import 'dart:async';

class VoiceRecognitionPage extends StatefulWidget {
  const VoiceRecognitionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VoiceRecognitionPageState createState() => _VoiceRecognitionPageState();
}

class _VoiceRecognitionPageState extends State<VoiceRecognitionPage> {
  String _recognizedText = '';
  List<double> amplitudes = List.generate(7, (_) => 40);
  @override
  void initState() {
    super.initState();
  }

  Future<void> _initRecognize() async {
    // if ((await PermissionUtil.checkMicAndSpeeh(context)) == false) {
    //   return;
    // }
    NuiConfig config = NuiConfig(
      appKey: AliyunConfig.appKey,
      deviceId: '660668cf0c874c848fbb467603927ebd',
      token: AliyunConfig.token,
    );

    await ALNui.initRecognize(config);
    ALNui.setMethodCallHandler(
      recognizeResultHandler: (result) {
        setState(() {
          _recognizedText = result.result;
          if (result.isLast) {
            debugPrint('识别完毕,内容为:${result.result}');
          }
        });
      },
      errorHandler: (error) {
        debugPrint(error.errorMessage);
      },
      rmsChangedHandler: (rms) {
        var r = rms + 160;
        // if (r < 100) {
        //   r = r - 20;
        // }
        setState(() {
          amplitudes.removeAt(0);
          amplitudes.add(r);
        });
      },
    );
  }

  Future<void> _startRecognition() async {
    setState(() {
      _recognizedText = '';
    });
    await ALNui.startRecognize(AliyunConfig.token);
  }

  Future<void> _stopRecognition() async {
    await ALNui.stopRecognize();
  }

  Future<void> _startStreamInputTts() async {
    NuiConfig config = NuiConfig(
      appKey: AliyunConfig.appKey,
      deviceId: '660668cf0c874c848fbb467603927ebd',
      token: AliyunConfig.token,
      format: 'pcm',
      voice: 'xiaoyun',
      sampleRate: 16000,
      speechRate: 0,
      pitchRate: 0,
      volume: 80,
    );
    await ALNui.startStreamInputTts(config);
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
            VoiceWave(amplitudes: amplitudes),
            const SizedBox(height: 40),
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

class VoiceWave extends StatelessWidget {
  final double waveWidth; // 单个音浪宽度
  final double waveHeight; // 音浪最大高度
  final double spacing; // 音浪间距
  final Color waveColor; // 音浪颜色
  final Color backgroundColor; // 背景色
  final Size backgroundSize; // 背景尺寸
  final EdgeInsets padding; // 内边距
  final List<double> amplitudes; // 振幅数据(0-1)
  final double maxAmplitude = 120.0;

  const VoiceWave({
    Key? key,
    this.waveWidth = 3.0,
    this.waveHeight = 30.0,
    this.spacing = 2.0,
    this.waveColor = Colors.green,
    this.backgroundColor = Colors.red,
    this.backgroundSize = const Size(300, 60),
    this.padding = EdgeInsets.zero,
    required this.amplitudes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: backgroundSize.width,
      height: backgroundSize.height,
      padding: padding,
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          waveItem(amplitudes),
          waveItem(amplitudes.reversed.toList()),
          waveItem(amplitudes),
          waveItem(amplitudes.reversed.toList()),
          waveItem(amplitudes),
          waveItem(amplitudes.reversed.toList()),
          waveItem(amplitudes),
          waveItem(amplitudes.reversed.toList()),
        ],
      ),
    );
  }

  waveItem(List<double> rms) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: rms.map((amplitude) {
        double l = amplitude > maxAmplitude ? maxAmplitude : amplitude;
        print(l);
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: waveWidth,
          height: l / maxAmplitude * waveHeight,
          decoration: BoxDecoration(
            color: waveColor,
            borderRadius: BorderRadius.circular(waveWidth / 2),
          ),
        );
      }).toList(),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> rmss;
  final double minRms;
  final double maxRms;
  final Color color;
  final double barWidth;
  final double barSpace;

  _WavePainter(
    this.rmss,
    this.minRms,
    this.maxRms, {
    this.color = Colors.blueAccent,
    double? barWidth,
    double? barSpace,
  })  : barWidth = barWidth ?? 4,
        barSpace = barSpace ?? 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final totalWidth = rmss.length * barWidth + (rmss.length - 1) * barSpace;
    final startX = (size.width - totalWidth) / 2; // 左右居中

    final centerY = size.height / 2;

    for (int i = 0; i < rmss.length; i++) {
      final barHeight = rmss[i] * (64 / 90);
      // 让每个bar以画布中心为中轴，上下剧中
      final top = centerY - barHeight / 2;
      final bottom = centerY + barHeight / 2;
      final left = startX + i * (barWidth + barSpace);
      final rect = Rect.fromLTRB(left, top, left + barWidth, bottom);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.rmss != rmss || oldDelegate.color != color || oldDelegate.barWidth != barWidth || oldDelegate.barSpace != barSpace;
}
