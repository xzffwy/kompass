---
title:  小米路由器mini刷PandoraBox
date: 2015/12/1 9:21:25 
description: 小米路由器mini刷PandoraBox
categories: 技术
tags: [router,network]
---
### 1.准备工作 ###

- 小米路由器mini
- U盘一个（FAT32格式）
- WinSCP
- Xshell

----------

### 2.刷入开发版本ROM ###
从[小米wifi官网](http://miwifi.com/miwifi_download.html)下载小米路由器mini的开发版本。首先，请先准备一个U盘，并确保这个U盘的格式为FAT或FAT32.接下来，就是具体的操作流程：

- 在miwifi.com官网下载路由器对应的ROM包，并将其放在U盘的根目录下，命名为miwifi.bin
- 断开小米路由器mini的电源，将U盘插入路由器的USB接口
- 按下reset按钮后重新接入电源，待指示灯变为黄色闪烁状态后松开reset键
- 等待5~8分钟，刷机完成之后系统会自动重启并进入正常的启动状态（指示灯由黄灯常亮变为蓝灯常亮），此时，说明刷机成功完成！

> 如果出现异常/失败/U盘无法读取状态，会进入红灯状态，建议重试或更换U盘再试。

----------

### 3.初始化路由器 ###
刷入开发版本的ROM，最好初始化一遍路由器，不初始化在之后的刷如PandoraBox可能有些问题。

----------

### 4.获取SSH权限 ###
要获取SSH权限，首先要和小米账户进行绑定，具体如何绑定请自行Google或者Baidu。   
绑定成功后，会在网页上显示root密码以及下载SSH工具包的链接。如图4-1，图4-2所示。

<span style="color:purple">图4-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/PandoraBox/4-1.jpg)

<span style="color:purple">图4-2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/PandoraBox/4-2.jpg)

刷入SSH工具包步骤如下。

- 将下载的工具包bin文件复制到U盘（FAT/FAT32格式）的根目录下，保证文件名为miwifi_ssh.bin；
- 断开小米路由器的电源，将U盘插入USB接口；
- 按住reset按钮之后重新接入电源，指示灯变为黄色闪烁状态即可松开reset键；
- 等待3-5秒后安装完成之后，小米路由器会自动重启，之后就可以尽情折腾啦。

----------

### 5.刷入PandoraBox ###
使用WinSCP将PandoraBox的镜像导入到小米路由器的/tmp目录下。PandoraBox下载地址请点击[这里](http://downloads.openwrt.org.cn/PandoraBox/)，或者[这里](http://pan.baidu.com/s/1sj6AI9f)。WinSCP的界面如图5-1所示。

<span style="color:purple">图5-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/PandoraBox/5-1.jpg)

此时，可以通过xshell SSH登录小米路由器mini了，路由器的IP缺省为192.168.1.1，账户为root，密码为在小米路由器官网上给出的。执行如下命令

	mtd -r write /tmp/PandoraBox-ralink-mt7620-xiaomi-mini-squashfs-sysupgrade-r512-20150309 OS1

这样开始了刷机，几分钟过后刷机成功，可在PC的wifi列表中找到PandoraBox的SSID。连接其中一个成功之后，可以登录192.168.1.1进行管理了，也可以通过xshell ssh登录，地址也为192.168.1.1。以上两种登录方式的账户都是root，缺省密码为admin。

----------

### 6.偏好设置 ###
在进行开始设置之前，极力推荐备份下/etc目录下的所有文件，如图6-1所示。在路由器命令行下，执行如下命令：

	tar cvpzf etc_back.tgz /etc

<span style="color:purple">图6-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/PandoraBox/6-1.jpg)

备份完毕，将备份下载到本地保存。
	
进行偏好设置，例如无线的SSID，无线密码，管理密码等等。设置完毕之后，可以在PandoraBox网页端进行备份，同时推荐在命令行下进行备份/etc目录。备份方法如上。

----------

### 7.IPv4 NAT ###
这个缺省已经设置好了，无需进行任何修改。

----------

### 8.IPv6 穿透 ###
这是我本次刷机最大的目的，实现了IPv4的NAT方式，然后还可以获取原生的IPv6。在最新版本的PandoraBox中，已经集成了实现IPv6穿透的服务或者软件，所以只需要修改一些配置文件即可。其中主要修改的就是/etc/config/network和/etc/config/dhcp文件，修改后的文件如下所示。

----------

#### /etc/config/network ####

    config interface 'loopback'
    	option ifname 'lo'
    	option proto 'static'
    	option ipaddr '127.0.0.1'
    	option netmask '255.0.0.0'
    
    config globals 'globals'
    	#option ula_prefix 'auto'
    
    config interface 'lan'
    	option ifname 'eth0.1'
    	option force_link '1'
    	option type 'bridge'
    	option proto 'static'
    	option ipaddr '192.168.1.1'
    	option netmask '255.255.255.0'
    	option ip6assign '64'
    	option macaddr 'f0:b4:29:5a:ff:f6'
    
    config interface 'wan'
    	option ipv6 '1'
    	option ifname 'eth0.2'
    	option proto 'dhcp'
    	option macaddr 'f0:b4:29:5a:ff:f7'
    
    config interface 'wan6'
    	option ifname '@wan'
    	#option ifname 'eth0.2'
    	option proto 'dhcpv6'
    
    config switch
    	option name 'mt762x'
    	option reset '1'
    	option enable_vlan '1'
    
    config switch_vlan
    	option device 'mt762x'
    	option vlan '1'
    	option ports '0 1 2 3 5 6t 7t'
    
    config switch_vlan
    	option device 'mt762x'
    	option vlan '2'
    	option ports '4 6t 7t'

#### /etc/config/dhcp ####

	config dnsmasq
		option domainneeded '1'
		option boguspriv '1'
		option filterwin2k '0'
		option localise_queries '1'
		option rebind_protection '1'
		option rebind_localhost '1'
		option local '/lan/'
		option domain 'lan'
		option expandhosts '1'
		option nonegcache '0'
		option authoritative '1'
		option readethers '1'
		option leasefile '/tmp/dhcp.leases'
		option resolvfile '/tmp/resolv.conf.auto'
	
	config dhcp 'lan'
		option interface 'lan'
		option start '100'
		option limit '150'
		option leasetime '12h'
		#option dhcpv6 'server'
		option ra 'relay'
		option ndp 'relay'
	
	config dhcp 'wan6'
		option ra 'relay'
		option ndp 'relay'
		option master '1'
	
	#config dhcp 'wan'
		#option interface 'wan'
		#option ignore '1'
	
	config odhcpd 'odhcpd'
		option maindhcp '0'
		option leasefile '/tmp/hosts/odhcpd'
		option leasetrigger '/usr/sbin/odhcpd-update'

设置好上面的两个文件之后，重启相关服务

	/etc/init.d/odhcpd restart
	/etc/init.d/network restart

这样在浏览器上就可以获取IPv4 NAT私有地址以及原生的IPv6地址了。如图8-1所示。

<span style="color:purple">图8-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/PandoraBox/8-1.jpg)

> 若IPv6能获取地址但是不能上网，请重启odhcpd服务。




