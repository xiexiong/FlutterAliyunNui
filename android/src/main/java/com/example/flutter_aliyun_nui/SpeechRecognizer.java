package com.example.flutter_aliyun_nui;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.util.Log;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONException;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.idst.nui.AsrResult;
import com.alibaba.idst.nui.Constants;
import com.alibaba.idst.nui.INativeNuiCallback;
import com.alibaba.idst.nui.KwsResult;
import com.alibaba.idst.nui.NativeNui;

import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.LinkedBlockingQueue;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * 阿里云语音识别 Flutter 插件核心实现
 */
public class SpeechRecognizer implements INativeNuiCallback {
    private static final String TAG = "SpeechRecognizer";
    private static final int SAMPLE_RATE = 16000;
    private static final int WAVE_FRAME_SIZE = 20 * 2 * 1 * SAMPLE_RATE / 1000; // 20ms audio for 16k/16bit/mono

    private final MethodChannel channel;
    private final Context context;
    private final NativeNui nuiInstance = new NativeNui();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final String[] permissions = {Manifest.permission.RECORD_AUDIO};

    private AudioRecord audioRecorder = null;
    private Handler handler;
    private boolean isInit = false;
    private boolean isStopping = false;
    private String debugPath = "";
    private String curTaskId = "";
    private final LinkedBlockingQueue<byte[]> tmpAudioQueue = new LinkedBlockingQueue<>();
    private String recordingAudioFilePath = "";
    private OutputStream recordingAudioFile = null;

    public SpeechRecognizer(Context context, MethodChannel channel) {
        this.context = context;
        this.channel = channel;
    }

