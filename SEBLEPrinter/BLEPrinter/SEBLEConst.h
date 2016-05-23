//
//  SEBLEConst.h
//  SEBLEPrinter
//
//  Created by Harvey on 16/5/5.
//  Copyright © 2016年 Halley. All rights reserved.
//

#ifndef SEBLEConst_h
#define SEBLEConst_h

typedef NS_ENUM(NSInteger, SEScanError) {
    SEScanErrorUnknown = 0,
    SEScanErrorResetting,
    SEScanErrorUnsupported,         //设备不支持
    SEScanErrorUnauthorized,        //未授权
    SEScanErrorPoweredOff,          //蓝牙可用，但是未打开
    SEScanErrorTimeout,             //搜索超时
};

typedef NS_ENUM(NSInteger, SEOptionStage) {
    SEOptionStageConnection,            //蓝牙连接阶段
    SEOptionStageSeekServices,          //搜索服务阶段
    SEOptionStageSeekCharacteristics,   //搜索特性阶段
    SEOptionStageSeekdescriptors,       //搜索描述信息阶段
};

/**
 *  扫描成功的block
 *
 *  @param perpherals 蓝牙外设列表
 */
typedef void(^SEScanPerpheralSuccess)(NSArray<CBPeripheral *> *perpherals, BOOL isTimeout);

/**
 *  扫描失败的block
 *
 *  @param errorDict 失败的字典
 */
typedef void(^SEScanPerpheralFailure)(SEScanError error);

/**
 *  连接完成的block
 *
 *  @param perpheral 要连接的蓝牙外设
 */
typedef void(^SEConnectCompletion)(CBPeripheral *perpheral, NSError *error);

/**
 *  连接、扫描服务、扫描特性、扫描描述全套流程
 *
 *  @param stage     枚举  所处阶段
 *  @param perpheral 蓝牙外设
 *  @param error     错误信息
 */
typedef void(^SEFullOptionCompletion)(SEOptionStage stage, CBPeripheral *perpheral, NSError *error);

/**
 *  断开蓝牙连接
 *
 *  @param CBPeripheral 蓝牙外设
 *  @param error        错误
 */
typedef void(^SEDisconnect)(CBPeripheral *perpheral, NSError *error);

/**
 *  打印回调
 *
 *  @param completion 是否完成
 *  @param error      错误信息
 */
typedef void(^SEPrintResult)(CBPeripheral *connectPerpheral, BOOL completion, NSString *error);


#endif /* SEBLEConst_h */
