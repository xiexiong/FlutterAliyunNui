//
//  FlutterAliyunNui.h
//  flutter_aliyun_nui
//
//  Created by andy on 2025/5/20.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface FlutterAliyunNui : NSObject  

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel;

// 语音识别 sdk 初始化
- (NSString *)nuiSdkInit:(NSDictionary *)args;

// 开始语音识别
- (void)startRecognizeWithToken:(NSString *)token result:(FlutterResult)result;

// 停止语音识别
- (void)stopRecognize;

// 释放语音识别对象
- (void)nuiRelase;

// 开始合成
- (void)startStreamInputTts:(NSDictionary *)args result:(FlutterResult)result;

// 流式播放
- (void)sendStreamInputTts:(NSDictionary *)args;

// 停止播放
- (void)stopStreamInputTts;

// 取消
- (void)cancelStreamInputTts;

// 暂停播放
- (void)pauseTts;

// 继续播放
- (void)resumeTts;



@end
