# SEBLEPrinter
iOS 蓝牙打印机库，侧重于打印部分，弱化蓝牙操作。<br>
# 更新
修复打印乱码，导致打印机脱机再次打印没有反应的重大Bug。(2016-06-14) <br>
删除了鸡肋的预览效果图。<br>
demo中已经给出分多次打印的示例代码。
# 效果图
![小票](https://github.com/Halley-Wong/HLBluetoothDemo/blob/master/HLBluetoothDemo/images/printer.png)
# 说明
与上一个蓝牙和打印demo中不同。
因为连接蓝牙打印机的功能比较单一，重点是往蓝牙设备中写入数据，而扫描服务、特性、描述以及读取特性值，这些使用者根本不care。
所以这个库的使用也更简单一些，所有的功能可以只看`SEPrinterManager`即可。

如果你有更好的建议或者疑问，欢迎加群：552735579。
