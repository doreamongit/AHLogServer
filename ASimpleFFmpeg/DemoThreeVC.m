//
//  DemoThreeVC.m
//  ASimpleFFmpeg
//
//  Created by Damon on 2019/3/22.
//  Copyright © 2019年 Damon. All rights reserved.
//

#import "DemoThreeVC.h"
#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libavutil/avutil.h>
#import <libswresample/swresample.h>
#import <libavdevice/avdevice.h>
#import <libavfilter/avfilter.h>

#import<AudioToolbox/AudioToolbox.h>
#import<VideoToolbox/VideoToolbox.h>

@interface DemoThreeVC ()
{
    AVFormatContext * _formatCtx;
    AVFrame * _audioFrame;
    CGFloat _audioTimeBase;
}

@property(nonatomic,assign)NSInteger audioStream;

@end

@implementation DemoThreeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self playVideo];
}

- (void)playVideo {
//    av_log_set_callback(FFLog);
    av_register_all();
    
    NSString *url = @"https://n5-pl-agv.autohome.com.cn/video-48/9C9DF5843CD64975/2019-02-19/75729B4FB1422BD9-200.mp4";
    if ([self openInput:url]) {
        NSLog(@"打开视频失败");
        return ;
    }
    
    [self findAudioStream];
    [self findAudioDecoder];
}

- (BOOL)openInput:(NSString *)path
{
    AVFormatContext * formatCtx = NULL;
    
    formatCtx = avformat_alloc_context();
    if (!formatCtx)
    {
        NSLog(@"打开文件失败");
        return NO;
    }
    
    if (avformat_open_input(&formatCtx, [path cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL) < 0)
    {
        if (formatCtx)
        {
            avformat_free_context(formatCtx);
        }
        NSLog(@"打开文件失败");
        return NO;
    }
    
    if (avformat_find_stream_info(formatCtx, NULL) < 0)
    {
        avformat_close_input(&formatCtx);
        NSLog(@"无法获取流信息");
        return NO;
    }
    
    av_dump_format(formatCtx, 0, [path.lastPathComponent cStringUsingEncoding:NSUTF8StringEncoding], false);
    
    _formatCtx = formatCtx;
    
    return YES;
}

//找到音频流
- (BOOL)findAudioStream {
    _audioStream = -1;
    for (NSInteger i = 0; i < _formatCtx->nb_streams; i++) {
        if (AVMEDIA_TYPE_AUDIO == _formatCtx->streams[i]->codec->codec_type) {
            if ([self openAudioStream: i])
                break;
        }
    }
    return true;
}

- (BOOL) openAudioStream: (NSInteger) audioStream
{
    AVCodecContext *codecCtx = _formatCtx->streams[audioStream]->codec;
    SwrContext *swrContext = NULL;
    
    AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
    if(!codec)
        return false;
    
    if (avcodec_open2(codecCtx, codec, NULL) < 0)
        return false;
    
    if (!audioCodecIsSupported(codecCtx)) {
        
//        AieAudioManager * audioManager = [AieAudioManager audioManager];
//        swrContext = swr_alloc_set_opts(NULL,
//                                        av_get_default_channel_layout(audioManager.numOutputChannels),
//                                        AV_SAMPLE_FMT_S16,
//                                        audioManager.samplingRate,
//                                        av_get_default_channel_layout(codecCtx->channels),
//                                        codecCtx->sample_fmt,
//                                        codecCtx->sample_rate,
//                                        0,
//                                        NULL);
//
//        if (!swrContext ||
//            swr_init(swrContext)) {
//
//            if (swrContext)
//                swr_free(&swrContext);
//            avcodec_close(codecCtx);
//
//            return false;
//        }
    }
    
    _audioFrame = av_frame_alloc();
    
    if (!_audioFrame) {
        if (swrContext)
            swr_free(&swrContext);
        avcodec_close(codecCtx);
        return false;
    }
    
    _audioStream = audioStream;
//    _audioCodecCtx = codecCtx;
//    _swrContext = swrContext;
    
    AVStream *st = _formatCtx->streams[_audioStream];
//    avStreamFPSTimeBase(st, 0.025, 0, &_audioTimeBase);
    
//    NSLog(@"audio codec smr: %.d fmt: %d chn: %d tb: %f %@",
//          _audioCodecCtx->sample_rate,
//          _audioCodecCtx->sample_fmt,
//          _audioCodecCtx->channels,
//          _audioTimeBase,
//          _swrContext ? @"resample" : @"");
    
    return true;
}

//初始化音频解码器
- (BOOL)findAudioDecoder {
    AVCodecContext *codecCtx = _formatCtx->streams[_audioStream]->codec;
    SwrContext *swrContext = NULL;
    
    AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
    if(!codec)
        return NO;
    
    if (avcodec_open2(codecCtx, codec, NULL) < 0)
        return NO;
    
    return YES;
}

//判断是否需要重采样
static BOOL audioCodecIsSupported(AVCodecContext *audio)
{
//    if (audio->sample_fmt == AV_SAMPLE_FMT_S16) {
//        AieAudioManager * audioManager = [AieAudioManager audioManager];
//        return  (int)audioManager.samplingRate == audio->sample_rate &&
//        audioManager.numOutputChannels == audio->channels;
//    }
    return NO;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
