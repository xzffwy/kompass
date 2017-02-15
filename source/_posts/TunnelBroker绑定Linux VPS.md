---
title:  TunnelBroker绑定Linux VPS 
date: 2016/5/28 9:21:25 
description: TunnelBroker绑定Linux VPS 
categories: 技术
tags: [vps,linux]
---

### 1.申请Tunnel Broke账号 ###
#### 账号注册 ####
账号注册如下图所示，具体流程略过。

***图1-1***
![](http://i.imgur.com/TT2bWgW.png)

----------

### 2.创建IPv6隧道 ###
创建常规隧道,如图2-1所示

***图2-1***
![](http://i.imgur.com/HkC2gLf.png)

填写VPS的IP地址，注意，需要在系统防火墙将icmp协议打开，然后会检测是否已经绑定IPv6隧道，检测通过后可以选择Tunnel服务器。

***图2-2***
![](http://i.imgur.com/SihlUvg.png)


阿里云VPS禁用了IPv6模块，以CentOS为例，开启IPv6模块，注释禁用IPv6的配置，在/etc/sysconfig/network中，以及/etc/modprobe.d/disable_ipv6.conf 中所有的配置，然后重启服务器。

    NETWORKING=yes
    HOSTNAME=XXXXXX
    NETWORKING_IPV6=no
    PEERNTP=no
    GATEWAY=115.28.XX.XXX

亚马逊VPS则修改/etc/sysctl.conf，将其中的0改为1然后重启服务器。

	net.ipv6.conf.all.disable_ipv6 = 0
	net.ipv6.conf.default.disable_ipv6 = 0 

选择操作系统类型，如图2-3所示，然后执行对应的命令，以linux为例子，ssh登陆阿里云服务器，以root用户执行网站给出的example configuration配置。

    modprobe ipv6
    ip tunnel add he-ipv6 mode sit remote 74.82.46.6 local 121.42.33.4 ttl 255
    ip link set he-ipv6 up
    ip addr add 2001:470:23:ed::2/64 dev he-ipv6
    ip route add ::/0 dev he-ipv6
    ip -f inet6 addr

***图2-3***
![](http://i.imgur.com/yNaoP6O.png)


防火墙配置，在iptables上放行协议41，命令如下，这时候可以使用带有IPv6地址的主机ping一下该VPS。

	iptables -A INPUT -p 41 -j ACCEPT

----------

### 3.删除隧道 ###
首先在VPS命令上上删除隧道适配器，命令为

	ip tunnel del he-ipv6

删除隧道之后，在tunnelbroker上删除对应隧道，然后可以绑定新的隧道。



