---
title:  基础DNS学习
date: 2016/7/17 14:33:46 
description: 基础DNS学习
categories: 学习
tags: [dns,network]
---

### 1. 常用命令

####  nslookup  

查询域名命令，Windows自带该工具，Linux一般自带，有一些distribution没有，可以通过如下命令安装该工具。可以列出查询出来的IP，可以执行正解和反解查询。

Ubuntu:


```shell
sudo apt-get install dnsutils
```
Debian:

```shell
apt-get update
apt-get install dnsutils
```

Fedora / Centos:

```shell
yum install bind-utils
```

####   dig

使用方法，可以执行正解和反解。

```shell
dig [options] FQDN [@server]
```

输出说明

- QUESTION（问题）: 要查询的IP
- ANSWER（回答）: 应答结果
- AUTHORITY（验证）: 哪个DNS给出的回答。

####   whois

查询领域设定，管理者是谁。

####   host

把一个主机名解析到一个网际地址或把一个网际地址解析到一个主机名

----------

### 2. DNS记录类型

####   正解

正解符合规范即可设定，取得域名授权就可以设定。

| domain | IN   | RR type | RR data      | command            |
| ------ | ---- | ------- | ------------ | ------------------ |
| 主机名.   | IN   | A       | IPv4 的 IP 地址 | dig [-t a] domain  |
| 主机名.   | IN   | AAAA    | IPv6 的 IP 地址 | dig -t aaaa domain |
| 领域名.   | IN   | NS      | 管理域名的服务器主机名字 | dig -t ns domain   |
| 领域名.   | IN   | SOA     | 管理域名的七个重要参数  | dig -t soa domain  |
| 领域名.   | IN   | MX      | 接收邮件的服务器主机名字 | dig -t mx domain   |
| 主机别名.  | IN   | CNAME   | 代表主机别名的主机名字  | dig domain         |

> <span style="color:red">**提示：**</span> domain一列后面一定要加一个.，例如www.test.com的格式为www.test.com.

SOA七个重要参数

1. **Master DNS 服务器主机名：**这个领域主要是哪部 DNS 作为 master 的意思
2. **管理员的 email**：那么管理员的 email 为何？发生问题可以联络这个管理员。要注意的是， 由于 @ 在数据库档案中是有特别意义的，所以改为.。
3. **序号 (Serial)**：这个序号代表的是这个数据库档案的新旧，序号越大代表越新。 当 slave 要判断是否主动下载新的数据库时，就以序号是否比 slave 上的还要新来判断，若是则下载，若不是则不下载。 所以当你修订了数据库内容时，记得要将这个数值放大才行！ 为了方便用户记忆，通常序号都会使用日期格式『YYYYMMDDNU』来记忆，例如昆山科大的 2010080369 序号代表 2010/08/03当天的第 69 次更新的感觉。不过，序号不可大于 2 的 32 次方，亦即必须小于 4294967296 才行。
4. **更新频率 (Refresh)**：那么啥时 slave 会去向 master 要求数据更新的判断？ 就是这个数值定义的。那每次 slave 去更新时， 如果发现序号没有比较大，那就不会下载数据库档案。
5. **失败重新尝试时间 (Retry)**：如果因为某些因素，导致 slave 无法对master 达成联机， 那么在多久的时间内，slave 会尝试重新联机到 master。
6. **失效时间 (Expire)**：如果一直失败尝试时间，持续联机到达这个设定值时限， 那么 slave 将不再继续尝试联机，并且尝试删除这份下载的 zone file 信息。
7. **快取时间 (Minumum TTL)**：如果这个数据库 zone file 中，每笔 RR 记录都没有写到 TTL 快取时间的话，那么就以这个 SOA 的设定值为主。

####   反解

除非取得的是整个 class C 以上等级的 IP 网段，ISP 才有可能给 IP 反解授权。否则，若有反解的需求，就得要向直属上层 ISP 申请。

