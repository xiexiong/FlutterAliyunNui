//
//  FlutterAliyunNui.h
//  flutter_aliyun_nui
//
//  Created by andy on 2025/5/20.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "AudioController.h"
#import <nuisdk/NeoNui.h>
#import "NuiSdkUtils.h"

@interface FlutterAliyunNui : NSObject <ConvVoiceRecorderDelegate, NeoNuiSdkDelegate>

@property (nonatomic, weak) FlutterMethodChannel *channel;
@property (nonatomic, strong) NSMutableData *recordedVoiceData;
@property (nonatomic, strong) AudioController *audioController;
@property (nonatomic, strong) NeoNui *nui; 
@property (nonatomic, strong) NuiSdkUtils *utils;
 

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel;

// 语音识别 sdk 初始化
- (NSString *)nuiSdkInit:(NSDictionary *)args;

// 开始语音识别
- (void)startRecognizeWithToken:(NSString *)token result:(FlutterResult)result;

// 停止语音识别
- (void)stopRecognize;

@end
