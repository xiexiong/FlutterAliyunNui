import android.util.Log;
class StreamTts {
    private static final String TAG = "StreamTts";

    public static void startStreamTts(String text, String voice, String speed, String pitch) {
        Log.d(TAG, "Starting Stream TTS with text: " + text + ", voice: " + voice + ", speed: " + speed + ", pitch: " + pitch);
    } 
}