| domain               | IN   | Type | IP Address | command |
| -------------------- | ---- | ---- | ---------- | ------- |
| [ip反写].in-addr.arpa. | IN   | PTR  | IP         | dig IP  |

----------

### 3. DNS服务搭建

安装bind套件，CentOS命令如下

```shell
yum install -y bind*
```

####  转发DNS  

只需要.这个zonefile的简单DNS服务器，只有快速搜索功能，没有本地主机IP正反解配置文件。需要指定一个上层DNS服务器。只需要编辑/etc/named.conf

````shell
  vim /etc/named.conf
    // 在预设的情况下，这个档案会去读取 /etc/named.rfc1912.zones 这个领域定义档
    // 所以请记得要修改成底下的样式
    options {
            listen-on port 53 { any; };                                             //可不设定，代表全部接受
            directory "/var/named";                                              //数据库默认放置的目录所在
            dump-file "/var/named/data/cache_dump.db";         //一些统计信息
            statistics-file "/var/named/data/named_stats.txt";
            memstatistics-file "/var/named/data/named_mem_stats.txt";
            allow-query { any; };                                                    //可不设定，代表全部接受
            recursion yes;                                                              //将自己视为客户端的一种查询模式
            forward only;                                                               //可暂时不设定
            forwarders {                                                                //是重点！
            168.95.1.1;                                                                  //先用中华电信的 DNS 当上层
            139.175.10.20;                                                            //再用 seednet 当上层
            };
    };
````

启动服务，注意开启iptables的tcp和udp的53端口。

```shell
service named start
```

####  权威DNS & 递归DNS 

- 规划IP地址和域名对应关系

- 主配置文件 /etc/named.conf

  ```shell
  vim  /etc/named.conf
  options {
  	directory "/var/named";
  	dump-file "/var/named/data/cache_dump.db";
  	statistics-file "/var/named/data/named_stats.txt";
  	memstatistics-file "/var/named/data/named_mem_stats.txt";
  	allow-query { any; };
  	recursion yes;
  	allow-transfer { none; };      // 不许别人进行 zone 转移
  };
  zone "." IN {
  	type hint;
  	file "named.ca";
  };
  zone "ucas.edu.cn" IN {                // 这个 zone 的名称
  	type master;                         // 是什么类型
  	file "named.ucas.edu.cn";    // 档案放在哪里
  };
  zone "100.168.192.in-addr.arpa" IN {
  	type master;
  	file "named.192.168.100";
  };
  ```

  zone内相关参数说明

  
  | 设定值    | 意义                                       |
  | ---------- | :--------------------------------------- |
  | type   | 该 zone 的类型，主要的类型有针对 . 的 hint，以及自己手动修改数据库档案的 master，与可自动更新数据库的 slave。 |
  | file   | zonefile 的对应的名称                          |
  | 反解zone | in-addr.arpa                             |

- 顶级.(root)数据库档案设定

  由INTERNIC 所管理维护的，全世界共有 13 部管理 . 的 DNS 服务器，在`/var/named/named.ca`中

- 正解数据库文件设置

  ​     少应该要有 $TTL, SOA, NS (与这部 NS 主机名的 A)，仍以上面`/etc/named.conf`为例，在/var/named/配置文件named.ucas.edu.cn内容如下

  ```shell
  $TTL 600
  @ IN SOA gsns.ucas.edu.cn. admin.www.ucas.edu.cn. (2011080401 3H 15M 1W 1D)
  @ IN NS gsns.ucas.edu.cn.                       #DNS服务器名称
  gsns.ucas.edu.cn. IN A 30.30.30.30           #DNS服务器IP地址

  @ IN MX 10 gsns.ucas.edu.cn.                  #域名邮件服务器
  										
  www.ucas.edu.cn. IN A 30.30.30.30           #相关正解
  linux.ucas.edu.cn. IN CNAME www.ucas.edu.cn.
  ```
  > <span style="color:red">提示：</span> 域名后面有一个点，不要落下，例如**www.ucas.edu.cn.**


