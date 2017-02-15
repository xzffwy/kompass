---
title: CentOS 7.x ocserv + freeradius验证 + SSL
date: 2016/9/29 9:49:19 
description:  CentOS 7.x ocserv + freeradius验证 + SSL
categories: 技术
tags: [ocserv,vpn,linux]
---
### 1.ocserv安装###

####  yum安装相关软件 ####
在CentOS7中，可以直接使用yum安装ocserv

```bash
yum install epel-release -y
yum install -y ocserv
```

####  自签名证书生成

##### 创建相关文件夹

ocserv服务的启动需要证书，这里介绍的是如何使用自签证书。首先创建相关文件夹

```bash
mkdir -p /etc/ocserv/ssl/private          
mkdir -p /etc/ocserv/ssl/ca               
mkdir -p /etc/ocserv/ssl/server           
mkdir -p /etc/ocserv/ssl/user             
mkdir -p /etc/ocserv/ssl/crl              
```

- `private` 保存服务器私钥
- `ca`      保存CA证书
- `server`  保存服务器证书
- `user`    保存用户证书
- `crl`     保存用户吊销证书链

##### 创建自签CA

创建自签名CA私钥

```bash
cd /etc/ocserv/ssl/private
certtool --generate-privkey --outfile ca-key.pem
```

创建自签CA模版，其中$1为参数，该参数为本机的域名或者IP，如果以域名登录，例如VPS域名为`test.com`，则`cn="test.com"`，organization字段随意填写，可以和cn一样，然后生成CA模版。

```bash
cd /etc/ocserv/ssl/ca
cat << EOF > ca.tmpl
  cn = "test.com"
  organization = "test.com"
  serial = 1
  expiration_days = 3650
  ca
  signing_key
  cert_signing_key
  crl_signing_key
EOF
```

创建CA

```bash
cd /etc/ocserv/ssl/ca
certtool --generate-self-signed --load-privkey ../private/ca-key.pem \
--template ca.tmpl --outfile ca-cert.pem
```

##### 创建服务器证书

创建服务器私钥

```bash
cd /etc/ocserv/ssl/private
certtool --generate-privkey --outfile server-key.pem
```

创建服务器模板，其中$1为参数，该参数为本机的域名或者IP，如果以域名登录，例如VPS域名为`test.com`，则`cn="test.com"`，organization字段随意填写，可以和cn一样，然后生成服务器证书模板

```bash
cd /etc/ocserv/ssl/server
cat << EOF > server.tmpl
  cn = "test.com"
  organization  = "test.com"
  expiration_days = 3650
  signing_key
  encryption_key 
  tls_www_server
EOF
```

生成服务器证书

```bash
cd /etc/ocserv/ssl/server
certtool --generate-certificate --load-privkey ../private/server-key.pem  \
--load-ca-certificate ../ca/ca-cert.pem --load-ca-privkey ../private/ca-key.pem \
--template server.tmpl --outfile server-cert.pem
```

自签名服务器证书在此配置完成。

####  使用授权证书

##### 申请证书

