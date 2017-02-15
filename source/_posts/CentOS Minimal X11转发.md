---
title: CentOS Minimal X11转发
date: 2016/9/29 9:49:19 
description: CentOS Minimal X11转发
categories: 技术
tags: [linux]
---

### 1. X11安装以SSH设置

####  X11安装  

下载CentOS所需要的软件包，命令如下所示。安装xterm，以及xorg-x11-xauth和相关依赖。

```shell
yum -y install xterm xorg-x11-xauth
yum -y  install libXext libXtst libXi twm
```
####  SSH设置 

修改/etc/ssh/sshd_config

```shell
AllowTcpForwarding yes
X11Forwarding yes
```

修改之后，重启ssh服务

####  其他问题

- 若是postfix服务无法启动，则使用postfix set-permissions命令查看原因，可能原因之一因为hosts文件中缺失对localhost地址的解析，所以导致了postfix服务无法启动。


- hosts文件中确实对localhost的解析，可能导致了X11无法转发。

----------

### 2. 软件设置
####  xshell设置 

在设置完基本的SSH登录之后，在隧道选项中添加如下信息，如图1-1所示。

<center>![](http://qingdao.icean.cc:11234/Imgbed/X11_forwarding/1-1.jpg)</center>
<center style="color:purple">**图1-1**</center>

但是xshell在通过IPv6登录到主机时候，不能成功执行，根据strace的结果，应该是xshell软件的问题或者xshell设置的问题。

####  putty设置 

安装Xming，[下载地址](https://sourceforge.net/projects/xming/)，安装之后，在执行X11 Forwarding之前，需要启动X11。

启动putty，选择Connection->SSH->X11，启动X11 Forwarding，如图2-1所示。

<center> ![1-2](http://qingdao.icean.cc:11234/Imgbed/X11_forwarding/1-2.jpg)</center>

<center style="color:purple">**图2-1**</center>

然后再设置SSH登录的服务器、账户和密码等。这时候SSH通过IPv4和IPv6登录均可启动X11 Forwarding。