---
title: CentOS 6.x ocserv 安装
date: 2017/1/18 9:07:14 
description: OpenConnect server (ocserv)以一款SSL VPN服务。它的目的是构建安全、小巧、快速以及容易配置的VPN服务器。它实现了OpenConnect SSL VPN协议，并且也兼容AnyConnect SSL VPN协议客户端。OpenConnect协议提供了基于TCP/UDP的双重VPN隧道，使用标准的IETF加密协议。该服务主要面向GNU/Linux平台。
categories: 技术
tags: [ocserv,vpn,linux]
---

### 1. ocserv

#### 1.1 介绍

OpenConnect server (ocserv)以一款SSL VPN服务。它的目的是构建安全、小巧、快速以及容易配置的VPN服务器。它实现了OpenConnect SSL VPN协议，并且也兼容AnyConnect SSL VPN协议客户端。OpenConnect协议提供了基于TCP/UDP的双重VPN隧道，使用标准的IETF加密协议。该服务主要面向GNU/Linux平台。

#### 1.2 yum安装ocserv

现在可以使用yum安装ocserv

~~~bash
yum install -y epel-release
yum install -y ocserv
~~~

-----

### 2. 证书安装

#### 2.1 配置文件夹创建

ocserv服务的启动需要相关证书，为了方便管理，首先在配置文件夹中创建一些文件夹

```bash
mkdir -p /etc/ocserv/ssl/private          #保存服务器私钥
mkdir -p /etc/ocserv/ssl/ca                 #保存CA
mkdir -p /etc/ocserv/ssl/server           #保存服务器证书
mkdir -p /etc/ocserv/ssl/user              #保存用户证书
mkdir -p /etc/ocserv/ssl/crl                 #保存用户吊销证书链
```

#### 2.2 使用自签证书

##### 2.2.1 CA证书生成

生成CA私钥

```bash
cd /etc/ocserv/ssl/private
certtool --generate-privkey --outfile ca-key.pem
```

生成CA模板，cn和o选项填入任意域名，本文以test.com代替。

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

CA证书生成

```bash
certtool --generate-self-signed --load-privkey ../private/ca-key.pem --template \
ca.tmpl --outfile ca-cert.pem
```

##### 2.2.2 Server证书生成

生成Server私钥

```bash
cd /etc/ocserv/ssl/private
certtool --generate-privkey --outfile server-key.pem
```

生成Server证书模板，cn和o选项填入ocserv服务器的域名，本文以test.com代替。

```bash
cd /etc/ocserv/ssl/server
cat << EOF > server.tmpl
cn = "test.com"
organization = "test.com"
expiration_days = 3650
signing_key
encryption_key 
tls_www_server
EOF
```

生成Server证书：

```bash
certtool --generate-certificate --load-privkey ../private/server-key.pem  \
--load-ca-certificate ../ca/ca-cert.pem --load-ca-privkey ../private/ca-key.pem \
--template server.tmpl --outfile server-cert.pem
```

#### 2.3 使用授权证书

##### 2.3.1 申请证书

