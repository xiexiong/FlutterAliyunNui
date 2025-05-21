////
////  TTSUtil.h
////  flutter_aliyun_nui
////
////  Created by andy on 2025/5/20.
//
//
////#define DEBUG_MODE
////#define DEBUG_TTS_DATA_SAVE
//#import "TTSUtil.h"
//#import "HWOptionButton.h"
//#import "NuiSdkUtils.h"
//
//
//
//#import "AudioController.h"
//#import <AVFoundation/AVFoundation.h>
//
//#ifdef DEBUG_TTS_DATA_SAVE
//FILE * fp;
//#endif
//
//static TTSUtil *myself = nil;
//
//// 本样例展示在线语音合成使用方法
//// iOS SDK 详细说明：https://help.aliyun.com/document_detail/173947.html
//@interface TTSUtil () <ConvVoiceRecorderDelegate, UITextFieldDelegate, HWOptionButtonDelegate, NeoNuiTtsDelegate> {
//     UIButton *PlayButton;
//     UIButton *TestButton;
//     UIButton *PauseButton;
//     UIButton *MultiPlayButton;
//     UITextView *textViewContent;
//
//     UILabel *labelFontName;
//     UILabel *labelModeType;
//     UILabel *labelSpeedLevel;
//     UILabel *labelPitchLevel;
//     UILabel *labelVolume;
//
//     UITextField *textfieldSpeedLevel;
//     UITextField *textfieldPitchLevel;
//     UITextField *textfieldVolume;
//    
//    NSString * playingContent;
//    FlutterMethodChannel *_channel;
//}
//
//@property(nonatomic, weak) HWOptionButton *fontName;
//@property(nonatomic, weak) HWOptionButton *modeType;
//@property(nonatomic) int ttsSampleRate;
//@end
//
//@implementation TTSUtil
//
//#define SCREEN_WIDTH_BASE 375
//#define SCREEN_HEIGHT_BASE 667
//
//static CGSize globalSize;
//static int loopIn = 0;
//static BOOL continuousPlaybackFlag = NO;
//static BOOL SegmentFinishPlaying = NO;
//static BOOL mSyntheticing = NO;  // TTS是否处于合成中
//static dispatch_queue_t workQueue;
//
//#pragma mark view controller methods
//
//- (instancetype)initWithChannel:(FlutterMethodChannel *)channel utils:(NuiSdkUtils *)utils audioController:(AudioController*)audioController{
//    self = [super init];
//    if (self) {
//        _channel = channel;
//        _utils = utils; 
//        _audioController = _audioController;
//        _audioController.delegate = self;
//    }
//    return self;
//}
//
//- (void)viewDidLoad {
//    TLog(@"TTSViewController did load");
//    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor whiteColor];
//    self.navigationItem.title = @"语音合成";
//
//    // Do any additional setup after loading the view.
//    globalSize = [UIScreen mainScreen].bounds.size;
//    TLog(@"TTSViewController-viewDidLoad mainScreen width=%f  height=%f",
//         globalSize.width, globalSize.height);
//
//    loopIn = TTS_EVENT_END;
//    myself = self;
//    
//    [self InitView];
//    
//    _utils = [NuiSdkUtils alloc];
//
//    workQueue = dispatch_queue_create("NuiTtsController", DISPATCH_QUEUE_CONCURRENT);
//
//    [self NuiTtsInit];
//}
//
//-(void)dealloc {
//    TLog(@"%s", __FUNCTION__);
//    // 若_nui未进行释放, 下次进入此view使用的_nui处于已初始化,
//    // 则再调用nui_tts_initialize无法覆盖已经设置的参数.
//    if (_audioController != nil) {
//        [_audioController cleanPlayerBuffer];
//    }
//    [_nui nui_tts_release];
//#ifdef DEBUG_TTS_DATA_SAVE
//    if (fp) {
//        fclose(fp);
//        fp = nullptr;
//    }
//#endif
//}
//
//- (void)dismissKeyboard:(id)sender {
//    [self.view endEditing:YES];
//}
//
//-(void)viewDidAppear:(BOOL)animated {
//    TLog(@"TTSViewController-viewDidAppear");
//    [super viewDidAppear:animated];
//    [self InitView];
//}
//
//-(void)viewWillDisappear:(BOOL)animated {
//    TLog(@"TTSViewController-viewWillDisappear");
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tts_test_loop:) object:testDataList];
//
//    if (_audioController != nil) {
//        [_audioController cleanPlayerBuffer];
//    }
//    // 若_nui未进行释放, 下次进入此view使用的_nui处于已初始化,
//    // 则再调用nui_tts_initialize无法覆盖已经设置的参数.
//    [_nui nui_tts_release];
//#ifdef DEBUG_TTS_DATA_SAVE
//    if (fp) {
//        fclose(fp);
//        fp = nullptr;
//    }
//#endif
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//}
//
//#pragma mark - Audio Player Delegate
//-(void)playerDidFinish {
//    //播放被中止后回调。
//    TLog(@"playerDidFinish");
//    SegmentFinishPlaying = YES;
//    if (continuousPlaybackFlag == NO) {
//        TLog(@"update UI of PlayButton");
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // UI更新代码
//            UIImage *image = [UIImage imageNamed:@"button_start"];
//            [PlayButton setBackgroundImage:image forState:UIControlStateNormal];
//            [PlayButton setTitle:@"播放" forState:UIControlStateNormal];
//            [PlayButton removeTarget:self action:@selector(stopTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PlayButton addTarget:self action:@selector(startTTS:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    }
//}
//-(void)playerDrainDataFinish {
//    //播放数据自然播放完成后回调。
//    TLog(@"playerDrainDataFinish");
//    SegmentFinishPlaying = YES;
//    if (continuousPlaybackFlag == NO) {
//        TLog(@"update UI of PlayButton");
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // UI更新代码
//            UIImage *image = [UIImage imageNamed:@"button_start"];
//            [PlayButton setBackgroundImage:image forState:UIControlStateNormal];
//            [PlayButton setTitle:@"播放" forState:UIControlStateNormal];
//            [PlayButton removeTarget:self action:@selector(stopTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PlayButton addTarget:self action:@selector(startTTS:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    }
//}
//
//#pragma mark -private methods
//
//-(NSString *)genInitParams {
////    NSString *strResourcesBundle = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
////    NSString *bundlePath = [[NSBundle bundleWithPath:strResourcesBundle] resourcePath]; // 注意: V2.6.2版本开始纯云端功能可不需要资源文件
//    NSString *debug_path = [_utils createDir];
//
//    NSMutableDictionary *ticketJsonDict = [NSMutableDictionary dictionary];
//    //获取账号访问凭证：
//    [ticketJsonDict setObject:@"K2W2xXRFH90s93gz" forKey:@"app_key"];
//    [ticketJsonDict setObject:@"f38646f7ab1f4d42a6b144e3461a6ffd" forKey:@"token"];
//    [ticketJsonDict setObject:@"660668cf0c874c848fbb467603927ebd" forKey:@"deviceId"];
//    [ticketJsonDict setObject:@"wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1" forKey:@"url"];
//
//    //工作目录路径，SDK从该路径读取配置文件
////    [ticketJsonDict setObject:bundlePath forKey:@"workspace"];  // V2.6.2版本开始纯云端功能可不设置workspace
////    TLog(@"workspace:%@", bundlePath);
//    [ticketJsonDict setObject:debug_path forKey:@"debug_path"];
//    TLog(@"debug_path:%@", debug_path);
//
//    //过滤SDK内部日志通过回调送回到用户层
//    [ticketJsonDict setObject:[NSString stringWithFormat:@"%d", NUI_LOG_LEVEL_INFO] forKey:@"log_track_level"];
//    //设置本地存储日志文件的最大字节数, 最大将会在本地存储2个设置字节大小的日志文件
//    [ticketJsonDict setObject:@(50 * 1024 * 1024) forKey:@"max_log_file_size"]; 
//
//    // 设置成在线语音合成模式, 这个设置很重要, 遗漏会导致无法运行
//    [ticketJsonDict setObject:@"2" forKey:@"mode_type"]; // 必填
//    
//    [ticketJsonDict setObject:@"empty_device_id" forKey:@"device_id"]; // 必填, 推荐填入具有唯一性的id, 方便定位问题
//
//    NSData *data = [NSJSONSerialization dataWithJSONObject:ticketJsonDict options:NSJSONWritingPrettyPrinted error:nil];
//    NSString * jsonStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    return jsonStr;
//}
//
//- (void)NuiTtsInit {
//    if (_nui == NULL) {
//        _nui = [NeoNuiTts get_instance];
//        _nui.delegate = self;
//    }
//    //请注意此处的参数配置，其中账号相关需要按照genInitParams的说明填入后才可访问服务
//    NSString * initParam = [self genInitParams];
//
//    int retcode = [_nui nui_tts_initialize:[initParam UTF8String] logLevel:NUI_LOG_LEVEL_VERBOSE saveLog:YES];
//    if (retcode != 0) {
//         TLog(@"init failed.retcode:%d", retcode);
//         return;
//     }
//#ifdef DEBUG_TTS_DATA_SAVE
//    NSString *sp = self.createDir;
//    const char* savePath = [sp UTF8String];
//
//    if (fp == nullptr) {
//        NSString *debug_file = [NSString stringWithFormat:@"%@/tts_dump.pcm", sp];
//        fp = fopen([debug_file UTF8String], "w");
//    }
//#endif
//}
//
//-(void)InitView {
//    // init Button
//    [self setButton];
//    // init TextView
//    [self setTextView];
//    // init Label
//    [self setLabel];
//    // init OptionButton
//    [self setOptionButton];
//    // init TextField
//    [self setTextField];
//}
//
//- (void)setButton {
//    int button_height_base = 65;
//
//    // ---- PlayButton ---
//    CGFloat button_width = globalSize.width/SCREEN_WIDTH_BASE * 80;
//    CGFloat button_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat x = globalSize.width/SCREEN_WIDTH_BASE * 27.5;
//    CGFloat y = globalSize.height/SCREEN_HEIGHT_BASE * button_height_base;
//    
//    PlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    PlayButton.frame = CGRectMake(x, y, button_width, button_height);
//    UIImage *image = [UIImage imageNamed:@"button_start"];
//    [PlayButton setBackgroundImage:image forState:UIControlStateNormal];
//    [PlayButton setTitle:@"播放" forState:UIControlStateNormal];
//    [PlayButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
//    PlayButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    [PlayButton addTarget:self action:@selector(startTTS:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:PlayButton];
//
//    // ---- PauseButton ---
//    CGFloat PauseButton_width = globalSize.width/SCREEN_WIDTH_BASE * 80;
//    CGFloat PauseButton_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat PauseButton_x = (globalSize.width - PauseButton_width)/2;
//    CGFloat PauseButton_y = globalSize.height/SCREEN_HEIGHT_BASE * button_height_base;
//
//    PauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    PauseButton.frame = CGRectMake(PauseButton_x, PauseButton_y, PauseButton_width, PauseButton_height);
//    UIImage *PauseButton_image = [UIImage imageNamed:@"button_start"];
//    [PauseButton setBackgroundImage:PauseButton_image forState:UIControlStateNormal];
//    [PauseButton setTitle:@"暂停" forState:UIControlStateNormal];
//    [PauseButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
//    PauseButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    [PauseButton addTarget:self action:@selector(pauseTTS:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:PauseButton];
//
//    // ---- TestButton ---
//    CGFloat TestButton_width = globalSize.width/SCREEN_WIDTH_BASE * 80;
//    CGFloat TestButton_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat TestButton_x = globalSize.width/SCREEN_WIDTH_BASE * (SCREEN_WIDTH_BASE - 27.5 - 80);
//    CGFloat TestButton_y = globalSize.height/SCREEN_HEIGHT_BASE * button_height_base;
//    
//    TestButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    TestButton.frame = CGRectMake(TestButton_x, TestButton_y, TestButton_width, TestButton_height);
//    UIImage *TestButton_image = [UIImage imageNamed:@"button_start"];
//    [TestButton setBackgroundImage:TestButton_image forState:UIControlStateNormal];
//    [TestButton setTitle:@"测试" forState:UIControlStateNormal];
//    [TestButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
//    TestButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    [TestButton addTarget:self action:@selector(startTest:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:TestButton];
//
//    // ---- Multi-segment speech synthesis TestButton ---
//    CGFloat multi_button_width = globalSize.width/SCREEN_WIDTH_BASE * 120;
//    CGFloat multi_button_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat x0 = globalSize.width/SCREEN_WIDTH_BASE * 27.5;
//    CGFloat y0 = globalSize.height/SCREEN_HEIGHT_BASE * (button_height_base + 40);
//
//    MultiPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    MultiPlayButton.frame = CGRectMake(x0, y0, multi_button_width, multi_button_height);
//    UIImage *multi_image = [UIImage imageNamed:@"button_start"];
//    [MultiPlayButton setBackgroundImage:multi_image forState:UIControlStateNormal];
//    [MultiPlayButton setTitle:@"多片段播放" forState:UIControlStateNormal];
//    [MultiPlayButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
//    MultiPlayButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    [MultiPlayButton addTarget:self action:@selector(startMultiSegmentTTS:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:MultiPlayButton];
//}
//
//- (void)setTextView {
//    int text_height_base = 150;
//
//    // ---- textViewContent ---
//    CGFloat textViewContent_width = globalSize.width/SCREEN_WIDTH_BASE * 320;
//    CGFloat textViewContent_height = globalSize.height/SCREEN_HEIGHT_BASE * 250;
//    CGFloat textViewContent_x = globalSize.width/2 - textViewContent_width/2;
//    CGFloat textViewContent_y = globalSize.height/SCREEN_HEIGHT_BASE * text_height_base;
//    
//    CGRect textViewContent_rect = CGRectMake(textViewContent_x, textViewContent_y, textViewContent_width, textViewContent_height);
//    if (!textViewContent) {
//        textViewContent = [[UITextView alloc] initWithFrame:textViewContent_rect];
//    }
//    textViewContent.layer.borderWidth = 0.6;
//    textViewContent.layer.borderColor = [UIColor blackColor].CGColor;
//    textViewContent.layer.cornerRadius = 10;
//    [textViewContent setBackgroundColor: [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.1]];
//    textViewContent.scrollEnabled = YES;
//
//    // 支持一次性合成300字符以内的文字，其中1个汉字、1个英文字母或1个标点均算作1个字符，
//    // 超过300个字符的内容将会截断。所以请确保传入的text小于300字符(不包含ssml格式)。
//    textViewContent.text = @"语音合成服务，通过先进的深度学习技术，将文本转换成自然流畅的语音。目前有多种音色可供选择，并提供调节语速、语调、音量等功能。适用于智能客服、语音交互、文学有声阅读和无障碍播报等场景。";
//    textViewContent.textColor = [UIColor darkGrayColor];
//    textViewContent.font = [UIFont systemFontOfSize:15];
//    [self.view addSubview:textViewContent];
//}
//
//- (void)setLabel {
//    int label_height_base = 400;
//
//    // ---- labelFontName ---
//    CGFloat labelFontName_width = globalSize.width/SCREEN_WIDTH_BASE * 180;
//    CGFloat labelFontName_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat labelFontName_x = globalSize.width/SCREEN_WIDTH_BASE * 27.5;
//    CGFloat labelFontName_y = globalSize.height/SCREEN_HEIGHT_BASE * label_height_base;
//
//    CGRect labelFontName_rect = CGRectMake(labelFontName_x, labelFontName_y, labelFontName_width, labelFontName_height);
//    labelFontName = [[UILabel alloc] initWithFrame:labelFontName_rect];
//    labelFontName.text = @"font name:";
//    labelFontName.textColor = [UIColor blackColor];
//    labelFontName.backgroundColor = [UIColor whiteColor];
//    labelFontName.font = [UIFont boldSystemFontOfSize:15];
//    [self.view addSubview:labelFontName];
//
//    // ---- labelModeType ---
//    CGFloat labelModeType_width = globalSize.width/SCREEN_WIDTH_BASE * 180;
//    CGFloat labelModeType_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat labelModeType_x = globalSize.width/SCREEN_WIDTH_BASE * 27.5;
//    CGFloat labelModeType_y = globalSize.height/SCREEN_HEIGHT_BASE * (label_height_base + 40);
//
//    CGRect labelModeType_rect = CGRectMake(labelModeType_x, labelModeType_y, labelModeType_width, labelModeType_height);
//    labelModeType = [[UILabel alloc] initWithFrame:labelModeType_rect];
//    labelModeType.text = @"mode type:";
//    labelModeType.textColor = [UIColor blackColor];
//    labelModeType.backgroundColor = [UIColor whiteColor];
//    labelModeType.font = [UIFont boldSystemFontOfSize:15];
//    [self.view addSubview:labelModeType];
//
//    // ---- labelSpeedLevel ---
//    CGFloat labelSpeedLevel_width = globalSize.width/SCREEN_WIDTH_BASE * 180;
//    CGFloat labelSpeedLevel_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat labelSpeedLevel_x = globalSize.width/SCREEN_WIDTH_BASE * 27.5;
//    CGFloat labelSpeedLevel_y = globalSize.height/SCREEN_HEIGHT_BASE * (label_height_base + 80);
//
//    CGRect labelSpeedLevel_rect = CGRectMake(labelSpeedLevel_x, labelSpeedLevel_y, labelSpeedLevel_width, labelSpeedLevel_height);
//    labelSpeedLevel = [[UILabel alloc] initWithFrame:labelSpeedLevel_rect];
//    labelSpeedLevel.text = @"speed level(0~2):";
//    labelSpeedLevel.textColor = [UIColor blackColor];
//    labelSpeedLevel.backgroundColor = [UIColor whiteColor];
//    labelSpeedLevel.font = [UIFont boldSystemFontOfSize:15];
//    [self.view addSubview:labelSpeedLevel];
//
//    // ---- labelPitchLevel ---
//    CGFloat labelPitchLevel_width = globalSize.width/SCREEN_WIDTH_BASE * 180;
//    CGFloat labelPitchLevel_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat labelPitchLevel_x = globalSize.width/SCREEN_WIDTH_BASE * 27.5;
//    CGFloat labelPitchLevel_y = globalSize.height/SCREEN_HEIGHT_BASE * (label_height_base + 120);
//
//    CGRect labelPitchLevel_rect = CGRectMake(labelPitchLevel_x, labelPitchLevel_y, labelPitchLevel_width, labelPitchLevel_height);
//    labelPitchLevel = [[UILabel alloc] initWithFrame:labelPitchLevel_rect];
//    labelPitchLevel.text = @"pitch level(-500~500):";
//    labelPitchLevel.textColor = [UIColor blackColor];
//    labelPitchLevel.backgroundColor = [UIColor whiteColor];
//    labelPitchLevel.font = [UIFont boldSystemFontOfSize:15];
//    [self.view addSubview:labelPitchLevel];
//
//    // ---- labelVolume ---
//    CGFloat labelVolume_width = globalSize.width/SCREEN_WIDTH_BASE * 180;
//    CGFloat labelVolume_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat labelVolume_x = globalSize.width/SCREEN_WIDTH_BASE * 27.5;
//    CGFloat labelVolume_y = globalSize.height/SCREEN_HEIGHT_BASE * (label_height_base + 160);
//
//    CGRect labelVolume_rect = CGRectMake(labelVolume_x, labelVolume_y, labelVolume_width, labelVolume_height);
//    labelVolume = [[UILabel alloc] initWithFrame:labelVolume_rect];
//    labelVolume.text = @"volume(0~2):";
//    labelVolume.textColor = [UIColor blackColor];
//    labelVolume.backgroundColor = [UIColor whiteColor];
//    labelVolume.font = [UIFont boldSystemFontOfSize:15];
//    [self.view addSubview:labelVolume];
//}
//
//- (void)setTextField {
//    int text_height_base = 480;
//
//    // ---- textfieldSpeedLevel ---
//    CGFloat textfieldSpeedLevel_width = globalSize.width/SCREEN_WIDTH_BASE * 110;
//    CGFloat textfieldSpeedLevel_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat textfieldSpeedLevel_x = globalSize.width/SCREEN_WIDTH_BASE * 210;
//    CGFloat textfieldSpeedLevel_y = globalSize.height/SCREEN_HEIGHT_BASE * text_height_base;
//
//    CGRect textfieldSpeedLevel_rect = CGRectMake(textfieldSpeedLevel_x, textfieldSpeedLevel_y, textfieldSpeedLevel_width, textfieldSpeedLevel_height);
//    textfieldSpeedLevel = [[UITextField alloc] initWithFrame:textfieldSpeedLevel_rect];
//    textfieldSpeedLevel.borderStyle = UITextBorderStyleRoundedRect;
//    textfieldSpeedLevel.font = [UIFont fontWithName:@"Arial" size:15];
//    textfieldSpeedLevel.textColor = [UIColor blackColor];
//    textfieldSpeedLevel.backgroundColor = [UIColor lightGrayColor];
//    textfieldSpeedLevel.userInteractionEnabled = YES;
//    [self.view addSubview:textfieldSpeedLevel];
//
//    // ---- textfieldPitchLevel ---
//    CGFloat textfieldPitchLevel_width = globalSize.width/SCREEN_WIDTH_BASE * 110;
//    CGFloat textfieldPitchLevel_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat textfieldPitchLevel_x = globalSize.width/SCREEN_WIDTH_BASE * 210;
//    CGFloat textfieldPitchLevel_y = globalSize.height/SCREEN_HEIGHT_BASE * (text_height_base + 40);
//
//    CGRect textfieldPitchLevel_rect = CGRectMake(textfieldPitchLevel_x, textfieldPitchLevel_y, textfieldPitchLevel_width, textfieldPitchLevel_height);
//    textfieldPitchLevel = [[UITextField alloc] initWithFrame:textfieldPitchLevel_rect];
//    textfieldPitchLevel.borderStyle = UITextBorderStyleRoundedRect;
//    textfieldPitchLevel.font = [UIFont fontWithName:@"Arial" size:15];
//    textfieldPitchLevel.textColor = [UIColor blackColor];
//    textfieldPitchLevel.backgroundColor = [UIColor lightGrayColor];
//    textfieldPitchLevel.userInteractionEnabled = YES;
//    [self.view addSubview:textfieldPitchLevel];
//
//    // ---- textfieldVolume ---
//    CGFloat textfieldVolume_width = globalSize.width/SCREEN_WIDTH_BASE * 110;
//    CGFloat textfieldVolume_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat textfieldVolume_x = globalSize.width/SCREEN_WIDTH_BASE * 210;
//    CGFloat textfieldVolume_y = globalSize.height/SCREEN_HEIGHT_BASE * (text_height_base + 80);
//
//    CGRect textfieldVolume_rect = CGRectMake(textfieldVolume_x, textfieldVolume_y, textfieldVolume_width, textfieldVolume_height);
//    textfieldVolume = [[UITextField alloc] initWithFrame:textfieldVolume_rect];
//    textfieldVolume.borderStyle = UITextBorderStyleRoundedRect;
//    textfieldVolume.font = [UIFont fontWithName:@"Arial" size:15];
//    textfieldVolume.textColor = [UIColor blackColor];
//    textfieldVolume.backgroundColor = [UIColor lightGrayColor];
//    textfieldVolume.userInteractionEnabled = YES;
//    [self.view addSubview:textfieldVolume];
//}
//
//- (void)setOptionButton {
//    int label_height_base = 400;
//
//    // ---- fontName ---
//    // 在线语音合成发音人可以参考阿里云官网
//    // https://help.aliyun.com/document_detail/84435.html
//    CGFloat fontName_width = globalSize.width/SCREEN_WIDTH_BASE * 150;
//    CGFloat fontName_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat fontName_x = globalSize.width/SCREEN_WIDTH_BASE * (SCREEN_WIDTH_BASE - 27.5 - 150);
//    CGFloat fontName_y = globalSize.height/SCREEN_HEIGHT_BASE * label_height_base;
//
//    HWOptionButton *fontNameBtn = [[HWOptionButton alloc] initWithFrame:CGRectMake(fontName_x, fontName_y, fontName_width, fontName_height)];
//    fontNameBtn.backgroundColor = [UIColor whiteColor];
//    fontNameBtn.array = @[@"xiaoyun", @"xiaogang", @"siqi", @"aixia"];
//    fontNameBtn.delegate = self;
//    fontNameBtn.showSearchBar = YES;
//    [self.view addSubview:fontNameBtn];
//    self.fontName = fontNameBtn;
//    
//    // ---- modeType ---
//    CGFloat modeType_width = globalSize.width/SCREEN_WIDTH_BASE * 150;
//    CGFloat modeType_height = globalSize.height/SCREEN_HEIGHT_BASE * 40;
//    CGFloat modeType_x = globalSize.width/SCREEN_WIDTH_BASE * (SCREEN_WIDTH_BASE - 27.5 - 150);
//    CGFloat modeType_y = globalSize.height/SCREEN_HEIGHT_BASE * (label_height_base + 40);
//
//    HWOptionButton *modeTypeBtn = [[HWOptionButton alloc] initWithFrame:CGRectMake(modeType_x, modeType_y, modeType_width, modeType_height)];
//    modeTypeBtn.array = @[@"在线合成"];
//    modeTypeBtn.backgroundColor = [UIColor whiteColor];
//    modeTypeBtn.delegate = self;
//    modeTypeBtn.showSearchBar = YES;
//    [self.view addSubview:modeTypeBtn];
//    self.modeType = modeTypeBtn;
//}
//
//- (void)playTTS:(NSString *)content {
//    playingContent = content;
//
//    if (!self.nui) {
//        TLog(@"nui tts not init");
//        return;
//    }
//
//    if (_audioController == nil) {
//        // 注意：这里audioController模块仅用于播放示例，用户可根据业务场景自行实现这部分代码
//        _audioController = [[AudioController alloc] init:only_player];
//        _audioController.delegate = self;
//        _ttsSampleRate = 16000;  // 返回音频的采样率
//        [_audioController setPlayerSampleRate:_ttsSampleRate];
//    }
//
//    if (_audioController != nil) {
//        textViewContent.text = content;
//        [self UpdateTtsParams:content];
//
//        dispatch_async(workQueue, ^{
//            // taskid用户可以自己设置，格式为32字节的uuid，如“bf2e88aa42a743028315ffc0dcb53cda”
//            // taskid为空时: SDK内部将自动产生32字节的uuid作为taskid
//            [self.nui nui_tts_play:"1" taskId:"" text:[content UTF8String]];
//        });
//    }
//}
//
//-(void) UpdateTtsParams:(NSString *)content {
//    if ([_fontName.title isEqualToString:@"-请选择-"]) {
//        // DO NOTHING
//    } else {
//        [self.nui nui_tts_set_param:"font_name" value:[_fontName.title UTF8String]];
//    }
//    int chars = 0;
//    if ([_modeType.title isEqualToString:@"离线合成"]) {
//        [self.nui nui_tts_set_param:"mode_type" value:"0"]; // 必填
//    } else if ([_modeType.title isEqualToString:@"在线合成"]) {
//        [self.nui nui_tts_set_param:"mode_type" value:"2"]; // 必填
//        
//        // 支持一次性合成300字符以内的文字，其中1个汉字、1个英文字母或1个标点均算作1个字符，
//        // 超过300个字符的内容将会截断。所以请确保传入的text小于300字符(不包含ssml格式)。
//        // 长短文本语音合成收费不同，请注意。
//        // 300字这个截点可能会变更，以官网文档为准。
//        chars = [self.nui nui_tts_get_num_of_chars: [content UTF8String]];
//        if (chars > 300) {
//            // 超过300字符设置成 长文本语音合成 模式
//            [self.nui nui_tts_set_param:"tts_version" value:"1"];
//        } else {
//            // 未超过300字符设置成 短文本语音合成 模式
//            [self.nui nui_tts_set_param:"tts_version" value:"0"];
//        }
//    } else {
//        [self.nui nui_tts_set_param:"mode_type" value:"2"]; // 必填
//
//        chars = [self.nui nui_tts_get_num_of_chars: [content UTF8String]];
//        if (chars > 300) {
//            [self.nui nui_tts_set_param:"tts_version" value:"1"];
//        } else {
//            [self.nui nui_tts_set_param:"tts_version" value:"0"];
//        }
//    }
//
//    // 详细参数可见: https://help.aliyun.com/document_detail/173642.html
//    if (self->textfieldSpeedLevel.text.length > 0) {
//        [self.nui nui_tts_set_param:"speed_level" value:[textfieldSpeedLevel.text UTF8String]];
//    }
//    if (self->textfieldPitchLevel.text.length > 0) {
//        [self.nui nui_tts_set_param:"pitch_level" value:[textfieldPitchLevel.text UTF8String]];
//    }
//    if (self->textfieldVolume.text.length > 0) {
//        [self.nui nui_tts_set_param:"volume)" value:[textfieldVolume.text UTF8String]];
//    }
//
//    // 字级别音素边界功能开关，该参数只对支持字级别音素边界接口的发音人有效。“1”表示打开，“0”表示关闭。
//    [self.nui nui_tts_set_param:"enable_subtitle" value:"1"];
//
//    // 打开音量回调onNuiTtsVolumeCallback
//    // 注意！此音频是SDK刚收到合成数据的音量值，而非正在播放的音量值。
//    // 正在播放音频的音量值可参考AudioController.m中的calculateVolumeFromPCMData
////    [self.nui nui_tts_set_param:"enable_callback_vol" value:"1"];
//
//    // 设置文档中不存在的参数, key为custom_params, value以json string的形式设置参数
////    [self.nui nui_tts_set_param:"custom_params" value:"{\"enable_phoneme_timestamp\":true}"];
//}
//
//static NSArray *testDataList = nil;
//- (void)tts_test_loop:(NSArray<NSString *>*)list {
//    static int i = 0;
//    if (!list || i >= list.count) {
//        TLog(@"tts test loop finish or list = nil");
//        return;
//    }
//    
//    if (loopIn == TTS_EVENT_START) {
//        [self performSelector:@selector(tts_test_loop:) withObject:list afterDelay:3];
//        return ;
//    }
//    
//    if (loopIn == TTS_EVENT_CANCEL ||
//        loopIn == TTS_EVENT_ERROR) {
//        TLog(@"Tts canceled or Error");
//        return ;
//    }
//    
//    NSString * dialog = list[i];
//    [self playTTS:dialog];
//    i++;
//    
//    [self performSelector:@selector(tts_test_loop:) withObject:list afterDelay:3];
//}
//
//#pragma mark - Button Action
//- (IBAction)startTTS:(UIButton *)sender {
//    playingContent = textViewContent.text;
//    if (!self.nui) {
//        TLog(@"tts not init");
//        return;
//    }
//
//    if (_audioController == nil) {
//        // 注意：这里audioController模块仅用于播放示例，用户可根据业务场景自行实现这部分代码
//        _audioController = [[AudioController alloc] init:only_player];
//        _audioController.delegate = self;
//        _ttsSampleRate = 16000;  // 返回音频的采样率
//        [_audioController setPlayerSampleRate:_ttsSampleRate];
//    }
//
//    if (_audioController != nil) {
//        NSString *content = textViewContent.text;
//        [self UpdateTtsParams:content];
//
//        dispatch_async(workQueue, ^{
//            // 如果上个任务没有合成完毕，手动取消，开始合成新的任务
//            [self.nui nui_tts_cancel:NULL];
//            [self.nui nui_tts_play:"1" taskId:"" text:[content UTF8String]];
//        });
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImage *image = [UIImage imageNamed:@"button_stop"];
//            [PlayButton setBackgroundImage:image forState:UIControlStateNormal];
//            [PlayButton setTitle:@"停止" forState:UIControlStateNormal];
//            [PlayButton removeTarget:self action:@selector(startTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PlayButton addTarget:self action:@selector(stopTTS:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    }
//}
//
//- (IBAction)stopTTS:(UIButton *)sender {
//    if (_nui != nil) {
//        TLog(@"TTSViewController stop tts");
//
//        dispatch_async(workQueue, ^{
//            if (mSyntheticing) {
//                [self.nui nui_tts_cancel:NULL];
//            }
//            if (_audioController != nil) {
//                [_audioController stopPlayer];
//            }
//        });
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // UI更新代码
//            UIImage *image = [UIImage imageNamed:@"button_start"];
//            [PlayButton setBackgroundImage:image forState:UIControlStateNormal];
//            [PlayButton setTitle:@"播放" forState:UIControlStateNormal];
//            [PlayButton removeTarget:self action:@selector(stopTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PlayButton addTarget:self action:@selector(startTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PauseButton setBackgroundImage:image forState:UIControlStateNormal];
//            [PauseButton setTitle:@"暂停" forState:UIControlStateNormal];
//            [PauseButton removeTarget:self action:@selector(resumeTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PauseButton addTarget:self action:@selector(pauseTTS:) forControlEvents:UIControlEventTouchUpInside];
//
//        });
//    } else {
//        TLog(@"in stopTTS, _nui == nil.");
//    }
//}
//
//
//- (IBAction)pauseTTS:(UIButton *)sender {
//    if (_nui != nil) {
//        dispatch_async(workQueue, ^{
//            if (mSyntheticing) {
//                int ret = [self.nui nui_tts_pause];
//                if (ret != SUCCESS) {
//                    const char *errmsg = [_nui nui_tts_get_param: "error_msg"];
//                    TLog(@"tts pause fail(%d) with errmsg:%s ", ret, errmsg);
//                }
//            }
//            if (_audioController != nil) {
//                [_audioController pausePlayer];
//            }
//        });
//            
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // UI更新代码
//            UIImage *image = [UIImage imageNamed:@"button_stop"];
//            [PauseButton setBackgroundImage:image forState:UIControlStateNormal];
//            [PauseButton setTitle:@"继续" forState:UIControlStateNormal];
//            [PauseButton removeTarget:self action:@selector(pauseTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PauseButton addTarget:self action:@selector(resumeTTS:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    } else {
//        TLog(@"in pauseTTS, _nui == nil.");
//    }
//}
//
//- (IBAction)resumeTTS:(UIButton *)sender {
//    if (_nui != nil) {
//        dispatch_async(workQueue, ^{
//            if (mSyntheticing) {
//                int ret = [self.nui nui_tts_resume];
//                if (ret != SUCCESS) {
//                    const char *errmsg = [_nui nui_tts_get_param: "error_msg"];
//                    TLog(@"tts resume fail(%d) with errmsg:%s ", ret, errmsg);
//                }
//            }
//            if (_audioController != nil) {
//                [_audioController resumePlayer];
//            }
//        });
//            
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // UI更新代码
//            UIImage *image = [UIImage imageNamed:@"button_start"];
//            [PauseButton setBackgroundImage:image forState:UIControlStateNormal];
//            [PauseButton setTitle:@"暂停" forState:UIControlStateNormal];
//            [PauseButton removeTarget:self action:@selector(resumeTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [PauseButton addTarget:self action:@selector(pauseTTS:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    } else {
//        TLog(@"in resumeTTS, _nui == nil.");
//    }
//}
//
//- (void)playText:(NSString *)text{
//    [_text_array addObject:text];
//}
//
//- (IBAction)startMultiSegmentTTS:(UIButton *)sender {
//    playingContent = textViewContent.text;
//    if (!self.nui) {
//        TLog(@"tts not init");
//        return;
//    }
//
//    if (_text_array == NULL) {
//        _text_array = [NSMutableArray arrayWithObjects:
//                       @"唧唧复唧唧，木兰当户织。不闻机杼声，唯闻女叹息。",
//               //        @"问女何所思，问女何所忆。女亦无所思，女亦无所忆。",
//               //        @"昨夜见军帖，可汗大点兵，军书十二卷，卷卷有爷名。",
//               //        @"阿爷无大儿，木兰无长兄，愿为市鞍马，从此替爷征。",
//               //        @"东市买骏马，西市买鞍鞯，南市买辔头，北市买长鞭。旦辞爷娘去，暮宿黄河边，不闻爷娘唤女声，但闻黄河流水鸣溅溅。",
//               //        @"旦辞黄河去，暮至黑山头，不闻爷娘唤女声，但闻燕山胡骑鸣啾啾。万里赴戎机，关山度若飞。朔气传金柝，寒光照铁衣。将军百战死，壮士十年归。",
//               //        @"归来见天子，天子坐明堂。策勋十二转，赏赐百千强。可汗问所欲，木兰不用尚书郎，愿驰千里足，送儿还故乡。爷娘闻女来，出郭相扶将；阿姊闻妹来，当户理红妆；小弟闻姊来，磨刀霍霍向猪羊。",
//               //        @"开我东阁门，坐我西阁床。脱我战时袍，著我旧时裳。当窗理云鬓，对镜帖花黄。出门看火伴，火伴皆惊忙：同行十二年，不知木兰是女郎。",
//                       @"雄兔脚扑朔，雌兔眼迷离；双兔傍地走，安能辨我是雄雌？", nil];
//    }
//
//    NSString *content = textViewContent.text;
//    [self UpdateTtsParams:content];
//
//    if (_audioController == nil) {
//        // 注意：这里audioController模块仅用于播放示例，用户可根据业务场景自行实现这部分代码
//        _audioController = [[AudioController alloc] init:only_player];
//        _audioController.delegate = self;
//        _ttsSampleRate = 16000;  // 返回音频的采样率
//        [_audioController setPlayerSampleRate:_ttsSampleRate];
//    }
//
//    if (_audioController != nil) {
//        dispatch_async(workQueue, ^{
//            continuousPlaybackFlag = YES;
//            
//            // 如果上个任务没有合成完毕，手动取消，开始合成新的任务
//            [self.nui nui_tts_cancel:NULL];
//
//            for (NSString* text in _text_array) {
//                SegmentFinishPlaying = NO;
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    textViewContent.text = text;
//                });
//
//                [self.nui nui_tts_play:"1" taskId:"" text:[text UTF8String]];
//
//                while (SegmentFinishPlaying == NO && continuousPlaybackFlag == YES) {
//                    usleep(10 * 1000);
//                }
//
//                if (continuousPlaybackFlag == NO) {
//                    break;
//                }
//                TLog(@"====== finish one text ======");
//            }
//
//            continuousPlaybackFlag = NO;
//        });
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImage *image = [UIImage imageNamed:@"button_stop"];
//            [MultiPlayButton setBackgroundImage:image forState:UIControlStateNormal];
//            [MultiPlayButton setTitle:@"多片段结束" forState:UIControlStateNormal];
//            [MultiPlayButton removeTarget:self action:@selector(startMultiSegmentTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [MultiPlayButton addTarget:self action:@selector(stopMultiSegmentTTS:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    }
//}
//
//- (IBAction)stopMultiSegmentTTS:(UIButton *)sender {
//    if (_nui != nil) {
//        TLog(@"TTSViewController stop multi segment tts");
//        continuousPlaybackFlag = NO;
//        dispatch_async(workQueue, ^{
//            [self.nui nui_tts_cancel:NULL];
//            if (_audioController != nil) {
//                [_audioController stopPlayer];
//            }
//        });
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // UI更新代码
//            UIImage *image = [UIImage imageNamed:@"button_start"];
//            [MultiPlayButton setBackgroundImage:image forState:UIControlStateNormal];
//            [MultiPlayButton setTitle:@"多片段播放" forState:UIControlStateNormal];
//            [MultiPlayButton removeTarget:self action:@selector(stopMultiSegmentTTS:) forControlEvents:UIControlEventTouchUpInside];
//            [MultiPlayButton addTarget:self action:@selector(startMultiSegmentTTS:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    } else {
//        TLog(@"in stopMultiSegmentTTS, _nui == nil.");
//    }
//}
//
//- (IBAction)startTest:(UIButton *)sender {
//    TLog(@"start a pthread for tts test.");
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tts_test_loop:) object:testDataList];
//
//    if (!self.nui) {
//        TLog(@"nui tts not init");
//    }
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIImage *image = [UIImage imageNamed:@"button_stop"];
//        [TestButton setBackgroundImage:image forState:UIControlStateNormal];
//        [TestButton setTitle:@"结束" forState:UIControlStateNormal];
//        [TestButton removeTarget:self action:@selector(startTest:) forControlEvents:UIControlEventTouchUpInside];
//        [TestButton addTarget:self action:@selector(stopTest:) forControlEvents:UIControlEventTouchUpInside];
//    });
//    
//    
//    if (!testDataList) {
//        TLog(@"get test list");
//        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"thirdparty/test" ofType:@"txt"];
//        NSString *dataFile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
//        testDataList = [dataFile componentsSeparatedByString:@"\n"];
//    }
//    
//    [self tts_test_loop:testDataList];
//    return;
//}
//
//- (IBAction)stopTest:(UIButton *)sender {
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tts_test_loop:) object:testDataList];
//    
//    if (_nui != nil) {
//        dispatch_async(workQueue, ^{
//            [_nui nui_tts_cancel:NULL];
//        });
//        loopIn = TTS_EVENT_END;
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // UI更新代码
//            UIImage *image = [UIImage imageNamed:@"button_start"];
//            [TestButton setBackgroundImage:image forState:UIControlStateNormal];
//            [TestButton setTitle:@"测试" forState:UIControlStateNormal];
//            [TestButton removeTarget:self action:@selector(stopTest:) forControlEvents:UIControlEventTouchUpInside];
//            [TestButton addTarget:self action:@selector(startTest:) forControlEvents:UIControlEventTouchUpInside];
//        });
//    } else {
//        TLog(@"in stopTest, _nui == nil.");
//    }
//}
//
//
//#pragma mark - tts callback
//- (void)onNuiTtsEventCallback:(NuiSdkTtsEvent)event taskId:(char*)taskid code:(int)code {
////    TLog(@"onNuiTtsEventCallback event[%d]", event);
//    if (event == TTS_EVENT_START) {
//        TLog(@"onNuiTtsEventCallback TTS_EVENT_START");
//        // 标记合成中，方便暂停/恢复的功能实现
//        mSyntheticing = YES;
//
//        loopIn = TTS_EVENT_START;
//        if (_audioController != nil) {
//            // 启动播放器
//            [_audioController startPlayer];
//        }
//    } else if (event == TTS_EVENT_END || event == TTS_EVENT_CANCEL || event == TTS_EVENT_ERROR) {
//        // 标记合成结束，方便暂停/恢复的功能实现
//        mSyntheticing = NO;
//        loopIn = event;
//
//        if (event == TTS_EVENT_END) {
//            TLog(@"onNuiTtsEventCallback TTS_EVENT_END");
//            // 注意这里的event事件是指语音合成完成，而非播放完成，播放完成需要由audioController对象来进行通知
//            [_audioController drain];
//        } else {
//            TLog(@"onNuiTtsEventCallback (%d) TTS_EVENT_CANCEL or TTS_EVENT_ERROR", event);
//            if (_audioController != nil) {
//                // 取消播报、或者发生异常时终止播放
//                [_audioController stopPlayer];
//            }
//        }
//        if (event == TTS_EVENT_ERROR) {
//            TLog(@"onNuiTtsEventCallback TTS_EVENT_ERROR with %d", code);
//            const char *errmsg = [_nui nui_tts_get_param: "error_msg"];
//            TLog(@"tts get errmsg:%s", errmsg);
//        }
//    }
//}
//
//- (void)onNuiTtsUserdataCallback:(char*)info infoLen:(int)info_len buffer:(char*)buffer len:(int)len taskId:(char*)task_id {
//    if (info_len > 0) {
//        TLog(@"onNuiTtsUserdataCallback info text %s. index %d.", info, info_len);
//    }
//    if (len > 0 && _audioController != nil) {
//        TLog(@"onNuiTtsUserdataCallback get data %dbytes ...", len);
//        [_audioController write:(char*)buffer Length:(unsigned int)len];
//    }
//}
//
//-(void)onNuiTtsVolumeCallback:(int)volume taskId:(char*)task_id {
//    ;
//}
//
//-(void)onNuiTtsLogTrackCallback:(NuiSdkLogLevel)level
//                     logMessage:(const char *)log {
//    TLog(@"onNuiTtsLogTrackCallback log level:%d, message -> %s", level, log);
//}
//@end
