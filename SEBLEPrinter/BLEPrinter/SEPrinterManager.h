//
//  SEPrinterManager.h
//  SEBLEPrinter
//
//  Created by Harvey on 16/5/5.
//  Copyright © 2016年 Halley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "SEBLEConst.h"
#import "HLPrinter.h"

@class SEPrinterManager;
@protocol SEPrinterManagerDelegate <NSObject>

/** 返回扫描到的蓝牙 设备列表
 *  因为蓝牙模块一次返回一个设备，所以该方法会调用多次
 */
- (void)printerManager:(SEPrinterManager *)manager perpherals:(NSArray<CBPeripheral *> *)perpherals isTimeout:(BOOL)isTimeout;

/** 扫描蓝牙设备失败
 *
 */
- (void)printerManager:(SEPrinterManager *)manager scanError:(SEScanError)error;

/**
 *  连接蓝牙外设完成
 *
 *  @param manager
 *  @param perpheral 蓝牙外设
 *  @param error
 */
- (void)printerManager:(SEPrinterManager *)manager completeConnectPerpheral:(CBPeripheral *)perpheral error:(NSError *)error;

/**
 *  断开连接
 *
 *  @param manager
 *  @param peripheral 设备
 *  @param error      错误信息
 */
- (void)printerManager:(SEPrinterManager *)manager disConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@end


@interface SEPrinterManager : NSObject

/**< 蓝牙操作代理 */
@property (assign, nonatomic)   id<SEPrinterManagerDelegate>             delegate;

@property (strong, nonatomic, readonly)   CBPeripheral                *connectedPerpheral;    /**< 当前连接的外设 */

#pragma mark - bluetooth method

+ (instancetype)sharedInstance;

/**
 *  上次连接的蓝牙外设的UUIDString
 *
 *  @return UUIDString,没有时返回nil
 */
+ (NSString *)UUIDStringForLastPeripheral;

/**
 *  蓝牙外设是否已连接
 *
 *  @return YES/NO
 */
- (BOOL)isConnected;

/**
 *  开始扫描蓝牙外设
 *  @param timeout 扫描超时时间,设置为0时表示一直扫描
 */
- (void)startScanPerpheralTimeout:(NSTimeInterval)timeout;

/**
 *  开始扫描蓝牙外设，block方式返回结果
 *  @param timeout 扫描超时时间，设置为0时表示一直扫描
 *  @param success 扫描成功的回调
 *  @param failure 扫描失败的回调
 */
- (void)startScanPerpheralTimeout:(NSTimeInterval)timeout Success:(SEScanPerpheralSuccess)success failure:(SEScanPerpheralFailure)failure;

/**
 *  停止扫描蓝牙外设
 */
- (void)stopScan;

/**
 *  连接蓝牙外设,连接成功后会停止扫描蓝牙外设
 *
 *  @param peripheral 蓝牙外设
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral;

/**
 *  连接蓝牙外设，连接成功后会停止扫描蓝牙外设，block方式返回结果
 *
 *  @param peripheral 要连接的蓝牙外设
 *  @param completion 完成后的回调
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral completion:(SEConnectCompletion)completion;

/**
 *  完整操作，包括连接、扫描服务、扫描特性、扫描描述
 *
 *  @param peripheral 要连接的蓝牙外设
 *  @param completion 完成后的回调
 */
- (void)fullOptionPeripheral:(CBPeripheral *)peripheral completion:(SEFullOptionCompletion)completion;

/**
 *  取消某个蓝牙外设的连接
 *
 *  @param peripheral 蓝牙外设
 */
- (void)cancelPeripheral:(CBPeripheral *)peripheral;

/**
 *  自动连接上次的蓝牙外设
 *
 *  @param timeout
 *  @param completion
 */
- (void)autoConnectLastPeripheralTimeout:(NSTimeInterval)timeout completion:(SEConnectCompletion)completion;

/**
 *  设置断开连接的block
 *
 *  @param disconnectBlock
 */
- (void)setDisconnect:(SEDisconnect)disconnectBlock;

/**
 *  直接打印数据
 *
 *  @param result 结果
 */
- (void)printWithResult:(SEPrintResult)result;

/**
 *  打印自己组装的数据
 *
 *  @param data
 *  @param result 结果
 */
- (void)sendPrintData:(NSData *)data completion:(SEPrintResult)result;

#pragma mark - print method

- (void)prepareForPrinter;
/**
 *  添加单行标题,默认字号是小号字体
 *
 *  @param title     标题名称
 *  @param alignment 标题对齐方式
 */
