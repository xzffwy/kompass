---
title:  CentOS 6.x PPTP + Radius + Mysql + Daloradius
date: 2016/9/29 9:07:14 
description: CentOS 6.x PPTP + Radius + Mysql + Daloradius
categories: 技术
tags: [pptp,vpn,linux]
---

### 1. radius服务器安装###
#### yum安装相关软件 ####

	yum install freeradius freeradius-mysql freeradius-utils mysql-server -y

#### mysql设置 ####
启动mysql

	service mysqld start

设置mysql密码和安全设置
	/usr/bin/mysql_secure_installation

创建数据库并授权

	mysql -uroot -p
	mysql-> CREATE DATABASE radius;
	mysql-> GRANT ALL PRIVILEGES ON radius.* TO radius@localhost IDENTIFIED BY "radpass";
	mysql-> flush privileges;

导入数据表

	mysql> use radius;
	mysql> SOURCE /etc/raddb/sql/mysql/schema.sql;
	mysql> exit；

#### 修改freeadius配置文件 ####
编辑freeradius配置文件，开启sql认证

文件1：/etc/raddb/sql.conf 

    # Connection info:
    server = "localhost"
    #port = 3306
    login = "radius"  #mysql登录用户名
    password = "radpass" #上述登录用户名的密码
    # Database table configuration for everything except Oracle
    radius_db = "radius"

文件2：/etc/raddb/radiusd.conf

	$INCLUDE  sql.conf   #去掉前面的注释

文件3： /etc/raddb/sites-available/default

	authorize{} accounting {} session {} 去掉里面sql前面的注释

文件4： /etc/raddb/sites-available/inner-tunnel 

	authorize {} session {} 去掉里面sql前面的注释

文件5： /etc/raddb/clients.conf，修改本地客户端的共享key

    secret = testing123 这个key太简单，可以为一个随机字符串。例如：
    secret = 3c23498n349c3yt290y93b4t3

可以在这个文件中添加其他客户端。

#### iptables端口开放 ####
需要在iptables上开放1812到1814之间，以及18120的udp端口

	iptables -A INPUT -p udp --dport 1812:1814 -j ACCEPT
	iptables -A INPUT -p udp --dport 18120 -j ACCEPT
#### 启动测试radius服务 ####

启动freeradius服务

	service radiusd restart

添加用户信息

	mysql -uroot -p
	use radius;
	insert into radcheck (username,attribute,op,value) values ('test','User-Password',':=','test');
	exit；
	radtest test test 127.0.0.1 0 3c23498n349c3yt290y93b4t3

看到“rad_recv: Access-Accept” 则本地客户端认证成功。

><span style="color:red">**提示：**</span>若出现radtest测试出现radclient:: Failed to find IP address for servername，修改  /etc/hosts 添加：127.0.0.1 servername

----------

### 2.pptp服务器设置 ###
#### 配置文件修改 ####
修改/etc/ppp/option.pptpd,添加如下

    plugin /usr/lib64/pppd/2.4.5/radius.so
    plugin /usr/lib64/pppd/2.4.5/radattr.so
    radius-config-file /etc/radiusclient/radiusclient.conf

去掉/etc/pptpd.conf中的logwtmp字段

><span style="color:red">**提示：**</span>pptp需要在iptables上开放gre协议，如果没有开放该端口，则无法进行验证，即无法登陆成功。这个问题在公网vps还没遇到，但是在同一个局域网内的pptp服务器则有这个问题。
>
>     iptables -A INPUT -p gre -j ACCEPT

#### freeradius客户端安装设置 ####
安装freeadius客户端，没有安装epel源的需要yum安装epel源，freeradius-utils为测试工具，radtest为freeradius-utils命令。

	yum install epel-release
	yum install freeradius-client freeradius-utils -y


#### freearadius配置 ####
**radius客户端**修改/etc/radiusclient/servers，添加条目，若是本地radius服务器，添加如下，rootroot为共享密钥，需要和服务器配置文件/etc/raddb/clients.conf中localhost中的secret一样。

	localhost/localhost rootroot

若要使用远程服务器，**radius客户端**需要在/etc/radiusclient/servers中添加如下，centos2为服务器主机名，需要在hosts文件中添加相应解析条目。

	centos2/centos2 rootroot


**radius客户端**也需要在/etc/radiusclient/radiusclient.conf中修改配置，修改

    authserver  centos2
    acctserver  centos2

**radius服务器**端的/etc/raddb/clients.conf添加如下配置，架设客户端为centos1，ip地址为192.168.86.101，secret为rootroot。在服务器端的hosts中也需要添加关于centos1的地址解析条目。

    client centos1 {
    	ipaddr = 192.168.86.101
    	secret= rootroot
    	require_message_authenticator = no
    	nastype = other 
    }  

#### freeadius测试 ####
客户端可以使用radtest测试远端radius服务器命令，若不成功，可以在服务器端查看/var/log/radius/radius.log来进行debug

#### 字典添加设置 ####
修改/etc/radiusclient/radiusclient.conf中的`/usr/share/radiusclient/dictionary`，将其修改为`/etc/radiusclient/dictionary`。注释掉84行的`radius_deadtime    0` 和87行`bindaddr *`


下载微软字典

	wget http://qingdao.icean.cc:11234/dictionary.microsoft

修改/etc/radiusclient/dictionary字典文件，在文件末尾添加如下

	INCLUDE /etc/radiusclient/dictionary.microsoft
	INCLUDE /etc/radiusclient/dictionary.merit 

需要将`dictionary.microsoft, dictionary.merit`放在`/etc/radiusclient`目录下,dictionary.merit在`/usr/share/radiusclient/`目录下。

><span style="color:red">**修订：**</span>需要将dictionary中所有关于IPv6的选项全部注释掉，否则无法鉴定成功。若出现鉴定失败字样，请使用tail -f /var/log/message来动态查看信息。



----------

### 3.Daloradius安装 ###
#### LAMP环境搭建 ####
Daloradius是基于LAMP环境的，所以首先需要搭建LAMP环境

#### 下载安装 ####
下载daloradius源码

	cd usr/share
	wget http://downloads.sourceforge.net/project/daloradius/daloradius/daloradius0.9-9/daloradius-0.9-9.tar.gz
	tar -xvzf daloradius-0.9-9.tar.gz
	mv daloradius-0.9-9 daloradius
	
#### 编辑daloradius配置文件 ####
修改/usr/share/daloradius/library/daloradius.conf.php
    
    $configValues['CONFIG_DB_HOST'] = 'localhost';
    $configValues['CONFIG_DB_USER'] = 'radius';
    $configValues['CONFIG_DB_PASS'] = '***';  // 设为自己的密码
    $configValues['CONFIG_DB_NAME'] = 'radius';

修改daloRadius路径

	$configValues['CONFIG_PATH_DALO_VARIABLE_DATA'] = '/usr/share/daloradius/var'

#### mysql导入表格数据 ####
导入daloradius数据

    mysql -uroot -p radius < /usr/share/daloradius/contrib/db/fr2-mysql-daloradius-and-freeradius.sql

#### 添加Apache虚拟主机 ####
在/etc/httpd/conf/httpd.conf中加入

    Alias /daloradius "/usr/share/daloradius/"
    <Directory "/usr/share/daloradius">
    </Directory>

#### php-pear-DB安装 ####
安装该软件，否则在浏览器下可以登录daloradius，但是出现http 500错误。


#### 重启服务并网页访问 ####
重启httpd，mysqld服务并在浏览器下输入http://[ip address]/daloradius，默认账户为administrator，密码为radius



