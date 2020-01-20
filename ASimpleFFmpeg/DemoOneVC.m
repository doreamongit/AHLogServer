//
//  DemoOneVC.m
//  ASimpleFFmpeg
//
//  Created by Damon on 2019/3/20.
//  Copyright © 2019年 Damon. All rights reserved.
//

#import "DemoOneVC.h"

#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libavutil/avutil.h>
#import <libswresample/swresample.h>
#import <libavdevice/avdevice.h>
#import <libavfilter/avfilter.h>

#import<AudioToolbox/AudioToolbox.h>
#import<VideoToolbox/VideoToolbox.h>

@interface DemoOneVC ()

@end

@implementation DemoOneVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    avdevice_register_all();
    
    avformat_network_init();
    
    AVFormatContext *avFormatContext = avformat_alloc_context();
    //    NSString *url = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    //    NSString *url = @"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8";
    
    NSString *url = @"https://n5-pl-agv.autohome.com.cn/video-48/9C9DF5843CD64975/2019-02-19/75729B4FB1422BD9-200.mp4";
    
    if (avformat_open_input(&avFormatContext, [url UTF8String], NULL, NULL) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file");
    }
    
    if (avformat_find_stream_info(avFormatContext, NULL)) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information");
    }else{
        av_dump_format(avFormatContext, 0, [url UTF8String], NO);
    }
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
