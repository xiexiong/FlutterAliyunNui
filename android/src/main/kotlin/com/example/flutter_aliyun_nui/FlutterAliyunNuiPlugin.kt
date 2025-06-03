// android/src/main/kotlin/com/example/flutter_aliyun_nui/FlutterAliyunNuiPlugin.kt
package com.example.flutter_aliyun_nui

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

class FlutterAliyunNuiPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_aliyun_nui")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initRecognize" -> {
//        initNui(call.argument, result)
      }
      "startRecognize" -> {
        val params = call.arguments as Map<String, Any>
        startRecognize(params, result)
      }
      "stopRecognize" -> {
        stopRecognize(result)
      }
      "release" -> {
        release(result)
      }
      else -> result.notImplemented()
    }
  }

//  private fun initNui( Map<String, Any>? args, result: Result) {
//    val appKey = call?.argument<String>("appKey")
//    val token = call?.argument<String>("token")
//    val deviceId = call?.argument<String>("deviceId")
//    val url = call?.argument<String>("url")

//    nuiAgent = NuiAgent.create()
//    nuiAgent?.init(appKey, token, deviceId)
//    nuiAgent?.setEventCallback(object : NuiEventAdapter() {
//      override fun onRecognizeResult(result: String?, isLast: Boolean) {
//        channel.invokeMethod("onRecognizeResult", mapOf(
//          "result" to result,
//          "isLast" to isLast
//        ))
//      }
//
//      override fun onError(errorCode: Int, errorMessage: String?) {
//        channel.invokeMethod("onError", mapOf(
//          "errorCode" to errorCode,
//          "errorMessage" to errorMessage
//        ))
//      }
//    })
//    result.success(null)
//  }

  private fun startRecognize(params: Map<String, Any>, result: Result) {
    val json = JSONObject(params)
//    nuiAgent?.startRecognize(json)
    result.success(null)
  }

  private fun stopRecognize(result: Result) {
//    nuiAgent?.stopRecognize()
    result.success(null)
  }

  private fun release(result: Result) {
//    nuiAgent?.release()
    result.success(null)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
