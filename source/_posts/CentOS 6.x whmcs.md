---
title: CentOS 6.x whmcs
date: 2016/5/18 9:07:14 
description: CentOS搭建whmcs破解版本
categories: 技术
tags: [web,linux]
---

### 1.LAMP安装 ###
#### php安装 ####

    yum install php php-mysql -y
    yum install php-mysql php-gd php-imap php-ldap php-odbc php-pear php-xml php-xmlrpc php-pear -y

#### http mysql 服务安装 ####
安装http mysql

    yum install httpd -y
    yum install mysql-server mysql mysql-devel -y

启动http mysql服务，并加入开机启动

	service httpd start
	service mysqld start
	chkconfig httpd on
	chkconfig mysqld on

#### mysql配置 ####
启动服务后，命令行下执行

	/usr/bin/mysql_secure_installation

出现如下几个选项，首次安装第一项直接回车即可，然后设置root密码，root远程登陆可以禁止
	
    Enter current password for root (enter for none):
    Remove anonymous users? [Y/n] y
    Disallow root login remotely? [Y/n] n
    Remove test database and access to it? [Y/n] y
    Reload privilege tables now? [Y/n] y

#### phpmyadmin安装 ####

   
yum安装phpmyadmin

    yum install epel-release -y
    yum install phpmyadmin -y


创建可以访问的软连接

    ln -s /usr/share/phpMyAdmin /var/www/html/phpMyAdmin

允许可以网页访问phpmyadmin，要不然会出现403错误
    
    cat <<EOF>>/etc/httpd/conf/httpd.conf
    <Directory "/usr/share/phpMyAdmin/">
    	AllowOverride None
    	Order allow,deny  
    	Allow from all  
    </Directory>
    EOF

><span style="color:red">**提示：**</span>不同版本的phpmyadmin可能名称不同，有些版本的文件夹名字为phpmyadmin

添加可以访问的IP地址，修改/etc/httpd/conf.d/phpMyAdmin.conf设置，其中192.168.86.104为可以通过IP地址访问phpmyadmin，不添加下面的选项，则无法通过非本地进行访问，配置完成后重启http和mysql服务。

    
    <Directory /usr/share/phpMyAdmin/>
       AddDefaultCharset UTF-8
    
       <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
       Require ip 127.0.0.1
       Require ip ::1
       Require ip 192.168.86.104
     </RequireAny>
       </IfModule>
       <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from All
     Allow from 127.0.0.1
     Allow from ::1
       </IfModule>
    </Directory>

如果是centos7，则删除上面的，添加如下，并重启httpd服务

    <Directory /usr/share/phpMyAdmin/>
	    Options none
	    AllowOverride Limit
	    Require all granted
    </Directory>

  
><span style="color:red">**提示：**</span>低版本的phpmyadmin可能不需要修改此文件

#### mysql添加whmcs用户 ####

使用root用户登录mysql,选择mysql数据库

	mysql -u root -p
	use mysql
	create user 'whmcs'@'localhost' identified by 'whmcs'
	flush privileges

为用户创建数据库

	create database whmcs;

为用户赋予操作数据库testdb的所有权限

	grant all privileges on whmcs.* to 'whmcs'@'localhost' identified  by 'whmcs';
	flush privileges;

用新用户登录
	
	mysql -u whmcs -p

----------

### 2.whmcs安装配置 ###

#### ioncube安装 ####

- whmcs的安装需要ioncube，首先需要安装ioncube，从官网下载linux的安装包，然后解压在/var/www/html目录下。
- 将解压文件重命名为ioncube
- 在浏览器下输入[http://[IP地址]/ioncube/loader-wizard.php](http://www.google.com)，启动ioncube安装向导。
- 将ioncube_loader_lin_5.3.so拷贝到 /usr/lib64/php/modules目录下。
- 将这个文件 [00-ioncube.ini]()下载到/etc/php.d文件夹下。
- 重启http服务器
- 在浏览器上访问测试ioncube是否安装成功，若安装成功则进行下一步。

#### whmcs安装 ####

将whmcs解压到/var/www/html目录下。下载地址请点击[这里](http://pan.baidu.com/s/1bzu4kY)，将目录下的configuration.php.new重命名为或拷贝configuration.php

	cp configuration.php.new configuration.php

修改一些文件的权限为777
	
	chmod -R 777  attachments downloads templates_c  configuration.php

这时候使用浏览器访问[http://192.168.86.104/whmcs/install/install.php](http://192.168.86.104/whmcs/install/install.php),按照提示，一步步进行安装设置，license填写任意数字，数据库一定按照之前创建的数据库填写，hosts，user，password。然后开始开始初始化。

#### whmcs安装完成 ####

- 删除install文件夹
- 修改configuration.php的权限为755
- 编辑configuration.php定义最高权限文件夹的路径，这样这三个文件夹对于网页访问者就不可见了。最后一项的myadminname，是指你将文件夹admin重命名成的新文件名！

<pre><code class="markdown">
$templates_compiledir = "/root/whmcs/templates_c/";
$attachments_dir = "/root/whmcs/attachments/";
$downloads_dir = "/root/whmcs/downloads/";
$customadminpath = "icean";
</code></pre>

#### whmcs破解 ####
使用破解文件中的class.license，替换掉include/class/class-license.php中的文件，破解文件下载请点击[这里](http://pan.baidu.com/s/1bo4ckeb)。






