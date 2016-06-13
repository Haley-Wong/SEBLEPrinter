# SEBLEPrinter
iOS 蓝牙打印机库，侧重于打印部分，弱化蓝牙操作。<br>
# 更新
添加了预览的功能。<br>
更新代码，修复一次打印的数据过多导致打印乱码的问题。解决方案，在写入前将数据拆分，然后分多次写入。<br>
当然也可以按照方式三，分多次打印。<br>
demo中已经给出分多次打印的示例代码。
# 效果图
![预览](https://github.com/Halley-Wong/HLBluetoothDemo/blob/master/HLBluetoothDemo/images/04.png)
![小票](https://github.com/Halley-Wong/HLBluetoothDemo/blob/master/HLBluetoothDemo/images/printer.png)
# 说明
与上一个蓝牙和打印demo中不同。
因为连接蓝牙打印机的功能比较单一，重点是往蓝牙设备中写入数据，而扫描服务、特性、描述以及读取特性值，这些使用者根本不care。
所以这个库的使用也更简单一些，所有的功能可以只看`SEPrinterManager`即可。

如果你有更好的建议或者疑问，欢迎加群：552735579。
