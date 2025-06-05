package com.example.flutter_aliyun_nui
import com.example.flutter_aliyun_nui.SpeechRecognizer
import com.example.flutter_aliyun_nui.StreamTts


import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterAliyunNuiPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel 
    private lateinit var sr: SpeechRecognizer
    private lateinit var tts: StreamTts

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_aliyun_nui")
        sr = SpeechRecognizer(binding.applicationContext, channel)
        tts = StreamTts(binding.applicationContext, channel)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "release") {
            tts.handleMethodCall(call, result)
            sr.handleMethodCall(call, result)
        } else if (call.method.contains("Tts")) {
            tts.handleMethodCall(call, result)
        } else {
            sr.handleMethodCall(call, result)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}