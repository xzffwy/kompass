---
title: CentOS 6.x/7.x Strongswan 5.5.0编译安装 + Freeradius验证
date: 2017/1/26 9:49:19 
description: 在CentOS 6或者CentOS 7上编译安装Strongswan 5.5.0，并配置Freeradius进行验证
categories: 技术
tags: [IKEv2,Strongswan,vpn,linux]
---

### 1. 编译安装Strongswan
#### 环境准备
需要安装如下依赖
~~~bash
yum -y install pam-devel
~~~

可能还需要安装如下依赖

~~~bash
 yum install -y openssl-devel make gcc curl wget 
~~~

#### 下载源码

从[Strongswan](https://www.strongswan.org/)官网下载最新Strongswan 5.5.1源码到并解压

~~~bash
wget https://download.strongswan.org/strongswan-5.5.1.tar.gz
tar xvf strongswan-5.5.1.tar.gz
~~~

####  编译安装
切换到Strongswan源码解压的目录，执行配置与编译安装
~~~bash
cd strongswan-5.5.1
./configure  --enable-eap-identity --enable-eap-md5 --enable-eap-mschapv2 --enable-eap-tls \
--enable-eap-ttls --enable-eap-peap --enable-eap-tnc --enable-eap-dynamic --enable-eap-radius \
--enable-xauth-eap --enable-xauth-pam  --enable-dhcp  --enable-openssl  --enable-addrblock --enable-unity  \
--enable-certexpire --enable-radattr --enable-swanctl --enable-openssl --disable-gmp --enable-farp \
--enable-kernel-libipsec  #如果主机为OpenVZ则需要添加这个模块
make && make install
~~~

根据主机性能，完成上述编译安装需要的时间不同。安装完成后，可执行文件的路径为/usr/local/sbin, 配置文件路径为/usr/local/etc，配置文件以及文件夹主要如下

- ipsec.conf              
- ipsec.secrets
- **ipsec.d**
- strongswan.conf
- **strongswan.d**
- **swanctl**

----------

### 2. 证书配置
#### Let's Encrypt免费服务器证书
Let's Encrypt是免费、自动化、开放的证书签发服务。它由 ISRG（Internet Security Research Group，互联网安全研究小组）提供服务，而 ISRG 是来自于美国加利福尼亚州的一个公益组织。Let's Encrypt 得到了 Mozilla、Cisco、Akamai、Electronic Frontier Foundation 和 Chrome 等众多公司和机构的支持。申请 Let's Encrypt 证书免费，每次只有 90 天的有效期，但可以通过脚本定期更新。

##### 生成证书
下载Let's Encrypt并执行生成证书。在执行过程中，会下载一些依赖，同时在提示输入域名的时候，要和主机的域名一致。
~~~bash
git clone https://github.com/letsencrypt/letsencrypt
cd letsencrypt
./letsencrypt-auto certonly --standalone
~~~

##### 安装证书

生成的证书和证书私钥位于 `/etc/letsencrypt/live/your.domain/` 目录下，如下所示，所有文件均是软链接，其原始文件后的数字为证书生成的次数，首次生成为1，每续期一次，数字加一，下面的为续期了两次的证书。

~~~bash
lrwxrwxrwx 1 root root 36 Dec  3 09:30 cert.pem -> ../../archive/[域名]/cert3.pem
lrwxrwxrwx 1 root root 37 Dec  3 09:30 chain.pem -> ../../archive/[域名]/chain3.pem
lrwxrwxrwx 1 root root 41 Dec  3 09:30 fullchain.pem -> ../../archive/[域名]/fullchain3.pem
lrwxrwxrwx 1 root root 39 Dec  3 09:30 privkey.pem -> ../../archive/[域名]/privkey3.pem
~~~

建立软链到 strongSwan 配置目录下，这样是为了方便证书续期也不用修改配置文件

~~~bash
ln -s /etc/letsencrypt/live/your.domain/fullchain.pem /etc/ipsec.d/certs/server.cert.pem
ln -s /etc/letsencrypt/live/your.domain/privkey.pem /etc/ipsec.d/private/server.key.pem
~~~

##### 证书自动续期

letsencrypt证书需要每三个月进行续期一次证书，续期命令如下，每隔两个月的4号进行一次证书续期

~~~bash
crontab -e
 * * 4 */2 * /root/letsencrypt/letsencrypt-auto  --renew-by-default  certonly --standalone -d [域名] --email [邮箱]  --agree-tos
~~~

#### 自签名CA颁发服务器证书
##### CA证书
生成一个CA私钥

~~~bash
ipsec pki --gen --outform pem > ca.key.pem
~~~

基于私钥生成一个CA证书
~~~bash
ipsec pki --self --in ca.key.pem --dn "C=CN, O=Strongswan, CN=Strongswan CA" --ca --lifetime 3650 --outform pem > ca.cert.pem
~~~
- --self 表示自签证书
- --in 是输入的私钥
- --dn 是判别名
- C 表示国家名，同样还有 ST 州/省名，L 地区名，STREET（全大写） 街道名
- O 组织名称
- CN 友好显示的通用名
- –ca 表示生成 CA 根证书
- –lifetime 为有效期, 单位是天

##### 服务器证书
生成服务器证书的私钥
~~~bash
ipsec pki --gen --outform pem > server.key.pem
~~~

用自签的 CA 证书签发一个服务器证书
~~~bash
ipsec pki --pub --in server.key.pem --outform pem > server.pub.pem
ipsec pki --issue --lifetime 1200 --cacert ca.cert.pem --cakey ca.key.pem --in server.pub.pem \
--dn "C=CN, O=Strongswan, CN=vpn.strongswan.org" --san="vpn.strongswan.org" --flag serverAuth \
--flag ikeIntermediate --outform pem > server.cert.pem
~~~

--issue, --cacert 和--cakey 就是表明要用刚才自签的 CA 证书来签这个服务器证书，--dn, --san，--flag 是一些客户端方面的特殊要求：

- iOS 客户端要求 CN 也就是通用名必须是服务器的 URL 或 IP 地址;
- Windows 7 或者更高版本不但要求了上面，还要求必须显式说明这个服务器证书的用途（用于与服务器进行认证），--flag serverAuth;
- 非 iOS 的 Mac OS X 要求了“IP 安全网络密钥互换居间（IP Security IKE Intermediate）”这种增强型密钥用法（EKU），–flag ikdeIntermediate;
- Android 和 iOS 都要求服务器别名（serverAltName）就是服务器的 URL 或 IP 地址，即是--san，同时Windows 7不能添加额外的服务器别名，Windows 10可以添加

<span style="color:red">*****</span>为了兼容Windows 7，只添加一个服务器别名（serverAltName）

##### 客户端证书（可选）
生成客户端私钥
~~~bash
ipsec pki --gen --outform pem > client.key.pem
~~~

用自签的CA证书来签发客户端证书
~~~bash
ipsec pki --pub --in client.key.pem --outform pem > client.pub.pem
ipsec pki --issue --lifetime 1200 --cacert ca.cert.pem --cakey ca.key.pem --in client.pub.pem \
--dn "C=CN, O=Strongswan, CN=vpn.strongswan.org" --outform pem > client.cert.pem
~~~

打包证书为 p12，生成 p12 证书可以设置密码，<span style="color:red">*****</span>OS X 无法导入密码为空的 p12 证书
~~~bash
openssl pkcs12 -export -inkey client.key.pem -in client.cert.pem -name "Strongswan Client Cert" \
-certfile ca.cert.pem -caname "Strongswan CA" -out client.cert.p12
~~~

##### 安装证书
复制证书到指定的路径
~~~bash
cp ca.key.pem /usr/local/etc/ipsec.d/private/
cp client.key.pem /usr/local/etc/ipsec.d/private/
cp server.key.pem /usr/local/etc/ipsec.d/private/
cp server.cert.pem /usr/local/etc/ipsec.d/certs/
cp client.cert.pem /usr/local/etc/ipsec.d/certs/
cp ca.cert.pem /usr/local/etc/ipsec.d/cacerts/
~~~

----------
### 3. Strongswan配置 ###
#### ipsec.conf配置
支持IPsec和ikev2的配置如下所示， 常用设置如下
~~~bash
cachecrls = yes					#是否缓存证书吊销列表
strictcrlpolicy=yes				    #是否严格执行证书吊销规则
uniqueids=no				    #如果同一个用户在不同的设备上重复登录,yes 断开旧连接,创建新连接;no 保持旧
  							   #连接,并发送通知; never 同 no, 但不发送通知.
ca %default					     #配置根证书, 如果不使用证书吊销列表, 可以不用这段. 命名为 %default 所有配置
  							   #节都会继承它
crl =						    #证书吊销列表URL,可以是 LDAP, http, 或文件路径
conn %default				     #定义连接项, 命名为 %default 所有连接都会继承它
compress = yes				     #是否启用压缩, yes 表示如果支持压缩会启用.
dpdaction = hold			       #当意外断开后尝试的操作, hold, 保持并重连直到超时.
dpddelay = 30s				      #意外断开后尝试重连时长
dpdtimeout = 60s			      #意外断开后超时时长, 只对 IKEv1 起作用
inactivity = 300s				   #闲置时长,超过后断开连接.
esp = aes256-sha256,aes256-sha1,3des-sha1!	
  							   #数据传输协议加密算法列表
~~~
~~~bash
ike = aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
  							   #密钥交换协议加密算法列表
							 #iOS支持的IKE加密方式为aes256-sha256-modp1024
  							   #OS X为3des-sha1-modp1024
  							   #Win7为aes256-sha1-modp1024，
keyexchange = ike			       #默认的密钥交换算法, ike 为自动, 优先使用 IKEv2
left = %any					      #服务端公网IP, 可以是魔术字 %any，表示从本地IP地址表中取.
right = %any				      #客户端IP, 同上
leftdns = 8.8.8.8,8.8.4.4			#指定服务端与客户端的dns, 多个用","分隔
rightdns = 8.8.8.8,8.8.4.4			#指定服务端与客户端的dns, 多个用","分隔
leftikeport = <port>			  #服务端用于ike认证时使用的端口, 默认为500,如果使用了nat 转发, 则使用4500
leftsourceip = %config			   #服务器端虚拟IP地址
rightsourceip = 10.0.0.0/24		       #客户端虚拟IP段
leftsubnet = 0.0.0.0/0		              #服务器端子网, 魔术字 0.0.0.0/0. 如果为客户端分配虚拟 IP 地址的话，那表示之
  							    #后要做 iptables 转发，那么服务器端就必须是用魔术字
~~~

~~~bash
leftca = ca.cert.pem 			    #服务器端根证书
leftcert = server.cert.pem		       #服务器证书, 可以是 PEM 或 DER 格式
rightcert = <path>				#不指定客户端证书路径
leftsigkey = server.pub.pem		     #指定服务器证书的公钥
leftsendcert = always			   #是否发送服务器证书到客户端
rightsendcert = never			  #客户端不发送证书
leftauth = pubkey	                         #服务端认证方法,使用证书
rightauth = eap-mschapv2	         #客户端认证使用 EAP 扩展认证 , 貌似 eap-mschapv2 比较通用
leftid = vpn.strongswan.com	            #服务端id, 可以任意指定, 默认为服务器证书的 subject, 还可以是魔术字 %any，
  							  #表示什么都行.
rightid = %any				      #客户端id, 任意
eap_identity = %any		                #指定客户端eap id
rekey = no					    #不自动重置密钥
fragmentation = yes		        	#开启IKE 消息分片
auto = add					   #当服务启动时, 应该如何处理这个连接项. add 添加到连接表中.
~~~

本文使用的配置
~~~bash
config setup
    uniqueids = no
    
conn %default
    compress = yes
    keyingtries = 1
    keyexchange = ike
~~~

IKE基础配置

~~~bash
conn IKE-BASE
    #leftca = ca.cert.pem                      #使用Let's Encript免费证书的时候注释这句
    leftcert = server.cert.pem                   
    left = %defaultroute                        #可以将所有流量都发送到VPN网关
    leftsubnet = 0.0.0.0/0
    right = %any
    rightsourceip = 192.168.90.0/24   #客户端接入分配的私有IP地址空间
~~~

IKEv1配置
~~~bash
conn IPSec-IKEv1-PSK
    also = IKE-BASE
    keyexchange = ikev1
    fragmentation = yes
    leftauth = psk
    rightauth = psk
    rightauth2 = xauth-radius
    auto = add
    
conn IPSec-IKEv1
    also = IKE-BASE
    keyexchange = ikev1
    fragmentation = yes
    leftauth = pubkey
    rightauth = pubkey
    rightcert = client.cert.pem
    auto = add
~~~
IKEv2面向Linux、Android、Windows配置
~~~bash
conn IKEv2-LAW
    also = IKE-BASE
    keyexchange = ikev2
    keyingtries = 1 
    ike = aes256-sha1-modp1024
    esp = aes256-sha1
    leftauth = pubkey
    leftsendcert = always
    rightauth = eap-radius
    rekey = no
    eap_identity = %identity
    auto = add 
~~~
IKEv2面向iOS、MAC OS X配置，<span style="color:red">*</span>`leftid`需要和服务器URL或者IP地址一致，否则无法登录。
~~~bash
conn IKEv2-Apple
    also = IKE-BASE
    keyexchange = ikev2
    keyingtries = 1 
    ike = aes256-sha256-modp1024
    esp = aes256-sha256
    leftid =  vpn.strongswan.com 
    leftauth = pubkey
    leftsendcert = always
    rightauth = eap-radius
    rightsendcert = never
    fragmentation = yes 
    rekey = yes
    eap_identity = %identity
    auto = add        
~~~

#### 日志配置
修改/usr/local/etc/strongswan.conf，修改为如下，其中filelog选项可以调节等级

~~~bash
charon {
    load_modular = yes 
    filelog {
        /var/log/charon.log {
            time_format = %b %e %T
            ike_name = yes 
            append = no
            default = 2 
            flush_line = yes 
        }   
        stderr {
            ike = 2 
            knl = 3 
        }                                                                                                                                                            
    }   
    syslog {
        identifier = charon-custom
        daemon {
        }   
        auth {
            default = -1
            ike = 0 
        }   
    }                                                                                                                                                
    plugins {
        include strongswan.d/charon/*.conf
    }   
}
include strongswan.d/*.conf
~~~

#### ipsec.secrets设置 ####
配置验证方式的用户名与密码，
~~~bash
: RSA server.key.pem 		#使用证书验证时的服务器端私钥
: PSK "pskkey"                           #使用预设加密密钥, 越长越好
: XAUTH "pskkey"		     #使用XAUTH预设加密密钥, 越长越好
test : EAP "test"		          #验证的账户和密码，如果配置了RADIUS ，账户密码无法进行有效验证
test2 : XAUTH "test2"
~~~
<span style="color:red">*****</span>PSK和XAUTH可以设置一样，这样可以避免已配置的麻烦，同时共享密钥中不能有符号等，否则登录不成功。

#### DNS设置 ####
修改/usr/local/etc/strongswan.d/charon.conf，添加DNS服务器，修改其中的dns1=8.8.8.8。

#### Freeradius 服务器设置 ####
修改/usr/local/etc/strongswan.d/charon/eap-radius .conf，设置accounting改为yes，并添加servers中添加Freeradius 服务器。
~~~bash
accounting = yes
servers {
  RadiusServer {
       secret = testing1234        #与Freeradius 服务器的暗码
       address = 1.2.3.4              #Freeradius 服务器IP地址
       auth_port = 1812             #验证端口
       acct_port = 1813              #记账端口
               }
       }
~~~

#### iptables设置
转发/usr/local/etc/ipsec.conf中设置的虚拟IP地址段，其中x.x.x.x为主机的公网IP地址
OpenVZ如下
~~~bash
iptables -t nat -A POSTROUTING -s 192.168.90.0/24 -o venet0 -j SNAT --to-source x.x.x.x
iptables -I FORWARD 4 -s 192.168.90.0/24 -j ACCEPT
~~~

KVM如下，eth0为公网IP所在的网卡。
~~~bash
iptables -t nat -A POSTROUTING -s 192.168.90.0/24 -o eth0 -j MASQUERADE
~~~

开放UDP的500和4500端口，删除转发表所有拒绝的条目，保存并重启iptables服务
~~~bash
iptables -A INPUT -p udp -m udp --dport 4500 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 500 -j ACCEPT  
iptables -D FORWARD 1
service iptables save
service iptables restart
~~~
----------

### 4. 服务启动
启动Strongswan服务
~~~bash
/usr/local/ipsec start
~~~

----------

### 5. IKEv2 VPN配置 ###
#### iOS

##### 系统版本要求

<span style="color:red">iOS 9</span>或者更高版本

##### 证书导入
- 通过**邮件**发送或者**Safari浏览器**[下载](https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem)CA证书到iOS设备
- 安装证书到设备
- 输入iOS密码

##### VPN设置
- 配置位置: **设置 -> VPN -> 添加配置**
- 类型: IKEv2
- 描述: 任意
- 用户鉴定: 用户名
- 服务器: VPN服务器URL或者IP地址
- 用户名: Freeradius服务器配置
- 密码: Freeradius服务器配置
- 远程ID: VPN远程ID
- 本地ID: 留空

#### OS X

##### 系统版本要求

<span style="color:red">OS X 10.11 ("El Capitan")</span>或者更高版本

##### 证书导入

- 下载CA证书到本地
- 配置位置: **钥匙串访问 -> 钥匙串 -> 系统**
- 选择要添加的证书文件
- 导入证书

##### VPN设置
- 配置位置: **系统偏好设置 -> 网络 ->添加网络连接**
- 接口: VPN
- VPN类型: IKEv2
- 服务名称: 任意
- 服务器: VPN服务器URL或者IP地址
- 远程ID: VPN远程ID
- 本地ID: 留空
- 鉴定设置 -> 用户名: Freeradius服务器配置
- 鉴定设置 -> 密码: Freeradius服务器配置

#### Android

##### 系统版本要求

<span style="color:red">Android 4</span>或者更高版本，需要安装[Strongswan客户端](http://pan.baidu.com/s/1gfkEXKB)

##### 证书导入
- 下载CA证书到本地
- 配置位置：**CA certificates -> Import certificates**
- 从文件系统选择证书文件
- 确认导入证书

##### VPN设置 #####
- 配置位置：**ADD VPN PROFILE**
- 服务器: VPN服务器URL或者IP地址
- VPN类型: IKEv2 EAP
- 用户名: Freeradius服务器配置
- 密码: Freeradius服务器配置

#### Windows

##### 系统版本要求

<span style="color:red">Win 7</span>或者更高版本

##### 证书导入
windows使用IKEv2 VPN需要导入服务器证书到**信任根证书颁发机构。如果服务器使用的是**自签名CA**颁发的证书，需要导入的CA证书为之前创建的ca.cert.pem。若使用**Let's Encript**证书，需要导入需要在客户端中导入[Let’s Encrypt Authority X3](https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem)证书。

- 下载CA证书到本地


- 开始菜单搜索**cmd**，打开后输入 **mmc（Microsoft 管理控制台）**
- **文件** -> **添加/删除管理单元**，添加**证书**单元
- 证书单元的弹出窗口中选**计算机账户**，之后选**本地计算机**，确定
- 在左边的**控制台根节点**下选择**证书** -> **受信任的根证书颁发机构** -> **证书**，右键 -> **所有任务** -> **导入**打开证书导入窗口。
- 选择证书文件导入即可

##### VPN设置 #####
###### Win10/Win8

- 配置位置: **设置 -> 网络和Internet -> VPN -> 添加VPN**
- VPN提供商: Windows（内置）
- 连接名称: 任意
- 服务器名称或地址: VPN服务器URL或者IP地址
- VPN类型: IKEv2
- 登录信息类型: 用户名和密码
- 用户名: Freeradius服务器配置
- 密码: Freeradius服务器配置

###### Win7

- 配置位置: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 连接新的网络或连接 -> 连接到工作区 -> 创建新连接 -> 使用我的Internet连接(VPN)**
- Internet 地址: VPN服务器URL或者IP地址
- 目标名称: 任意
- 用户名: Freeradius服务器配置
- 密码: Freeradius服务器配置

设置完毕后，先不连接

- 配置位置: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**
- 在新建的 VPN 连接上右键**属性**
- 切换到**安全**选项卡
  - VPN 类型: IKEv2
  - 数据加密选: 需要加密
  - 身份验证: EAP-MSCHAP v2

然后选择连接VPN，win7/8/10连接界面可能不同，但是大同小异。

#### Linux
Linux 的版本众多，认证方法与协议支持也非常丰富，详细方法请根据 Linux 版本查询连接方法。一般而言，Linux 通过 NetworkManager-strongswan。

----------

### 6. IPsec VPN配置 ###
#### iOS
- 配置位置: **设置 -> VPN -> 添加配置 -> IPSec**
- 描述: 任意
- 用户鉴定: 用户名
- 服务器: VPN服务器URL或者IP地址
- 用户名: Freeradius服务器配置
- 密码: Freeradius服务器配置
- 密钥: ipsec.secrets 中设置的 XAUTH 预共享密码

#### OS X
- 配置位置: **系统偏好设置 -> 网络 ->添加网络连接**
- 接口: VPN
- VPN类型: IPsec/Cisco
- 服务器地址: 服务器URL或者IP地址
- 账户名称: Freeradius服务器配置
- 密码: Freeradius服务器配置
- 鉴定设置 -> 共享的密钥: ipsec.secrets 中设置的 EAP 预共享密码

#### Android

- 配置位置: **设置 -> 其它连接方式 -> VPN -> 添加 VPN**
- 名称: 任意
- 服务器地址: 服务器URL或者IP地址
- 类型: IPSec Xauth PSK
- IPsec 标识符: 不更改
- 预共享密钥: ipsec.secrets 中设置的 EAP 预共享密码
- 连接时账户名密码: Freeradius服务器配置

#### Linux
Linux 的版本众多，认证方法与协议支持也非常丰富，详细方法请根据 Linux 版本查询连接方法。一般而言，Linux 通过 NetworkManager-strongswan。

---

### 7. 参考 & 问题

https://wiki.strongswan.org/projects/strongswan/wiki/ConnSection

https://blog.itnmg.net/centos7-ipsec-vpn/