授权证书可以从[沃通](https://buy.wosign.com/)或者[startssl](https://startssl.com)、[Let's Encrypt](https://letsencrypt.org/)等申请免费的ssl证书。申请证书的大概流程为：

- CSR文件为请求证书的文件，会产生一对公私钥，公钥（pub-key）需要上传给证书颁发结构，私钥（private-key）则要自己保留不能泄露。
- 证书颁发结构需要要验证申请人的域名拥有权，证明域名拥有权之后，使用其私钥（signature private-key）申请人上传的pub-lkey进行签名，并把域名等证书信息追加到其中，产生一个证书，例如`2_dovzinp3.icean.me.crt`
- 终端用户并不信任这个证书，鉴于这个证书不是权威机构颁发，所以需要证书链，来证明颁发该证书的结构是权威机构认证的。
- 证书链为颁发`2_dovzinp3.icean.me.crt`证书的结构，其上级机构对其公钥进行签名，逐级进行签名，直到顶级CA。

##### 2.3.2 安装证书

下载证书的压缩文件包中，解压OtherServer，以startssl为例子，解压出如下图所示。

<center>![](http://i.imgur.com/aUSEeOG.png)</center>

<center style="color:purple">**图2-1 授权证书**</center>

服务器私钥为生成CSR文件所用的私钥

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

---

### 3. 主要配置

#### 3.1 配置文件备份&修改

备份原配置文件

```bash
cd /etc/ocserv
mv ocserv.conf ocserv.conf.bak
```

创建新的配置文件`ocserv.conf`，内容如下，缺省验证方式为账户密码验证

```bash
auth = "plain[/etc/ocserv/passwd]"                                            #本地账户密码验证      
#auth = "certificate"                                                                    #证书验证
#auth = "radius[config=/etc/radcli/radiusclient.conf,groupconfig=true]"  
                                                                                                     #radius验证
#acct = "radius[config=/etc/radcli/radiusclient.conf]"                #radius审计

stats-report-time = 360                                                               #发送审计报告时间间隔
max-clients = 16
max-same-clients = 1
tcp-port = 443                                                                            #连接端口号，可以修改为其他端口
udp-port = 443                                                                           #连接端口号，可以修改为其他端口
keepalive = 32400
dpd = 90
mobile-dpd = 1800
try-mtu-discovery = true
cisco-client-compat = true
#ca-cert /etc/ocserv/ssl/ca/ca-cert.pem                                      #CA证书路径
server-cert = /etc/ocserv/ssl/server/server-cert.pem                  #服务器证书存储路径
server-key = /etc/ocserv/ssl/private/server-key.pem                  #服务器私钥存储路径
#crl = /etc/ocserv/ssl/crl/crl.pem                                                 #吊销证书链
auth-timeout = 40
pid-file = /var/run/ocserv.pid
socket-file = /var/run/ocserv-socket
run-as-user = nobody
run-as-group = daemon
device = vpns
ipv4-network = 192.168.80.0                                                       #虚拟IP地址段，分配给VPN客户端
ipv4-netmask = 255.255.255.0                                                    #虚拟IP掩码
dns = 8.8.8.8                                                                                #DNS地址
dns = 8.8.4.4

#no-route = 1.0.0.0/255.192.0.0                                                   #不路由某些地址
#route = 1.64.0.0/255.224.0.0                                                      #只路由某些地址，no-route和route不可同时用
```

#### 3.2 route & no-route

如果需要指定客户端只能路由到某些地址，则需要在配置文件`ocserv.conf`中添加如下样例

~~~
route = 192.168.1.0/255.255.255.0
~~~

如果需要指定客户端不需要路由到某些地址，则需要在配置文件`ocserv.conf`中添加如下样例

~~~
no-route = 192.168.1.0/255.255.255.0
~~~

两者不可同时使用

#### 3.3 账户密码验证

在配置文件`ocserv.conf`中修改，如下所示

~~~bash
auth = "plain[/etc/ocserv/passwd]"  
#auth = "certificate" 
#auth = "radius[config=/etc/radcli/radiusclient.conf,groupconfig=true]"  
#acct = "radius[config=/etc/radcli/radiusclient.conf]"   
.......
~~~

创建登录用户以及密码，每次创建用户，都需要参数c

	ocpasswd -c /etc/ocserv/passwd username
#### 3.4 radius验证

在配置文件中`ocserv.conf`修改如下, 其中radius客户端配置路径为`/etc/radcli`，在安装ocserv时候，radcli作为依赖被安装

~~~bash
#auth = "plain[/etc/ocserv/passwd]"  
#auth = "certificate" 
auth = "radius[config=/etc/radcli/radiusclient.conf,groupconfig=true]"  
acct = "radius[config=/etc/radcli/radiusclient.conf]"   
.......
~~~

添加radius服务器，修改`/etc/radcli/servers`，例如添加本机作为radius服务器，如下所示。也可以按照格式添加其他的radius服务器

~~~bash
localhost/localhost  testing123   #验证服务器/审计服务器  服务器暗码
~~~

修改配置文件`/etc/radcli/radiusclient.conf`，选择要使用的验证服务器以及审计服务器，如下为使用localhost作为验证和审计服务器，其他选项不需要修改。

~~~bash
authserver  localhost
acctserver  localhost
~~~

#### 3.5 证书验证

##### 3.5.1 用户证书生成

使用账户密码以及radius验证，接入的客户端需要每次输入账户名和密码，而证书验证则不需要每次输入账户名和密码。第一次在客户端导入证书即可。

使用certtool生成用户私钥

```bash
cd /etc/ocserv/ssl/private
certtool --generate-privkey --outfile user-key.pem
```

创建用户模板

```bash
cat << EOF > user.tmpl
cn = "example-cn"
unit = "example-unit"
expiration_days = 365
signing_key
tls_www_client
EOF
```

生成用户证书

```bash
#生成用户证书
cd  /etc/ocserv/ssl/user
certtool --generate-certificate --load-privkey ../private/user-key.pem \
--load-ca-certificate ca-cert.pem --load-ca-privkey ../private/ca-key.pem \
--template user.tmpl --outfile user-cert.pem

#将用户证书和密钥打包为p12格式，在此过程中，需要输入名称和密码，在安装证书时，需要输入该密码进行验证。
certtool --to-p12 --load-privkey ../private/user-key.pem --pkcs-cipher \ 
3des-pkcs12 --load-certificate user-cert.pem --outfile user-cert.p12 --outder
```

自动生成证书脚本，运行下面脚本之前，请确认当前目录下有`user.tmpl`，`ca-key.pem`，`ca-cert.pem`三个文件，或者自己命令中的路径参数。

```bash
#!/bin/bash

#定义变量
id=test
day=365

cd  /etc/ocserv/ssl/user
cp user.tmpl $id.tmpl
sed -i "s/example-cn/$id/g" $id.tmpl
sed -i "s/example-unit/$id/g" $id.tmpl
sed -i "s/365/$day/g" $id.tmpl
certtool --generate-privkey --outfile $id-key.pem
certtool --generate-certificate --load-privkey $id-key.pem \
--load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
--template $id.tmpl --outfile $id-cert.pem
certtool --to-p12 --load-privkey $id-key.pem --pkcs-cipher 3des-pkcs12 \
--load-certificate $id-cert.pem --outfile $id-cert.p12 --outder

#最后所有相关的文件放入名字为$id的文件夹中
mkdir $id
mv $id* $id
```

##### 3.5.2 用户证书吊销 #####

创建空吊销列表文件

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

创建空的吊销列表，当`revoked.pem`为空时，执行如下命令生成吊销证书链文件`crl.pem`。

```bash
certtool --generate-crl --load-ca-privkey ../private/ca-key.pem \
--load-ca-certificate ../ca/ca-cert.pem --template crl.tmpl --outfile crl.pem
```

吊销一个用户，假设要吊销用户证书为user1，首先将其用户证书追加到`revoked.pem`，然后生成新的吊销证书链文件`crl.pem`

```bash
cd /etc/ocserv/ssl/crl
cat ../user/user1/user1-cert.pem >> revoked.pem
certtool --generate-crl --load-ca-privkey ../private/ca-key.pem \
--load-ca-certificate ../ca/ca-cert.pem --load-certificate revoked.pem \
--template crl.tmpl --outfile crl.pem
```

若想重新启用一个被吊销的用户，则需要删除`revoked.pem`其中对应用户证书的密钥，然后重新生成吊销证书链文件`crl.pem`，若revoke.pem被清空，则生成的时候不添加`--load-certificate`参数

完整CA添加/吊销/重新启用脚本请点击[这里](http://pan.baidu.com/s/1o7Z55Om)

----------

### 4. ocserv服务启动###
#### 4.1 开启系统转发####
编译/etc/sysctl.conf，开启IPv4转发，启用此项

```bash
net.ipv4.ip_forward=1
```

并刷新配置

```bash
sysctl -p /etc/sysctl.conf
```
#### 4.2 iptables配置####
添加条目到iptables，端口号为配置文件定义的，下面以443为例，同时添加转发表条目

```bash
iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
iptables -I INPUT 1 -p udp --dport 443 -j ACCEPT
iptables -I FORWARD 1  -j ACCEPT
```

根据需要，设定要访问的网络，例如如果要VPN终端用户要访问服务器eth0网段的网卡，则添加如下条目，访问eth1的添加规则类似

```bash
iptables -t nat -A POSTROUTING -s  192.168.80.0/24 -o eth0 -j MASQUERADE
```

保存并重启iptables

```bash
service iptables save
service iptables restart
```

#### 4.3 ocserv服务启动 ####

启动ocserv服务，然后终端用户可以通过思科Anyconnect客户端进行连接。

```bash
service ocserv start
```



