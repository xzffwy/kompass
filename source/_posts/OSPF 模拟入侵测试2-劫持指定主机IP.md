---
title:  OSPF 模拟入侵测试2-劫持指定主机IP
date:  2016/7/18 14:33:46 
description: OSPF 模拟入侵测试2-劫持指定主机IP
categories: 技术
tags: [ospf,network]
---

### 1. 实验环境
####  实验拓扑  

使用GNS3搭建实验拓扑，实验拓扑如图1-1所示，其中R1、R2为OSPF网络，Vigilante为入侵主机，模拟路由器，PC3模拟一个服务器，IP地址为210.76.211.7/24，Ovzinp将冒充该服务器，Vigilante注入主机路由并重分布进OSPF中，将属于PC3的流量劫持到Vigilante。
<center> ![1-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/1-1.jpg)</center><center style="color:purple">**图1-1 实验拓扑**</center>

####  IP地址表

| 设备        | 端口   | IPv4地址               | IPv6地址                |
| --------- | ---- | -------------------- | --------------------- |
| Gateway   | f0/0 | 10.10.10.253/24      | 2001:10:10:10::253/64 |
|           | lo0  | 1.1.1.1/32           | 2001:1:1:1::1/64      |
| R2        | f1/0 | 10.10.10.254/24      | 2001:10:10:10::254/64 |
|           | f0/0 | 20.20.20.1/24        | 2001:20:20:20::1/64   |
| R1        | f1/0 | 30.30.30.254/24      | 2001:30:30:30::254/64 |
|           | f0/0 | 20.20.20.2/24        | 2001:20:20:20::2/64   |
|           | f1/1 | 210.76.211.254/24    | /                     |
| Vigilante | e0   | 30.30.30.30/24       | eui-64                |
| Winxp2    | e2   | 30.30.30.2/24 (DHCP) | eui-64                |
|           | e2   | 210.76.211.254/24    | /                     |
| PC3       | e0   | 210.76.211.7/24      | /                     |
| Ovzinp    | e2   | 210.76.211.7/24      | /                     |

####  路由器配置 

Gateway和R2配置不变，与《OSPF 模拟入侵测试1-路由表获取&路由注入》中配置一样。

R1配置如下，添加端口f1/1的IP地址，并添加了一个DHCP地址池。

```
ipv6 unicast-routing
ipv6 cef

int f1/0
no sh
ip addr 30.30.30.254 255.255.255.0
ipv6 enable
ipv6 addr 2001:30:30:30::254/64
ipv6 ospf 106 area 0

ip dhcp pool R1
network 30.30.30.0 255.255.255.0
default-router 30.30.30.254

int f0/0
no sh
ip addr 20.20.20.2 255.255.255.0
ipv6 enable
ipv6 addr 2001:20:20:20::2/64
ipv6 ospf 106 area 0

int f1/1
no sh
ip addr 210.77.211.254 255.255.255.0

router ospf 104
router-id 1.1.1.4
network 30.30.30.0 0.0.0.255 a 0
network 20.20.20.0 0.0.0.255 a 0
network 210.76.211.0 0.0.0.255 a 0

ipv6 router ospf 106
router-id 1.1.1.6
```

####  VirtualBox虚拟机接入 

- Vigilante
  - eth0、eth2为UDPtunnel模式，接入到实验拓扑
  - eth1为host-only模式，用于本地宿主机通过xshell登录。
- Ovzinp
  - eth1为host-only模式，用于本地宿主机通过xshell登录。
  - eth2为UDPtunnel模式，接入到实验拓扑

####  前提

- ospf或者ospfv3没有开启链路或者区域验证
- 路由器R1没有在f1/0上开启passive端口，则终端可以抓去到明文的ospf或者ospfv3的hello包。

----------

### 2. 入侵测试 
####  ping PC3 

210.76.211.7为**PC3**的IP地址，在**Winxp2**上ping  210.76.211.7，路由正常，在**PC3~R1**链路上抓包结果如下。

<center> ![2-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/2-1.jpg)</center><center style="color:purple">**图2-1 抓包结果**</center>



<center>![2-2](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/2-2.jpg)</center><center style="color:purple">**图2-2 Winxp2 ping**</center>

说明**PC3**到 210.76.211.7的路由是正常的，**PC3**访问了真正的服务器。

####  入侵设置 

- 修改Vigilante的e2端口IP地址为211.76.211.254
- Ovzinp的e2端口地址为211.76.211.7，Ovzinp用于冒充PC3。
- Vigilante的直连路由表如图2-3所示。

<center> ![2-3](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/2-3.jpg)</center><center style="color:purple">**图2-3 Vigilante路由表**</center>

此时，**Winxp2**到210.76.211.7的ping数据包为什么不到Vigilante？因为**Winxp2**的网关为30.30.30.254，首先会把到210.76.211.7的数据包转发到该地址，该地址在R1，而R1上有到210.76.211.0/24的路由，如图2-4所示，目的地为210.76.211.7的数据包会被直接转发到f1/1端口，而不是转发到Vigilante。

<center> ![2-3](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/2-4.jpg)</center><center style="color:purple">**图2-4 R1正常路由表**</center>

####  注入主机路由条目 

因为会涉及到转发，所以**Vigilante**最好关闭**iptables**和**ip6tables**，这样可以避免一些不必要的麻烦，同时要开启linux内核转发。确定**/etc/sysctl.conf**中**net.ipv4.ip_forward = 1**，然后执行如下命令

```shell
sysctl -p
```

在**Vigilante**上添加如下静态路由，添加一条指向210.76.211.7的主机路由。

```css
ip route 210.76.211.7/32 eth2
```

重分布到OSPF中，必须重分布到OSPF中，这样所有的路由器才能学习到该路由条目。

```css
router ospf
redistribute  static
```

**R1**注入后路由表如下图所示，因为路由表查找最长匹配的原则，所以当接收到目的地为210.77.211.7为目的的数据包时，路由器会将该数据包从30.30.30.1转发出去，即转发到了**Vigilante**。根据图2-3中，**Vigilante**收到该数据包后，会通过eth2转发给**Ovzinp**。

<center> ![2-3](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/2-5.jpg)</center><center style="color:purple">**图2-5 R1注入后路由表**</center>

测试结果如下，注入路由条目之后，**Winxp2** ping 210.76.211.7，在链路**Vigilante~SW2**之间抓到结果如图2-6

<center> ![2-3](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/2-6.jpg)</center><center style="color:purple">**图2-6 Winxp2 ping**</center>

也可以访问**Ovzinp**的http服务器，如图2-7所示

<center> ![2-3](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试2_指定主机欺骗/2-7.jpg)</center><center style="color:purple">**图2-7  http服务访问**</center>



----------

### 3. 总结

- 利用路由转发最长匹配原则
- **Vigilante**开启IPv4转发
- **Vigilante**关闭iptables，这样可以避免麻烦，也可以编辑iptables，允许哪些数据包转发。
- 可以简化实验，让**Vigilante**的eth2的IP地址为210.76.211.7，添加主机路由也可以实现同样的欺骗效果。





