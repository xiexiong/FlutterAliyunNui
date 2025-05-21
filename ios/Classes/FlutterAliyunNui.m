//
//  FlutterAliyunNui.m
//  flutter_aliyun_nui
//
//  Created by andy on 2025/5/20.
//

#import "FlutterAliyunNui.h"

static BOOL save_wav = NO;
static BOOL save_log = NO;
static BOOL is_stopping = NO;
static NuiVadMode vad_mode = MODE_VAD;
static NSString *debug_path = @"";
static dispatch_queue_t sr_work_queue;

static FlutterAliyunNui *myself = nil;


@implementation FlutterAliyunNui
{
    FlutterResult _startResult;
}

- (NeoNui *)nui {
    if (!_nui) {
        _nui = [NeoNui get_instance];
        _nui.delegate = self;
    }
    return _nui;
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel{
    self = [super init];
    if (self) {
        myself = self;
        _channel = channel;
        _utils = [NuiSdkUtils alloc];
        _recordedVoiceData = [NSMutableData data];
        _audioController = [[AudioController alloc] init:only_recorder];
        _audioController.delegate = self;
    }
    return self;
}

// 语音识别 sdk 初始化
- (NSString *)nuiSdkInit:(NSDictionary *)args {
    //请注意此处的参数配置，其中账号相关需要按照genInitParams的说明填入后才可访问服务
    NSString * initParam = [self genInitParams:args];
    
    NuiResultCode retCode = [self.nui nui_initialize:[initParam UTF8String] logLevel:NUI_LOG_LEVEL_VERBOSE saveLog:save_log];
    TLog(@"nui initialize with code:%d", retCode);
    NSString *errorShow = [NSString stringWithFormat:@"%d",retCode];
    if (retCode != 0) {
        NSString *errInfo = [_utils getGuideWithError:retCode withError:@"" withStatus:@"init"];
        errorShow = [NSString stringWithFormat:@"error code:%d\nerror mesg: %@",
                                 (int)retCode, errInfo];
    }

    NSString * parameters = [self genParams];
    [self.nui nui_set_params:[parameters UTF8String]];
    return  errorShow;
}

// 开始语音识别
- (void)startRecognizeWithToken:(NSString *)token result:(FlutterResult)result {
    _startResult = result;
    TLog(@"click START BUTTON, start recorder!");
    is_stopping = NO;
    if (_audioController == nil) {
        // 注意：这里audioController模块仅用于录音示例，用户可根据业务场景自行实现这部分代码
        _audioController = [[AudioController alloc] init:only_recorder];
        _audioController.delegate = self;
    }

    if (_audioController != nil) {
        if (sr_work_queue == NULL){
            sr_work_queue = dispatch_queue_create("NuiSRController", DISPATCH_QUEUE_CONCURRENT);
        }

        dispatch_async(sr_work_queue, ^{
            if (self->_nui != nil) {
                //若需要修改token等参数, 可详见genDialogParams()
                NSString * parameters = [self genDialogParams:token];
                //若要使用VAD模式，则需要设置nls_config参数启动在线VAD模式(见genParams())
                // 因为VAD断句用到的是云端VAD，所以nui_dialog_start入参为MODE_P2T
                [self->_nui nui_dialog_start:MODE_P2T dialogParam:[parameters UTF8String]];
            } else {
                TLog(@"in StartButHandler no nui alloc");
            }
        });
    }
   
}

// 停止语音识别
- (void)stopRecognize {
    self.recordedVoiceData = nil;
    is_stopping = YES;
    if (_nui != nil) {
        [_nui nui_dialog_cancel:NO];
        if (_audioController != nil) {
            [_audioController stopRecorder:NO];
        }
    } else {
        TLog(@"in StopButHandler no nui alloc");
    }
}

#pragma mark - Voice Recorder Delegate
-(void) recorderDidStart{
    TLog(@"recorderDidStart");
}

-(void) recorderDidStop{
    [self.recordedVoiceData setLength:0];
    TLog(@"recorderDidStop");
}

-(void) voiceRecorded:(unsigned char*)buffer Length:(int)len{
    NSData *frame = [NSData dataWithBytes:buffer length:len];
    @synchronized(_recordedVoiceData){
        [_recordedVoiceData appendData:frame];
    }
}

-(void) voiceDidFail:(NSError*)error{
    TLog(@"recorder error ");
    [_channel invokeMethod:@"onError" arguments:@{@"errorCode": @(error.code), @"errorMessage": error.userInfo.description ?: @""}];
}

#pragma mark - Nui Listener
-(void)onNuiEventCallback:(NuiCallbackEvent)nuiEvent
                   dialog:(long)dialog
                kwsResult:(const char *)wuw
                asrResult:(const char *)asr_result
                 ifFinish:(bool)finish
                  retCode:(int)code {
    TLog(@"onNuiEventCallback event %d finish %d", nuiEvent, finish);
    if (nuiEvent == EVENT_ASR_STARTED) {
        // asr_result在此包含task_id，task_id有助于排查问题，请用户进行记录保存。
        NSString *startedInfo = [NSString stringWithFormat:@"EVENT_ASR_STARTED: %@",
                                 [NSString stringWithUTF8String:asr_result]];
        TLog(@"%@", startedInfo);
         
    } else if (nuiEvent == EVENT_ASR_PARTIAL_RESULT) {
        // asr_result在此包含task_id，task_id有助于排查问题，请用户进行记录保存。
        NSString *asrPartialResult = [NSString stringWithFormat:@"EVENT_ASR_PARTIAL_RESULT: %@",
                                      [NSString stringWithUTF8String:asr_result]];
        TLog(@"%@", asrPartialResult);
        NSString *result = [myself getAsrFromResult:asr_result];
        [_channel invokeMethod:@"onRecognizeResult" arguments:@{@"result": result ?: @"",@"isLast": @(0)}];
    } else if (nuiEvent == EVENT_ASR_RESULT) {
        // asr_result在此包含task_id，task_id有助于排查问题，请用户进行记录保存。
        NSString *asrFinalResult = [NSString stringWithFormat:@"EVENT_ASR_RESULT: %@, finish: %@",
                                    [NSString stringWithUTF8String:asr_result],
                                    finish ? @"YES" : @"NO"];
        TLog(@"%@", asrFinalResult);
        NSString *result = [myself getAsrFromResult:asr_result];
        is_stopping = NO;
        [_channel invokeMethod:@"onRecognizeResult" arguments:@{@"result": result ?: @"",@"isLast": @(1)}];
    } else if (nuiEvent == EVENT_VAD_START) {
        TLog(@"EVENT_VAD_START");
    } else if (nuiEvent == EVENT_VAD_END) {
        TLog(@"EVENT_VAD_END");
    } else if (nuiEvent == EVENT_ASR_ERROR) {
        // asr_result在EVENT_ASR_ERROR中为错误信息，搭配错误码code和其中的task_id更易排查问题，请用户进行记录保存。
        const char* all_response = [_nui nui_get_all_response];
        NSString *errorMessage = [NSString stringWithFormat:@"EVENT_ASR_ERROR error[%d], all mesg[%@]",
                                  (int)code, [NSString stringWithUTF8String:all_response]];
        TLog(@"%@", errorMessage);

        NSString *result = [NSString stringWithUTF8String:asr_result];
        NSString *errInfo = [_utils getGuideWithError:code withError:result withStatus:@"run"];

        NSString *errorDetail = [NSString stringWithFormat:@"error code:%d\nerror mesg: %@\n\n%@",
                                 (int)code, [myself getErrMesgFromResponse:all_response], errInfo];

        if (_audioController != nil) {
            [_audioController stopRecorder:NO];
            [_audioController startRecorder];
        }
        is_stopping = NO;
        if (_startResult) {
            _startResult(@(code));
        }
        [_channel invokeMethod:@"onError" arguments:@{@"errorCode": @(code), @"errorMessage": errorDetail ?: @""}];
    } else if (nuiEvent == EVENT_MIC_ERROR) {
        TLog(@"MIC ERROR");
        if (_audioController != nil) {
            [_audioController stopRecorder:NO];
            [_audioController startRecorder];
        }
        is_stopping = NO;
//        [_channel invokeMethod:@"onError" arguments:@{@"errorCode": @(code), @"errorMessage": @"EVENT_MIC_ERROR"}];
    }
    
    //finish 为真（可能是发生错误，也可能是完成识别）表示一次任务生命周期结束，可以开始新的识别
    if (finish) {
 
    }
    
    return;
}

-(int)onNuiNeedAudioData:(char *)audioData length:(int)len {
//    TLog(@"onNuiNeedAudioData");
    static int emptyCount = 0;
    @autoreleasepool {
        @synchronized(_recordedVoiceData){
            if (_recordedVoiceData.length > 0) {
                int recorder_len = 0;
                if (_recordedVoiceData.length > len)
                    recorder_len = len;
                else
                    recorder_len = _recordedVoiceData.length;
                NSData *tempData = [_recordedVoiceData subdataWithRange:NSMakeRange(0, recorder_len)];
                [tempData getBytes:audioData length:recorder_len];
                tempData = nil;
                NSInteger remainLength = _recordedVoiceData.length - recorder_len;
                NSRange range = NSMakeRange(recorder_len, remainLength);
                [_recordedVoiceData setData:[_recordedVoiceData subdataWithRange:range]];
                emptyCount = 0;
                return recorder_len;
            } else {
                if (emptyCount++ >= 50) {
                    TLog(@"_recordedVoiceData length = %lu! empty 50times.", (unsigned long)_recordedVoiceData.length);
                    emptyCount = 0;
                }
                return 0;
            }

        }
    }
    return 0;
}
-(void)onNuiAudioStateChanged:(NuiAudioState)state{
    TLog(@"onNuiAudioStateChanged state=%u", state);
    if (state == STATE_CLOSE) {
        if (_audioController != nil) {
            [_audioController stopRecorder:NO];
        }
    } else if (state == STATE_PAUSE) {
        if (_audioController != nil) {
            [_audioController stopRecorder:NO];
        }
    } else if (state == STATE_OPEN){
        self.recordedVoiceData = [NSMutableData data];
        if (_audioController != nil) {
            [_audioController startRecorder];
        }
    }
}

-(void)onNuiRmsChanged:(float)rms {
//    TLog(@"onNuiRmsChanged rms=%f", rms);
}

-(void)onNuiLogTrackCallback:(NuiSdkLogLevel)level
                  logMessage:(const char *)log {
    TLog(@"onNuiLogTrackCallback log level:%d, message -> %s", level, log);
}



#pragma mark - Private methods
-(NSString*) getErrMesgFromResponse:(const char*)response {
    if (response == NULL || strlen(response) == 0) {
        return @"";
    } else {
        // 将 const char* 转换为 NSString
        NSString *jsonStr = [NSString stringWithUTF8String:response];
        // 将 JSON 字符串转换为 NSData
        NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        // 使用 NSJSONSerialization 解析 JSON
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (!error && jsonDict) {
            // 从字典中获取 status_text
            NSDictionary *header = jsonDict[@"header"];
            NSString *statusText = header[@"status_text"];
            return statusText;
        } else {
            return @"";
        }
    }
}

-(NSString*) getAsrFromResult:(const char*)response {
    if (response == NULL || strlen(response) == 0) {
        return @"";
    } else {
        // 将 const char* 转换为 NSString
        NSString *jsonStr = [NSString stringWithUTF8String:response];
        // 将 JSON 字符串转换为 NSData
        NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        // 使用 NSJSONSerialization 解析 JSON
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (!error && jsonDict) {
            // 从字典中获取 status_text
            NSDictionary *payload = jsonDict[@"payload"];
            NSString *result = payload[@"result"];
            return result;
        } else {
            return @"";
        }
    }
}


-(NSString*) genInitParams:(NSDictionary *)flutterInitArgs {
     
    NSString *appkey = [flutterInitArgs objectForKey:@"appKey"];
    NSString *token = [flutterInitArgs objectForKey:@"token"];
    NSString *deviceId = [flutterInitArgs objectForKey:@"deviceId"];
    NSString *url = [flutterInitArgs objectForKey:@"url"];
    
    NSMutableDictionary *ticketJsonDict = [NSMutableDictionary dictionary];
    //获取账号访问凭证：
    [ticketJsonDict setObject:appkey forKey:@"app_key"];
    [ticketJsonDict setObject:token forKey:@"token"];
    [ticketJsonDict setObject:deviceId forKey:@"device_id"];
    [ticketJsonDict setObject:url forKey:@"url"];
 

    //当初始化SDK时的save_log参数取值为true时，该参数生效。表示是否保存音频debug，该数据保存在debug目录中，需要确保debug_path有效可写
    [ticketJsonDict setObject:save_wav ? @"true" : @"false" forKey:@"save_wav"];
    //debug目录，当初始化SDK时的save_log参数取值为true时，该目录用于保存中间音频文件
    [ticketJsonDict setObject:debug_path forKey:@"debug_path"];

    //过滤SDK内部日志通过回调送回到用户层
    [ticketJsonDict setObject:[NSString stringWithFormat:@"%d", NUI_LOG_LEVEL_ERROR] forKey:@"log_track_level"];
    //设置本地存储日志文件的最大字节数, 最大将会在本地存储2个设置字节大小的日志文件
    [ticketJsonDict setObject:@(50 * 1024 * 1024) forKey:@"max_log_file_size"];

    //FullMix = 0   // 选用此模式开启本地功能并需要进行鉴权注册
    //FullCloud = 1 // 在线实时语音识别可以选这个
    //FullLocal = 2 // 选用此模式开启本地功能并需要进行鉴权注册
    //AsrMix = 3    // 选用此模式开启本地功能并需要进行鉴权注册
    //AsrCloud = 4  // 在线一句话识别可以选这个
    //AsrLocal = 5  // 选用此模式开启本地功能并需要进行鉴权注册
    [ticketJsonDict setObject:@"4" forKey:@"service_mode"]; // 必填
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:ticketJsonDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString * jsonStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return jsonStr;
}


-(NSString*) genParams {
    NSMutableDictionary *nls_config = [NSMutableDictionary dictionary];
    [nls_config setValue:@YES forKey:@"enable_intermediate_result"]; // 是否返回中间识别结果，默认值：False
    [nls_config setValue:@YES forKey:@"enable_punctuation_prediction"]; // 是否在后处理中添加标点，默认值：False

    //参数可根据实际业务进行配置
    //接口说明可见: https://help.aliyun.com/document_detail/173298.html
    //查看 2.开始识别

    //由于对外的SDK(01B版本)不带有本地VAD模块(仅带有唤醒功能(029版本)的SDK具有VAD模块)，
    //若要使用VAD模式，则需要设置nls_config参数启动在线VAD模式(见genParams())
    if (vad_mode == MODE_VAD) {
        [nls_config setValue:@YES forKey:@"enable_voice_detection"];
        [nls_config setValue:@10000 forKey:@"max_start_silence"];
        [nls_config setValue:@800 forKey:@"max_end_silence"];
    }

//    [nls_config setValue:@"<更新token>" forKey:@"token"];
//    [nls_config setValue:@YES forKey:@"enable_punctuation_prediction"];
//    [nls_config setValue:@YES forKey:@"enable_inverse_text_normalization"];
//    [nls_config setValue:@16000 forKey:@"sample_rate"];
//    [nls_config setValue:@"opus" forKey:@"sr_format"];

    NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
    [dictM setObject:nls_config forKey:@"nls_config"];
    [dictM setValue:@(SERVICE_TYPE_ASR) forKey:@"service_type"]; // 必填

//    如果有HttpDns则可进行设置
//    [dictM setObject:[_utils getDirectIp] forKey:@"direct_ip"];
    
    /*若文档中不包含某些参数，但是此功能支持这个参数，可以用如下万能接口设置参数*/
//    NSMutableDictionary *extend_config = [NSMutableDictionary dictionary];
//    [extend_config setValue:@YES forKey:@"custom_test"];
//    [dictM setObject:extend_config forKey:@"extend_config"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictM options:NSJSONWritingPrettyPrinted error:nil];
    NSString * jsonStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return jsonStr;
}

-(NSString*) genDialogParams:(NSString *)token {
    NSMutableDictionary *dialog_params = [NSMutableDictionary dictionary];

    // 运行过程中可以在nui_dialog_start时更新临时参数，尤其是更新过期token
    // 注意: 若下一轮对话不再设置参数，则继续使用初始化时传入的参数
    long distance_expire_time_5m = 300;
    [_utils refreshTokenIfNeed:dialog_params distanceExpireTime:distance_expire_time_5m];

    // 注意: 若需要更换appkey和token，可以直接传入参数
//    [dialog_params setValue:@"" forKey:@"app_key"];
//    token = @"6373809de80541a4a433c7fa79e37a2a";
    [dialog_params setValue:token forKey:@"token"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dialog_params options:NSJSONWritingPrettyPrinted error:nil];
    NSString * jsonStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return jsonStr;
}

@end
