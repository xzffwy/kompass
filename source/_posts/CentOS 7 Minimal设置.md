---
title: CentOS 7 minimal设置
date: 2016/9/2 9:49:19 
description: CentOS7 minimal初始化安装之后一些设置
categories: 技术
tags: [linux]
---

#### iptables ####

停用firewalld服务 安装iptables

	service firewalld stop
	chkconfig firewalld off
	
	yum install iptables-services
	service iptables start
	chkconfig iptables on
	service ip6tables start
	chkconfig ip6tables on

保存iptables

	iptables-save >> /etc/sysconfig/iptables

#### sysctl.conf ####
ipv4开启转发

    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf

验证是否开启转发
​	
	cat /proc/sys/net/ipv4/ip_forward

#### nmtui ####
界面修改网络配置信息
