---
title: CentOS 6.x ocserv IPv6 实验
date: 2016/9/29 9:07:14 
description: CentOS 6.x ocserv IPv6 实验
categories: 技术
tags: [ocserv,vpn,linux]
---

### 1.ocserv安装 ###
需要提前安装好ocserv，运行ocserv服务后，Anyconnect客户端可以成功登录服务器。

----------

### 2.配置 ###
#### 修改ocserv.conf ####
<strike style="color:red">添加如下字段，其中ipv6-network字段从vps供应商处获取，或者通过查看自己网卡获取的ipv6地址来找出ipv6的网络地址，记住一定要在网络地址后加::，例如x:x:x:x::，否者无法连接服务。prefix也是从供应商处获知，dns自己可以填写谷歌的公共ipv6 DNS服务器或者其他。</strike>

    ipv6-network = 2607:f358:1a:1::
    ipv6-prefix = 64
    ipv6-dns = 2001:4860:4860::8888
    ipv6-dns = 2001:4860:4860::8844

><span style="color:red">**修订：**</span>填写vps供应商提供的可以路由的IPv6地址池，如果vps供应商没提供可以全局路由的IPv6地址池，则无法配置支持IPv6的ocserv。距离例子如下所示，DNS服务器可以填写谷歌的公共IPv6 DNS。

    ipv6-network = 2607:f358:1a:1::
    ipv6-prefix = 124
    ipv6-dns = 2001:4860:4860::8888
    ipv6-dns = 2001:4860:4860::8844


#### 开启ipv6转发 ####
root用户下执行如下命令，开启ipv6转发功能

sysctl net.ipv6.conf.all.forwarding

#### ip6tables修改 ####
ip6tables中不存在nat表，所以只删除filter表FORWARD链中可能阻碍的条目即可，在我的vps中缺省有拒绝转发所有请求的条目，删除之。


><span style="color:red">**提示：**</span>ocserv.conf的修改一定要严格遵守格式，否则Anyconnect客户端无法连接服务器，之前在最后少写个冒号，导致了这个问题。DNS服务器推荐填写google的公共DNS。

----------

### 3.连接测试 ###
#### iPhone连接 ####
iPhone连接成功，成功地获取了IPv4地址和IPv6地址，如图3-1所示。可以进行IPv4访问，但是仍然无法访问IPv6网站。。

<span style="color:purple">图3-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/3-1.jpg)

#### PC测试 ####
PC连接成功，成功地获取IPv4和IPv6地址，如图3-2所示，但是IPv6却无网络连接，如图3-3所示。

<span style="color:purple">图3-2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/3-2.jpg)

<span style="color:purple">图3-3</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/3-3.jpg)

----------

### 4.排错流程 ###
#### 网关地址寻找 ####
<strike style="color:red">在vps上通过traceroute6命令来找到vps所在局域网的网关地址，如图4-1所示，第一跳为网关地址。</strike>
><span style="color:red">**修订：**</span>vps的网关确实为图4-1所圈出的，但是在Anyconnect客户端连接时vps服务器会生成vpns0的网卡，该网卡的地址如下所示。对于接入到vps服务器的Anyconnect客户端而言，其获取的网关地址是vps服务器的虚拟网卡，而不是vps服务器局域网的网关，之前理解为填写vps服务器所在局域网的IPv6地址段，客户端获取的IPv6地址是接入的到vps所在的局域网，其实则不然，因为填写了vps所在局域网的地址池前缀，所以接入到vps服务器的客户端其发送的数据包，都被发送到vpns0这块虚拟网卡之上，但是该网卡IPv6地址与vps的IPv6网关地址冲突，因为数据包无法被转发，所以无法接入vps的Anyconnect的IPv6网络无法连接到因特网。

    vpns0 Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  
	      inet addr:192.168.30.1  P-t-P:192.168.30.172  Mask:255.255.255.255
	      inet6 addr: 2607:f358:1a:1::1/128 Scope:Global
	      UP POINTOPOINT RUNNING  MTU:1341  Metric:1
	      RX packets:0 errors:0 dropped:0 overruns:0 frame:0
	      TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
	      collisions:0 txqueuelen:500 
	      RX bytes:0 (0.0 b)  TX bytes:76 (76.0 b)
    
<span style="color:purple">图4-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/4-1.png)

<strike style="color:red">在PC端ping网关和手机的IPv6地址，ping成功，如图4-2，图4-3所示。</strike>
><span style="color:red">**修订：**</span>虽然Anyconnect客户端无法通过IPv6接入网络，但是局域网还是可以进行通信。

<span style="color:purple">图4-2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/4-2.png)

<span style="color:purple">图4-3</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/4-3.png)

说明局域网之间是可以通信的。

#### tcpdump抓包 ####
使用tcpdump进行抓包，抓包的过程中，手机向一个IPv6站点发送http请求。抓包命令如下。

    tcpdump ip6 -w ipv6.cap

<strike style="color:red">抓包结果如图4-4所示，http请求发出去若干个但是，但是没有收到回应。</strike>
><span style="color:red">**修订：**</span>数据包都发送到了vpns0网卡，可以被tcpdump抓到。

<span style="color:purple">图4-4</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/4-4.png)

<strike style="color:red">由此暂时可以认为http请求数据包已经发出，但是却没有收到任何回应，ocserv的配置没有问题。</strike>

><span style="color:red">**修订：**</span>http请求没有发出去，因为vpns0和vps的IPv6默认网关冲突，此时vps都

#### tracert排错 ####
<strike style="color:red">在PC使用Anyconnect连接到服务器之后，命令行下使用tracert，查看结果，如图4-5所示，tracert只能到网关无法到下一跳，由此可以认为在网关路由器处http请求没有被转发。</strike>

><span style="color:red">**修订：**</span>tracert只能到vpns0，无法tracert到下一跳。

<span style="color:purple">图4-5</span>   
![](http://qingdao.icean.cc:11234/Imgbed/openconnect_IPv6/4-5.png)


----------

### 5.结论与猜想 ###
#### 结论 ####

- <strike style="color:red">vps服务商可能禁用了非注册IPv6地址的转发。</strike>
- <strike style="color:red">ocserv配置可能还存在问题，具体问题不得而知。</strike>
- <strike style="color:red">设备获取的IPv6地址不是eui-64地址，配置方式不得而知。</strike>

如果在ocserv.conf中填写的ipv6地址池范围，不被上游路由器转发，则vpn方式接入的设备仍无法上网，如果填写和vps所在的网段相同，也无法上网，因为vps会在有设备接入的时候，虚拟化出一张网卡，该网卡的IPv6地址和局域网网关的IP地址一样，所以其数据包也不会被转发。


#### 猜想 ####

- 换一家vps供应商试试，例如linode或者搬瓦工。
- 在自己局域网的双栈linux主机上尝试配置ocserv服务，并进行验证。



