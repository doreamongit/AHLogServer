//
//  QYPlayerObject.m
//  ASimpleFFmpeg
//
//  Created by Damon on 2019/4/17.
//  Copyright © 2019年 Damon. All rights reserved.
//

#import "QYPlayerObject.h"


@interface QYPlayerObject()
{
    AVFormatContext     *XYQFormatCtx;
    AVCodecContext      *XYQCodecCtx;
    AVFrame             *XYQFrame;
    AVStream            *stream;
    AVPacket            packet;
    AVPicture           picture;
    int                 videoStream;
    BOOL                isReleaseResources;
}
@property (nonatomic, copy) NSString *cruutenPath;
@end

@implementation QYPlayerObject

- (instancetype)initWithVideo:(NSString *)moviePath {
    
    if (!(self=[super init])) return nil;
    if ([self initializeResources:[moviePath UTF8String]]) {
        self.cruutenPath = [moviePath copy];
        return self;
    } else {
        return nil;
    }
}

- (BOOL)initializeResources:(const char *)filePath {
    AVCodec *pCodec;
    
    avcodec_register_all();
    av_register_all();
    
    avformat_network_init();
    
    //打开视频文件
    if (avformat_open_input(&XYQFormatCtx, filePath, NULL, NULL) != 0) {
        NSLog(@"打开文件失败");
        goto initError;
    }
    
    //检查数据流
    if (avformat_find_stream_info(XYQFormatCtx, NULL) < 0) {
        NSLog(@"检查数据流失败");
        goto initError;
    }
    
    //根据数据流，找到第一个视频流
    videoStream = av_find_best_stream(XYQFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0);
    if (videoStream < 0) {
        NSLog(@"没有找到第一个视频流");
        goto initError;
    }
    
    //获取视频流的编解码上下文的指针
    stream = XYQFormatCtx->streams[videoStream];
    XYQCodecCtx = stream->codec;
#if DEBUG
    // 打印视频流的详细信息
    av_dump_format(XYQFormatCtx, videoStream, filePath, 0);
#endif
    
    //avg_frame_rate帧率
    if (stream->avg_frame_rate.den && stream->avg_frame_rate.num) {
        //其中av_q2d求帧数，利用其中的分子分母做运算
        _fps = av_q2d(stream->avg_frame_rate);
    }else{
        _fps = 30;
    }
    
    //查找解码器
    pCodec = avcodec_find_decoder(XYQCodecCtx->codec_id);
    if (pCodec == NULL) {
        NSLog(@"没有找到解码器");
        goto initError;
    }
    
    //打开解码器
    if (avcodec_open2(XYQCodecCtx, pCodec, NULL) < 0) {
        NSLog(@"打开解码器失败");
        goto initError;
    }
    
    //分配视频帧
    XYQFrame = av_frame_alloc();
    _outputWidth = XYQCodecCtx->width;
    _outputHeight = XYQCodecCtx->height;
    return YES;
initError:
    return NO;
}

- (BOOL)stepFrame {
    int frameFinished = 0;
    while (!frameFinished && av_read_frame(XYQFormatCtx, &packet) >= 0) {
        if (packet.stream_index == videoStream) {
            avcodec_decode_video2(XYQCodecCtx, XYQFrame, &frameFinished, &packet);
        }
    }
//    if (frameFinished == 0 && ) {
//        <#statements#>
//    }
    return frameFinished != 0;
}

- (void)seekTime:(double)seconds {
    //AVRational FFmpeg存在很多个时间单位，比如pts， dts， ffmpeg内部基准时间，常规时间
    AVRational timeBase = XYQFormatCtx->streams[videoStream]->time_base;
    int64_t targetFrame = (int64_t)((double)timeBase.den/timeBase.num *seconds);
    
    avformat_seek_file(XYQFormatCtx, videoStream, 0, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
    
    avcodec_flush_buffers(XYQCodecCtx);
}

-(UIImage *)currentImage {
    if (!XYQFrame->data[0]) {
        return nil;
    }
    return [self imageFromAVPicture];
}

- (UIImage *)imageFromAVPicture
{
    avpicture_free(&picture);
    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, _outputWidth, _outputHeight);
    
    struct SwsContext *imgConvertCtx = sws_getContext(XYQFrame->width, XYQFrame->height, AV_PIX_FMT_YUV420P, _outputWidth, _outputHeight, AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    
    if (imgConvertCtx == nil) {
        return nil;
    }
    
    sws_scale(imgConvertCtx, XYQFrame->data, XYQFrame->linesize, 0, XYQFrame->height, picture.data, picture.linesize);
    
    sws_freeContext(imgConvertCtx);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, picture.data[0], picture.linesize[0]*_outputHeight);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImage = CGImageCreate(_outputWidth, _outputHeight, 8, 24, picture.linesize[0], colorSpace, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
    
}

@end
