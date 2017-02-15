---
title: CentOS 6.x vsftp 启用 SSL或TLS
date: 2016/6/24 19:35
description: CentOS 6.x vsftp 启用 SSL或TLS
categories: 技术
tags: [vsftp,linux]
---

### 1. 创建用户以及用户组 ###

在CeotOS下建立一个单独的FTP账户，并不允许进行SSH登录

```shell
useradd -s /sbin/nologin vxftp
passwd vxftp
```

建立图床的文件夹，按照管理，将该目录放置在账户的home文件夹下，例如如下命令

```shell
mkdir -p /home/vxftp/imgbed
```

创建一个单独的FTP用户组

```shell
groupadd vsftp
```

把之前建立的图床文件夹分配给FTP用户,并更改其用户组

```shell
usermod -g vsftp -d /home/vxftp/imgbed -U vxftp
```

更改文件夹属性

```shell
chown -R vxftp.vsftp /home/vxftp/imgbed
```

----------

### 2.安装配置vsftp ###

####  不使用SSL/TLS配置

安装vsftpd
```shell
yum install -y vsftpd
```

修改vsftpd配置文件

```shell
vi /etc/vsftpd/vsftpd.conf
```

检查一下是否正确

```shell
listen=YES
local_enable=YES
write_enable=YES
local_umask=022
pasv_promiscuous=YES
```


禁止其他用户访问FTP,若userlist_enable=YES，则/etc/vsftpd/user_list中的用户将被禁止访问FTP，如果为NO，则只有user_list里面的用户可以访问FTP。

```shell
userlist_enable=NO
anonymous_enable = NO
```

把vxftp用户加入到user_list中

```shell
echo "vxftp" >> /etc/vsftpd/user_list
```

把之前创建的图床目录路径加入到chroot_list中，并修改配置文件

```shell
echo "/home/vxftp/imgbed" >> /etc/vsftpd/chroot_list
echo "chroot_list_enable=YES">>/etc/vsftpd/vsftpd.conf
echo "chroot_list_file=/etc/vsftpd/chroot_list">>/etc/vsftpd/vsftpd.conf
```

其中vsftpd服务并将其加入到开机自启动

```shell
service vsftpd start
chkconfig --level 35 vsftpd on
```

在windows下打开任意一个文件夹窗口，输入如下地址

```shell
ftp://ftp-server:11235
```

不使用SSL/TLS则可以不设置下面内容。

####  SSL/TLS加密配置

创建证书存放文件夹并生成证书

```shell
cd /etc/vsftpd/
mkdir ssl
sudo openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout /etc/vsftpd/ssl/vsftpd.pem -out /etc/vsftpd/ssl/vsftpd.pem
```

修改`/etc/vsftpd/vsftpd.conf`配置文件，如下所示

```shell
rsa_cert_file=/etc/vsftpd/ssl/vsftpd.pem           #证书路径
ssl_enable=YES                                                   #是否启用 SSL,默认为no
allow_anon_ssl=NO                                            #是否允许匿名用户使用SSL,默认为no
force_local_data_ssl=YES                                    #非匿名用户传输数据时是否加密,默认为yes
force_local_logins_ssl=YES                                  #非匿名用户登陆时是否加密,默认为yes
ssl_tlsv1=YES                                                       #是否激活sslv1加密,默认no
ssl_sslv2=NO                                                       #是否激活sslv2加密,默认no
ssl_sslv3=NO                                                       #是否激活sslv3加密,默认no
require_ssl_reuse=NO
ssl_ciphers=HIGH             
```

----------

### 3.修改FTP端口号 ###

默认FTP端口号可能有一些安全问题，可以把默认端口号改为其他端口号

编辑/etc/vsftpd/vsftpd.conf文件，将预设端口号加入文件末尾，其中11235为修改后的端口号

```shell
cat "listen_port=11235" >> /etc/vsftpd/vsftpd.conf
```

编辑/etc/services 将其中的 ftp 21/tcp 改为 ftp 11235/tcp，ftp 21/udp 改为 ftp 11235/udp

修改/etc/vsftpd/vsftpd.conf的配置文件，在文件末端添加如下，端口范围可以自己选定，这里选定的范围为2333到2343,vsftp会使用这个范围的端口号进行传输数据，如果在防火墙上不放行这个端口号范围，vsftp客户端可以登录，但是无法获取文件列表。

```shell
pasv_min_port=2333
pasv_max_port=2343
```

防火墙中加入条目，然后保存并重启防火墙

```shell
iptables -I INPUT 1 -p tcp --dport 11235 -j ACCEPT
iptables -I INPUT 1 -p udp --dport 11235 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 2333:2343 -j ACCEPT
service iptables save
service iptabkes restart
```

重新启动vsftpd服务

```shell
service vsftpd restart
```