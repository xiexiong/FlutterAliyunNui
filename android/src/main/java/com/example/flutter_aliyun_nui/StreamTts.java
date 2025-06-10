package com.example.flutter_aliyun_nui;

import android.content.Context;
import android.util.Log;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;

import com.alibaba.fastjson.JSONException;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.idst.nui.Constants;
import com.alibaba.idst.nui.INativeStreamInputTtsCallback;
import com.alibaba.idst.nui.NativeNui;

import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;


import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * 阿里云语音合成（流式TTS）Flutter插件核心实现
 */
public class StreamTts {
    private static final String TAG = "StreamTts";

    private final MethodChannel channel;
    private final Context context;

    private final NativeNui streamInputTtsInstance = new NativeNui(Constants.ModeType.MODE_STREAM_INPUT_TTS);
    private boolean isStarted = false;
    private String debugPath;
    private String mEncodeType = "pcm"; // 只支持PCM播放
    private String curTaskId = "";
    private String mSynthesisAudioFilePath = "";
    private OutputStream mSynthesisAudioFile = null;
    private boolean isFirstData = true;
    private List<String> sendText = new ArrayList<>();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    // 采样率16000
    private final AudioPlayer mAudioTrack = new AudioPlayer(new AudioPlayerCallback() {
        @Override
        public void playStart() {
            Log.i(TAG, "start play");
        }
        @Override
        public void playOver() {
            Log.i(TAG, "play over");
            mAudioTrack.stop();
            // mAudioTrack.releaseAudioTrack(); 
            mainHandler.post(() -> channel.invokeMethod("onPlayerDrainFinish", sendText)); 
        }
        @Override
        public void playSoundLevel(int level) {}
    });

    public StreamTts(Context context, MethodChannel channel) {
        this.context = context;
        this.channel = channel; 
    }

