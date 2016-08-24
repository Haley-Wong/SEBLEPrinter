//
//  SEPrinterManager.m
//  SEBLEPrinter
//
//  Created by Harvey on 16/5/5.
//  Copyright © 2016年 Halley. All rights reserved.
//

#import "SEPrinterManager.h"

#define kSECharacter    @"character"
#define kSEType         @"type"

// 发送数据时，需要分段的长度，部分打印机一次发送数据过长就会乱码，需要分段发送。这个长度值不同的打印机可能不一样，你需要调试设置一个合适的值（最好是偶数）
#define kLimitLength    146

@interface SEPrinterManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (copy, nonatomic)   SEScanPerpheralSuccess             scanPerpheralSuccess;  /**< 扫描设备成功的回调 */
@property (copy, nonatomic)   SEScanPerpheralFailure             scanPerpheralFailure;  /**< 扫描设备失败的回调 */
@property (copy, nonatomic)   SEConnectCompletion                connectCompletion;    /**< 连接完成的回调 */
@property (copy, nonatomic)   SEFullOptionCompletion             optionCompletion;    /**< 连接、扫描、搜索 */

@property (copy, nonatomic)   SEDisconnect                       disconnectBlock;    /**< 断开连接的回调 */

@property (strong, nonatomic)   SEPrintResult                   printResult;  /**< 打印结果的回调 */

@property (strong, nonatomic)   CBCentralManager            *centralManager;        /**< 中心管理器 */
@property (strong, nonatomic)   CBPeripheral                *connectedPerpheral;    /**< 当前连接的外设 */
@property (strong, nonatomic)   NSMutableArray              *perpherals;  /**< 搜索到的蓝牙设备列表 */

@property (strong, nonatomic)   NSMutableArray              *writeChatacters;  /**< 可写入数据的特性 */

@property (assign, nonatomic)   NSTimeInterval              timeout;  /**< 默认超时时间 */

@property (strong, nonatomic)   HLPrinter            *printer;  /**< 打印器 */

@property (assign, nonatomic)   BOOL             autoConnect;  /**< 自动连接上次的外设 */

@property (assign, nonatomic)   NSInteger         writeCount;   /**< 写入次数 */
@property (assign, nonatomic)   NSInteger         responseCount; /**< 返回次数 */

@end

static SEPrinterManager *instance = nil;

@implementation SEPrinterManager

+ (instancetype)sharedInstance
{
    return [[self alloc] init];
}

+ (NSString *)UUIDStringForLastPeripheral
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *UUIDString = [userDefaults objectForKey:@"peripheral"];
    return UUIDString;
}

- (instancetype)init
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super init];
        instance.perpherals = [[NSMutableArray alloc] init];
        instance.writeChatacters = [[NSMutableArray alloc] init];
        instance.timeout = 30;
        [instance resetBLEModel];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    
    return instance;
}

#pragma mark - bluetooth method
- (void)setTimeout:(NSTimeInterval)timeout
{
    _timeout = timeout;
    
    if (_timeout > 0) {
        [self performSelector:@selector(timeoutAction) withObject:nil afterDelay:timeout];
    }
}

- (void)timeoutAction
{
    [_centralManager stopScan];
    if (_perpherals.count == 0) {
        //分发错误信息
        if (_delegate && [_delegate respondsToSelector:@selector(printerManager:scanError:)]) {
            [_delegate printerManager:self scanError:SEScanErrorTimeout];
        }
        
        if (_scanPerpheralFailure) {
            _scanPerpheralFailure(SEScanErrorTimeout);
        }
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(printerManager:perpherals:isTimeout:)]) {
            [_delegate printerManager:self perpherals:_perpherals isTimeout:YES];
        }
        if (_scanPerpheralSuccess) {
            _scanPerpheralSuccess(_perpherals,YES);
        }
    }
}

- (BOOL)isConnected
{
    if (!_connectedPerpheral) {
        return NO;
    }
    
    if (_connectedPerpheral.state != CBPeripheralStateConnected && _connectedPerpheral.state != CBPeripheralStateConnecting) {
        return NO;
    }
    
    return YES;
}

- (void)resetBLEModel
{
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    [_perpherals removeAllObjects];
    _connectedPerpheral = nil;
}

- (void)startScanPerpheralTimeout:(NSTimeInterval)timeout
{
    self.timeout = timeout;
    if (_centralManager.state == CBCentralManagerStatePoweredOn) {
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
        return;
    }
    
    [self resetBLEModel];
}

