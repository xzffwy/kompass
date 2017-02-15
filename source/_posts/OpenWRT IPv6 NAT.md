---
title: OpenWRT IPv6 NAT
date:  2017.2.10 20:33
description: 虽然IPv6在设计之初，没有考虑NAT，在主流的网络设备上也没有IPv6的NAT配置，但 Linux 内核从 3.7 版本开始实现了 IPv6 的 NAT，OpenWRT接入客户端以NAT的形式访问访问IPv6互联网
categories: 技术
tags: [router,openwrt,network]
---

### 1. IPv6 NAT
虽然IPv6在设计之初，没有考虑NAT，在主流的网络设备上也没有IPv6的NAT配置，但 Linux 内核从 3.7 版本开始实现了 IPv6 的 NAT

----------

### 2. OpenWRT配置

#### 2.1 软件包安装 

<span style="color:red">现在假设OpenWRT为初始化状态</span>，安装相应的软件包

~~~bash
opkg update
opkg install ip6tables kmod-ipv6 kmod-ipt-nat6 kmod-ip6tables kmod-ip6tables-extra luci-proto-ipv6 iputils-traceroute6
~~~
<!-- more -->
- `kmod-ipv6`并非必须
- `kmod-ipt-nat6`提供IPv6的NAT支持
- `ip6tables`,·`kmod-ip6tables`,`kmod-ip6tables-extra`等提供IPv6防火墙
- `luci-proto-ipv6`为LuCI提供IPv6设置选项
- `iputils-traceroute6`为IPv6提供traceroute功能(`mtr`是个不错的支持双栈的`traceroute`替代品，占用的存储空间相对大些)

#### 2.2 IPv6私网地址 

OpenWRT在默认情况下，会分配一个IPv6私网地址段，在**Network->Interfaces**页面底下有**Global network options->IPv6 ULA-Prefix**这里应该有一个随机的`fd`开头的`/64`IPv6地址段，LAN客户端可以从这个地址段自动获取私有的IPv6地址，[DHCPv6](https://zh.wikipedia.org/wiki/DHCPv6)和[无状态地址自动配置（SLAAC）](https://zh.wikipedia.org/wiki/IPv6#.E6.97.A0.E7.8A.B6.E6.80.81.E5.9C.B0.E5.9D.80.E8.87.AA.E5.8A.A8.E9.85.8D.E7.BD.AE.EF.BC.88SLAAC.EF.BC.89)默认已经开启

#### 2.3 IPv6私网地址网关配置 

缺省配置下，LAN客户端获取的私有IPv6地址没有IPv6网关的

在**Network->Interfaces->LAN**下的**DHCP Server**部分的**IPv6 Settings**选项卡部分，勾选**Always announce default router**，否则OpenWRT不会向LAN客户端推送OpenWRT私有的IPv6网关地址

为了确保设置生效，最好重启路由器

#### 2.4 NAT设置 

客户端有了私有的IPv6地址之后，私有地址可以单向路由到互联网中的，但是无法被路由回LAN客户端。因此需要在OpenWRT上开启IPv6 NAT。在默认情况下，OpenWRT防火墙不会配置ip6tables的NAT表，因此在OpenWRT命令下手动添加如下规则

~~~bash
ip6tables -t nat -A POSTROUTING -o eth0.2 -j MASQUERADE
ip6tables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -i br-lan -j ACCEPT
~~~

- `eth0.2`为OpenWRT的获取全球可路由IPv6地址的WAN口名称，这个名字不是防火墙区域名字，也不是LuCI里面`Network->Interfaces`里面看到的名字，而是`ifconfig`看到的网卡名字
- `br-lan`为LAN口对应名称，也是通过`ifconfig`看到的网卡名字

#### 2.5 路由条目添加 

到当前设置，LAN客户端可以访问OpenWRT的IPv6公网所在网段，不能访问该网段以外的IPv6地址，原因不明，查看IPv6路由表，发现存在默认路由，因此需要添加全球可路由IPv6路由到OpenWRT

查询下一条地址

~~~bash
root@OpenWrt:~# route -A inet6
Kernel IPv6 routing table
Destination                                 Next Hop                                Flags Metric Ref    Use Iface
::/0                                        fe80::3a22:d6ff:febf:1b00               UG    512    0        6 eth0.2 
……
~~~

根据默认路由，可知`fe80::3a22:d6ff:febf:1b00`为下一条的本地链路地址，然后添加全球可路由IPv6地址的路由条目

~~~bash
route -A inet6 add 2000::/3 gw fe80::3a22:d6ff:febf:1b00 dev eth0.2
~~~

#### 2.6 LAN客户端测试 

在Windows客户端使用tracert命令，结果如下

~~~power
C:\Users\xxxx>tracert bt.byr.cn

通过最多 30 个跃点跟踪
到 bt.byr.cn [2001:da8:215:4078:250:56ff:fe97:654d] 的路由:

  1     1 ms     3 ms     2 ms  fd42:adf7:c821::1
  2    28 ms   145 ms     3 ms  xxxx:xxxx:xxxx:xxxx:3a22:d6ff:febf:1b00
  3    54 ms     8 ms     3 ms  xxxx:xxxx:xxxx:ffff::1
  4     7 ms    12 ms    34 ms  xxxx:xxxx:1fff::1d
  5     4 ms    10 ms     3 ms  xxxx:xxxx:1fff::fffd
  6   126 ms   155 ms   155 ms  xxxx:xxxx:1fff::1ea
  7   343 ms   141 ms   119 ms  cernet2.net [2001:252:0:1::1]
  8   124 ms   132 ms   149 ms  2001:da8:1:1c::2
  9   110 ms   119 ms   133 ms  2001:da8:1:50e::2
 10   111 ms   142 ms   124 ms  cernet2.net [2001:da8:ad:1000::2]
 11   126 ms   139 ms   124 ms  cernet2.net [2001:da8:ad:3001::2]
 12   122 ms   115 ms   110 ms  2001:da8:215:0:10:0:3:2
 13     *      108 ms   116 ms  2001:da8:215:0:10:0:4:32
 14   112 ms     *      139 ms  2001:da8:215:4078:250:56ff:fe97:654d
~~~

#### 2.7 配置保存

每次重启，添加的ip6tables和路由条目都会消失，因此需要将这些配置添加开机启动

~~~bash
cat <<EOF >>/etc/rc.local
    ip6tables -t nat -A POSTROUTING -o eth0.2 -j MASQUERADE
    ip6tables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    ip6tables -A FORWARD -i br-lan -j ACCEPT
    route -A inet6 add 2000::/3 gw fe80::3a22:d6ff:febf:1b00 dev eth0.2
EOF
~~~

----------

### 3. 参考
https://github.com/tuna/ipv6.tsinghua.edu.cn/blob/master/openwrt.md

https://blog.blahgeek.com/2014/02/22/openwrt-ipv6-nat/