//
//  ViewController.m
//  SEBLEPrinter
//
//  Created by Harvey on 16/5/5.
//  Copyright © 2016年 Halley. All rights reserved.
//

#import "ViewController.h"

#import "SEPrinterManager.h"
#import "SVProgressHUD.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic)   NSArray              *deviceArray;  /**< 蓝牙设备个数 */

@property (strong, nonatomic)   SEPrinterManager      *manager;  /**< 蓝牙打印机 */

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"未连接";
    _manager = [SEPrinterManager sharedInstance];
    [_manager startScanPerpheralTimeout:10 Success:^(NSArray<CBPeripheral *> *perpherals) {
        NSLog(@"perpherals:%@",perpherals);
        _deviceArray = perpherals;
        [_tableView reloadData];
    } failure:^(SEScanError error) {
         NSLog(@"error:%ld",(long)error);
    }];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)rightAction
{
    NSString *title = @"测试电商";
    NSString *str1 = @"测试电商服务中心(销售单)";
    
    //方式一：
//    HLPrinter *printer = [[HLPrinter alloc] init];
//    [printer appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
//    [printer appendText:str1 alignment:HLTextAlignmentCenter];
//    [printer appendBarCodeWithInfo:@"RN3456789012"];
//    [printer appendSeperatorLine];
//    
//    [printer appendTitle:@"时间:" value:@"2016-04-27 10:01:50" valueOffset:150];
//    [printer appendTitle:@"订单:" value:@"4000020160427100150" valueOffset:150];
//    [printer appendText:@"地址:深圳市南山区学府路东深大店" alignment:HLTextAlignmentLeft];
//    
//    [printer appendSeperatorLine];
//    [printer appendLeftText:@"商品" middleText:@"数量" rightText:@"单价" isTitle:YES];
//    CGFloat total = 0.0;
//    NSDictionary *dict1 = @{@"name":@"铅笔",@"amount":@"5",@"price":@"2.0"};
//    NSDictionary *dict2 = @{@"name":@"橡皮",@"amount":@"1",@"price":@"1.0"};
//    NSDictionary *dict3 = @{@"name":@"笔记本",@"amount":@"3",@"price":@"3.0"};
//    NSArray *goodsArray = @[dict1, dict2, dict3];
//    for (NSDictionary *dict in goodsArray) {
//        [printer appendLeftText:dict[@"name"] middleText:dict[@"amount"] rightText:dict[@"price"] isTitle:NO];
//        total += [dict[@"price"] floatValue] * [dict[@"amount"] intValue];
//    }
//    
//    [printer appendSeperatorLine];
//    NSString *totalStr = [NSString stringWithFormat:@"%.2f",total];
//    [printer appendTitle:@"总计:" value:totalStr];
//    [printer appendTitle:@"实收:" value:@"100.00"];
//    NSString *leftStr = [NSString stringWithFormat:@"%.2f",100.00 - total];
//    [printer appendTitle:@"找零:" value:leftStr];
//    
//    [printer appendFooter:nil];
//    
//    [printer appendImage:[UIImage imageNamed:@"ico180"] alignment:HLTextAlignmentCenter maxWidth:300];
//    
//    NSData *mainData = [printer getFinalData];
//    
//    [_manager sendPrintData:mainData completion:nil];
    
    //方式二：
    [_manager prepareForPrinter];
    [_manager appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
    [_manager appendText:str1 alignment:HLTextAlignmentCenter];
//    [_manager appendBarCodeWithInfo:@"RN3456789012"];
    [_manager appendSeperatorLine];
    
    [_manager appendTitle:@"时间:" value:@"2016-04-27 10:01:50" valueOffset:150];
    [_manager appendTitle:@"订单:" value:@"4000020160427100150" valueOffset:150];
    [_manager appendText:@"地址:深圳市南山区学府路东深大店" alignment:HLTextAlignmentLeft];
    
    [_manager appendSeperatorLine];
    [_manager appendLeftText:@"商品" middleText:@"数量" rightText:@"单价" isTitle:YES];
    CGFloat total = 0.0;
    NSDictionary *dict1 = @{@"name":@"铅笔",@"amount":@"5",@"price":@"2.0"};
    NSDictionary *dict2 = @{@"name":@"橡皮",@"amount":@"1",@"price":@"1.0"};
    NSDictionary *dict3 = @{@"name":@"笔记本",@"amount":@"3",@"price":@"3.0"};
    NSArray *goodsArray = @[dict1, dict2, dict3];
    for (NSDictionary *dict in goodsArray) {
        [_manager appendLeftText:dict[@"name"] middleText:dict[@"amount"] rightText:dict[@"price"] isTitle:NO];
        total += [dict[@"price"] floatValue] * [dict[@"amount"] intValue];
    }
    
    [_manager appendSeperatorLine];
    NSString *totalStr = [NSString stringWithFormat:@"%.2f",total];
    [_manager appendTitle:@"总计:" value:totalStr];
    [_manager appendTitle:@"实收:" value:@"100.00"];
    NSString *leftStr = [NSString stringWithFormat:@"%.2f",100.00 - total];
    [_manager appendTitle:@"找零:" value:leftStr];
    
    [_manager appendFooter:nil];
    
//    [_manager appendImage:[UIImage imageNamed:@"ico180"] alignment:HLTextAlignmentCenter maxWidth:300];
    
    [_manager printWithResult:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"deviceId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    CBPeripheral *peripherral = [self.deviceArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"名称:%@",peripherral.name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CBPeripheral *peripheral = [self.deviceArray objectAtIndex:indexPath.row];
    
    [_manager connectPeripheral:peripheral completion:^(CBPeripheral *perpheral, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:@"连接失败"];
        } else {
            self.title = @"已连接";
            [SVProgressHUD showSuccessWithStatus:@"连接成功"];
        }
    }];
}

@end
