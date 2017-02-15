---
title:  OpenWRT 无线中继
date: 2016/10/29 9:21:25 
description: 主路由器Netgear位置远，影响网络体验；设想过在单独置办一个路由器，但是希望两个路由器的局域网之间可以进行通信；构思通过中继路由器对主路由器的SSID进行中继
categories: 技术
tags: [openwrt,router,network]
---

### 1. 前言
#### 起因 ####
- 主路由器Netgear位置远，影响网络体验
- 设想过在单独置办一个路由器，但是希望两个路由器的局域网之间可以进行通信。
- 构思通过中继路由器对主路由器的SSID进行中继

#### WDS ####
WDS连接，再购买一个Netgear路由器，使得主从路由器通过WDS连接，实现无缝漫游。查阅了NetGear的[官方资料](http://club.netgear.cn/Knowledgebase/Document.aspx?Did=234)之后，再综合其他资料，如下理由放弃该方案：

- WDS是非标准协议，不同厂商很可能不兼容，而且芯片、固件版本最好一致。
- Netgear官方支持的WDS协议，路由器的加密只支持WEP方式，不支持WPA2。

#### OpenWRT ####

- Routed Client Mode， 拓展的路由器网络还有经过一个NAT到上级网络
<center>![](http://i.imgur.com/OA0NKDF.png)</center><center style="color:purple">**图1-2 路由客户端模式**</center>

- Bridged Client Mode (brcm-2.4 only)，拓展的路由器可以和原来的路由器位于同一个网络，后来买路由器网卡不支持，放弃。
<center>![](http://i.imgur.com/IoXvhfk.png)</center><center style="color:purple">**图1-3 桥接客户端模式(仅仅brcm-2.4)**</center>

- Bridged Client Mode (with relayd)，使用relayed软件进行中继，伪桥接方式，[介绍资料](https://wiki.openwrt.org/doc/recipes/relayclient)。
<center>![](http://i.imgur.com/uKnMcxw.png)</center><center style="color:purple">**图1-4 使用relayed桥接客户端模式**</center>

----------

### 2.  路由客户端模式
#### 连接无线网络
- 配置位置：Network → WiFi → 选择5G/2.4G网卡 → Scan
- 出现无线网络列表之后，选择要中继的SSID，本文要中继的SSID是Onion-5G，然后输入无线网路密码
- Network选择创建一个新的虚拟适配器WWAN
- 保存之后，过一会在Network → Interface 会看到一个WWAN的虚拟适配器，并从Onion-5G获取到了IP地址，假设这里是192.168.1.7/24

#### 防火墙设置 ####
- 配置位置：Network → Interface
- 选择刚才生成的wwan虚拟适配器，然后转到Firewall Settings，确认分配到防火墙区域为wan
- 保存生效

#### IPv6中继设置
与之前设置OpenWRT IPv6中继的方法相同

#### LAN配置
修改LAN接口IP地址段，因为使用的NAT模式，所以LAN接口的IP地址段不能与主路由器的IP段（192.168.1.0/24）重复，主假设修改的IP地址段为10.10.10.0/24

#### 无线配置
创建一个新的SSID，并桥接到LAN接口

- 配置位置：Network → WiFi → 选择5G/2.4G网卡 → Add
- ESSID：Onion-5G+
	- 疑问：此处可以设置为Onion-5G吗？SSID相同会有什么干扰吗？
- Mode：Access Point
- Network： LAN

#### 终端连接测试
此时连接到Onion-5G+的终端设备，可以从主路由器获取192.168.1.0/24地址段的IP地址了

#### 失败总结 ####
无法将wifi虚拟适配器直接桥接到WWAN接口，如果这样设置，会导致导致WWAN虚拟适配器变为Bridge interface类型，这样WWAN接口无法从主路由器获取IP地址，因此整个路由器也不能连接到网络了。

----------

### 3. 使用relayd桥接客户端模式
#### 软件安装 ####
- relayd
- luci-proto-relay
#### 注意事项 ####
- 创建一个新的网络192.168.2.0/24, 用来正常访问路由器，<span style="color:red">否则在完成relay桥接模式后无法访问从路由器</span>，所以创建一个LAN2用来保证可以正常访问路由器
- ssh管理切换到LAN2
- 无法通过WAN，WWAN接口的IP地址段访问luci网页管理端，只能通过LAN地址段访问luci网页管理端。

#### 连接无线网络
- 配置位置：Network → WiFi → 选择5G/2.4G网卡 → Scan
- 出现无线网络列表之后，选择要中继的SSID，本文要中继的SSID是Onion-5G，然后输入无线网路密码
- Network选择创建一个新的虚拟适配器WWAN
- 保存之后，过一会在Network → Interface 会看到一个WWAN的虚拟适配器，并从Onion-5G获取到了IP地址，假设这里是192.168.1.7/24

#### 防火墙设置 ####
- 配置位置：Network → Interface
- 选择刚才生成的wwan虚拟适配器，然后转到Firewall Settings，<span style="color:red">确认分配到防火墙区域为lan，不是wan</span>
- 保存生效

#### 关闭LAN接口 DHCP功能 ####
关闭lLAN接口的DHCP功能，保证客户端可以从主路由器获取IP地址

#### 桥接适配器创建
- 配置位置：Network → Interface → Add new interface
- Protocol：Relay Bridge
- Relay between Network：lan wwan
- 保存设置

#### 无线配置
- 配置位置：Network → WiFi → 选择5G/2.4G网卡 → Add
- ESSID：Onion-5G
	- 疑问：此处可以设置为Onion-5G吗？SSID相同会有什么干扰吗？
- Mode：Access Point
- Network： LAN

#### 终端连接测试
此时连接到Onion-5G的终端设备，可以从主路由器获取192.168.1.0/24地址段的IP地址了，可以实现设备无缝漫游了

#### 配置文件示例
使用luci网页配置可能有问题，可以直接修改配置文件并重启网络

- /etc/config/network
	~~~
	config interface 'lan'
		option ifname 'eth0'
		option type 'bridge'
		option proto 'static'
		option netmask '255.255.255.0'
		option ipaddr '192.168.2.1' 
	
	config interface 'stabridge' 
		option proto 'relay'
		option network 'lan wwan'
	
	config interface 'wwan'
		option proto 'dhcp'	
	~~~
- /etc/config/dhcp
	~~~
	option interface        lan
		option start         100
		option limit        150
		option leasetime        12h
		option ignore 1          #这一行添加，关掉lan的dhcp功能
	~~~
- /etc/config/firewall
	~~~
	config zone
		option name 'lan'
		option input 'ACCEPT'
		option output 'ACCEPT'
		option forward 'ACCEPT'       #修改前为REJECT
		option network 'lan wwan'     #添加了wwan
	~~~

#### 测试后记
试用了一天之后，发现通过relayd方式分别连接到主从路由器的设备之间ping延时很高，因此不得不放弃这种方式。

----------

### 4. 局域网之间路由模式
#### 思路 ####
OpenWRT固件和Netgear官方固件都拥有自定义路由表的接口，两个路由器之间通过无线进行连接，分别在两个路由器上配置相互局域网转发的路由表。

#### 防火墙设置 ####
- 创建wlan区域，为Netgear固件路由器所在区域
- 允许wlan转到lan，同时lan也可以转发到wlan，其中lan为OpenWRT固件所在区域。
- 只允许IPv4转发，禁止IPv6转发

#### 路由表 ####
##### OpenWRT静态路由设置
- 配置位置：Network → WiFi → 选择5G/2.4G网卡 → Scan
- 出现无线网络列表之后，选择要中继的SSID，本文要中继的SSID是Onion-2.4G，然后输入无线网路密码
- Network选择创建一个新的虚拟适配器WLAN，防火墙区域为wlan
- 保存之后，过一会在Network → Interface 会看到一个WLAN的虚拟适配器，并从Onion-2.4G获取到了IP地址，假设这里是192.168.1.2/24


SSH连接到路由器后查看路由表，如下。
~~~
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         192.168.1.1     0.0.0.0         UG    0      0        0 eth1
10.30.0.0       *               255.255.224.0   U     0      0        0 eth1
10.30.0.254     *               255.255.255.255 UH    0      0        0 eth1
192.168.1.0     *               255.255.255.0   U     0      0        0 wlan0
192.168.1.1     *               255.255.255.255 UH    0      0        0 wlan0
192.168.2.0     *               255.255.255.0   U     0      0        0 br-lan
~~~

从上述路由表可以看出，这时候所有本地的流量也被转发到192.168.1.1，不需要转发所有的流量，因为需要避免wlan0成为默认路由的出口，修改虚拟适配器WLAN的选项，修改文件/etc/conf/network
~~~
config interface 'wlan'       
        option proto 'dhcp'  
        option defaultroute '0'    
~~~
手动修改回正确的默认路由，这样路由器每次重启之后，或者连接到Onion-2.4G后，不会把Onion-2.4G的网络当作默认路由了。

##### Netgear静态路由设置#####
添加到192.168.2.0/24的路由表条目，网关地址为192.168.2.1，即为OpenWRT的IP的地址。

#### 问题总结 ####
- 速度不稳定，ping延时有时候会很高


