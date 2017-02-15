---
title: CentOS6.x Freeradius 3.0.11编译安装
date: 2016/8/31 9:07:14 
description: CentOS6.x Freeradius 3.0.11编译安装
categories: 技术
tags: [freeradius,linux]
---

### 1.编译安装Freeradius
CentOS6.5的源只有Freeradius2，没有Freeradius3，这样只能编译安装Freeradius3

#### 环境准备
需要安装gcc，make，mysql-devel等
~~~bash
yum install -y gcc make mysql-devel libtalloc-devel
~~~

#### 下载源码
从[Freeradius官网](http://freeradius.org/)下载最新的源码到主机，然后解压。由于本文下载的版本为3.0.11，所以解压后的文件夹为`freeradius-server-3.0.11`

#### 配置安装
切换到解压后的文件夹，进行配置，然后安装,这个过程时间可能比较长，根据主机的性能而定。
~~~bash
./configure --with-modules=rlm_sql_mysql
make && make install
~~~

安装完成后，radius可执行文件的路径为/usr/local/sbin, 配置文件路径为/usr/local/etc/raddb

----------

### 2. MySQL设置
#### 创建数据库&用户
为Freeradius3创建一个数据库，并创建一个用户将该数据库的所有权限赋予给这个用户。首先以root登录mysql，执行如下语句

~~~mysql
CREATE DATABASE radius3;
GRANT ALL PRIVILEGES ON radius3.* TO radius3@"localhost" IDENTIFIED BY "radpass";
flush privileges;
~~~

#### navicat管理MySQL ####
为方便管理MySQL，可以使用navicat进行管理，则需要添加一个可以远程访问radius数据库的账户，如下添加一个radcat用户，密码为radpass，radius@'%'代表可以从任何地点访问radius数据库。

~~~mysql
CREATE DATABASE radcat;
GRANT ALL PRIVILEGES ON radius.* TO radius@'%' IDENTIFIED BY "radpass";
flush privileges;
~~~

可以控制navicat的权限粒度，例如只赋予某些表的查看权限

~~~mysql
CREATE USER radcat IDENTIFIED BY 'radpass';
GRANT SELECT ON radius.radacct TO radcat@'%' IDENTIFIED BY 'radpass';
~~~

#### 导入Freeradius的MySQL数据库表格
以root用户，或者以radius用户登录，选择radius数据库，导入Freeradius数据表格

~~~mysql
use radius;
SOURCE /usr/local/etc/raddb/mods-config/sql/main/mysql/schema.sql;
exit；
~~~

#### 增加表格列
因为个人需求，可以增加导入表的列，例如增加radcheck中条目的创建时间，自动记录每个用户的添加时间。
~~~mysql
alter table radcheck add column create_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP;
~~~

#### 插入验证条目
~~~mysql
#账户账号密码
insert into radcheck (username,attribute,op,value) values ('test','Cleartext-Password',':=','test');

#将test用户加入到test组中
insert into radusergroup (username,groupname) values ('test','test');
~~~

----------

### 3. Freeradius配置
####  启用mysql模块 ####
执行如下命令，启用mysql模块
~~~bash
cd /usr/local/etc/raddb/mods-enabled
ln -s ../mods-available/sql
~~~

编辑/etc/raddb/mods-available/sql，找到

~~~bash
dialect = "sqlite"
driver = "rlm_sql_null"
radius_db = "radius"
#server = "localhost"
#port = 3306
#login = "radius"
#password = "radiuspwd"
#read_clients =yes
~~~

修改为如下，其中mysql账户为之被授权radius数据库的用户

~~~bash
dialect = "mysql"                   #选择mysql
driver = "rlm_sql_mysql"       #选择mysql驱动
server = "localhost"               #服务器地址
port = 3306                           #mysql端口号
radius_db = "radius"             #所使用的数据库
login = "radius"                    #mysql账户
password = "radpass"          #mysql账户密码
read_clients =yes
~~~

#### NAS客户端添加 ####
Freeradius服务器的主要作用是为NAS客户端提供验证服务器，添加NAS客户端设置如下，修改`/usr/local/etc/raddb/clients.conf`，添加如下
~~~bash
client ovzinp {     
    ipaddr = 1.2.2.2                            #客户端地址
    secret= testing1234                     #与客户端之间使用的暗码
    require_message_authenticator = no
    nastype = other 
}
~~~
NAS客户端的设置可能有些不同，但是大同小异，都要填写Freeradius服务器的URL或者IP地址，以及上文的暗码。

#### iptables配置
需要在iptables上开放1812、1813 UDP端口
~~~bash
iptables -I INPUT 2 -p udp --dport 1812:1813 -j ACCEPT
~~~

----------

### 4. Freeradius服务器测试 ###
####  Freeradius调试 ####
命令行下使用radiusd -X开启debug模式，然后打开另一个终端，使用如下命令进行测试
~~~bash
radtest test test localhost 0 testing123
~~~

- test：账户名
- test：密码
- localhost：Freeradius服务器地址，代表本地
- testing123：与Freeradius之间的共享密钥，在Freeradius服务器的配置目录下的raddb/clients.conf中定义，最好很长很复杂
><span style="color:red">**提示：**</span> radtest工具可能需要yum进行安装 yum install freeradius-utils -y

----------
### 5. 流量限制模块添加 ###
#### 启用sqlcounter模块 ####
切换到`/usr/local/etc/raddb/mods-enabled`下，启用sqlcounter模块

~~~bash
cd /usr/local/etc/raddb/mods-enabled
ln -s ../mods-available/sqlcounter
~~~

#### 添加自定义模块 ####
编辑sqlcounter，添加如下每月流量限制模块
~~~bash
sqlcounter monthlytrafficcounter {          #counter名字
    sql_module_instance = sql            
    dialect = ${modules.sql.dialect}
    counter_name = Monthly-Traffic          #任意名字
    check_name = Max-Monthly-Traffic     #检查字段，这个字段的临界值要在radcheck或者radcheckgroup表中设置
    reply_name = Monthly-Traffic-Limit   
    key = User-Name                                 #控制粒度，一般是用户
    reset = monthly				       #时间周期，这里设置为每月

    $INCLUDE ${modconfdir}/sql/counter/${dialect}/${.:instance}.conf       #配置文件目录                                                                  
}
~~~

设置SQL语句，在`/etc/raddb/mods-config/sql/counter/mysql`目录下，创建monthlytrafficcounter.conf文件，注意，这个文件名是与之前的counter名字对应的。其中

- %{${key}}为上面设置的key
- %b为每个周期的第一天
- %e为每个周期的最后一天，这里只用到了第一天
- Freeradius流量按照字节（byte）统计，所以统计结果除以1048576（1024*1024），正好是1MB，则在数据库里可以直接按照MB统计，而不是字节。
~~~sql
query = "\
    SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 \                                                                             
    FROM radacct \
    WHERE UserName='%{${key}}' \ 
    AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
~~~

#### 授权启用自定义模块 ####
修改`/usrlocal/etc/raddb/sites-available/default`，找到authorize字段，启用自定义模块。
~~~bash
authorize {
	monthlytrafficcounter
}
~~~
#### 字典修改 ####
修改`/usr/local/etc/dictionary`,添加如下两行，这两个变量在sqlcounter中提到过。
~~~bash
ATTRIBUTE Max-Monthly-Traffic 3003 integer
ATTRIBUTE Monthly-Traffic-Limit 3004 integer
~~~

#### SQL语句插入 ####
插入如下语句，则test用户组下的所用用户流量上限是1MB。
~~~mysql
insert into radgroupcheck (groupname,attribute,op,value) VALUES ('test','Max-Monthly-Traffic',':=','1');
~~~

统计数据是在每次登陆时检查,因此使用过程中超流量不会强制下线，而是在下一次登陆时被拒绝。



问题

~~~
Debugger not attached
Refusing to start with libssl version OpenSSL 1.0.1e-fips 11 Feb 2013 0x1000105f (1.0.1e release) (in range 1.0.1 release - 1.0.1t rele)
Security advisory CVE-2016-6304 (OCSP status request extension)
For more information see https://www.openssl.org/news/secadv/20160922.txt
Once you have verified libssl has been correctly patched, set security.allow_vulnerable_openssl = 'CVE-2016-6304'
Refusing to start with libssl version OpenSSL 1.0.1e-fips 11 Feb 2013 0x1000105f (1.0.1e release) (in range 1.0.1 dev - 1.0.1f release)
Security advisory CVE-2014-0160 (Heartbleed)
For more information see http://heartbleed.com
[root@localhost freeradius-server-3.0.12]# 
~~~

