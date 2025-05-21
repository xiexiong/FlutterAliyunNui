#import "FlutterAliyunNuiPlugin.h"
#import "FlutterAliyunNui.h"


@implementation FlutterAliyunNuiPlugin {
    FlutterMethodChannel *_channel;
//    TTSUtil *_ttsUtil;
    FlutterAliyunNui *_nui; 
}

- (FlutterAliyunNui *)nui {
    if (!_nui) {
        _nui = [[FlutterAliyunNui alloc] initWithChannel:_channel];
    }
    return _nui;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
            methodChannelWithName:@"flutter_aliyun_nui"
                  binaryMessenger:[registrar messenger]];
    FlutterAliyunNuiPlugin* instance = [[FlutterAliyunNuiPlugin alloc] init];
    instance->_channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}



- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        result([self.nui nuiSdkInit:call.arguments]);
    } else if ([@"startRecognize" isEqualToString:call.method]) {
        NSString *token = [call.arguments objectForKey:@"token"];
        [self.nui startRecognizeWithToken:token result:result];
    } else if ([@"stopRecognize" isEqualToString:call.method]) {
        [self.nui  stopRecognize];
        result(nil);
    } else if ([@"release" isEqualToString:call.method]) {
        [self.nui.nui nui_release];
        result(nil);
    }else if ([@"playText" isEqualToString:call.method]) {
//        NSString *text = call.arguments[@"Text"];
//        if (text != NULL && text.length > 0) {
//            [_ttsUtil playText:text];
//        } else if (_ttsUtil == NULL) {
//            _ttsUtil = [[TTSUtil alloc] initWithChannel:_channel utils:_utils audioController:_audioController];
//        } 
    } else if ([@"pauseTTS" isEqualToString:call.method]) {
         
    } else if ([@"resumeTTS" isEqualToString:call.method]) {
         
    } else if ([@"stopTTS" isEqualToString:call.method]) {
         
    } else {
        result(FlutterMethodNotImplemented);
    }
}
     

@end
