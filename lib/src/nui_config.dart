class InitRecognizeConfig {
  late String appKey;

  String? deviceId;
  String? url;
  String? format;
  String? voice;
  int? sampleRate;
  int? speechRate;
  int? pitchRate;
  int? volume;

  InitRecognizeConfig(
      {required this.appKey,
      this.deviceId,
      this.url,
      this.format,
      this.voice,
      this.sampleRate,
      this.speechRate,
      this.pitchRate,
      this.volume});

  InitRecognizeConfig.fromJson(Map<String, dynamic> json) {
    appKey = json['app_key'] ?? '';
    assert(appKey.isNotEmpty, 'appKey can not null');
    deviceId = json['device_id'] ?? '';
    url = json['url'] ?? 'wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1';
    format = json['format'] ?? 'pcm';
    voice = json['voice'] ?? 'xiaoyun';
    sampleRate = json['sample_rate'] ?? 16000;
    speechRate = json['speech_rate'] ?? 0;
    pitchRate = json['pitch_rate'] ?? 0;
    volume = json['volume'] ?? 50;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['app_key'] = appKey;
    data['device_id'] = deviceId ?? '';
    data['url'] = url ?? 'wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1';
    data['format'] = format ?? 'pcm';
    data['voice'] = voice ?? 'xiaoyun';
    data['sample_rate'] = sampleRate ?? 16000;
    data['speech_rate'] = speechRate ?? 0;
    data['pitch_rate'] = pitchRate ?? 0;
    data['volume'] = volume ?? 50;
    return data;
  }
}