- (void)startScanPerpheralTimeout:(NSTimeInterval)timeout Success:(SEScanPerpheralSuccess)success failure:(SEScanPerpheralFailure)failure
{
    self.timeout = timeout;
    _scanPerpheralSuccess = success;
    _scanPerpheralFailure = failure;
    
    if (_centralManager.state == CBCentralManagerStatePoweredOn) {
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
        return;
    }
    
    [self resetBLEModel];
}

- (void)stopScan
{
    [_centralManager stopScan];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral
{
    [_centralManager connectPeripheral:peripheral options:nil];
    peripheral.delegate = self;
}

- (void)connectPeripheral:(CBPeripheral *)peripheral completion:(SEConnectCompletion)completion
{
    _connectCompletion = completion;
    [self connectPeripheral:peripheral];
}

- (void)fullOptionPeripheral:(CBPeripheral *)peripheral completion:(SEFullOptionCompletion)completion
{
    _optionCompletion = completion;
    [self connectPeripheral:peripheral];
}

- (void)cancelPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral) {
        return;
    }
    [_centralManager cancelPeripheralConnection:peripheral];
    _connectedPerpheral = nil;
    [_writeChatacters removeAllObjects];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"peripheral"];
    [userDefaults synchronize];
}

- (void)autoConnectLastPeripheralTimeout:(NSTimeInterval)timeout completion:(SEConnectCompletion)completion
{
    self.timeout = timeout;
    
    _autoConnect = YES;
    
    _connectCompletion = completion;
    
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)setDisconnect:(SEDisconnect)disconnectBlock
{
    _disconnectBlock = disconnectBlock;
}

- (void)sendPrintData:(NSData *)data completion:(SEPrintResult)result
{
    if (!self.connectedPerpheral) {
        if (result) {
            result(_connectedPerpheral,NO,@"未连接蓝牙设备");
        }
        return;
    }
    
    if (self.writeChatacters.count == 0) {
        if (result) {
           result(_connectedPerpheral,NO,@"该蓝牙设备不能写入数据");
        }
        return;
    }
    
    NSDictionary *dict = [_writeChatacters lastObject];
    
    _writeCount = 0;
    _responseCount = 0;
    // 如果kLimitLength 小于等于0，则表示不用分段发送
    if (kLimitLength <= 0) {
        _printResult = result;
        [_connectedPerpheral writeValue:data forCharacteristic:dict[kSECharacter] type:[dict[kSEType] integerValue]];
        _writeCount ++;
        return;
    }
    
    if (data.length <= kLimitLength) {
        _printResult = result;
        [_connectedPerpheral writeValue:data forCharacteristic:dict[kSECharacter] type:[dict[kSEType] integerValue]];
        _writeCount ++;
    } else {
        NSInteger index = 0;
        for (index = 0; index < data.length - kLimitLength; index += kLimitLength) {
            NSData *subData = [data subdataWithRange:NSMakeRange(index, kLimitLength)];
            [_connectedPerpheral writeValue:subData forCharacteristic:dict[kSECharacter] type:[dict[kSEType] integerValue]];
            _writeCount++;
        }
        _printResult = result;
        NSData *leftData = [data subdataWithRange:NSMakeRange(index, data.length - index)];
        if (leftData) {
            [_connectedPerpheral writeValue:leftData forCharacteristic:dict[kSECharacter] type:[dict[kSEType] integerValue]];
            _writeCount++;
        }
    }
}

- (void)printWithResult:(SEPrintResult)result
{
    NSData *finalData = [_printer getFinalData];
    if (finalData.length == 0) {
        if (result) {
            result(_connectedPerpheral,NO,@"打印数据格式出错");
        }
        return;
    }
    
    [self sendPrintData:finalData completion:result];
}

#pragma mark - ------------print method ----------------
- (void)prepareForPrinter
{
    HLPrinter *printer = [[HLPrinter alloc] init];
    _printer = printer;
}

/**
 *  添加单行标题,默认字号是小号字体
 *
 *  @param title     标题名称
 *  @param alignment 标题对齐方式
 */
- (void)appendText:(NSString *)text alignment:(HLTextAlignment)alignment
{
    [_printer appendText:text alignment:alignment];
}

/**
 *  添加单行标题
 *
 *  @param title     标题名称
 *  @param alignment 标题对齐方式
 *  @param fontSize  标题字号
 */
- (void)appendText:(NSString *)text alignment:(HLTextAlignment)alignment fontSize:(HLFontSize)fontSize
{
    [_printer appendText:text alignment:alignment fontSize:fontSize];
}

