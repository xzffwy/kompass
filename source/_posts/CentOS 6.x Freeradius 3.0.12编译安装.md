---
title: CentOS 6.x Freeradius 3.0.12编译安装
date: 2017/1/18 9:07:14 
description: CentOS 6.x 通过yum只能安装Freeradius2，因此需要通过编译来安装Freeradius3
categories: 技术
tags: [freeradius,linux]
---

### 1.编译安装 Freeradius 3.0.12

CentOS 6.x 通过yum只能安装Freeradius2，因此需要通过编译来安装Freeradius3

#### 1.1 环境准备
需要安装一些包以及gcc、make工具
~~~bash
yum install -y gcc make mysql-devel libtalloc-devel
~~~

#### 1.2 下载源码
从[Freeradius官网](http://freeradius.org/)下载最新的源码到主机，然后解压并切换到解压后的目录

~~~bash
wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-server-3.0.12.tar.bz2
tar xvf freeradius-server-3.0.12.tar.bz2 
cd freeradius-server-3.0.12
~~~

#### 1.3 配置安装
进行配置，然安装，根据主机的性能而定，花费的时间不定
~~~bash
./configure
make && make install
~~~

安装完成后，radius可执行文件的路径为`/usr/local/sbin`, 配置文件路径为`/usr/local/etc/raddb`

#### 1.4 运行测试

修改配置文件的安全选项，配置文件为`/usr/local/etc/raddb/radiusd.conf`，将**allow_vulnerable_openssl**选项改为**yes**，否则无法启动radius服务，会提示因为OpenSSL心脏滴血问题而无法启动。

~~~bash
security {
   allow_vulnerable_openssl = yes
}
~~~

若不修改安全选项，则会报如下错误

~~~bash
Debugger not attached
Refusing to start with libssl version OpenSSL 1.0.1e-fips 11 Feb 2013 0x1000105f (1.0.1e release) (in range 1.0.1 release - 1.0.1t rele)
Security advisory CVE-2016-6304 (OCSP status request extension)
For more information see https://www.openssl.org/news/secadv/20160922.txt
Once you have verified libssl has been correctly patched, set security.allow_vulnerable_openssl = 'CVE-2016-6304'
Refusing to start with libssl version OpenSSL 1.0.1e-fips 11 Feb 2013 0x1000105f (1.0.1e release) (in range 1.0.1 dev - 1.0.1f release)
Security advisory CVE-2014-0160 (Heartbleed)
For more information see http://heartbleed.com
~~~

以debug模式运行radius，命令为`radius -X`，如果出现如下提示信息，说明radius服务在debug模式下运行成功，正在监听radius请求

~~~bash
Listening on auth address 127.0.0.1 port 18120 bound to server inner-tunnel
Listening on auth address * port 1812 bound to server default
Listening on acct address * port 1813 bound to server default
Listening on auth address :: port 1812 bound to server default
Listening on acct address :: port 1813 bound to server default
Listening on proxy address * port 57298
Listening on proxy address :: port 47250
Ready to process requests
~~~

如果要确认当前系统的OpenSSL是否已经打上心脏滴血的补丁，运行如下命令

~~~bash
rpm -q --changelog openssl | grep -i -E "CVE-2014-0160"
~~~

----------

### 2. MySQL设置
#### 2.1 创建数据库&用户
为Freeradius创建一个数据库，并创建一个用户将。以root登录mysql，创建`数据库radius`，创建`用户radius`，并将`数据库radius`所有权限赋予给`用户radiu`s，登录密码为`radpass`

~~~mysql
CREATE DATABASE radius;
GRANT ALL PRIVILEGES ON radius.* TO radius@"localhost" IDENTIFIED BY "radpass";
flush privileges;
~~~

#### 2.2 Navicat管理MySQL ####
为方便管理MySQL，可以使用Navicat进行管理，则需要添加一个可以远程访问`数据库radius`的用户，如下添加一个`用户radcat`，密码为`radpass`，`radcat@'%'`代表可以从任何地点访问`数据库radius`

~~~mysql
GRANT ALL PRIVILEGES ON radius.* TO radcat@'%' IDENTIFIED BY "radpass";
flush privileges;
~~~

可以控制navicat的权限粒度，例如只赋予某些表的查看权限

~~~mysql
GRANT SELECT ON radius.radacct TO radcat@'%' IDENTIFIED BY 'radpass';
flush privileges;
~~~

#### 2.2 导入Freeradius数据库表格
以用户root，或者以用户radius登录，选择数据库adius，导入Freeradius数据表格

~~~mysql
use radius;
SOURCE /usr/local/etc/raddb/mods-config/sql/main/mysql/schema.sql;
exit；
~~~

#### 2.3 增加表格列
因为个人需求，可以增加导入表的列，例如增加radcheck中条目的创建时间，自动记录每个用户的添加时间。
~~~mysql
alter table radcheck add column create_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP;
~~~

#### 2.4 插入验证条目

以命令行的方式添加测试用户

~~~mysql
#账户账号密码
insert into radcheck (username,attribute,op,value) values ('test','Cleartext-Password',':=','test');

#将test用户加入到test组中
insert into radusergroup (username,groupname) values ('test','test');
~~~
或者使用Navicat以图形界面的方式添加测试用户

----
### 3. Freeradius配置
####  3.1 启用mysql模块 ####
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

#### 3.2 NAS客户端添加 ####
默认已经添加了本地机器为NAS客户端。若添加其他NAS客户端设置如下，修改`/usr/local/etc/raddb/clients.conf`，添加如下
~~~bash
client ovzinp {     
    ipaddr = 1.2.2.2                            #客户端地址
    secret= testing1234                     #与客户端之间使用的暗码
    require_message_authenticator = no
    nastype = other 
}
~~~
NAS客户端的设置可能有些不同，但是大同小异，都要填写Freeradius服务器的URL或者IP地址，以及上文的暗码。

#### 3.3 iptables配置
需要在iptables上开放1812、1813 UDP端口
~~~bash
iptables -I INPUT 2 -p udp --dport 1812:1813 -j ACCEPT
~~~

----------
### 4. Freeradius服务器测试&运行 ###
####  4.1 Freeradius调试 ####
命令行下使用`radiusd -X`开启debug模式，然后打开另一个终端，使用测试账户测试，命令如下
~~~bash
radtest test test localhost 0 testing123
~~~

- test：账户名
- test：密码
- localhost：Freeradius服务器地址，代表本地
- testing123：与Freeradius之间的共享密钥，在Freeradius服务器的配置目录下的raddb/clients.conf中定义，实际生产环境暗码需要设置很长而且复杂

#### 4.2 Freeradius运行

若debug模式测试完毕，则可以正常启动radius，使用如下命令启动radius服务，如果要终止服务，通过kill命令来杀掉radius的服务进程

~~~bash
radiusd
~~~

---

### 5. 流量限制模块添加 ###

#### 5.1 启用sqlcounter模块 ####
切换到`/usr/local/etc/raddb/mods-enabled`下，启用sqlcounter模块

~~~bash
cd /usr/local/etc/raddb/mods-enabled
ln -s ../mods-available/sqlcounter
~~~

#### 5.2 添加自定义模块 ####
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

#### 5.3 授权启用自定义模块 ####
修改`/usrlocal/etc/raddb/sites-available/default`，找到authorize字段，启用自定义模块。
~~~bash
authorize {
	monthlytrafficcounter
}
~~~
#### 5.4 字典修改 ####
修改`/usr/local/etc/dictionary`,添加如下两行，这两个变量在sqlcounter中提到过。
~~~bash
ATTRIBUTE Max-Monthly-Traffic 3003 integer
ATTRIBUTE Monthly-Traffic-Limit 3004 integer
~~~

#### 5.5 SQL语句插入 ####
插入如下语句，则test用户组下的所用用户流量上限是1MB。
~~~mysql
insert into radgroupcheck (groupname,attribute,op,value) VALUES ('test','Max-Monthly-Traffic',':=','1');
~~~

统计数据是在每次登陆时检查,因此使用过程中超流量不会强制下线，而是在下一次登陆时被拒绝。

#### 5.6 服务重启

因为添加了新的模块，所以要手动杀掉radius进程然后重新启动radius