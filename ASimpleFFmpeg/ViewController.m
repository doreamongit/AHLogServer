//
//  ViewController.m
//  ASimpleFFmpeg
//
//  Created by Damon on 2019/3/19.
//  Copyright © 2019年 Damon. All rights reserved.
//

#import "ViewController.h"

#import "DemoOneVC.h"
#import "DemoTwoVC.h"
#import "DemoFourVC.h"
#import "DemoFiveVC.h"
#import "DemoSixVC.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) NSMutableArray *dataSource;
@property(nonatomic,strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.dataSource = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4播放视频，用UIImageView显示",@"5录制网络视频到本地",@"6获取指定时间的截图", nil];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.tableView];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"idididid"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"idididid"];
    }
    
    cell.textLabel.text = self.dataSource[indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        {
            //外部设置缓存比例
            DemoOneVC *vc = [[DemoOneVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1:
        {
            //外部设置缓存比例
            DemoTwoVC *vc = [[DemoTwoVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
            //外部设置缓存比例
//            DemoOneVC *vc = [[DemoOneVC alloc] init];
//            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 3:
        {
            //外部设置缓存比例
            DemoFourVC *vc = [[DemoFourVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 4:
        {
            //外部设置缓存比例
            DemoFiveVC *vc = [[DemoFiveVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 5:
        {
            //外部设置缓存比例
            DemoSixVC *vc = [[DemoSixVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        
        default:
            break;
    }
}

@end