- (void)appendText:(NSString *)text alignment:(HLTextAlignment)alignment;

/**
 *  添加单行标题
 *
 *  @param title     标题名称
 *  @param alignment 标题对齐方式
 *  @param fontSize  标题字号
 */
- (void)appendText:(NSString *)text alignment:(HLTextAlignment)alignment fontSize:(HLFontSize)fontSize;

/**
 *  添加单行信息，左边名称(左对齐)，右边实际值（右对齐）,默认字号是小号。
 *  @param title    名称
 *  @param value    实际值
 *  警告:因字号和字体与iOS中字体不一致，计算出来有误差，可以用[-appendTitle:value:valueOffset:]或[-appendTitle:value:valueOffset:fontSize:]
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value;

/**
 *  添加单行信息，左边名称(左对齐)，右边实际值（右对齐）。
 *  @param title    名称
 *  @param value    实际值
 *  @param fontSize 字号大小
 *  警告:因字号和字体与iOS中字体不一致，计算出来有误差,所以建议用在价格方面
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value fontSize:(HLFontSize)fontSize;

/**
 *  设置单行信息，左标题，右实际值
 *
 *  @param title    标题
 *  @param value    实际值
 *  @param offset   实际值偏移量
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value valueOffset:(NSInteger)offset;

/**
 *  设置单行信息，左标题，右实际值
 *
 *  @param title    标题
 *  @param value    实际值
 *  @param offset   实际值偏移量
 *  @param fontSize 字号
 */
- (void)appendTitle:(NSString *)title value:(NSString *)value valueOffset:(NSInteger)offset fontSize:(HLFontSize)fontSize;

/**
 *  添加选购商品信息标题,一般是三列，名称、数量、单价
 *
 *  @param LeftText   左标题
 *  @param middleText 中间标题
 *  @param rightText  右标题
 */
- (void)appendLeftText:(NSString *)left middleText:(NSString *)middle rightText:(NSString *)right isTitle:(BOOL)isTitle;

/**
 *  添加图片，一般是添加二维码或者条形码
 *
 *  @param image     图片
 *  @param alignment 图片对齐方式
 *  @param maxWidth  图片的最大宽度，如果图片过大，会等比缩放
 */
- (void)appendImage:(UIImage *)image alignment:(HLTextAlignment)alignment maxWidth:(CGFloat)maxWidth;

/**
 *  添加条形码图片
 *
 *  @param info 条形码中包含的信息，默认居中显示，最大宽度为300。如果大于300,会等比缩放。
 */
- (void)appendBarCodeWithInfo:(NSString *)info;

/**
 *  添加条形码图片
 *
 *  @param info      条形码中的信息
 *  @param alignment 图片对齐方式
 *  @param maxWidth  图片最大宽度
 */
- (void)appendBarCodeWithInfo:(NSString *)info alignment:(HLTextAlignment)alignment maxWidth:(CGFloat)maxWidth;

/**
 *  添加二维码
 *  ✅推荐：这种方式使用的是打印机的指令生成二维码并打印机，所以比较推荐这种方式
 *
 *  @param info 二维码中的信息
 *  @param size 二维码的大小 取值范围1 <= size <= 16
 */
- (void)appendQRCodeWithInfo:(NSString *)info size:(NSInteger)size;

/**
 *  添加二维码
 *  ✅推荐：这种方式使用的是打印机的指令生成二维码并打印机，所以比较推荐这种方式
 *
 *  @param info      二维码中的信息
 *  @param size      二维码大小，取值范围 1 <= size <= 16
 *  @param alignment 设置图片对齐方式
 */
- (void)appendQRCodeWithInfo:(NSString *)info size:(NSInteger)size alignment:(HLTextAlignment)alignment;

/**
 *  添加二维码图片
 *
 *  @param info 二维码中的信息
 */
- (void)appendQRCodeWithInfo:(NSString *)info;

/**
 *  添加二维码图片
 *
 *  @param info        二维码中的信息
 *  @param centerImage 二维码中间的图片
 *  @param alignment   对齐方式
 *  @param maxWidth    二维码的最大宽度
 */
- (void)appendQRCodeWithInfo:(NSString *)info centerImage:(UIImage *)centerImage alignment:(HLTextAlignment)alignment maxWidth:(CGFloat )maxWidth;

/**
 *  添加一条分割线，like this:---------------------------
 */
- (void)appendSeperatorLine;

/**
 *  添加底部信息
 *
 *  @param footerInfo 不填默认为 谢谢惠顾，欢迎下次光临！
 */
- (void)appendFooter:(NSString *)footerInfo;

@end
