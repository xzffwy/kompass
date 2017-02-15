---
title: CentOS 7 ocserv IPv6 支持实验分析
date: 2016/9/29 9:07:14 
description: CentOS 7 ocserv IPv6 支持实验分析
categories: 技术
tags: [ocserv,vpn,linux]
---

### 1.实验环境搭建 ###
#### 所需软件 ####

- VirtualBox
- Wireshark
- GNS3

#### 实验拓扑 ####
实验拓扑如图1-1所示。其中Centos7为ocserv服务器，其网卡e0连接到R1，另一张网卡通过host-only模式连接到我的宿主机。Centos_1_vigilante为一个台CentOS 6.6主机。

<span style="color:purple">图1-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/1-1.PNG)

#### IP地址分配 ####

Centos7 

| 端口\IP地址 | IPv4 | IPv6 | 备注  
| :---: | :---: | :---: | :---:     
|  e0	|  172.16.1.2/24 | 2001:2001::a00:27ff:fe0c:a199/64| 自动获取
|  e1	|  192.168.86.107/24  |   \  	| \

Centos_1_vigilante

| 端口\IP地址 | IPv4 | IPv6 | 备注  
| :---: | :---: | :---: | :---:     
|  e2	|  172.16.2.2/24 | 2001:2002::a00:27ff:fe92:7d69/64 |自动获取
|  e1	|  192.168.86.101/24  |   \  	|\

R1 

| 端口\IP地址 | IPv4 | IPv6 | 备注  
| :---: | :---: | :---: | :---:     
|  f0/0	|  172.16.1.1/24 | 2001:2001::1/64| \|
|  f1/0	|  172.16.2.1/24  |   2001:2002::1/64 | \|



#### 路由器配置 ####

    conf t
    ipv6 unicast-routing
    
    int fa0/0
    ip address 172.16.1.1 255.255.255.0
    no sh
    
    ipv6 enable
    ipv6 address 2001:2001::1/64
    
    int fa1/0
    ip address 172.16.2.1 255.255.255.0
    no sh
    
    ipv6 enable
    ipv6 address 2001:2002::1/64
    
    ip dhcp pool F00
    network 172.16.1.0 255.255.255.0
    default-router 172.16.1.1
    
    ip dhcp pool F10
    network 172.16.2.0 255.255.255.0
    default-router 172.16.2.1

#### Centos7配置 ####
开启IPv6转发，添加如下到/etc/sysctl.conf并刷新配置。
	
	net.ipv6.conf.all.forwarding = 1

刷新配置
	
	sysctl  -p

关闭ip6tables转发中禁止的条目，ip6tables缺省有禁止所有转发的条目，如果不删除，客户端无法获取IPv6地址，也无法连接成功。删除其执行如下命令
	
	ip6tables -D

已经配置好ocserv服务，Centos7在epel仓库中提供了ocserv安装，可以直接通过yum命令安装。

    yum install epel-release
    yum install ocserv

鉴于是模拟器测试网段，所以使用了2001:cc0:2020:4008:2333::/80网段为Anyconnect客户端使用的ipv6地址。在/etc/ocserv.conf中添加如下字段。并启动ocserv服务

    ipv6-network = 2001:cc0:2020:4008:2333::
    ipv6-prefix = 80
    ipv6-dns = 2001:4860:4860::8888
    ipv6-dns = 2001:4860:4860::8844

启动ocserv服务
	
	service ocserv start

Centos7 e0获取的IP地址如图1-2所示。

<span style="color:purple">图1-2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/1-2.PNG)

#### Centos_1_vigilante配置 ####
安装httpd服务，并在iptables和ip6tables对80端口进行放行。Centos_1_vigilante e2获取的IP地址如图1-3所示。

<span style="color:purple">图1-3</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/1-3.PNG)

----------

### 2.客户端测试 ###
#### PC连接Centos7服务器 ####
宿主机通过Anyconnect客户端连接Centos7服务器，通过192.168.86.107这个IP地址连接Centos7，该地址为Centos与宿主机之间的host-only网卡IP地址。连接成功后，宿主机获取的IP地址如图2-1所示。

<span style="color:purple">图2-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/2-1.PNG)

#### 访问Centos_1_vigilante HTTP服务（IPv4） ####
在宿主机上通过IPv4访问Centos_1_vigilante的http服务，可以访问成功，结果如图2-2所示。


<span style="color:purple">图2-2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/2-3.PNG)

但是访问IPv6失败，如图2-3所示。

<span style="color:purple">图2-3</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/2-2.PNG)

#### 抓包分析 ####
抓取路由器R1的f0/0接口数据包，从图2-4可以发现，tcp连接没有建立成功。

<span style="color:purple">图2-4</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/2-4.png)

#### 路由器添加IPv6路由条目 ####
可以断定，因为Anyconnect客户端的IPv6全局地址的数据包被Centos7转发，也被转发到访问Centos_1_vigilante，但是由于R1不知道到2001:cc0:2020:4008:2333::/80的路由，因为需要在R1上添加静态路由条目。添加规则如下。

	//ipv6 route [destination network] [out port] [destination link_local address] 
	ipv6 route [destination network] [out port] [destination gloab address] 

本次实验中添加的条目如下。

	ipv6 route 2001:cc0:2020:4008:2333::/80 f0/0 fe80::a00:27ff:fe0c:a199

修正：填写目标全局地址也可以

#### 访问Centos_1_vigilante HTTP服务（IPv6） ####
在宿主机上通过IPv6访问Centos_1_vigilante的http服务，可以访问成功，结果如图2-5所示。

<span style="color:purple">图2-5</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_centos7/2-5.PNG)


----------

### 3.结论 ###

如果需要配置ocserv客户端支持IPv6，则需要vps供应商提供可以路由的IPv6地址池。

