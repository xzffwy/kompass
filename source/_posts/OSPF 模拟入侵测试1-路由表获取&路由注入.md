---
title:  OSPF 模拟入侵测试1-路由表获取&路由注入
date:  2016/7/18 14:33:46 
description:  OSPF 模拟入侵测试1-路由表获取&路由注入
categories: 技术
tags: [ospf,network]
---

### 1. 实验环境
####  实验拓扑  

使用GNS3搭建实验拓扑，实验拓扑如图1-1所示，其中R1、R2为OSPF网络，Vigilante为入侵主机，模拟路由器，PC1和PC2辅助测试入侵效果，Gateway模拟外网。

<center> ![1-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_hacking/1-1.jpg)</center><center style="color:purple">**图1-1 实验拓扑**</center>

####  IP地址表

| 设备        | 端口   | IPv4地址          | IPv6地址                |
| --------- | ---- | --------------- | --------------------- |
| Gateway   | f0/0 | 10.10.10.253/24 | 2001:10:10:10::253/64 |
|           | lo0  | 1.1.1.1/32      | 2001:1:1:1::1/64      |
| R2        | f1/0 | 10.10.10.254/24 | 2001:10:10:10::254/64 |
|           | f0/0 | 20.20.20.1/24   | 2001:20:20:20::1/64   |
| R1        | f1/0 | 30.30.30.254/24 | 2001:30:30:30::254/64 |
|           | f0/0 | 20.20.20.2/24   | 2001:20:20:20::2/64   |
| Vigilante | e2   | 30.30.30.30/24  | eui-64                |
| PC1       | e0   | 30.30.30.100/24 | eui-64                |
| PC2       | e0   | 30.30.30.200/24 | eui-64                |


####  路由器配置 

Gateway配置如下

```markdown
ipv6 unicast-routing
ipv6 cef

int f0/0
ipv6 enable
ip address 10.10.10.253 255.255.255.0
ipv6 address 2001:10:10:10::253/64
no sh

int lo 0
ipv6 enable
ip address 1.1.1.1 255.255.255.0
ipv6 address 2001:1:1:1::1/64

ip route 0.0.0.0 0.0.0.0 10.10.10.254
ipv6 route ::/0 fastEthernet0/0 2001:10:10:10::254
```

R1配置如下

````markdown
ipv6 unicast-routing
ipv6 cef

int f1/0
no sh
ip addr 30.30.30.254 255.255.255.0
ipv6 enable
ipv6 addr 2001:30:30:30::254/64
ipv6 ospf 106 area 0

int f0/0
no sh
ip addr 20.20.20.2 255.255.255.0
ipv6 enable
ipv6 addr 2001:20:20:20::2/64
ipv6 ospf 106 area 0

router ospf 104
router-id 1.1.1.4
network 30.30.30.0 0.0.0.255 a 0
network 20.20.20.0 0.0.0.255 a 0

ipv6 router ospf 106
router-id 1.1.1.6
````

R2配置如下

```markdown
ipv6 unicast-routing
ipv6 cef

int f1/0
no sh
ip addr 10.10.10.254 255.255.255.0
ipv6 enable
ipv6 addr 2001:10:10:10::254/64
ipv6 ospf 106 area 0

int f0/0
no sh
ip addr 20.20.20.1 255.255.255.0
ipv6 enable
ipv6 addr 2001:20:20:20::1/64
ipv6 ospf 106 area 0

ip route 0.0.0.0 0.0.0.0 10.10.10.254
ipv6 route ::/0 fastEthernet1/0 2001:10:10:10::253

router ospf 104
router-id 2.2.2.4
network 10.10.10.0 0.0.0.255 a 0
network 20.20.20.0 0.0.0.255 a 0
default-information originate

ipv6 router ospf 106
router-id 2.2.2.6
default-information originate
```

####  VirtualBox虚拟机接入  

一台VirtualBox虚拟机需要接入到拓扑，虚拟机系统为CentOS6，有三块网卡，

- eth0为用于连接Internet，模式为桥接模式或者NAT网络。
- eth1为host-only模式，用于本地宿主机通过xshell登录。
- eth2为UDPtunnel，连接到GNS3拓扑中。