    /**
     * Flutter MethodChannel 入口
     */
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
                result.success(null);
                break;
            default:
                result.notImplemented();
        }
    }

    /**
     * 初始化 SDK
     */
    private void initNui(Map<String, Object> params, MethodChannel.Result result) {
        if (handler == null) {
            HandlerThread handlerThread = new HandlerThread("process_thread");
            handlerThread.start();
            handler = new Handler(handlerThread.getLooper());
            debugPath = context.getExternalCacheDir().getAbsolutePath() + "/debug";
            Utils.createDir(debugPath);
        }
        JSONObject json = new JSONObject(params);

        int ret = nuiInstance.initialize(this, genInitParams(debugPath, json),
                Constants.LogLevel.LOG_LEVEL_ERROR, true);
        Log.i(TAG, "NUI init result = " + ret);
        isInit = (ret == Constants.NuiResultCode.SUCCESS);
        if (isInit) {
            Log.i(TAG, "NUI init success");
        } else {
            Log.e(TAG, "NUI init failed: " + ret);
        }
        result.success(ret);
    }

    /**
     * 开始识别
     */
    private void startRecognize(Map<String, Object> params, MethodChannel.Result result) {
        JSONObject json = new JSONObject(params);
        Log.i(TAG, "startRecognize json = " + json);

        // 动态权限申请
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            int i = ContextCompat.checkSelfPermission(context, permissions[0]);
            if (i != PackageManager.PERMISSION_GRANTED && context instanceof Activity) {
                ((Activity) context).requestPermissions(permissions, 321);
            }
        }
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            if (audioRecorder == null) {
                audioRecorder = new AudioRecord(MediaRecorder.AudioSource.DEFAULT,
                        SAMPLE_RATE,
                        AudioFormat.CHANNEL_IN_MONO,
                        AudioFormat.ENCODING_PCM_16BIT,
                        WAVE_FRAME_SIZE * 4);
                Log.d(TAG, "AudioRecorder new ...");
            } else {
                Log.w(TAG, "AudioRecord has been new ...");
            }
        } else {
            Log.e(TAG, "donnot get RECORD_AUDIO permission!");
            result.success("-1");
            return;
        }

        handler.post(() -> {
            String setParamsString = genParams();
            Log.i(TAG, "nui set params " + setParamsString);
            nuiInstance.setParams(setParamsString);
            int ret = nuiInstance.startDialog(Constants.VadMode.TYPE_P2T,
                    genDialogParams(json.getString("token")));
            Log.i(TAG, "start done with " + ret);
            if (ret != 0) {
                final String msgText = Utils.getMsgWithErrorCode(ret, "start");
                Log.e(TAG, "startDialog failed: " + msgText);
                result.success("-1");
            } else {
                result.success("0");
            }
        });
    }

    /**
     * 停止识别
     */
    private void stopRecognize(MethodChannel.Result result) {
        handler.post(() -> {
            isStopping = true;
            long ret = nuiInstance.stopDialog();
            Log.i(TAG, "cancel dialog " + ret + " end");
        });
        result.success(null);
    }

    /**
     * 释放资源
     */
    private void release(MethodChannel.Result result) {
        nuiInstance.release();
        result.success(null);
    }

    /**
     * 生成识别参数
     */
    private String genParams() {
        try {
            JSONObject nlsConfig = new JSONObject();
            nlsConfig.put("enable_intermediate_result", true);
            nlsConfig.put("enable_punctuation_prediction", true);
            nlsConfig.put("sample_rate", SAMPLE_RATE);
            nlsConfig.put("sr_format", "pcm");
            nlsConfig.put("enable_voice_detection", false);

            JSONObject parameters = new JSONObject();
            parameters.put("nls_config", nlsConfig);
            parameters.put("service_type", Constants.kServiceTypeASR);
            return parameters.toString();
        } catch (JSONException e) {
            e.printStackTrace();
            return "";
        }
    }

    /**
     * 生成初始化参数
     */
    private String genInitParams(String debugPath, JSONObject json) {
        String gAppKey = json.getString("app_key");
        String gToken = json.getString("token");
        String deviceId = json.getString("device_id");
        String url = json.getString("url");
        try {
            Auth.GetTicketMethod method = Auth.GetTicketMethod.GET_TOKEN_FROM_SERVER_FOR_ONLINE_FEATURES;
            if (!gAppKey.isEmpty()) Auth.setAppKey(gAppKey);
            if (!gToken.isEmpty()) Auth.setToken(gToken);

            if (!gAppKey.isEmpty() && !gToken.isEmpty()) {
                method = Auth.GetTicketMethod.GET_TOKEN_IN_CLIENT_FOR_ONLINE_FEATURES;
            }
            Log.i(TAG, "Use method:" + method);
            JSONObject object = Auth.getTicket(method);
            if (!object.containsKey("token")) {
                Log.e(TAG, "Cannot get token !!!");
            }
            object.put("device_id", deviceId);
            object.put("url", url);
            object.put("save_wav", "true");
            object.put("debug_path", debugPath);
            object.put("log_track_level", String.valueOf(Constants.LogLevel.toInt(Constants.LogLevel.LOG_LEVEL_INFO)));
            object.put("service_mode", Constants.ModeAsrCloud);
            return object.toString();
        } catch (JSONException e) {
            e.printStackTrace();
            return "";
        }
    }

    /**
     * 生成对话参数
     */
    private String genDialogParams(String token) {
        try {
            JSONObject dialogParam = new JSONObject();
            long distanceExpireTime5m = 300;
            dialogParam = Auth.refreshTokenIfNeed(dialogParam, distanceExpireTime5m);
            dialogParam.put("token", token);
            return dialogParam.toString();
        } catch (JSONException e) {
            e.printStackTrace();
            return "";
        }
    }

    // ================== SDK 回调实现 ==================

    @Override
    public void onNuiEventCallback(Constants.NuiEvent event, final int resultCode,
                                   final int arg2, KwsResult kwsResult,
                                   AsrResult asrResult) {
        Log.i(TAG, "event=" + event + " resultCode=" + resultCode);

        switch (event) {
            case EVENT_ASR_STARTED:
                JSONObject jsonObject = JSON.parseObject(asrResult.allResponse);
                JSONObject header = jsonObject.getJSONObject("header");
                curTaskId = header.getString("task_id");
                break;
            case EVENT_ASR_RESULT:
                isStopping = false;
                JSONObject resultObj = JSON.parseObject(asrResult.asrResult);
                JSONObject payload = resultObj.getJSONObject("payload");
                String result = payload.getString("result");
                Log.i(TAG, "EVENT_ASR_RESULT " + result);
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("result", result);
                arguments.put("isLast", 1);
                mainHandler.post(() -> channel.invokeMethod("onRecognizeResult", arguments));
                break;
            case EVENT_ASR_PARTIAL_RESULT:
                JSONObject partialObj = JSON.parseObject(asrResult.asrResult);
                JSONObject partialPayload = partialObj.getJSONObject("payload");
                String partialResult = partialPayload.getString("result");
                Log.i(TAG, "EVENT_ASR_PARTIAL_RESULT " + partialResult);
                Map<String, Object> partialArguments = new HashMap<>();
                partialArguments.put("result", partialResult);
                partialArguments.put("isLast", 0);
                mainHandler.post(() -> channel.invokeMethod("onRecognizeResult", partialArguments));
                break;
            case EVENT_ASR_ERROR:
                final String msgText = Utils.getMsgWithErrorCode(resultCode, "start");
                isStopping = false;
                Log.e(TAG, "EVENT_ASR_ERROR: " + msgText);
                Map<String, Object> errorArguments = new HashMap<>();
                errorArguments.put("errorCode", 1);
                errorArguments.put("errorMessage", msgText);
                mainHandler.post(() -> channel.invokeMethod("onError", errorArguments));
                break;
            case EVENT_MIC_ERROR:
                final String micMsgText = Utils.getMsgWithErrorCode(resultCode, "start");
                isStopping = false;
                Log.e(TAG, "EVENT_MIC_ERROR: " + micMsgText);
                break;
            case EVENT_DIALOG_EX:
                Log.i(TAG, "dialog extra message = " + asrResult.asrResult);
                break;
            default:
                break;
        }
    }

    @Override
    public int onNuiNeedAudioData(byte[] buffer, int len) {
        if (audioRecorder == null || audioRecorder.getState() != AudioRecord.STATE_INITIALIZED) {
            Log.e(TAG, "audio recorder not init");
            return -1;
        }
        return audioRecorder.read(buffer, 0, len);
    }

    @Override
    public void onNuiAudioStateChanged(Constants.AudioState state) {
        Log.i(TAG, "onNuiAudioStateChanged: " + state);
        try {
            if (state == Constants.AudioState.STATE_OPEN) {
                if (audioRecorder == null || audioRecorder.getState() != AudioRecord.STATE_INITIALIZED) {
                    audioRecorder = new AudioRecord(
                            MediaRecorder.AudioSource.DEFAULT,
                            SAMPLE_RATE,
                            AudioFormat.CHANNEL_IN_MONO,
                            AudioFormat.ENCODING_PCM_16BIT,
                            WAVE_FRAME_SIZE * 4
                    );
                    Log.i(TAG, "AudioRecorder re-initialized in onNuiAudioStateChanged");
                }
                if (audioRecorder.getState() == AudioRecord.STATE_INITIALIZED) {
                    audioRecorder.startRecording();
                } else {
                    Log.e(TAG, "AudioRecord still not initialized, cannot startRecording!");
                }
            } else if (state == Constants.AudioState.STATE_CLOSE || state == Constants.AudioState.STATE_PAUSE) {
                if (audioRecorder != null) {
                    if (state == Constants.AudioState.STATE_PAUSE) audioRecorder.stop();
                    else audioRecorder.release();
                }
                if (recordingAudioFile != null) {
                    recordingAudioFile.close();
                    recordingAudioFile = null;
                    Log.i(TAG, "存储录音音频到 " + recordingAudioFilePath);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onNuiAudioRMSChanged(float val) {
        // 可选：音量变化回调
    }

    @Override
    public void onNuiVprEventCallback(Constants.NuiVprEvent event) {
        Log.i(TAG, "onNuiVprEventCallback event " + event);
    }

    @Override
    public void onNuiLogTrackCallback(Constants.LogLevel level, String log) {
        // 可选：SDK日志回调
    }
}