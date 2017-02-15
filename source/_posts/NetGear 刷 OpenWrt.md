---
title:  NetGear 刷OpenWRT
date: 2016/11/14 14:33:46 
description: NetGear 刷OpenWRT
categories: 技术
tags: [openwrt,router,network]
---

### 1. 准备工作 ###
正式开始刷机之前，需要准备一些软件和工具。

- Xshell
- WinSCP
- TFTP客户端
- 网线

----------

### 2. OpenWRT###
#### NetGear路由器固件初始化 ####
根据NetGear路由器说明书，将路由器的WAN接口（黄色）连接到上级ISP提供的网络接口，再将任意LAN接口（蓝色）连接到PC，确认PC正常连接到路由器之后，则可以对路由器进行初始化了，初始化步骤请参考说明书，登录路由器管理界面的默认帐号是admin，密码是password，管理IP是192.168.1.1。

#### 下载OpenWRT固件 ####
首先下载对应NetGear硬件型号的OpenWRT固件，下载地址请点击[这里](http://downloads.OpenWRT.org)，可以下载最新版本或者历史版本，以现在最新版本15.05.1 Chaos Calmer 版本为例，需要下载两个文件，根据不同的硬件，其文件命名方式也不同，主要有CPU架构、闪存和路由器硬件型号的区别：

- OpenWRT-15.05.1-[架构]-[闪存类型]-[路由器硬件型号]-ubi-factory.img，从Netgear固件升级到OpenWRT。
- OpenWRT-15.05.1-[架构]-[闪存类型]-[路由器硬件型号]-squashfs-sysupgrade.tar, 从其他OpenWRT版本升级或者降级到当前版本。

#### 刷入OpenWRT ####
进入Netgear官方固件的网页管理页面

- 配置位置：高级管理 → 固件升级
- OpenWRT-15.05.1-[架构]-[闪存类型]-[路由器硬件型号]-ubi-factory.img固件文件
- 点击固件升级，确认升级

等待几分钟，完成OpenWRT的刷入。

#### OpenWRT固件升级####
在刷完OpenWRT之后，登录[http://192.168.1.1](http://192.168.1.1)进行偏好设置等，账户为root，缺省密码为空。这时先不要着急进行偏好设置，首先进行系统升级，刷入最新的固件

- 配置位置：System → Backup/Flash Firmware → Flash new firmware image
- 上传OpenWRT-15.05.1-[架构]-[闪存类型]-[路由器硬件型号]-squashfs-sysupgrade.tar
- 点击Flash image，确认升级

过几分钟后，升级到最新固件，这时候可以进行偏好设置

----------
### 3. OpenWRT网络基本讲解###
#### 网卡介绍 ####
- [交换机手册](http://wiki.openwrt.org/zh-cn/doc/uci/network/switch)
- [Linux 网络接口](http://wiki.openwrt.org/zh-cn/doc/networking/network.interfaces)
#### Interface ####
- LAN：缺省的IPv4网络虚拟适配器，用户本地局域网，缺省IP地址192.168.1.1/24，默认开启了IPv4 DHCP服务器，也开启了IPv6 DHCP服务器，防火墙区域为lan。
- WAN：缺省的IPv4网络虚拟适配器，DHCP客户端模式，用于从上级ISP获取IP地址，防火前区域位于wan
- WAN6：缺省的IPv6网络虚拟适配器，DHCPv6客户端模式，可以从上级ISP获取IPv6地址，防火墙区域位于wan
#### WiFi ####
一般拥有双频的设备会有两个SSID，两个无线信号，都桥接到eth0.1
#### Firewall ####
- lan： LAN接口所在的网络，转发wan。
- wan：WAN、WAN6接口所在网络，转发到ISP，具有NAT功能。
#### Switch ####
每个端口在分组中有三个选项： 
- off：这一分组中不使用这个接口 
- untagged：这个接口将被直接桥接到这个分组 
- tagged：这个接口需要通过VLAN ID来访问这一分组

以个人购买的Netgear WNDR3700V1为例，LAN接口映射：

| 路由器端口物理标识 | OpenWRT端口管理标识 |
| :-------: | :-----------: |
|     1     |    port 3     |
|     2     |    port 2     |
|     3     |    port 1     |
|     4     |    port 0     |

### 4. OpenWRT网络设置###
#### IPv4 设置 ####
系统缺省已经有了IPv4的NAT设置。如果想折腾，自行研究。

><span style="color:red">提示：</span>在进行修改任何文件之前，一定要做好备份，方便修改造成任何问题之后恢复。

#### IPv6 设置####
修改/etc/config/dhcp文件，添加如下部分

~~~
config dhcp 'lan'
	option dhcpv6 'relay'
	option ra 'relay'
	option ndp 'relay'

config dhcp 'wan6'
	option interfere 'wan'
	option dhcpv6 'relay'
	option ra 'relay'
	option ndp 'relay'
	option master '1'
~~~

设置好上面的两个文件之后，重启odhcpd服务，否则接入设备无法获取IPv6地址

~~~
/etc/init.d/odhcpd restart
~~~

这种方式可以获取原生的IPv6地址，需要注意的是每次路由器重启上述配置并不会生效，需要重启下odhcpd服务接入的终端设备方可获取IPv6地址。可以在开机启动脚本`/etc/rc.local`中添加如下脚本，每次开机后系统启动60秒后重启odhcpd服务。

~~~
sleep 30
/etc/init.d/odhcpd restart
~~~

----------

### 5. USB磁盘挂载 ###
#### 磁盘设置
在任意linux系统上，使用fdisk工具，对整块磁盘进行如下分区
- 第一个分区512MB，将来作为路由器的交换空间
- 第二个分区为剩下的空间，格式为ext4文件系统，作为存储空间

#### 应用安装 ####
安装应用前进行源更新
~~~
opkg update
~~~

需要安装的程序
~~~
opkg install block-mount
opkg install kmod-usb-storage
opkg install kmod-usb-storage-extras
opkg install kmod-fs-ext4
opkg install fdisk
~~~

安装格式化工具
~~~
e2fsprogs 
~~~

最好使用ext4文件格式的文件系统，这样效率最高，不建议使用ntfs或者vfat，磁盘可以在其他Linux系统上格式化

#### 应用设置 ####
安装上述程序后，虽然设置网页Luci管理端出现了**System → Mount Points**，但是无法访问，需要如下设置：
~~~
block detect > /etc/config/fstab
~~~

设置开机启动并启动
~~~
/etc/init.d/fstab enable
block mount
~~~
#### 网页管理设置 ####
- 配置位置：System → Mount Points
- Mount Points：选择第二分区挂载
- SWAP：选择第一个分区挂载

也可以在命令下进行设置挂载，但是在网页端就不会显示了，只会显示挂载的结果。

### 6. Transmission ###
#### 应用安装 ####
~~~
opkg update
opkg install transmission-daemon    
opkg install transmission-cli 		     
opkg install transmission-web
opkg install transmission-remote
opkg install luci-app-transmission
~~~

#### 应用设置 ####
设置开机启动并启动transmission
~~~
/etc/init.d/transmission enable
/etc/init.d/transmission start
~~~

执行如下命令，启动一下 transmission-daemon
~~~
transmission-daemon
~~~
关闭transmission-daemon
~~~
killall transmission-daemon
~~~

编辑/root/.config/transmission-daemon/settings.json文件
改"rpc-whitelist": "127.0.0.1", 为 "0.0.0.0"，或者将"rpc-whitelist-enabled": true改成false

再执行 `transmission-daemon`，就可以启动了在浏览器地址栏输入：`http://[管理地址]:9091`，添加种子就可以开始BT下载了。

在防火墙里打开TCP 51413端口，可提高下载速度。


### 7. Samba共享设置
#### 应用安装 ####
可以在OpenWRT下设置Samba文件共享服务器，这样可以通过其他设备访问共享服务器上的资源，首先执行如下命令：

~~~
opkg update
opkg install samba36-server
opkg install luci-app-samba
~~~

#### 应用设置 ####
在命令行下启动samba服务并开机启动
~~~
/etc/init.d/samba start
/etc/init.d/samba enable
~~~

#### 权限设置 ####
- 配置位置：Services → Network Shares
- General Settings
  - Path：为共享路径
  - Allowed users： 允许访问用户，默认不允许root
- Edit Template： 注释掉 `invalid users = root`
- 添加新用户: 在/etc/passwd最后一行添加`garlic:*:1000:1000:garlic:/var:/bin/false`
- 创建用户密码：命令行执行 `smbpasswd -a garlic`，设置密码
- root用户通过`smbpasswd -a root`设置密码，root用户有创建文件夹，删除文件等权限，其他用户没有

### 8. 问题 ###
如果局域网中有两台OpenWRT路由器，都是用IPv6 Relay模式，有路由器Onion和Garlic

- Onion WAN IPv6地址：2001:xxxx:xxxx:400:e6f4:c6ff:fee9:d5b
- Garlic WAN IPv6地址： 2001:xx​x​x:xxxx:400:2ac6:8eff:fe0f:823f

正常使用情况下，连接到Onion的设备路由表为
~~~
Internet6:
Destination                             Gateway                         Flags         Netif Expire
default                                 fe80::e6f4:c6ff:fee9:d5a%en0    UGc             en0
::1                                     ::1                             UHL             lo0
2001:xxxx:xxxx:400::/64                  link#4                          UC              en0
2001:xxxx:xxxx:400:3a22:d6ff:febf:1b00   e4:f4:c6:e9:d:5a                UHLWIi          en0
2001:xxxx:xxxx:400:717e:7352:6a24:9ca5   ac:bc:32:af:7e:8b               UHL             lo0
2001:xxxx:xxxx:400:aebc:32ff:feaf:7e8b   ac:bc:32:af:7e:8b               UHL             lo0
2001:xxxx:xxxx:400:e6f4:c6ff:fee9:d5b    e4:f4:c6:e9:d:5a                UHLWIi          en0
fe80::%lo0/64                           fe80::1%lo0                     UcI             lo0
fe80::1%lo0                             link#1                          UHLI            lo0
fe80::%en0/64                           link#4                          UCI             en0
fe80::20c:29ff:fe40:7252%en0            link#4                          UHLWIi          en0
fe80::2ac6:8eff:fe0f:823e%en0           28:c6:8e:f:82:3e                UHLWIi          en0
fe80::3a22:d6ff:febf:1b00%en0           link#4                          UHLWIi          en0
fe80::aebc:32ff:feaf:7e8b%en0           ac:bc:32:af:7e:8b               UHLI            lo0
fe80::e6f4:c6ff:fee9:d5a%en0            e4:f4:c6:e9:d:5a                UHLWIir         en0
fe80::%awdl0/64                         link#8                          UCI           awdl0
fe80::5c4e:77ff:fe44:279a%awdl0         5e:4e:77:44:27:9a               UHLI            lo0
ff01::%lo0/32                           ::1                             UmCI            lo0
ff01::%en0/32                           link#4                          UmCI            en0
ff01::%awdl0/32                         link#8                          UmCI          awdl0
ff02::%lo0/32                           ::1                             UmCI            lo0
ff02::%en0/32                           link#4                          UmCI            en0
ff02::%awdl0/32                         link#8                          UmCI          awdl0
~~~

在使用过IPv6一段时间后，连接到Onion的设备路由表发生了变化，其默认路由地址变成了fe80::2ac6:8eff:fe0f:823e
~~~
Internet6:
Destination                             Gateway                         Flags         Netif Expire
default                                 fe80::e6f4:c6ff:fee9:d5a%en0    UGc             en0
::1                                     ::1                             UHL             lo0
2001:xxxx:xxxx:400::/64                  link#4                          UC              en0
2001:xxxx:xxxx:400:2ac6:8eff:fe0f:823f   e4:f4:c6:e9:d:5a                UHLWIi          en0
2001:xxxx:xxxx:400:aebc:32ff:feaf:7e8b   ac:bc:32:af:7e:8b               UHL             lo0
2001:xxxx:xxxx:400:e6f4:c6ff:fee9:d5b    e4:f4:c6:e9:d:5a                UHLWIi          en0
fe80::%lo0/64                           fe80::1%lo0                     UcI             lo0
fe80::1%lo0                             link#1                          UHLI            lo0
fe80::%en0/64                           link#4                          UCI             en0
fe80::2ac6:8eff:fe0f:823e%en0           28:c6:8e:f:82:3e                UHLWIi          en0
fe80::aebc:32ff:feaf:7e8b%en0           ac:bc:32:af:7e:8b               UHLI            lo0
fe80::e6f4:c6ff:fee9:d5a%en0            e4:f4:c6:e9:d:5a                UHLWIir         en0
fe80::%awdl0/64                         link#8                          UCI           awdl0
fe80::5c4e:77ff:fe44:279a%awdl0         5e:4e:77:44:27:9a               UHLI            lo0
ff01::%lo0/32                           ::1                             UmCI            lo0
ff01::%en0/32                           link#4                          UmCI            en0
ff01::%awdl0/32                         link#8                          UmCI          awdl0
ff02::%lo0/32                           ::1                             UmCI            lo0
ff02::%en0/32                           link#4                          UmCI            en0
ff02::%awdl0/32                         link#8                          UmCI          awdl0
~~~

推测Onion接收到了Garlic的某些IPv6广播包，所以在Onion的防火墙上配置禁止接收Garlic所有IPv6的数据包，同时禁用Linklocal和Global地址。