- 反解数据库文件设置

  需要 $TTL, SOA, NS，正解里面有 A，反解里面则仅有 PTR 。另外，由于反解的 zone 名称是zz.yy.xx.in-addr.arpa.的模样，因此只要在反解里面要用到主机名时，192.168.100.0/24 这个网域的 DNS 反解则成为如/var/named/named.192.168.100所示。

  ```shell
  $TTL 600
  @ IN SOA gsns.ucas.edu.cn. admin.www.ucas.edu.cn. (2011080401 3H 15M 1W 1D)
  @ IN NS gsns.ucas.edu.cn.
  30 IN PTR gsns.ucas.edu.cn.
  254 IN PTR gate.ucas.edu.cn.
  30 IN PTR www.ucas.edu.cn.
  30 IN PTR linux.ucas.edu.cn.
  ```


- DNS启动

  ```shell
  service named restart
  ```


####  授权子域  

- 需要在上层DNS服务器的zonefile内指定增加NS并指向下层DNS的主机名和IP（A）即可，zonefile的序号也需要增加。
- 下层DNS服务器必须上层DNS所提供的可用子域名，并被上层DNS管理员所获知。

假设上层DNS管理edu.cn这个域名。其对应的zonefile为`/var/named/named.edu.cn`，内容如下

````shell
$TTL 600
@ IN SOA dns.edu.cn. admin.edu.cn. (2011080401 3H 15M 1W 1D)
@ IN NS dns.edu.cn.
dns.edu.cn. IN A 210.76.211.1
@ IN MX 10 dns.edu.cn.

ucas.edu.cn IN NS gsns.ucas.edu.cn      #子DNS服务器名称
gsns.ucas.edu.cn IN A 30.30.30.30         #子DNS服务器IP地址
````

----------

### 4. 相关操作
####  日志功能 

检查 /var/log/messages 的内容讯息 (极重要！)，

####  数据库更新 

- 先针对要更改的那个 zone 的数据库档案去做更新，就是加入 RR 的标志即是！


- 更改该 zone file 的序号 (Serial) ，就是那个 SOA 的第三个参数 (第一个数字)，因为这个数字会影响到 master/slave 的判定更新与否！


- 重新启动 named ，或者是让 named 重新读取配置文件即可。

####  其他 

有待补充

----------

### 5. 实验测试
####  实验拓扑 
<center> ![5-1](http://qingdao.icean.cc:11234/Imgbed/GNS3_DNS_learn/5-1.jpg)</center><center style="color:purple">**图5-1 实验拓扑**</center>

####  设备信息 

| 设备名              | 端口   | IP地址              | 备注                           |
| ---------------- | ---- | ----------------- | ---------------------------- |
| dns.edu.cn       | e2   | 210.76.211.1/24   | 管理edu.cn域名                   |
| gsns.ucas.edu.cn | e2   | 30.30.30.30/24    | 管理ucas.edu.cn域名，dns.edu.cn授权 |
| R1               | f1/1 | 211.76.211.254/24 |                              |
| R1               | f1/0 | 30.30.30.254/24   |                              |
| Winxp2           | e1   | 30.30.30.2/24     | 测试客户机                        |

####  DNS测试 

Winxp2的DNS地址为gsns.ucas.edu.cn时，可以进行nslookup测试，如图5-2所示

<center> ![5-2](http://qingdao.icean.cc:11234/Imgbed/GNS3_DNS_learn/5-2.jpg)</center><center style="color:purple">**图5-2 nslookup**</center>



在**Winxp2**上使用如下命令

```shell
dig www.ucas.edu.cn @210.76.211.1
```

在dns.edu.cn没有关闭递归查询的情况下，首先向gsns.ucas.edu.cn查询www.ucas.edu.cn，然后继续向根进行递归查询,因为实验环境是模拟环境,所以还无法确认,可以模拟使用虚拟机模拟根DNS服务器进行测试.

在dns.edu.cn关闭递归查询的情况下，查询www.ucas.edu.cn, 然后返回结果给**Winxp2**为管理其域名的DNS服务器。