/**
 *  添加单行信息，左边名称(左对齐)，右边实际值（右对齐）,默认字号是小号。
 *  @param title    名称
 *  @param value    实际值
 *  警告:因字号和字体与iOS中字体不一致，计算出来有误差，可以用[-appendTitle:value:valueOffset:]或[-appendTitle:value:valueOffset:fontSize:]
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value
{
    [_printer appendTitle:title value:value];
}

/**
 *  添加单行信息，左边名称(左对齐)，右边实际值（右对齐）。
 *  @param title    名称
 *  @param value    实际值
 *  @param fontSize 字号大小
 *  警告:因字号和字体与iOS中字体不一致，计算出来有误差,所以建议用在价格方面
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value fontSize:(HLFontSize)fontSize
{
    [_printer appendTitle:title value:value fontSize:fontSize];
}

/**
 *  设置单行信息，左标题，右实际值
 *
 *  @param title    标题
 *  @param value    实际值
 *  @param offset   实际值偏移量
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value valueOffset:(NSInteger)offset
{
    [_printer appendTitle:title value:value valueOffset:offset];
}

/**
 *  设置单行信息，左标题，右实际值
 *
 *  @param title    标题
 *  @param value    实际值
 *  @param offset   实际值偏移量
 *  @param fontSize 字号
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value valueOffset:(NSInteger)offset fontSize:(HLFontSize)fontSize
{
    [_printer appendTitle:title value:value valueOffset:offset fontSize:fontSize];
}

/**
 *  添加选购商品信息标题,一般是三列，名称、数量、单价
 *
 *  @param LeftText   左标题
 *  @param middleText 中间标题
 *  @param rightText  右标题
 */
- (void)appendLeftText:(NSString *)left middleText:(NSString *)middle rightText:(NSString *)right isTitle:(BOOL)isTitle
{
    [_printer appendLeftText:left middleText:middle rightText:right isTitle:isTitle];
}

/**
 *  添加图片，一般是添加二维码或者条形码
 *
 *  @param image     图片
 *  @param alignment 图片对齐方式
 *  @param maxWidth  图片的最大宽度，如果图片过大，会等比缩放
 */
- (void)appendImage:(UIImage *)image alignment:(HLTextAlignment)alignment maxWidth:(CGFloat)maxWidth
{
    [_printer appendImage:image alignment:alignment maxWidth:maxWidth];
}

/**
 *  添加条形码图片
 *
 *  @param info 条形码中包含的信息，默认居中显示，最大宽度为300。如果大于300,会等比缩放。
 */
- (void)appendBarCodeWithInfo:(NSString *)info
{
    [_printer appendBarCodeWithInfo:info];
}

/**
 *  添加条形码图片
 *
 *  @param info      条形码中的信息
 *  @param alignment 图片对齐方式
 *  @param maxWidth  图片最大宽度
 */
- (void)appendBarCodeWithInfo:(NSString *)info alignment:(HLTextAlignment)alignment maxWidth:(CGFloat)maxWidth
{
    [_printer appendBarCodeWithInfo:info alignment:alignment maxWidth:maxWidth];
}

- (void)appendQRCodeWithInfo:(NSString *)info size:(NSInteger)size
{
    [_printer appendQRCodeWithInfo:info size:size];

}

- (void)appendQRCodeWithInfo:(NSString *)info size:(NSInteger)size alignment:(HLTextAlignment)alignment
{
    [_printer appendQRCodeWithInfo:info size:size alignment:alignment];
}

/**
 *  添加二维码图片
 *
 *  @param info 二维码中的信息
 */
- (void)appendQRCodeWithInfo:(NSString *)info
{
    [_printer appendQRCodeWithInfo:info];
}

/**
 *  添加二维码图片
 *
 *  @param info        二维码中的信息
 *  @param centerImage 二维码中间的图片
 *  @param alignment   对齐方式
 *  @param maxWidth    二维码的最大宽度
 */
- (void)appendQRCodeWithInfo:(NSString *)info centerImage:(UIImage *)centerImage alignment:(HLTextAlignment)alignment maxWidth:(CGFloat )maxWidth
{
    [_printer appendQRCodeWithInfo:info centerImage:centerImage alignment:alignment maxWidth:maxWidth];
}

/**
 *  添加一条分割线，like this:---------------------------
 */
- (void)appendSeperatorLine
{
    [_printer appendSeperatorLine];
}

/**
 *  添加底部信息
 *
 *  @param footerInfo 不填默认为 谢谢惠顾，欢迎下次光临！
 */
