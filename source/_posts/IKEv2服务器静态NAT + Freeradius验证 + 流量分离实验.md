---
title: IKEv2服务器静态NAT + Freeradius验证 + 流量分离实验
date:  2017/1/26 9:49:19 
description: 需求分析：IKEv2服务器地址为私有IP，通过静态NAT映射，外网可以访问；使用Freeradius进行验证；客户端接入VPN之后，只有指定的流量可以通过VPN网关，其他流量仍通过客户端原来的网关
categories: 技术
tags: [IKEv2,Strongswan,vpn,linux]
---

### 1. 需求分析

- IKEv2服务器地址为私有IP，通过静态NAT映射，外网可以访问
- 使用Freeradius进行验证
- 客户端接入VPN之后，只有指定的流量可以通过VPN网关，其他流量仍通过客户端原来的网关

---

### 2. 实验环境

#### 2.1 实验拓扑

<center>![topo](http://qingdao.icean.cc:11234/Imgbed/ikev2 + freeradius + nat/topo+.png)</center><center style="color:purple">**图2-1 实验拓扑**</center>

#### 2.2 设备信息

各个设备的操作系统、IP地址以及网卡信息如下所示

| 设备                | 系统        | 网卡   | IP              | 备注                    |
| ----------------- | --------- | ---- | --------------- | --------------------- |
| IKEv2 Server      | CentOS 7  | e0   | 10.10.10.3/24   | 静态NAT地址为10.10.20.3/24 |
| Freeradius Server | CentOS 7  | e0   | 10.10.10.2/24   |                       |
| Router            | IOS       | f0/0 | 10.10.10.254/24 |                       |
|                   |           | f0/1 | 10.10.20.254/24 | 方便测试，使用私有地址           |
| Client            | Windows 7 | e0   | 10.10.20.1/24   | 网关地址为10.10.20.5       |
| Internet          | CentOS 7  | e2   | 10.10.20.5/24   | 模拟互联网，实际为多网卡转发        |

**Internet**设备有多个网卡，使用iptables的nat表，将转发到e2网卡的所有流量转发到可以上网的其他网卡，这样**Client**可以与互联网进行连接

---

### 3. 路由器配置

路由器配置如下

~~~
interface FastEthernet0/0
 ip address 10.10.10.254 255.255.255.0
 ip nat inside

interface FastEthernet0/1
 ip address 10.10.20.254 255.255.255.0
 ip nat outside

ip nat inside source static 10.10.10.3 10.10.20.3
~~~

---

### 4. Strongswan编译安装

#### 4.1 环境准备
需要安装如下依赖
~~~bash
yum -y install pam-devel
~~~

可能还需要安装如下依赖

~~~bash
 yum install -y openssl-devel make gcc curl wget 
~~~

#### 4.2 下载源码

从[Strongswan](https://www.strongswan.org/)官网下载最新Strongswan 5.5.1源码到并解压

~~~bash
wget https://download.strongswan.org/strongswan-5.5.1.tar.gz
tar xvf strongswan-5.5.1.tar.gz
~~~

####  4.3 编译安装
切换到Strongswan源码解压的目录，执行配置与编译安装
~~~bash
cd strongswan-5.5.1
./configure  --enable-eap-identity --enable-eap-md5 --enable-eap-mschapv2 --enable-eap-tls \
--enable-eap-ttls --enable-eap-peap --enable-eap-tnc --enable-eap-dynamic \
--enable-eap-radius --enable-xauth-eap --enable-xauth-pam  --enable-dhcp  \
--enable-openssl  --enable-addrblock --enable-unity  --enable-certexpire --enable-radattr \
--enable-swanctl --enable-openssl --disable-gmp --enable-farp
make && make install
~~~

`--enable-farp`参数为编译farp插件，[farp](https://wiki.strongswan.org/projects/strongswan/wiki/Farpplugin#farp-plugin)插件允许接入VPN客户端在逻辑上与服务器处于同一局域网

`--enable-dhcp`参数为编译dhcp插件，dhcp插件允许接入VPN客户端获取某个DHCP分配的IP地址

根据主机性能，完成上述编译安装需要的时间不同。安装完成后，可执行文件的路径为/usr/local/sbin, 配置文件路径为/usr/local/etc，配置文件以及文件夹主要如下

- ipsec.conf              
- ipsec.secrets
- **ipsec.d**
- strongswan.conf
- **strongswan.d**
- **swanctl**

---

### 5. 证书配置

#### 5.1 自签名CA证书
生成一个CA私钥

~~~bash
ipsec pki --gen --outform pem > ca.key.pem
~~~

基于私钥生成一个自签名的CA证书
~~~bash
ipsec pki --self --in ca.key.pem --dn "C=CN, O=ACS, CN=ACS CA" --ca --lifetime 3650 --outform pem > ca.cert.pem
~~~
- --self 表示自签证书
- --in 是输入的私钥
- --dn 是判别名
- C 表示国家名，同样还有 ST 州/省名，L 地区名，STREET（全大写） 街道名
- O 组织名称
- CN 友好显示的通用名
- --ca 表示生成 CA 根证书
- --lifetime 为有效期, 单位是天

#### 5.2 服务器证书
生成服务器证书的私钥
~~~bash
ipsec pki --gen --outform pem > server.key.pem
~~~

用自签的 CA 证书签发一个服务器证书
~~~bash
ipsec pki --pub --in server.key.pem --outform pem > server.pub.pem
ipsec pki --issue --lifetime 1200 --cacert ca.cert.pem --cakey ca.key.pem --in server.pub.pem \
--dn "C=CN, O=Strongswan, CN=test.icean.cc" --san="test.icean.cc" --flag serverAuth \
--flag ikeIntermediate --outform pem > server.cert.pem
~~~

--issue, --cacert 和--cakey 就是表明要用刚才自签的 CA 证书来签这个服务器证书，--dn, --san，--flag 是一些客户端方面的特殊要求：

- iOS 客户端要求 CN 也就是通用名必须是服务器的 URL 或 IP 地址;
- Windows 7 或者更高版本不但要求了上面，还要求必须显式说明这个服务器证书的用途（用于与服务器进行认证），--flag serverAuth;
- 非 iOS 的 Mac OS X 要求了“IP 安全网络密钥互换居间（IP Security IKE Intermediate）”这种增强型密钥用法（EKU），–flag ikdeIntermediate;
- Android 和 iOS 都要求服务器别名（serverAltName）就是服务器的 URL 或 IP 地址，即是--san，同时Windows 7不能添加额外的服务器别名，Windows 10可以添加

<span style="color:red">*****</span>为了兼容Windows 7，只添加一个服务器别名（serverAltName）

#### 5.3 安装证书
复制证书到指定的路径
~~~bash
cp ca.key.pem /usr/local/etc/ipsec.d/private/
cp server.key.pem /usr/local/etc/ipsec.d/private/
cp server.cert.pem /usr/local/etc/ipsec.d/certs/
cp ca.cert.pem /usr/local/etc/ipsec.d/cacerts/
~~~
---

### 6. Strongswan配置&启动

#### 6.1 ipsec.conf设置

基础设置

~~~
config setup
    uniqueids = no
    
conn %default
    compress = yes
    keyingtries = 1
    keyexchange = ike
~~~

IKE基础配置，其中leftsubnet流量选择器的参数，这里设置为客户端只能访问10.10.10.0/24这个网段

~~~
conn IKE-BASE          
    leftcert = server.cert.pem                   
    left = %any
    leftsubnet = 10.10.10.0/24            #这很重要，只允许VPN接入客户端可以访问这个网段，可以通过逗
                                                           #号分割， 添加其他单个地址或者网段
    right = %any
    rightsourceip = %dhcp                  #使用dhcp插件从局域网的DHCP服务器给客户端分配IP地址，若要
                                                           #具体选择哪个DHCP服务器，
~~~

IKEv2面向Windows配置，次设置也适用于Linux、Android
~~~
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
~~~
conn IKEv2-Apple
    also = IKE-BASE
    keyexchange = ikev2
    keyingtries = 1 
    ike = aes256-sha256-modp1024
    esp = aes256-sha256
    leftid =  test.icean.cc
    leftauth = pubkey
    leftsendcert = always
    rightauth = eap-radius
    rightsendcert = never
    fragmentation = yes 
    rekey = yes
    eap_identity = %identity
    auto = add        
~~~

#### 6.2 strongswan.conf设置
修改/usr/local/etc/strongswan.conf，修改为如下，其中filelog选项可以调节等级，通过修改default后面的数字调节日志等级

~~~
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

#### 6.3 ipsec.secrets设置 ####
配置验证方式的用户名与密码，
~~~
: RSA server.key.pem 		#使用证书验证时的服务器端私钥
~~~
#### 6.4 Freeradius设置 ####
修改/usr/local/etc/strongswan.d/charon/eap-radius .conf，设置accounting改为yes，并添加servers中添加Freeradius 服务器
~~~
accounting = yes
servers {
  RadiusServer {
       secret = testing1234        #与Freeradius 服务器的暗码
       address = 10.10.10.2        #Freeradius 服务器IP地址
       auth_port = 1812             #验证端口
       acct_port = 1813              #记账端口
               }
       }
~~~

freeradius服务器设置参考其他资料，这里使用的测试帐号和密码都是test

#### 6.5 iptables设置

开放UDP的500和4500端口，删除转发表所有拒绝的条目，保存并重启iptables服务
~~~bash
iptables -A INPUT -p udp -m udp --dport 4500 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 500 -j ACCEPT  
iptables -D FORWARD 1
service iptables save
service iptables restart
~~~
#### 6.6 Strongswan服务启动

启动服务

~~~bash
ipsec start
~~~

---

### 7. 客户端设置-Windows 

#### 7.1 系统版本要求

Windows 7或者更高版本

#### 7.2 证书导入

- 下载**ca.cert.pem**(自签名CA证书)到本地


- 开始菜单搜索 **mmc（Microsoft 管理控制台）**
- **文件** -> **添加/删除管理单元**，添加**证书**单元
- 证书单元的弹出窗口中选**计算机账户**，之后选**本地计算机**，确定
- 在左边的**控制台根节点**下选择**证书** -> **受信任的根证书颁发机构** -> **证书**，右键 -> **所有任务** -> **导入**，打开证书导入窗口。
- 选择证书文件导入即可

#### 7.3 DNS设置

在`C:\Windows\System32\drivers\etc\hosts`中添加如下解析条目

~~~
10.10.20.3 test.icean.cc
~~~

在正式生产环境中，需要在DNS服务器具体设置

#### 7.4 VPN设置

##### 7.4.1 Win10/Win8

- 配置位置: **设置 -> 网络和Internet -> VPN -> 添加VPN**
- VPN提供商: Windows（内置）
- 连接名称: 任意
- 服务器名称或地址: test.icean.cc
- VPN类型: IKEv2
- 登录信息类型: 用户名和密码
- 用户名: test
- 密码: test

##### 7.4.2 Win7

- 配置位置: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 连接新的网络或连接 -> 连接到工作区 -> 创建新连接 -> 使用我的Internet连接(VPN)**
- Internet 地址: test.icean.cc
- 目标名称: 任意
- 用户名: test
- 密码: test

设置完毕后，先不连接

- 配置位置: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**
- 在新建的 VPN 连接上右键**属性**
- 切换到**安全**选项卡
  - VPN 类型: IKEv2
  - 数据加密选: 需要加密
  - 身份验证: EAP-MSCHAP v2

然后选择连接VPN，win7/8/10连接界面可能不同，但是大同小异。

#### 7.5 网关设置

若不想将本机的默认网关设置为VPN服务器的网关，Windows设置如下

- 配置位置：**控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**
- 在新建的 VPN 连接上右键**属性**
- 切换到**网络**选项卡
  - 选择**Internet协议版本4 -> 高级 **
  - 切换到**IP设置**选项卡
  - 不选择**在远程网络上使用默认网关**，然后保存
- 再次连接VPN

#### 7.6 连接测试

VPN登录成功后，查看路由表，10.10.10.4是从VPN网关获取的地址，默认网关还是10.10.20.5

~~~powershell
IPv4 路由表
===============================================================================
活动路由:
网络目标        网络掩码          网关       接口   跃点数
          0.0.0.0          0.0.0.0       10.10.20.5       10.10.20.1    266
         10.0.0.0        255.0.0.0            在链路上        10.10.10.4     11
       10.10.10.4  255.255.255.255            在链路上        10.10.10.4    266
       10.10.20.0    255.255.255.0            在链路上        10.10.20.1    266
       10.10.20.1  255.255.255.255            在链路上        10.10.20.1    266
       10.10.20.3  255.255.255.255            在链路上        10.10.20.1     11
     10.10.20.255  255.255.255.255            在链路上        10.10.20.1    266
   10.255.255.255  255.255.255.255            在链路上        10.10.10.4    266
        127.0.0.0        255.0.0.0            在链路上         127.0.0.1    306
        127.0.0.1  255.255.255.255            在链路上         127.0.0.1    306
  127.255.255.255  255.255.255.255            在链路上         127.0.0.1    306
        224.0.0.0        240.0.0.0            在链路上         127.0.0.1    306
        224.0.0.0        240.0.0.0            在链路上        10.10.20.1    266
        224.0.0.0        240.0.0.0            在链路上        10.10.10.4    266
  255.255.255.255  255.255.255.255            在链路上         127.0.0.1    306
  255.255.255.255  255.255.255.255            在链路上        10.10.20.1    266
  255.255.255.255  255.255.255.255            在链路上        10.10.10.4    266
===============================================================================
~~~

---

### 8. 客户端设置-MacOSX

#### 8.1 系统版本要求

OS X 10.11 ("El Capitan")或者更高版本

#### 8.2 证书导入

- 下载**ca.cert.pem**(自签名CA证书)到本地


- 配置位置: **钥匙串访问 -> 钥匙串 -> 系统**
- 选择要添加的证书文件
- 导入证书

#### 8.3 DNS设置

在`/etc/hosts`中添加如下解析条目

```
10.10.20.3 test.icean.cc
```

在正式生产环境中，需要在DNS服务器具体设置

#### 8.4 VPN设置

- 配置位置: **系统偏好设置 -> 网络 ->添加网络连接**
- 接口: VPN
- VPN类型: IKEv2
- 服务名称: 任意
- 服务器: test.icean.cc
- 远程ID: test.icean.cc
- 本地ID: 留空
- 鉴定设置 -> 用户名: test
- 鉴定设置 -> 密码: test

#### 8.5 连接测试

VPN连接成功后，查看新添加的路由条目

---

### 9. 实验脚本

#### 9.1 证书相关脚本

删除所有证书

~~~bash
#!/bin/bash
rm -rf /usr/local/etc/ipsec.d/cacert/*
rm -rf /usr/local/etc/ipsec.d/private/*
rm -rf /usr/local/etc/ipsec.d/cert/*
~~~

生成并安装证书

~~~bash
#!/bin/bash
C="CN"
O="ACS"
CN="ACS CA"

#自签名CA生成
ipsec pki --gen --outform pem > ca.key.pem
ipsec pki --self --in ca.key.pem --dn "C=$C, O=$O, CN=$CN" --ca --lifetime 3650 --outform pem > ca.cert.pem
cp ca.key.pem /usr/local/etc/ipsec.d/private/
cp ca.cert.pem /usr/local/etc/ipsec.d/cacerts/

C="CN"
O="ACS"
URL="test2.icean.cc"
san="test2.icean.cc"

#服务器证书生成
ipsec pki --gen --outform pem > server.key.pem
ipsec pki --pub --in server.key.pem --outform pem > server.pub.pem
ipsec pki --issue --lifetime 1200 --cacert ca.cert.pem --cakey ca.key.pem --in server.pub.pem --dn "C=$C, O=$O, CN=$URL" --san="$san" --flag serverAuth --flag ikeIntermediate --outform pem > server.cert.pem

cp server.key.pem /usr/local/etc/ipsec.d/private/
cp server.cert.pem /usr/local/etc/ipsec.d/certs/
~~~

#### 9.2 配置文件

ipsec.conf配置文件

~~~bash
cd /usr/local/etc
mv ipsec.conf ipsec.conf.bak
cat <<EOF >> ipsec.conf
config setup
    uniqueids=yes

conn %default
    compress = yes
    keyingtries = 1
    keyexchange = ike

conn IKE-BASE
    leftca = ca.cert.pem
    leftcert = server.cert.pem
    left = %any
    leftsubnet = 10.10.10.0/24
    right = %any
    #rightsourceip = 192.168.80.0/24
    rightsourceip = %dhcp
 
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

conn IKEv2-Apple
    also = IKE-BASE
    keyexchange = ikev2
    keyingtries = 1 
    ike = aes256-sha256-modp1024
    esp = aes256-sha256
    leftid =  test.icean.cc
    leftauth = pubkey
    leftsendcert = always
    rightauth = eap-radius
    rightsendcert = never
    fragmentation = yes 
    rekey = yes
    eap_identity = %identity
    auto = add 
EOF
~~~

ipsec.secrets配置文件，因为保密需要，该文件属组和其他没有读和执行权限

~~~bash
cd /usr/local/etc
cat <<EOF > ipsec.secrets
: RSA server.key.pem
EOF
~~~

strongswan.conf配置文件

~~~bash
cd /usr/local/etc
mv strongswan.conf strongswan.conf.bak
cat <<EOF >> strongswan.conf
charon {
       dns1 = 8.8.8.8    
 
       filelog {
               /var/log/strongswan.charon.log {
                   time_format = %b %e %T
                   default = 0
                   append = no
                   flush_line = yes
                                              }
              }
       plugins {
         eap-radius {
               accounting = yes
               servers {
                  radiusServer {
                       secret = testing1234
                       address = radius
                       auth_port = 1812
                       acct_port = 1813
                               }
                        }
                    }
                }
}

include strongswan.d/*.conf
EOF
~~~

#### 9.3 系统设置

iptables设置

~~~bash
iptables -I INPUT 1 -p udp -m udp --dport 4500 -j ACCEPT
iptables -I INPUT 1 -p udp -m udp --dport 500 -j ACCEPT
iptables -I  FORWARD 1 -j ACCEPT
iptables -t nat -I POSTROUTING 1 -s 192.168.80.0/24 -o enp0s8 -j MASQUERADE
iptables-save >/etc/sysconfig/iptables
service iptables restart
~~~

sysctl设置

~~~bash
cat <<EOF>>/etc/sysctl.conf  
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding=1 
EOF
sysctl -p
~~~



