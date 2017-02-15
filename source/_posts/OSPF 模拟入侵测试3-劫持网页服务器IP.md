---
title:  OSPF 模拟入侵测试3-劫持网页服务器IP
date:  2016/7/18 14:33:46 
description: OSPF 模拟入侵测试3-劫持网页服务器IP
categories: 技术
tags: [ospf,network]
---

### 1. 实验环境

####  实验拓扑

使用GNS3搭建实验拓扑，实验拓扑如图1-1所示，其中R1、R2为OSPF网络，Vigilante为入侵主机，模拟路由器，PC3模拟一个服务器，IP地址为210.76.211.7/24，同时Vigilante，也将冒充该服务器，其eth2的IP地址为210.76.211.7/24。Vigilante注入主机路由并重分布进OSPF中，欺骗整个网络中的设备，将属于PC3的流量将被路由到Vigilante的eth2。
<center> ![1-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试3_网站服务器伪装/1-1.jpg)</center><center style="color:purple">**图1-1 实验拓扑**</center>

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
|           | e2   | 210.76.211.7/24      | eui-64                |
| Winxp2    | e2   | 30.30.30.2/24 (DHCP) | eui-64                |
| PC3       | e0   | 210.76.211.7/24      | /                     |

####  路由器配置 

配置不变，与《OSPF 模拟入侵测试2-指定主机欺骗》中配置一样。

----------

### 2. 抓取数据
####  注入路由 

在Vigilante上注入路由如下，将本来到PC3的流量引到Vigilante的eth2上。

```css
ip route 210.76.211.7/32 eth2
```
####  网页下载

- 下载sep.ucas.edu.cn的登录主页，并把其中的名称修改为为index.html，其配置文件夹的名称也改为英文 。
- 修改网页跳转，可以跳转到本机，成功跳转才能抓到post请求，否则不能抓到post，这点很重要。

####  上传伪装服务器

把修改的网站上传到Vigilante，伪装为网页服务器，并将伪装服务器的主页改为index.html，修改步骤如下，在**/etc/httpd/conf/httpd.conf**中添加如下

```
DirectoryIndex index.html
```

####  tcpdump抓取POST请求

tcpdump抓post语句如下所示

```
tcpdump -i eth0 'host 210.76.211.7 and port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354' -w sep+.cap
```

其中0x504f5354意义为，代表POST

```
P=0x50
O=0x4f
S=0x53
T=0x54
```

####  读取结果 

讲读取文件结果使用sftp传输到本机，使用Wireshark打开，记过如图2-1所示。

<center>![1-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试3_网站服务器伪装/2-1.jpg)</center><center style="color:purple">**图2-1 POST请求**</center>

经过验证，该网页登录没用其他加密手段，其验证口令通过POST明文传输，如图2-2所示。其中账户名和密码为在Winxp2上输入的账户名和密码。

<center>![1-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试3_网站服务器伪装/2-2.jpg)</center><center style="color:purple">**图2-2 POST抓取验证口令**</center>

----------

### 3. 拓展

- 引流DNS流量，做中间人攻击。