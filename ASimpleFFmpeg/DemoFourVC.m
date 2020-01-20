//
//  DemoFourVC.m
//  ASimpleFFmpeg
//
//  Created by Damon on 2019/4/17.
//  Copyright © 2019年 Damon. All rights reserved.
//

#import "DemoFourVC.h"
#import "QYPlayerObject.h"

@interface DemoFourVC ()

@property (nonatomic, strong) QYPlayerObject *video;

@property (strong, nonatomic) UIImageView *videoImageView;

@end

@implementation DemoFourVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.\
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //播放网络视频
//    self.video = [[QYPlayerObject alloc] initWithVideo:@"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4"];
    
    self.video = [[QYPlayerObject alloc] initWithVideo:@"http://n5-pl-agv.autohome.com.cn/video-41/9C9DF5843CD64975/2019-01-05/8FA1D30C74F075BE-200.mp4"];
    
    self.videoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 60, [UIScreen mainScreen].bounds.size.width, 200)];
    [self.view addSubview:self.videoImageView];
    
    self.videoImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(50, 300, 100, 44);
    button.backgroundColor = [UIColor greenColor];
    [button addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)playVideo
{
    NSLog(@"播放视频");
    [self.video seekTime:0.0];
    
    
    [NSTimer scheduledTimerWithTimeInterval:1/self.video.fps
                                     target:self
                                   selector:@selector(displayNextFrame:)
                                   userInfo:nil
                                    repeats:YES];
}

-(void)displayNextFrame:(NSTimer *)timer {
    
    if (![self.video stepFrame]) {
//        [timer invalidate];
        return;
    }
    
    self.videoImageView.image = self.video.currentImage;
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
