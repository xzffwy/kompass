---
title:  NetGear刷回固件
date: 2016/1/19 9:21:25 
description: NetGear刷回固件
categories: 教程
tags: [router,network]
---

### 1.进入路由器恢复模式 ###
#### 恢复模式 ####
路由器断电，使用针状工具按住如图1-1所示的reset按钮，然后路由器通电，路由器电源指示灯开始闪烁，首先黄色闪烁几次，等到指示灯变为绿色时，放开reset按钮。

<span style="color:purple">图1-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/netgear_recovery/1-1.jpg)


#### IP配置 ####
使用网线，讲路由器其中的一个lan接口连接到PC，并把PC网卡地址改为192.168.1.2/24，并ping 192.168.1.1（路由器reset缺省IP地址），ping同路由器缺省地址后，进行下一步。

----------

### 2.上传原生固件 ###
#### 打开tftp ####
打开tftp软件，如图2-1所示。

<span style="color:purple">图2-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/netgear_recovery/2-1.PNG)

#### 上传固件 ####
选择服务器为192.168.1.1，并选择固件路径，如图2-2所示，然后点击Upgrade

<span style="color:purple">图2-2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/netgear_recovery/2-2.PNG)

#### 刷入成功 ####
如图2-3，图2-4所示，之后等待一段时间后，固件刷入成功。若电源指示灯一直闪烁黄灯，路由器进行断电重启。

<span style="color:purple">图2-3</span>   
![](http://qingdao.icean.cc:11234/Imgbed/netgear_recovery/2-3.PNG)

<span style="color:purple">图2-4</span>   
![](http://qingdao.icean.cc:11234/Imgbed/netgear_recovery/2-4.PNG)
----------

### 3.登陆原声固件系统 ###
#### 网页登陆 ####
默认登陆地址为192.168.1.1 账户:admin 密码: password。

----------

### 4.路由器设置 ###
根据路由器提供的网页UI自行设置。



