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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"未连接";
    SEPrinterManager *_manager = [SEPrinterManager sharedInstance]; // 这里本来不是单例，后来加的，所以下面还是当成实例变量在用
    [_manager startScanPerpheralTimeout:10 Success:^(NSArray<CBPeripheral *> *perpherals,BOOL isTimeout) {
        NSLog(@"perpherals:%@",perpherals);
        _deviceArray = perpherals;
        [_tableView reloadData];
    } failure:^(SEScanError error) {
         NSLog(@"error:%ld",(long)error);
    }];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (HLPrinter *)getPrinter
{
    HLPrinter *printer = [[HLPrinter alloc] init];
    NSString *title = @"测试电商";
    NSString *str1 = @"测试电商服务中心(销售单)";
    [printer appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
    [printer appendText:str1 alignment:HLTextAlignmentCenter];
    [printer appendBarCodeWithInfo:@"RN3456789012"];
    [printer appendSeperatorLine];
    
    [printer appendTitle:@"时间:" value:@"2016-04-27 10:01:50" valueOffset:150];
    [printer appendTitle:@"订单:" value:@"4000020160427100150" valueOffset:150];
    [printer appendText:@"地址:深圳市南山区学府路东深大店" alignment:HLTextAlignmentLeft];
    
    [printer appendSeperatorLine];
    [printer appendLeftText:@"商品" middleText:@"数量" rightText:@"单价" isTitle:YES];
    CGFloat total = 0.0;
    NSDictionary *dict1 = @{@"name":@"铅笔测试一下哈哈",@"amount":@"5",@"price":@"2.0"};
    NSDictionary *dict2 = @{@"name":@"abcdefghijfdf",@"amount":@"1",@"price":@"1.0"};
    NSDictionary *dict3 = @{@"name":@"abcde笔记本啊啊",@"amount":@"3",@"price":@"3.0"};
    NSArray *goodsArray = @[dict1, dict2, dict3];
    for (NSDictionary *dict in goodsArray) {
        [printer appendLeftText:dict[@"name"] middleText:dict[@"amount"] rightText:dict[@"price"] isTitle:NO];
        total += [dict[@"price"] floatValue] * [dict[@"amount"] intValue];
    }
    
    [printer appendSeperatorLine];
    NSString *totalStr = [NSString stringWithFormat:@"%.2f",total];
    [printer appendTitle:@"总计:" value:totalStr];
    [printer appendTitle:@"实收:" value:@"100.00"];
    NSString *leftStr = [NSString stringWithFormat:@"%.2f",100.00 - total];
    [printer appendTitle:@"找零:" value:leftStr];
    
    [printer appendSeperatorLine];
    
    [printer appendQRCodeWithInfo:@"www.baidu.com"];
//    [printer appendQRCodeWithInfo:@"www.baidu.com" size:10];

    [printer appendFooter:nil];
    [printer appendImage:[UIImage imageNamed:@"ico180"] alignment:HLTextAlignmentCenter maxWidth:300];
    
    // 你也可以利用UIWebView加载HTML小票的方式，这样可以在远程修改小票的样式和布局。
    // 注意点：需要等UIWebView加载完成后，再截取UIWebView的屏幕快照，然后利用添加图片的方法，加进printer
    // 截取屏幕快照，可以用UIWebView+UIImage中的catogery方法 - (UIImage *)imageForWebView
    
    return printer;
}

- (void)rightAction
{
    //方式一：
    HLPrinter *printer = [self getPrinter];
    
    NSData *mainData = [printer getFinalData];
    [[SEPrinterManager sharedInstance] sendPrintData:mainData completion:^(CBPeripheral *connectPerpheral, BOOL completion, NSString *error) {
        NSLog(@"写入数据返回结果啦");
    }];
    
    //方式二：
//    [_manager prepareForPrinter];
//    [_manager appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
//    [_manager appendText:str1 alignment:HLTextAlignmentCenter];
////    [_manager appendBarCodeWithInfo:@"RN3456789012"];
//    [_manager appendSeperatorLine];
//    
//    [_manager appendTitle:@"时间:" value:@"2016-04-27 10:01:50" valueOffset:150];
//    [_manager appendTitle:@"订单:" value:@"4000020160427100150" valueOffset:150];
//    [_manager appendText:@"地址:深圳市南山区学府路东深大店" alignment:HLTextAlignmentLeft];
//    
//    [_manager appendSeperatorLine];
//    [_manager appendLeftText:@"商品" middleText:@"数量" rightText:@"单价" isTitle:YES];
//    CGFloat total = 0.0;
//    NSDictionary *dict1 = @{@"name":@"铅笔",@"amount":@"5",@"price":@"2.0"};
//    NSDictionary *dict2 = @{@"name":@"橡皮",@"amount":@"1",@"price":@"1.0"};
//    NSDictionary *dict3 = @{@"name":@"笔记本",@"amount":@"3",@"price":@"3.0"};
//    NSArray *goodsArray = @[dict1, dict2, dict3];
//    for (NSDictionary *dict in goodsArray) {
//        [_manager appendLeftText:dict[@"name"] middleText:dict[@"amount"] rightText:dict[@"price"] isTitle:NO];
//        total += [dict[@"price"] floatValue] * [dict[@"amount"] intValue];
//    }
//    
//    [_manager appendSeperatorLine];
//    NSString *totalStr = [NSString stringWithFormat:@"%.2f",total];
//    [_manager appendTitle:@"总计:" value:totalStr];
//    [_manager appendTitle:@"实收:" value:@"100.00"];
//    NSString *leftStr = [NSString stringWithFormat:@"%.2f",100.00 - total];
//    [_manager appendTitle:@"找零:" value:leftStr];
//    
//    [_manager appendFooter:nil];
//    
////    [_manager appendImage:[UIImage imageNamed:@"ico180"] alignment:HLTextAlignmentCenter maxWidth:300];
//    
//    [_manager printWithResult:nil];
    
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
    
    [[SEPrinterManager sharedInstance] connectPeripheral:peripheral completion:^(CBPeripheral *perpheral, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:@"连接失败"];
        } else {
            self.title = @"已连接";
            [SVProgressHUD showSuccessWithStatus:@"连接成功"];
        }
    }];
    
    // 如果你需要连接，立刻去打印
//    [[SEPrinterManager sharedInstance] fullOptionPeripheral:peripheral completion:^(SEOptionStage stage, CBPeripheral *perpheral, NSError *error) {
//        if (stage == SEOptionStageSeekCharacteristics) {
//            HLPrinter *printer = [self getPrinter];
//            
//            NSData *mainData = [printer getFinalData];
//            [[SEPrinterManager sharedInstance] sendPrintData:mainData completion:nil];
//        }
//    }];
}

@end