    /**
     * Flutter MethodChannel 入口
     */
    public void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> params = call.arguments();
        switch (call.method) {
            case "startStreamInputTts":
                startStreamInputTts(params, result);
                break;
            case "sendStreamInputTts":
                sendStreamInputTts(params);
                result.success(null);
                break;
            case "stopStreamInputTts":
                stopStreamInputTts();
                result.success(null);
                break;
            case "cancelStreamInputTts":
                cancelStreamInputTts();
                result.success(null);
                break;
            case "release":
                onDestroy();
                result.success(null);
            break;
            default:
                result.notImplemented();
        }
    }

    /**
     * 初始化并启动流式TTS
     */
    private void startStreamInputTts(Map<String, Object> params, MethodChannel.Result result) {
        if (debugPath == null) {
            debugPath = context.getExternalCacheDir().getAbsolutePath() + "/debug";
            Utils.createDir(debugPath);
        }
        sendText.clear();
        JSONObject json = new JSONObject(params);

        if (!isStarted) {
            Log.i(TAG, "start flow tts");
            int ret = startTts(json);
            if (Constants.NuiResultCode.SUCCESS == ret) {
                isStarted = true;
                Log.e(TAG, "start tts SUCCESS");
            } else {
                Log.e(TAG, "start tts failed");
            }
            result.success(ret);
        }
    }

    /**
     * 发送文本到TTS
     */
    private void sendStreamInputTts(Map<String, Object> params) {
        JSONObject json = new JSONObject(params);
        String text = json.getString("text");
        sendText.add(text);
        streamInputTtsInstance.sendStreamInputTts(text); 
    }

    /**
     * 停止TTS
     */
    private void stopStreamInputTts() {
        Log.i(TAG, "stop stream input tts");
        isStarted = false;
        streamInputTtsInstance.asyncStopStreamInputTts(); 
    }

    /**
     * 取消TTS
     */
    private void cancelStreamInputTts() {
        Log.i(TAG, "cancel stream input tts");
        isStarted = false;
        streamInputTtsInstance.cancelStreamInputTts();
        mAudioTrack.stop();
    }

    /**
     * 销毁资源
     */
    private void onDestroy() {
        mAudioTrack.stop();
        // mAudioTrack.releaseAudioTrack();
        if (isStarted) {
            streamInputTtsInstance.cancelStreamInputTts();
            isStarted = false;
        }
    }

    /**
     * 生成鉴权ticket
     */
    private String genTicket(JSONObject json) {
        String str = "";
        String g_appkey = json.getString("app_key");
        String g_token = json.getString("token");
        String device_id = json.getString("device_id");
        String url = json.getString("url");
        try {
            Auth.GetTicketMethod method = Auth.GetTicketMethod.GET_TOKEN_FROM_SERVER_FOR_ONLINE_FEATURES;
            if (!g_appkey.isEmpty()) Auth.setAppKey(g_appkey);
            if (!g_token.isEmpty()) Auth.setToken(g_token);

            if (!g_appkey.isEmpty() && !g_token.isEmpty()) {
                method = Auth.GetTicketMethod.GET_TOKEN_IN_CLIENT_FOR_ONLINE_FEATURES;
            }
            Log.i(TAG, "Use method:" + method);
            JSONObject object = Auth.getTicket(method);
            if (!object.containsKey("token") && !object.containsKey("sts_token")) {
                Log.e(TAG, "Cannot get token or sts_token!!!");
            }

            if (url.isEmpty()) {
                url = "wss://nls-gateway-cn-beijing.aliyuncs.com/ws/v1";
            }
            object.put("device_id", device_id);
            object.put("url", url);

            if (!debugPath.isEmpty()) {
                object.put("debug_path", debugPath);
                object.put("max_log_file_size", 50 * 1024 * 1024);
            }
            object.put("log_track_level", String.valueOf(Constants.LogLevel.toInt(Constants.LogLevel.LOG_LEVEL_INFO)));
            str = object.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Log.i(TAG, "user ticket:" + str);
        return str;
    }

    /**
     * 生成TTS参数
     */
    private String genParameters(JSONObject json) {
        String str = "";
        try {
            String voice = json.getString("voice");
            String format = json.getString("format");
            int sample_rate = json.getIntValue("sample_rate");
            int volume = json.getIntValue("volume");
            int speech_rate = json.getIntValue("speech_rate");
            int pitch_rate = json.getIntValue("pitch_rate");
            String session_id = json.getString("session_id");
            JSONObject object = new JSONObject();
            object.put("enable_subtitle", false);
            object.put("voice", voice);
            object.put("format", format);
            object.put("sample_rate", sample_rate);
            object.put("volume", volume);
            object.put("speech_rate", speech_rate);
            object.put("pitch_rate", pitch_rate);
            object.put("session_id", session_id);
            str = object.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Log.i(TAG, "user parameters:" + str);
        return str;
    }

    /**
     * 启动TTS
     */
    private int startTts(JSONObject json) {
        int ret = streamInputTtsInstance.startStreamInputTts(new INativeStreamInputTtsCallback() {
            @Override
            public void onStreamInputTtsEventCallback(
                    INativeStreamInputTtsCallback.StreamInputTtsEvent event, String task_id,
                    String session_id, int ret_code, String error_msg,
                    String timestamp, String all_response) {
                Log.i(TAG, "stream input tts event(" + event +
                        ") session id(" + session_id +
                        ") task id(" + task_id +
                        ") retCode(" + ret_code +
                        ") errMsg(" + error_msg + ")");
                if (event == StreamInputTtsEvent.STREAM_INPUT_TTS_EVENT_SYNTHESIS_STARTED) {
                    Log.i(TAG, "STREAM_INPUT_TTS_EVENT_SYNTHESIS_STARTED");
                    isFirstData = true;
                    curTaskId = task_id;
                    mAudioTrack.play();
                } else if (event == StreamInputTtsEvent.STREAM_INPUT_TTS_EVENT_SENTENCE_SYNTHESIS) {
                    Log.i(TAG, "STREAM_INPUT_TTS_EVENT_SENTENCE_SYNTHESIS:" + timestamp);
                } else if (event == StreamInputTtsEvent.STREAM_INPUT_TTS_EVENT_SYNTHESIS_COMPLETE ||
                        event == StreamInputTtsEvent.STREAM_INPUT_TTS_EVENT_TASK_FAILED) {
                    isStarted = false;
                    Log.i(TAG, "play end");
                    mAudioTrack.isFinishSend(true);
                    try {
                        if (mSynthesisAudioFile != null) {
                            mSynthesisAudioFile.close();
                            mSynthesisAudioFile = null;
                            if (mEncodeType.equals("wav")) {
                                Utils.fixWavHeader(mSynthesisAudioFilePath);
                            }
                            Log.i(TAG, "存储TTS音频到 " + mSynthesisAudioFilePath);
                        }
                        curTaskId = "";
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    if (event == StreamInputTtsEvent.STREAM_INPUT_TTS_EVENT_TASK_FAILED) {
                        Log.e(TAG, "STREAM_INPUT_TTS_EVENT_TASK_FAILED: error_code(" + ret_code + ") error_message(" + error_msg + ")");
                        Utils.getMsgWithErrorCode(ret_code, error_msg);
                    }
                } else if (event == StreamInputTtsEvent.STREAM_INPUT_TTS_EVENT_SENTENCE_BEGIN) {
                    Log.i(TAG, "STREAM_INPUT_TTS_EVENT_SENTENCE_BEGIN:" + all_response);
                } else if (event == StreamInputTtsEvent.STREAM_INPUT_TTS_EVENT_SENTENCE_END) {
                    Log.i(TAG, "STREAM_INPUT_TTS_EVENT_SENTENCE_END:" + all_response);
                }
            }
            @Override
            public void onStreamInputTtsDataCallback(byte[] data) {
                if (data.length > 0) {
                    if (isFirstData) {
                        isFirstData = false;
                        Log.i(TAG, "Get first audio data.");
                    }
                    if (mEncodeType.equals("pcm") || mEncodeType.equals("wav")) {
                        mAudioTrack.setAudioData(data);
                    }
                    try {
                        if (mSynthesisAudioFile != null) {
                            mSynthesisAudioFile.write(data);
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
            @Override
            public void onStreamInputTtsLogTrackCallback(Constants.LogLevel level, String log) {
                Log.i(TAG, "onStreamInputTtsLogTrackCallback log level:" + level + ", message -> " + log);
            }
        }, genTicket(json), genParameters(json), "",
                Constants.LogLevel.toInt(Constants.LogLevel.LOG_LEVEL_VERBOSE), true);

        if (Constants.NuiResultCode.SUCCESS != ret) {
            Log.i(TAG, "start tts failed " + ret);
            isStarted = false;
            Utils.getMsgWithErrorCode(ret, "start");
        } else {
            isStarted = true;
        }
        return ret;
    }
}