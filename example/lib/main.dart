import 'package:flutter/material.dart';
import 'package:flutter_aliyun_nui_example/nui_controller.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VoiceRecognitionPage(),
    );
  }
}
