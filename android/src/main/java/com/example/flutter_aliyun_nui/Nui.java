package com.example.flutter_aliyun_nui;

// import com.example.flutter_aliyun_nui.Utils;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.text.TextUtils;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;
import android.content.Context;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONException;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.idst.nui.CommonUtils;
import com.alibaba.idst.nui.AsrResult;
import com.alibaba.idst.nui.Constants;
import com.alibaba.idst.nui.INativeNuiCallback;
import com.alibaba.idst.nui.KwsResult;
import com.alibaba.idst.nui.NativeNui;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.LinkedBlockingQueue;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class Nui extends Object implements INativeNuiCallback {
    private static final String TAG = "SpeechRecognizer";

    private MethodChannel channel;
    private Context context;

    NativeNui nui_instance = new NativeNui();
    private final Map<String, List<String>> paramMap = new HashMap<>();
    private final static int SAMPLE_RATE = 16000;
    private final static int WAVE_FRAM_SIZE = 20 * 2 * 1 * SAMPLE_RATE / 1000; //20ms audio for 16k/16bit/mono
    private AudioRecord mAudioRecorder = null;

    private boolean mInit = false;
    private boolean mStopping = false;
    private String mDebugPath = "";
    private String curTaskId = "";
    private LinkedBlockingQueue<byte[]> tmpAudioQueue = new LinkedBlockingQueue();
    private String mRecordingAudioFilePath = "";
    private OutputStream mRecordingAudioFile = null;
    private Handler mHandler;
    private HandlerThread mHanderThread;
    private Handler mainHandler = new Handler(Looper.getMainLooper());
    private final String[] permissions = {Manifest.permission.RECORD_AUDIO};

    public Nui(Context context, MethodChannel channel) {
        this.context = context;
        this.channel = channel;
        mHanderThread = new HandlerThread("process_thread");
        mHanderThread.start();
        mHandler = new Handler(mHanderThread.getLooper());
    }


    public void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> params = call.arguments();
        switch (call.method) {
            case "initRecognize":
                initNui(params, result);
                break;
            case "startRecognize":
                startRecognize(params, result);
                break;
            case "stopRecognize":
                stopRecognize(result);
                break;
            case "release":
                release(result);
                break;
            default:
                result.notImplemented();
        }
    }

    private void initNui(Map<String, Object> params, MethodChannel.Result result) {
        JSONObject json = new JSONObject(params);
        //获取工作路径, 即获得拷贝后资源文件存储的cache路径, 作为workspace
        // 注意: V2.6.2版本开始纯云端功能可不需要资源文件
        // 注意: 029版本如果不设置workspace也可继续用一句话识别, 但是日志系统会刷WARN日志
        String asset_path = "";

        mDebugPath = context.getExternalCacheDir().getAbsolutePath() + "/debug";
        Utils.createDir(mDebugPath);

        //初始化SDK，注意用户需要在Auth.getTicket中填入相关ID信息才可以使用。
        int ret = nui_instance.initialize(this, genInitParams(asset_path, mDebugPath, json),
                Constants.LogLevel.LOG_LEVEL_DEBUG, true);
        Log.i(TAG, "result = " + ret);
        if (ret == Constants.NuiResultCode.SUCCESS) {
            mInit = true;
            result.success("0");
            Log.i(TAG, "NUI init success");
        } else {
            Log.e(TAG, "NUI init failed: " + ret);
            result.error("NUI_INIT_FAILED", "NUI initialization failed with code: " + ret, null);
            return;
        }
    }

    private void startRecognize(Map<String, Object> params, MethodChannel.Result result) {
        JSONObject json = new JSONObject(params);
        // 你的识别逻辑
        // ...
        Log.i(TAG, "startRecognize json = " + json.toString());

        // /*
        //  * 首先，录音权限动态申请
        //  * */
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // 检查该权限是否已经获取
            int i = ContextCompat.checkSelfPermission(context, permissions[0]);
            // 权限是否已经 授权 GRANTED---授权  DINIED---拒绝
            if (i != PackageManager.PERMISSION_GRANTED) {
                // 如果没有授予该权限，就去提示用户请求
                if (context instanceof Activity) {
                    ((Activity) context).requestPermissions(permissions, 321);
                }
            }
        }
        if (ActivityCompat.checkSelfPermission(
                context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            if (mAudioRecorder == null) {
                //录音初始化，录音参数中格式只支持16bit/单通道，采样率支持8K/16K
                //使用者请根据实际情况选择Android设备的MediaRecorder.AudioSource
                //录音麦克风如何选择,可查看https://developer.android.google.cn/reference/android/media/MediaRecorder.AudioSource
                mAudioRecorder = new AudioRecord(MediaRecorder.AudioSource.DEFAULT,
                        16000, //采样率
                        AudioFormat.CHANNEL_IN_MONO,
                        AudioFormat.ENCODING_PCM_16BIT,
                        WAVE_FRAM_SIZE * 4);
                Log.d(TAG, "AudioRecorder new ...");
            } else {
                Log.w(TAG, "AudioRecord has been new ...");
            }
        } else {
            Log.e(TAG, "donnot get RECORD_AUDIO permission!");
            return;
        }

        mHandler.post(new Runnable() {
            @Override
            public void run() {
                //由于对外的SDK不带有本地VAD模块(仅带有唤醒功能的SDK具有VAD模块)，
                //若要使用VAD模式，则需要设置nls_config参数启动在线VAD模式(见genParams())
//                Constants.VadMode vad_mode = Constants.VadMode.TYPE_P2T;
                // if (mVadSwitch.isChecked()) {
                //TYPE_VAD: 云端服务自动判断句尾结束识别
                //vad_mode = Constants.VadMode.TYPE_VAD;
                // } else {
                //TYPE_P2T: 由用户主动stop()以告知识别完成
                //vad_mode = Constants.VadMode.TYPE_P2T;
                // }

                //设置相关识别参数，具体参考API文档
                //  initialize()之后startDialog之前调用
                String setParamsString = genParams();
                Log.i(TAG, "nui set params " + setParamsString);
                nui_instance.setParams(setParamsString);
                //开始一句话识别
                int ret = nui_instance.startDialog(Constants.VadMode.TYPE_P2T,
                        genDialogParams(json.getString("token")));
                Log.i(TAG, "start done with " + ret);
                if (ret != 0) {
                    final String msg_text = Utils.getMsgWithErrorCode(ret, "start");
                }
            }
        });
        result.success(null);
    }

    private void stopRecognize(MethodChannel.Result result) {
        // 你的停止逻辑
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                mStopping = true;
                long ret = nui_instance.stopDialog();
                Log.i(TAG, "cancel dialog " + ret + " end");
            }
        });
        result.success(null);
    }

    private void release(MethodChannel.Result result) {
        // 你的释放逻辑
        nui_instance.release();
        result.success(null);
    }

    private String genParams() {
        String params = "";
        try {
            JSONObject nls_config = new JSONObject();

            //参数可根据实际业务进行配置
            //接口说明可见: https://help.aliyun.com/document_detail/173298.html
            //查看 2.开始识别

            // 是否返回中间识别结果，默认值：False。
            nls_config.put("enable_intermediate_result", true);
            // 是否在后处理中添加标点，默认值：False。
            nls_config.put("enable_punctuation_prediction", true);

            nls_config.put("sample_rate", 16000); // 采样率，单位Hz，默认值：16000);
            nls_config.put("sr_format", "pcm"); // 音频格式，默认值：pcm

            // DNS解析的超时时间设置(单位ms)，默认5000
            //nls_config.put("dns_timeout", 500);

            //由于对外的SDK(01B版本)不带有本地VAD模块(仅带有唤醒功能(029版本)的SDK具有VAD模块)，
            //若要使用VAD模式，则需要设置nls_config参数启动在线VAD模式(见genParams())
            // if (mVadSwitch.isChecked()) {
            //     nls_config.put("enable_voice_detection", true);
            //     nls_config.put("max_start_silence", 10000);
            //     nls_config.put("max_end_silence", 800);
            // } else {
            nls_config.put("enable_voice_detection", false);
            // }

            //nls_config.put("enable_inverse_text_normalization", true);
            //nls_config.put("enable_voice_detection", true);
            //nls_config.put("customization_id", "test_id");
            //nls_config.put("vocabulary_id", "test_id");
            //nls_config.put("max_start_silence", 10000);
            //nls_config.put("max_end_silence", 800);

            /*若文档中不包含某些参数，但是此功能支持这个参数，可以用如下万能接口设置参数*/
//            JSONObject extend_config = new JSONObject();
//            JSONObject vocab = new JSONObject();
//            vocab.put("热词1", 2);
//            vocab.put("热词2", 2);
//            extend_config.put("vocabulary", vocab);
//            nls_config.put("extend_config", extend_config);

            JSONObject parameters = new JSONObject();

            parameters.put("nls_config", nls_config);
            parameters.put("service_type", Constants.kServiceTypeASR); // 必填

            //如果有HttpDns则可进行设置
//            parameters.put("direct_ip", "1.1.1.1");

            params = parameters.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return params;
    }

    private String genInitParams(String workpath, String debugpath, JSONObject json) {

        String g_appkey = json.getString("app_key");
        String g_token = json.getString("token");
        String device_id = json.getString("device_id");
        String url = json.getString("url");
        String str = "";
        try {
            //获取账号访问凭证：
            Auth.GetTicketMethod method = Auth.GetTicketMethod.GET_TOKEN_FROM_SERVER_FOR_ONLINE_FEATURES;
            if (!g_appkey.isEmpty()) {
                Auth.setAppKey(g_appkey);
            }
            if (!g_token.isEmpty()) {
                Auth.setToken(g_token);
            }
            // if (!g_ak.isEmpty()) {
            //     Auth.setAccessKey(g_ak);
            // }
            // if (!g_sk.isEmpty()) {
            //     Auth.setAccessKeySecret(g_sk);
            // }
            // Auth.setStsToken(g_sts_token);
            // 此处展示将用户传入账号信息进行交互，实际产品不可以将任何账号信息存储在端侧
            if (!g_appkey.isEmpty()) {
                // if (!g_ak.isEmpty() && !g_sk.isEmpty()) {
                //     if (g_sts_token.isEmpty()) {
                //         method = Auth.GetTicketMethod.GET_ACCESS_IN_CLIENT_FOR_ONLINE_FEATURES;
                //     } else {
                //         method = Auth.GetTicketMethod.GET_STS_ACCESS_IN_CLIENT_FOR_ONLINE_FEATURES;
                //     }
                // }
                if (!g_token.isEmpty()) {
                    method = Auth.GetTicketMethod.GET_TOKEN_IN_CLIENT_FOR_ONLINE_FEATURES;
                }
            }
            Log.i(TAG, "Use method:" + method);
            JSONObject object = Auth.getTicket(method);
            if (!object.containsKey("token")) {
                Log.e(TAG, "Cannot get token !!!");
            }

            object.put("device_id", device_id); // 必填, 推荐填入具有唯一性的id, 方便定位问题 
            object.put("url", url);

            //工作目录路径，SDK从该路径读取配置文件
//            object.put("workspace", workpath); // V2.6.2版本开始纯云端功能可不设置workspace

            //当初始化SDK时的save_log参数取值为true时，该参数生效。表示是否保存音频debug，该数据保存在debug目录中，需要确保debug_path有效可写。
            object.put("save_wav", "true");
            //debug目录，当初始化SDK时的save_log参数取值为true时，该目录用于保存中间音频文件。
            object.put("debug_path", debugpath);

            //过滤SDK内部日志通过回调送回到用户层
            object.put("log_track_level", String.valueOf(Constants.LogLevel.toInt(Constants.LogLevel.LOG_LEVEL_INFO)));

            // FullMix = 0   // 选用此模式开启本地功能并需要进行鉴权注册
            // FullCloud = 1
            // FullLocal = 2 // 选用此模式开启本地功能并需要进行鉴权注册
            // AsrMix = 3    // 选用此模式开启本地功能并需要进行鉴权注册
            // AsrCloud = 4
            // AsrLocal = 5  // 选用此模式开启本地功能并需要进行鉴权注册
            object.put("service_mode", Constants.ModeAsrCloud); // 必填
            str = object.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }

        // 注意! str中包含ak_id ak_secret token app_key等敏感信息, 实际产品中请勿在Log中输出这类信息！
        Log.i(TAG, "InsideUserContext:" + str);
        return str;
    }

    private String genDialogParams(String token) {
        String params = "";
        try {
            JSONObject dialog_param = new JSONObject();
            // 运行过程中可以在startDialog时更新临时参数，尤其是更新过期token
            // 注意: 若下一轮对话不再设置参数，则继续使用初始化时传入的参数
            long distance_expire_time_5m = 300;
            dialog_param = Auth.refreshTokenIfNeed(dialog_param, distance_expire_time_5m);

            // 注意: 若需要更换appkey和token，可以直接传入参数
//            dialog_param.put("app_key", "");
            dialog_param.put("token", token);
            params = dialog_param.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }

        Log.i(TAG, "dialog params: " + params);
        return params;
    }


    //当回调事件发生时调用
    @Override
    public void onNuiEventCallback(Constants.NuiEvent event, final int resultCode,
                                   final int arg2, KwsResult kwsResult,
                                   AsrResult asrResult) {
        Log.i(TAG, "event=" + event + " resultCode=" + resultCode);
        // asrResult包含task_id，task_id有助于排查问题，请用户进行记录保存。

        if (event == Constants.NuiEvent.EVENT_ASR_STARTED) {
            // EVENT_TRANSCRIBER_STARTED 为V2.6.3版本新增
            JSONObject jsonObject = JSON.parseObject(asrResult.allResponse);
            JSONObject header = jsonObject.getJSONObject("header");
            curTaskId = header.getString("task_id");
        } else if (event == Constants.NuiEvent.EVENT_ASR_RESULT) {
            mStopping = false;
            JSONObject jsonObject = JSON.parseObject(asrResult.asrResult);
            JSONObject payload = jsonObject.getJSONObject("payload");
            String result = payload.getString("result");
            Log.i(TAG, "EVENT_ASR_RESULT " + result);
            // 创建参数Map（使用HashMap保证类型安全）
            Map<String, Object> arguments = new HashMap<>();
            arguments.put("result", result);  // 确保result是可序列化类型
            arguments.put("isLast", true);
            mainHandler.post(() -> { 
                channel.invokeMethod("onRecognizeResult", arguments);
            });
           
        } else if (event == Constants.NuiEvent.EVENT_ASR_PARTIAL_RESULT) {
            JSONObject jsonObject = JSON.parseObject(asrResult.asrResult);
            JSONObject payload = jsonObject.getJSONObject("payload");
            String result = payload.getString("result");
            Log.i(TAG, "EVENT_ASR_PARTIAL_RESULT " + result);
            Map<String, Object> arguments = new HashMap<>();
            arguments.put("result", result);  // 确保result是可序列化类型
            arguments.put("isLast", true);
            mainHandler.post(() -> { 
                channel.invokeMethod("onRecognizeResult", arguments);
            });
        } else if (event == Constants.NuiEvent.EVENT_ASR_ERROR) {
            // asrResult在EVENT_ASR_ERROR中为错误信息，搭配错误码resultCode和其中的task_id更易排查问题，请用户进行记录保存。 
            final String msg_text = Utils.getMsgWithErrorCode(resultCode, "start");
            mStopping = false;
        } else if (event == Constants.NuiEvent.EVENT_VAD_START) {

        } else if (event == Constants.NuiEvent.EVENT_VAD_END) {

        } else if (event == Constants.NuiEvent.EVENT_MIC_ERROR) {
            // EVENT_MIC_ERROR表示2s未传入音频数据，请检查录音相关代码、权限或录音模块是否被其他应用占用。
            final String msg_text = Utils.getMsgWithErrorCode(resultCode, "start");
            mStopping = false;
            // 此处也可重新启动录音模块
        } else if (event == Constants.NuiEvent.EVENT_DIALOG_EX) { /* unused */
            Log.i(TAG, "dialog extra message = " + asrResult.asrResult);
        }
    }

    //当调用NativeNui的start后，会一定时间反复回调该接口，底层会提供buffer并告知这次需要数据的长度
    //返回值告知底层读了多少数据，应该尽量保证return的长度等于需要的长度，如果返回<=0，则表示出错
    @Override
    public int onNuiNeedAudioData(byte[] buffer, int len) {
        if (mAudioRecorder == null) {
            return -1;
        }
        if (mAudioRecorder.getState() != AudioRecord.STATE_INITIALIZED) {
            Log.e(TAG, "audio recorder not init");
            return -1;
        }

        // 送入SDK
        int audio_size = mAudioRecorder.read(buffer, 0, len);

        // 音频存储到本地
        // if (mSaveAudioSwitch.isChecked() && audio_size > 0) {
        //     if (mRecordingAudioFile == null) {
        //         // 音频存储文件未打开，则等获得task_id后打开音频存储文件，否则数据存储到tmpAudioQueue
        //         if (!curTaskId.isEmpty() && mRecordingAudioFile == null) {
        //             try {
        //                 mRecordingAudioFilePath = mDebugPath + "/" + "sr_task_id_" + curTaskId + ".pcm";
        //                 Log.i(TAG, "save recorder data into " + mRecordingAudioFilePath);
        //                 mRecordingAudioFile = new FileOutputStream(mRecordingAudioFilePath, true);
        //             } catch (IOException e) {
        //                 e.printStackTrace();
        //             }
        //         } else {
        //             tmpAudioQueue.offer(buffer);
        //         }
        //     }
        //     if (mRecordingAudioFile != null) {
        //         // 若tmpAudioQueue有存储的音频，先存到音频存储文件中
        //         if (tmpAudioQueue.size() > 0) {
        //             try {
        //                 // 将未打开recorder前的音频存入文件中
        //                 byte[] audioData = tmpAudioQueue.take();
        //                 try {
        //                     mRecordingAudioFile.write(audioData);
        //                 } catch (IOException e) {
        //                     e.printStackTrace();
        //                 }
        //             } catch (InterruptedException e) {
        //                 e.printStackTrace();
        //             }
        //         }

        //         // 当前音频数据存到音频存储文件
        //         try {
        //             mRecordingAudioFile.write(buffer);
        //         } catch (IOException e) {
        //             e.printStackTrace();
        //         }
        //     }
        // }

        return audio_size;
    }

    //当录音状态发送变化的时候调用
    @Override
    public void onNuiAudioStateChanged(Constants.AudioState state) {
        Log.i(TAG, "onNuiAudioStateChanged");
        if (state == Constants.AudioState.STATE_OPEN) {
            Log.i(TAG, "audio recorder start");
            if (mAudioRecorder != null) {
                mAudioRecorder.startRecording();
            }
            Log.i(TAG, "audio recorder start done");
        } else if (state == Constants.AudioState.STATE_CLOSE) {
            Log.i(TAG, "audio recorder close");
            if (mAudioRecorder != null) {
                mAudioRecorder.release();
            }

            try {
                if (mRecordingAudioFile != null) {
                    mRecordingAudioFile.close();
                    mRecordingAudioFile = null;
                    String show = "存储录音音频到 " + mRecordingAudioFilePath;


                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        } else if (state == Constants.AudioState.STATE_PAUSE) {
            Log.i(TAG, "audio recorder pause");
            if (mAudioRecorder != null) {
                mAudioRecorder.stop();
            }

            try {
                if (mRecordingAudioFile != null) {
                    mRecordingAudioFile.close();
                    mRecordingAudioFile = null;
                    String show = "存储录音音频到 " + mRecordingAudioFilePath;
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onNuiAudioRMSChanged(float val) {
//        Log.i(TAG, "onNuiAudioRMSChanged vol " + val);
    }

    @Override
    public void onNuiVprEventCallback(Constants.NuiVprEvent event) {
        Log.i(TAG, "onNuiVprEventCallback event " + event);
    }

    @Override
    public void onNuiLogTrackCallback(Constants.LogLevel level, String log) {
//        Log.i(TAG, "onNuiLogTrackCallback log level:" + level + ", message -> " + log);
    }
}