授权证书可以从[沃通](https://buy.wosign.com/)或者[startssl](https://startssl.com)、[Let's Encrypt](https://letsencrypt.org/)等申请免费的ssl证书。申请证书的大概流程为：

- CSR文件为请求证书的文件，会产生一对公私钥，公钥（pub-key）需要上传给证书颁发结构，私钥（private-key）则要自己保留不能泄露。
- 证书颁发结构需要要验证申请人的域名拥有权，证明域名拥有权之后，使用其私钥（signature private-key）申请人上传的pub-lkey进行签名，并把域名等证书信息追加到其中，产生一个证书，例如2_dovzinp3.icean.xxx.crt
- 终端用户并不信任这个证书，鉴于这个证书不是权威机构颁发，所以需要证书链，来证明颁发该证书的结构是权威机构认证的。
- 证书链为颁发2_dovzinp3.icean.me.crt证书的结构，其上级机构对其公钥进行签名，逐级进行签名，直到顶级CA。

##### 安装证书

下载证书的压缩文件包中，解压OtherServer，以startssl为例子，解压出如下图所示。


<center>![](http://i.imgur.com/aUSEeOG.png)</center>

<center style="color:purple">**图1-1 授权证书**</center>

假定现在证书的路径仍和自签时候相同，服务器私钥为生成CSR文件所用的私钥

```bash
mv xxx.key server-key.pem
mv server-key.pem /etc/ocserv/ssl/private
```

创建服务器证书，根据证书链的顺序，首先追加服务器证书，然后追加中间证书，最后追加CA证书。

```bash
cat 2_dovzinp3.icean.me.crt >> server-cert.pem
cat 1_Intermediate.crt >> server-cert.pem
cat root.crt >> server-cert.pem
mv server-cert.pem /etc/ocserv/ssl/server
```

ocserv配置

####  配置文件修改

备份原配置文件

```bash
cd /etc/ocserv
mv ocserv.conf ocserv.conf.bak
```

创建新的配置文件，no-route列表过长，只是部分给出。

```bash
cat << EOF >/etc/ocserv/ocserv.conf
    #auth = "plain[/etc/ocserv/passwd]"
    #本地账户密码验证      
    #auth = "certificate
    #证书验证
    #ca-cert /etc/ocserv/ssl/ca/ca-cert.pem
    #CA证书路径
    #crl = /etc/ocserv/ssl/crl/crl.pem
    #吊销证书链
    
    #auth = "radius[config=/etc/radiusclient/radiusclient.conf,groupconfig=true]"
    # acct = "radius[config=/etc/radiusclient/radiusclient.conf]"
    #审计采用radius
    #stats-report-time = 360
    #发送审计报告时间间隔
    
    max-clients = 16
    max-same-clients = 1
    tcp-port = 443
    udp-port = 443
    keepalive = 32400
    dpd = 90
    mobile-dpd = 1800
    try-mtu-discovery = true
    cisco-client-compat = true
    server-cert = /etc/ocserv/ssl/server/server-cert.pem
    #服务器证书存储路径
    server-key = /etc/ocserv/ssl/private/server-key.pem
    #服务器私钥存储路径
    auth-timeout = 40
    pid-file = /var/run/ocserv.pid
    socket-file = /var/run/ocserv-socket
    run-as-user = nobody
    run-as-group = daemon
    device = vpns
    ipv4-network = 192.168.80.0
    ipv4-netmask = 255.255.255.0
    ipv6-network = 2001:cc0:2020:4008:2333::
    ipv6-prefix = 80
    ipv6-dns = 2001:4860:4860::8888
    ipv6-dns = 2001:4860:4860::8844
    dns = 8.8.8.8
    dns = 8.8.4.4
    no-route = 1.0.0.0/255.192.0.0
    no-route = 1.64.0.0/255.224.0.0
EOF
```
##### 本地账户密码验证

此时ocserv.conf前面部分应该为如下所示

```bash
auth = "plain[/etc/ocserv/passwd]"
#本地账户密码验证      
#auth = "certificate
#证书验证
#ca-cert /etc/ocserv/ssl/ca/ca-cert.pem 
#CA证书路径
#crl = /etc/ocserv/ssl/crl/crl.pem
#吊销证书链

#auth = "radius[config=/etc/radiusclient/radiusclient.conf,groupconfig=true]"
#acct = "radius[config=/etc/radiusclient/radiusclient.conf]"
#审计采用radius
#stats-report-time = 360
#发送审计报告时间间隔
```

需要安装httpd-tools工具

```bash
yum install -y httpd-tools
```

创建账户密码，新添加用户也需要执行下面命令，不可省略`-c`，存储帐号密码文件需路径与配置文件中一致。

```bash
ocpasswd -c /etc/ocserv/passwd username
```

##### 证书验证

此时ocserv.conf前面部分应该为如下所示

```bash
#auth = "plain[/etc/ocserv/passwd]"
#本地账户密码验证      
auth = "certificate
#证书验证
ca-cert /etc/ocserv/ssl/ca/ca-cert.pem 
#CA证书路径
crl = /etc/ocserv/ssl/crl/crl.pem
#吊销证书链

#auth = "radius[config=/etc/radiusclient/radiusclient.conf,groupconfig=true]"
#acct = "radius[config=/etc/radiusclient/radiusclient.conf]"
#审计采用radius
#stats-report-time = 360
#发送审计报告时间间隔
```

使用证书登录不需要每次输入登录密码，在客户端导入证书即可，首先生成用户私钥

```bash
cd /etc/ocserv/ssl/private
certtool --generate-privkey --outfile user-key.pem
```

创建用户模版

```bash
cat << EOF > user.tmpl
  cn = "test.com"
  unit = "test.com"
  expiration_days = 365
  signing_key
  tls_www_client
EOF
```

生成用户证书

```bash
certtool --generate-certificate --load-privkey ../private/user-key.pem \
--load-ca-certificate ca-cert.pem --load-ca-privkey ../private/ca-key.pem \
--template user.tmpl --outfile user-cert.pem
#将用户证书和密钥打包为p12格式，在此过程中，需要输入名称和密码，在安装证书时，需要输入该密码进行验证。
certtool --to-p12 --load-privkey ../private/user-key.pem --pkcs-cipher \ 
3des-pkcs12 --load-certificate user-cert.pem --outfile user-cert.p12 --outder
```

批量创建用户证书脚本如下所示，其中需要一个user.tmpl文件。

```bash
#定义变量
usr=icean
id=ic-iPhone
day=365

#最后相关的文件被放置在以id为名称的文件夹中
mkdir $id
cp user.tmpl $id.tmpl
sed -i "s/example-cn/$id/g" $id.tmpl
sed -i "s/example-unit/$usr/g" $id.tmpl
sed -i "s/1024/$day/g" $id.tmpl
certtool --generate-privkey --outfile $id-key.pem
certtool --generate-certificate --load-privkey $id-key.pem \
--load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
--template $id.tmpl --outfile $id-cert.pem
certtool --to-p12 --load-privkey $id-key.pem --pkcs-cipher 3des-pkcs12 \
--load-certificate $id-cert.pem --outfile $id-cert.p12 --outder
mv $id* $id
```

##### 吊销证书

创建空吊销列表密钥文件

```bash
cd /etc/ocserv/ssl/crl
touch revoked.pem
```

创建吊销证书模板

```bash
cat << EOF > crl.tmpl
  crl_next_update = 9999
  crl_number = 1
EOF
```

使用certtool创建空的吊销列表，当revoked.pem为空时，执行如下命令生成crl.pem文件。

```bash
certtool --generate-crl --load-ca-privkey ../private/ca-key.pem \
--load-ca-certificate ../ca/ca-cert.pem --template crl.tmpl --outfile crl.pem
```

吊销一个用户，假设吊销用户为user1，首先将其证书追加到revoked.pem，然后生成新的吊销证书链文件crl.pem

```bash
cat ../user/user1/user1-cert.pem >> revoked.pem
certtool --generate-crl --load-ca-privkey ../private/ca-key.pem \
--load-ca-certificate ../ca/ca-cert.pem --load-certificate revoked.pem \
--template crl.tmpl --outfile crl.pem
```

若想重新启用一个被吊销的用户，则需要删除revoked.pem其中对应的密钥，然后重新生成吊销证书crl.pem,若revoke.pem被清空，则生成的时候不添加`--load-certificate`参数。吊销或者重新启用被吊销的证书时需要重启ocserv服务。

完整CA添加/吊销/重新启用脚本请点击[这里](http://pan.baidu.com/s/1o7Z55Om)

----------

### 2.其他设置

####  iptables设置

在CentOS下，首先禁用Firewall

~~~bash
service firewalld stop
chkconfig firewalld off
~~~

安装iptables并添加到开机启动

~~~bash
yum install -y iptables-services
service iptables start
chkconfig iptables on
chkconfig ip6ables on
~~~

添加如下条目到iptables和ip6tables，并保存。

```bash
iptables -I INPUT 2 -p tcp --dport 443 -j ACCEPT
iptables -I INPUT 3 -p udp --dport 443 -j ACCEPT
iptables -I FORWARD 1  -j ACCEPT
ip6tables -I FORWARD 1  -j ACCEPT
iptables -t nat -A POSTROUTING -s  192.168.80.0/24 -o eth0 -j MASQUERADE   #转发ocserv虚拟子网
iptables-save > /etc/sysconfig/iptables
ip6tables-save > /etc/sysconfig/ip6tables
```

####  系统转发设置

开启IPv4和IPv6转发

```bash
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
```

----

### 3.freeradius 设置 ###

####  ocserv配置文件

此时ocserv.conf前面部分应该为如下所示

```bash
#auth = "plain[/etc/ocserv/passwd]"
#本地账户密码验证      
#auth = "certificate
#证书验证
#ca-cert /etc/ocserv/ssl/ca/ca-cert.pem 
#CA证书路径
#crl = /etc/ocserv/ssl/crl/crl.pem
#吊销证书链

auth = "radius[config=/etc/radiusclient/radiusclient.conf,groupconfig=true]"
acct = "radius[config=/etc/radiusclient/radiusclient.conf]"
#审计采用radius
stats-report-time = 360
#发送审计报告时间间隔
```

- groupconfig在配置文件的auth选项中去掉，否则freeradius的验证组radgroupreply属性只能添加**'Auth-Type',':=','Local'**, **acct字段为向freeradius服务器发送审计日志**，否则ocserv只有在建立VPN连接之初与freeradius服务器进行验证用户的有效性，**stats-report-time**字段定义了向freeradius服务器发送审计日志的时间间隔。
- groupconfig在配置文件的auth选项保留时，这时候需要在radius服务器的数据库插入IP、DNS等信息。 同时max-same->clients的应用灵敏度也提高了，之前不开启groupconfig时，max-same-clients的反应灵敏度有问题
- 不使用udp端口，可以提高下载速度，但是上传速度下降
- 经过验证，ocserv不能使用本地freeradius服务器进行验证,密码不匹配。

####  freeradius客户端安装 ####
安装freeradius客户端以及工具

```bash
yum install freeradius-client freeradius-utils -y
```

####  freeradius客户端配置 ####

变量设置，serverHostname为freeradius服务器hostname，serverIP为其IP地址，secret为共享的密钥。
```bash
serverHostname=$1
serverIP=$2
secret=$3
```

向hosts文件中添加freeradius服务器地址解析

```bash
echo "$serverIP $serverHostname">> /etc/hosts
```

向freeradius server配置文件中追加freeradius服务器hostname

```bash
echo "$serverHostname/$serverHostname $secret" >> /etc/radiusclient/servers
```

备份配置文件，将验证服务器从localhost改为其他，如果是时本地freeradius服务器，不需要修改

```bash
cd /etc/radiusclient
cp radiusclient.conf radiusclient.conf.bak
sed -i 's/localhost/$serverHostname/g' radiusclient.conf
```

修改字典原来路径/usr/share/radiusclient为/etc/radiusclient

```bash
sed -i 's/usr\/share/etc/g' radiusclient.conf
```
其他修改，具体原因不了解

```bash
sed -i 's/radius_deadtime/#radius_deadtime/g' radiusclient.conf
sed -i 's/bindaddr */#bindaddr */g' radiusclient.conf
```


下载字典，并修改字典文件，注释掉所有dictionary中带IPv6的条目，否则会报错
```bash
cd /etc/radiusclient
wget http://qingdao.icean.cc:11234/dictionary.microsoft
cp /usr/share/radiusclient/dictionary.merit ./
cp dictionary dictionary.bak 

cat << EOF >> /etc/radiusclient/dictionary
  INCLUDE /etc/radiusclient/dictionary.microsoft
  INCLUDE /etc/radiusclient/dictionary.merit 
EOF
```

####  freeradius服务器配置 ####

变量设置，clientHostname为配置ocserv服务的hostname，clientIP为其IP地址，secret为共享密钥

```bash
clientHostname= $1
clientIP=$2
secret=$3
```

添加客户端地址解析到hosts文件

```bash
echo "$clientIP $clientHostname">> /etc/hosts
```

添加设置到clients.conf

```bash
cat << EOF >> /etc/raddb/clients.conf
client $clientHostname {
	ipaddr = $clientIP
	secret= $secret
	require_message_authenticator = no
	nas_type = other 
} 
EOF
```

服务器端mysql插入相应的验证条目，验证类型为本地，服务种类为Frame-User，其中Acct-Interim-Interval为统计流量的时间间隔，Max-Monthly-Traffic为每个月最大流量，这里以MB为准。**在freeradius3中，不能添加更多属性，否则无法验证成功，这个问题有待探究。**


```sql
insert into radgroupreply (groupname,attribute,op,value) values ('ocserv','Auth-Type',':=','Local'); 
insert into radgroupreply (groupname,attribute,op,VALUE) VALUES ('ocserv','Acct-Interim-Interval',':=','600');
insert into radgroupreply (groupname,attribute,op,VALUE) VALUES ('ocserv','Max-Monthly-Traffic',':=','1024');
```

Max-Monthly-Traffic为用户自定义变量，需要在/etc/raddb/dictionary 中添加如下条目。

```bash
ATTRIBUTE Max-Monthly-Traffic 3003 integer
ATTRIBUTE  Monthly-Traffic-Limit  3004    integer
```

账户和密码

```sql
insert into radcheck (username,attribute,op,value) values ('ociPhone','Cleartext-Password',':=','test');
```

将账号加入对应的用户组

```sql
insert into radusergroup (username,groupname) values ('ociPhone','ocserv');
```
切换到/etc/raddb/mods-enabled/目录下，建立sqlcounter的软链接，启用sqlcounter模块。

```bash
cd /etc/raddb/mods-enabled/
ln -s ../sqlcounter
```

添加新的计数器

```bash
sqlcounter monthlytrafficcounter {
    sql_module_instance = sql                                                                                                                
    dialect = ${modules.sql.dialect}

    counter_name = Monthly-Traffic               #计数器名字，可以任意填写
    check_name = Max-Monthly-Traffic          #限制最大流量
    reply_name = Monthly-Traffic-Limit          #回复给客户端

    key = User-Name
    reset = monthly

    $INCLUDE ${modconfdir}/sql/counter/${dialect}/${.:instance}.conf
}
```

切换到/etc/raddb/mods-config/sql/counter/mysql目录下，添加与计数器同名的配置文件，变量如下

- ${key}  与计数器中的key属性队形
- %b 为计数的起始时间，若reset为monthly，则为当前时间的月份第一天，其数值为标准UNIX时间
- %e 为计数的结束时间，若reset为monthly，则为当前时间的月份最后一天，其数值为标准UNIX时间

```bash
cd /etc/raddb/mods-config/sql/counter/mysql
cat << EOF >monthlytrafficcounter.conf
 query = "\
	 SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 \     #1MB字节数，radacct按照字节统计的。
          FROM radacct \
         WHERE UserName='%{${key}}' \
         AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
EOF
```

在/etc/raddb/sites-enabled/default中启用monthlytrafficcounter模块，在authenticate字段中，添加monthlytrafficcounter，然后重启radius服务

```bash
authenticate{
  	monthlytrafficcounter
}
```

----------

### 4. 启动服务###
启动ocserv服务，在终端进行测试，使用在freeradius服务器端配置的账号和密码进行登陆。

```bash
service ocserv start
```
----------------------------------------------------------------

### 5. 问题拓展

- ocserv验证对应的radgroupreply无法添加更多属性。

- ocserv验证对应的radgroupcheck中Simultaneous-Use，限制同时在线人数属性不生效，验证pptp时候也如此。

- nas-identifier验证没解决，解决如何分辨多台nas，使其只能使用特定的账户验证，而不是可以使用数据库中所有的验证条目。

- ocserv证书验证能否使用freeradius？

  ​