- (void)appendFooter:(NSString *)footerInfo
{
    [_printer appendFooter:footerInfo];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        if (_delegate && [_delegate respondsToSelector:@selector(printerManager:scanError:)]) {
            [_delegate printerManager:self scanError:(SEScanError)central.state];
        }
        
        if (_scanPerpheralFailure) {
            _scanPerpheralFailure((SEScanError)central.state);
        }
        
    } else {
        [central scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (peripheral.name.length <= 0) {
        return ;
    }
    if (_perpherals.count == 0) {
        [_perpherals addObject:peripheral];
    } else {
        BOOL isExist = NO;
        for (int i = 0; i < _perpherals.count; i++) {
            CBPeripheral *per = [_perpherals objectAtIndex:i];
            if ([per.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                isExist = YES;
                [_perpherals replaceObjectAtIndex:i withObject:peripheral];
            }
        }
        
        if (!isExist) {
            [_perpherals addObject:peripheral];
        }
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(printerManager:perpherals:isTimeout:)]) {
        [_delegate printerManager:self perpherals:_perpherals isTimeout:NO];
    }
    
    if (_scanPerpheralSuccess) {
        _scanPerpheralSuccess(_perpherals,NO);
    }
    
    if (_autoConnect) {
        NSString *UUIDString = [SEPrinterManager UUIDStringForLastPeripheral];
        
        if ([peripheral.identifier.UUIDString isEqualToString:UUIDString]) {
            [_centralManager connectPeripheral:peripheral options:nil];
            peripheral.delegate = self;
        }
    }
}

#pragma mark ---------------- 连接外设成功和失败的代理 ---------------
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    _connectedPerpheral = peripheral;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:peripheral.identifier.UUIDString forKey:@"peripheral"];
    [userDefaults synchronize];
    
    [_centralManager stopScan];
    
    if (_connectCompletion) {
        _connectCompletion(peripheral,nil);
    }
    
    if (_optionCompletion) {
        _optionCompletion(SEOptionStageConnection,peripheral,nil);
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(printerManager:completeConnectPerpheral:error:)]) {
        [_delegate printerManager:self completeConnectPerpheral:peripheral error:nil];
    }
    
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    if (_connectCompletion) {
        _connectCompletion(peripheral,error);
    }
    
    if (_optionCompletion) {
        _optionCompletion(SEOptionStageConnection, peripheral,error);
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(printerManager:completeConnectPerpheral:error:)]) {
        [_delegate printerManager:self completeConnectPerpheral:peripheral error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    _connectedPerpheral = nil;
    [_writeChatacters removeAllObjects];
    
    if (_delegate && [_delegate respondsToSelector:@selector(printerManager:disConnectPeripheral:error:)]) {
        [_delegate printerManager:self disConnectPeripheral:peripheral error:error];
    }
    
    if (_disconnectBlock) {
        _disconnectBlock(peripheral,error);
    }
}

#pragma mark ---------------- 发现服务的代理 -----------------
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    if (error) {
        if (_optionCompletion) {
            _optionCompletion(SEOptionStageSeekServices,peripheral,error);
        }
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
    if (_optionCompletion) {
        _optionCompletion(SEOptionStageSeekServices,peripheral,nil);
    }
}

#pragma mark ---------------- 服务特性的代理 --------------------
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    if (error) {
        if ([service isEqual:peripheral.services.lastObject]) {
            if (_writeChatacters.count > 0) {
                if (_optionCompletion) {
                    _optionCompletion(SEOptionStageSeekCharacteristics,peripheral,nil);
                }
            } else {
                if (_optionCompletion) {
                    _optionCompletion(SEOptionStageSeekCharacteristics,peripheral,error);
                }
            }
        }
        return;
    }
    
    for (CBCharacteristic *character in service.characteristics) {
        CBCharacteristicProperties properties = character.properties;
        //如果我们需要回调，则就不要使用没有返回的特性来写入数据
//        if (properties & CBCharacteristicPropertyWriteWithoutResponse) {
//            NSDictionary *dict = @{kSECharacter:character,kSEType:@(CBCharacteristicWriteWithoutResponse)};
//            [_writeChatacters addObject:dict];
//        }
        
        if (properties & CBCharacteristicPropertyWrite) {
            NSDictionary *dict = @{kSECharacter:character,kSEType:@(CBCharacteristicWriteWithResponse)};
            [_writeChatacters addObject:dict];
        }
    }
    
    if ([service isEqual:peripheral.services.lastObject]) {
        if (_optionCompletion) {
            _optionCompletion(SEOptionStageSeekCharacteristics,peripheral,nil);
        }
    }
}

#pragma mark ---------------- 写入数据的回调 --------------------
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (!_printResult) {
        return;
    }
    _responseCount ++;
    if (_writeCount != _responseCount) {
        return;
    }
    
    if (error) {
        _printResult(_connectedPerpheral,NO,@"发送失败");
    } else {
        _printResult(_connectedPerpheral,YES,@"已成功发送至蓝牙设备");
    }
}


@end
