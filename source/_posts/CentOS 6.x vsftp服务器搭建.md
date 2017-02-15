---
title: CentOS 6.x vsftp服务器搭建
date: 2016/8/24 14:59:17
description: CentOS 6.x搭建图床
categories: 技术
tags: [vsftp,linux]
---
## CentOS 6.x搭建图床 ##

### 1. 创建用户以及用户组 ###

在CeotOS下建立一个单独的FTP账户，并不允许进行SSH登录

    useradd -s /sbin/nologin vxftp
    passwd vxftp

建立图床的文件夹，按照管理，将该目录放置在账户的home文件夹下，例如如下命令

	mkdir -p /home/vxftp/imgbed

创建一个单独的FTP用户组

	groupadd vsftp

把之前建立的图床文件夹分配给FTP用户,并更改其用户组

	usermod -g vsftp -d /home/vxftp/imgbed -U vxftp

更改文件夹属性

	chown -R vxftp.vsftp /home/vxftp/imgbed


----------

### 2.安装配置vsftp ###

安装vsftpd
	yum install -y vsftpd

修改vsftpd配置文件

	vi /etc/vsftpd/vsftpd.conf

检查一下是否正确

	listen=YES
	local_enable=YES
	write_enable=YES
	local_umask=022
	pasv_promiscuous=YES

禁止其他用户访问FTP,若userlist_enable=YES，则/etc/vsftpd/user_list中的用户将被禁止访问FTP，如果为NO，则只有user_list里面的用户可以访问FTP。禁用匿名，配置中修改如下

	userlist_enable=NO
	anonymous_enable = NO

把vxftp用户加入到user_list中

	echo "vxftp" >> /etc/vsftpd/user_list

把之前创建的图床目录路径加入到chroot_list中，并修改配置文件

	echo "/home/vxftp/imgbed" >> /etc/vsftpd/chroot_list
	echo "chroot_list_enable=YES">>/etc/vsftpd/vsftpd.conf
	echo "chroot_list_file=/etc/vsftpd/chroot_list">>/etc/vsftpd/vsftpd.conf

其中，服务并将其加入到开机自启动

	service vsftpd start
	chkconfig --level 35 vsftpd on

在windows下打开任意一个文件夹窗口，输入如下地址

	ftp://ftp-server:11235

然后会弹出登录框，登录成功后，可以创建一个文件夹，并把该文件夹收藏到收藏夹，方便上传图片

----------

### 3.修改FTP端口号 ###

默认FTP端口号可能有一些安全问题，可以把默认端口号改为其他端口号

编辑/etc/vsftpd/vsftpd.conf文件，将预设端口号加入文件末尾，其中11235为修改后的端口号

	cat "listen_port=11235" >> /etc/vsftpd/vsftpd.conf
编辑/etc/services， 将其中的 ftp 21/tcp 改为 ftp 11235/tcp，ftp 21/udp 改为 ftp 11235/udp

修改/etc/vsftpd/vsftpd.conf的配置文件，在文件末端添加如下，端口范围可以自己选定，这里选定的范围为2333到2343,vsftp会使用这个范围的端口号进行传输数据，如果在防火墙上不放行这个端口号范围，vsftp客户端可以登录，但是无法获取文件列表。

    pasv_min_port=2333
    pasv_max_port=2343

防火墙中加入条目，然后保存并重启防火墙

	iptables -A INPUT -p tcp --dport 11235 -j ACCEPT
	iptables -A INPUT -p udp --dport 11235 -j ACCEPT
	iptables -A INPUT -p tcp --dport 2333:2343 -j ACCEPT
	service iptables save
	service iptabkes restart

重新启动vsftpd服务

	service vsftpd restart
----------
### 4.安装HTTP服务器 ###

安装httpd服务

	yum install -y httpd

启动httpd服务并加入到开机启动中

	service httpd start
	chkconfig httpd on

去掉缺省页面，将/etc/httpd/conf.d/welcome.conf内容全部注释掉，并重启服务

	vi /etc/httpd/conf.d/welcome.conf 

	service httpd restart

httpd默认文件夹在/var/www/html/，建立/home/vxftp/imgbed的软链接

	ln -s /home/vxftp/imgbed

此时在网页下还不能访问imgbed文件夹，因为权限问题，需要给vxftp的用户文件夹加上执行权限

	chmod +x /home/vxftp

这样在网页下就可以访问imgbed图床文件夹了

----------

### 5. 修改HTTP端口 ###

若不想用80端口，可以将端口修改为其他放，首先找到配置文件/etc/httpd/conf/httpd.conf

	将Listen 80改为 Listen 11234

11234为修改后的端口号，继续修改httpd.conf，找到#ServerName www.example.com:80，在下面添加一行

	ServerName localhost:11234
防火墙中加入条目，然后保存并重启防火墙

	iptables -A INPUT -p tcp --dport 11234 -j ACCEPT
	service iptables save
	service iptabkes restart

重新启动服务

	service httpd restart
---

### 6. Selinux问题

关闭selinux，否则网页上没有权限访问软链接的内容，或者查看selinux关于ftp相关的设置，命令如下

```shell
getsebool -a| grep ftp
```

若不关闭设置如下

```
setsebool ftpd_disable_trans 1
setsebool -P ftp_home_dir 1
setsebool -P httpd_read_user_content 1
```