####   前提

- ospf或者ospfv3没有开启链路或者区域验证
- 路由器R1没有在f1/0上开启passive端口，则终端可以抓去到明文的ospf或者ospfv3的hello包。

----------

### 2. CentOS安装quagga
####  quagga安装 

xshell登录CentOS7虚拟机，yum安装quagga

```shell
yum install quagga -y
```

在CentOS7，SELinux默认会阻止quagga将配置文件写到/usr/sbin/zebra。这个SELinux策略会干扰我们接下来要介绍的安装过程，所以我们要禁用此策略。对于这一点，无论是[关闭SELinux](http://xmodulo.com/how-to-disable-selinux.html)（这里不推荐），还是如下启用“zebra*write*config”都可以。如果你使用的是CentOS6的请跳过此步骤。

````shell
setsebool -P zebra_write_config 1 
````

如果没有做这个修改，在我们尝试在Quagga命令行中保存配置的时候看到如下错误。

```
Can't open configuration file /etc/quagga/zebra.conf.OS1Uu5.
```

安装完Quagga后，需要配置必要的对等IP地址，并更新OSPF设置。Quagga自带了一个命令行称为vtysh。vtysh里面用到的Quagga命令与主要的路由器厂商如思科和Juniper是相似的。

####   配置zebra 

我们首先创建Zebra配置文件，并启用Zebra守护进程。

```shell
cp /usr/share/doc/quagga-XXXXX/zebra.conf.sample /etc/quagga/zebra.conf
service zebra start
chkconfig zebra on 
```

启动vtysh命令行：

```shell
vtysh
```
为Zebra配置日志文件。输入下面的命令进入vtysh的全局配置模式
```markdown
hostname# configure terminal
```

指定日志文件位置，接着退出模式

```markdown
hostname(config)# log file /var/log/quagga/quagga.log
```

永久保存配置

```markdown
hostname(config)#do write
```

接下来，确定可用的接口并按需配置它们的IP地址。

```markdown
hostname(config)# do show interface 
hostname(config)#interface eth2
hostname(config)#ip address 30.30.30.252/24
hostname(config)#no shutdown 
```

####  配置OSPF 

首先创建OSPF配置文件，并启动OSPF守护进

```shell
cp /usr/share/doc/quagga-XXXXX/ospfd.conf.sample /etc/quagga/ospfd.conf
service ospfd start
chkconfig ospfd on 
```

iptables允许OSPF协议通过，否则无法交换OSPF数据包，邻居关系无法建立！OSPF协议号是89

```shell
iptables -A INPUT -p 89 -j ACCEPT
```

输入路由配置模式

```markdown
vtysh
hostname# configure terminal
hostname(config)# router ospf
```

可选配置路由id

```markdown
hostname(config-router)# router-id 3.3.3.4
```

添加在OSPF中的网络

```markdown
hostname(config-router)# network  30.30.30.0/24 area 0
```

永久保存配置

```markdown
hostname(config-router)# do write
```

查看邻居关系，若结果有邻居关系且为full，说明建立了邻居关系

```markdown
Vigilante# show ip ospf  neighbor  
 Neighbor ID Pri State           Dead Time Address         Interface            RXmtL RqstL DBsmL
1.1.1.4           1 Full/DR           36.907s 30.30.30.254    eth2:30.30.30.1          0     0     0
```

查看路由表信息，这时候可以查看整个网络中完整路由表

```css
Vigilante# sh ip route  
Codes: K - kernel route, C - connected, S - static, R - RIP, O - OSPF,
       I - ISIS, B - BGP, > - selected route, * - FIB route

K>* 0.0.0.0/0 via 30.30.30.254, eth2
C>* 10.0.2.0/24 is directly connected, eth0
O>* 10.10.10.0/24 [110/12] via 30.30.30.254, eth2, 00:10:25
O>* 20.20.20.0/24 [110/11] via 30.30.30.254, eth2, 00:10:25
O   30.30.30.0/24 [110/10] is directly connected, eth2, 00:11:11
C>* 30.30.30.0/24 is directly connected, eth2
C>* 127.0.0.0/8 is directly connected, lo
K>* 169.254.0.0/16 is directly connected, eth2
C>* 192.168.86.0/24 is directly connected, eth1
```

####   配置OSPFv3

首先创建OSPF配置文件，并启动OSPF守护进

```shell
cp /usr/share/doc/quagga-XXXXX/ospf6d.conf.sample /etc/quagga/ospf6d.conf
service ospf6d start
chkconfig ospf6d on 
```

ip6tables允许OSPF协议通过，否则无法交换OSPFv3数据包，邻居关系无法建立！OSPFv3协议号是89

```shell
ip6tables -A INPUT -p 89 -j ACCEPT
```

输入路由配置模式

```markdown
vtysh
hostname# configure terminal
hostname(config)# router ospf6
```

可选配置路由id

```markdown
hostname(config-router)# router-id 3.3.3.6
```

添加在OSPFv3中的网络，area必须为x.x.x.x这种格式，否则会报错。

```markdown
hostname(config-router)# interface eth2 area 0.0.0.0
```

永久保存配置

```markdown
hostname(config-router)# do write
```

查看邻居关系，若结果有邻居关系且为full，说明建立了邻居关系

```markdown
Vigilante# show ipv6  ospf6  neighbor  
Neighbor ID     Pri    DeadTime  State/IfState         Duration I/F[State]
1.1.1.6                1    00:00:37   Full/DR              00:09:23 eth2[DROther]
```

查看路由表

```css
Vigilante# show ipv6  route  
Codes: K - kernel route, C - connected, S - static, R - RIPng, O - OSPFv3,
       I - ISIS, B - BGP, * - FIB route.

C>* ::1/128 is directly connected, lo
O>* 2001:10:10:10::/64 [110/3] via fe80::c801:1fff:fea4:1c, eth2, 00:11:53
O>* 2001:20:20:20::/64 [110/2] via fe80::c801:1fff:fea4:1c, eth2, 00:11:53
O   2001:30:30:30::/64 [110/1] is directly connected, eth2, 00:11:53
C>* 2001:30:30:30::/64 is directly connected, eth2
C * fe80::/64 is directly connected, eth2
C * fe80::/64 is directly connected, eth1
C>* fe80::/64 is directly connected, eth0
C>* fec0::/64 is directly connected, eth1
```

----------

### 3. 入侵测试

####   IPv4注入默认路由

在Vigilante上，添加错误默认路由，并同时注入到ospf中，则所有的ospf路由器都会学习到该错误默认路由。则终端无法转发数据到默认网关。

```markdown
ip route 0.0.0.0 0.0.0.0 eth1
router ospf
default-information originate always
```

中间路由器的OSPF默认路由变化如下图所示

<center> ![3-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_hacking/3-2.jpg)</center><center style="color:purple">**图3-2 正确默认路由**</center>

<center> ![3-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_hacking/3-3.jpg)</center><center style="color:purple">**图3-2 被注入错误默认路由**</center>

####   IPv4注入主机路由

添加错误主机路由器，例如屏蔽某些主机的流量，若屏蔽PC1（30.30.30.100），加入如下路由条目，然后重分布，由于最长匹配原则，所以会转发入侵路由器，如下图3-3路由表所示，30.30.30.100路由条目。根据最长匹配原则，数据包会转发到Vigilante上，然后Vigilante将该数据包转发到null0.

```markdown
ip route 30.30.30.100 255.255.255.255 null0
router ospf
redistribute  static 
```

<center> ![3-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_hacking/3-4.jpg)</center><center style="color:purple">**图3-4 R1注入后路由表**</center>


####   IPv6注入路由

类似IPv4，也是添加静态路由，然后重分布到OSPFv3中。

------

### 4. 其他 

####  排错 

- 注意iptables，ip6tables开启相应的协议，例如ospf为89.
- 若网卡有IPv4或者IPv6地址，则可以不用在路由器模式再配置IP地址。
- 可以修改/etc/quagga中的配置文件，修改ospf或者ospf6等的配置，然后重启服务。
- ospf6每次都需要重新执行router-id x.x.x.x以及 interface port area x.x.x.x，才能建立邻居关系







