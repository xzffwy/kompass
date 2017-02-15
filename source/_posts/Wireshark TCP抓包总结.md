---
title:  Wireshark TCP抓包总结
date: 2015/12/23 9:21:25 
description:  Wireshark TCP抓包总结
categories: 学习
tags: [network]
---

### 1.TCP ###
#### 连接状态标记字段 ####

- SYN表示建立连接
- FIN表示关闭连接
- ACK表示响应
- PSH表示有DATA数据传输
- RST表示连接重置

><span style="color:red">**提示：**</span>
>
> 1. ACK是可能与SYN，FIN等同时使用的，比如SYN和ACK可能同时为1，它表示的就是建立连接之后的响应。
> 2. 如果只是单个的一个SYN，它表示的只是建立连接。
> 1. TCP的几次握手就是通过这样的ACK表现出来的。
> 1. 但SYN与FIN是不会同时为1的，因为前者表示的是建立连接，而后者表示的是断开连接。
> 1. RST一般是在FIN之后才会出现为1的情况，表示的是连接重置。
> 1. 一般地，当出现FIN包或RST包时，可以认为客户端与服务器端断开了连接；而当出现SYN和SYN＋ACK包时，可以认为客户端与服务器建立了一个连接。
> 1. PSH为1的情况，一般只出现在 DATA内容不为0的包中，也就是说PSH为1表示的是有真正的TCP数据包内容被传递。
> 1. TCP的连接建立和连接关闭，都是通过请求－响应的模式完成的。

#### 所有标记字段 ####

- SYN(synchronous)建立联机
- ACK(acknowledgement)确认
- PSH(push)传送
- FIN(finish)结束
- RST(reset) 重置
- URG(urgent)紧急
- Sequence number顺序号码
- Acknowledge number()确认号码

#### 三次握手 ####

- 第一次握手：主机A发送位码为syn＝1，随机产生seq number=1234567的数据包到服务器，主机B由SYN=1知道，A要求建立联机；
- 第二次握手：主机B收到请求后要确认联机信息，向A发送ack number=(主机A的seq+1)，syn=1，ack=1，随机产生seq=7654321的包；
- 第三次握手：主机A收到后检查ack number是否正确，即第一次发送的seq number+1，以及位码ack是否为1，若正确，主机A会再发送ack number=(主机B的seq+1)，ack=1，主机B收到后确认seq值与ack=1则连接建立成功。

#### TCP常见错误状态 ####

- TCP previous segment lost（TCP先前的分片丢失）
- TCP acked lost segment（TCP应答丢失）
- TCP window update（TCP窗口更新）
- TCP dup ack（TCP重复应答）
- TCP keep alive（TCP保持活动）
- TCP retransmission（TCP重传）
- TCP ACKed unseen segument （TCP看不见确认应答）
- TCP port numbers reused（TCP端口重复使用）
- TCP retransmission（TCP重传）
- TCP fast retransmission (TCP快速重传)
- TCP Previoussegment lost（发送方数据段丢失）
- TCP spurious retransmission(TCP伪重传)

----------

### 2.wireshark过滤器 ###
#### 捕捉过滤器(CaptureFilters) ####
用于决定将什么样的信息记录在捕捉结果中。

    语法： Protocol Direction	Host(s)    Value Logical Operations Other expression   
    例子： tcp dst 10.1.1.1 80 and tcp dst 10.2.2.2 3128

><span style="color:green">**示例：**</span>   
> (host 10.4.1.12 or src net 10.6.0.0/16) and tcp dst port range 200-10000 and dst net 10.0.0.0/8   
> 捕捉IP为10.4.1.12或者源IP位于网络10.6.0.0/16，目的IP的TCP端口号在200至10000之间，并且目的IP位于网络 10.0.0.0/8内的所有封包。

- Protocol（协议）:   
	可能值: ether, fddi, ip, arp, rarp, decnet, lat, sca, moprc, mopdl, tcp and udp.      
	如果没指明协议类型，则默认为捕捉所有支持的协议。

- Direction（方向）:      
	可能值: src, dst, src and dst, src or dst    
	如果没指明方向，则默认使用 "src or dst" 作为关键字。    
	"host 10.2.2.2″与"src or dst host 10.2.2.2"等价。

- Host(s):     
	可能值：net, port, host, portrange.   
	默认使用"host"关键字，"src 10.1.1.1"与"src host 10.1.1.1"等价。

- Logical Operations（逻辑运算）:   
	可能值：not, and, or.   
	否(not")具有最高的优先级。或("or")和与("and")具有相同的优先级，运算时从左至右进行。   
	"not tcp port 3128 and tcp port 23″与"(not tcp port 3128) and tcp port 23″等价。   
	"not tcp port 3128 and tcp port 23″与"not (tcp port 3128 and tcp port 23)"不等价。   


#### 显示过滤器(DisplayFilters) ####
用于在捕捉结果中进行详细查找。

	语法：Protocol String1 String2 Comparison operator Value Logical Operations Other expression
	例子：http request method == "POST" or icmp.type

><span style="color:red">**提示：**</span>   
> wireshark过滤支持比较运算符、逻辑运算符，内容过滤时还能使用位运算。
> 如果过滤器的语法是正确的，表达式的背景呈绿色。如果呈红色，说明表达式有误。

- 依据协议过滤时:   
	可直接通过协议来进行过滤，也能依据协议的属性值进行过滤。
- 按协议进行过滤:   
	snmp || dns || icmp	显示SNMP或DNS或ICMP封包。
- 按协议的属性值进行过滤:
	ip.addr == 10.1.1.1   
	ip.src != 10.1.2.3 or ip.dst != 10.4.5.6   
	ip.src == 10.230.0.0/16	显示来自10.230网段的封包。   
	tcp.port == 25 显示来源或目的TCP端口号为25的封包。   
	tcp.dstport == 25 显示目的TCP端口号为25的封包。   
	http.request.method== "POST" 显示post请求方式的http封包。   
	http.host == "tracker.1ting.com" 显示请求的域名为tracker.1ting.com的http封包。   
	tcp.flags.syn == 0×02 显示包含TCP SYN标志的封包。

- 深度字符串匹配

    `contains: Does the protocol, field or slice contain a value`  
  
><span style="color:green">**示例：**</span>   
>`tcp contains "http"` 显示payload中包含"http"字符串的tcp封。
> `http.request.uri contains "online"` 显示请求的uri包含"online"的http封包。

- 特定偏移处值的过滤
><span style="color:green">**示例：**</span>   
> tcp[20:3] == 47:45:54    
> 16进制形式，tcp头部一般是20字节，所以这个是对payload的前三个字节进行过滤
>http.host[0:4] == "trac"

- 过滤中函数的使用（upper、lower）

	upper(string-field) - converts a string field to uppercase   
	lower(string-field) - converts a string field to lowercase

><span style="color:green">**示例：**</span>    	
>upper(http.request.uri) contains "ONLINE"

----------

### 3.wireshark TCP数据 ###
#### 数据流追踪 ####
一下所有的wireshark都是以2.0为例子，点击任意一个TCP协议传输的数据帧，右键选择追踪流，选择TCP或者SSL，则可以追踪这个TCP连接的数据流。如图3-1所示。之后可以观察到这个TCP数据流传输的数据，并可以把数据保存。

<span style="color:purple">图3-1</span>   
![](http://qingdao.icean.cc:11234/Imgbed/wireshark/3-1.png)

#### 端点（Endpoints） ####
Statistics（统计） → Endpoints是统计当前抓包文件的重要工具，如图3-2所示，可以查看TCP/IP以及UDP等协议的统计结果，也可以根据统计结果进行过滤。

<span style="color:purple">图3-2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/wireshark/3-2.jpg)

#### 序号-时间（Stevens） ####
Statistics（统计） → TCP流图形 → 时间序列（Stevens），可以查看当前文件中某一个TCP时间序列图形，使用PgUP/PgDN切换TCP数据流，使用D键切换目的地址和源地址。如图3-2.2所示。   

也可在切换到其他数据统计，例如图3-2.2红色圈出部分。

<span style="color:purple">图3-2.2</span>   
![](http://qingdao.icean.cc:11234/Imgbed/wireshark/3-2.2.jpg)


#### IO图表 ####
Statistics（统计） → IO图表可以创建一些自定义统计数据，其界面如图3-3所示，以bytes in flight为例子。首先选择过滤器过滤数据包，

<span style="color:purple">图3-3</span>   
![](http://qingdao.icean.cc:11234/Imgbed/wireshark/3-3.jpg)

- 名称：如图3-3中1所示，可以根据需要，写对应的名字。
- 显示过滤器：如图3-3中2所示，可以选取一个过滤器对包进行过滤，图中示例选取的过滤器为一个TCP连接中发发送端的所有数据帧，`ip.src==172.25.221.2 && tcp.port==53400`。具体情况根据作图要求填入对应的过滤器。
- 样式：根据作图需要，使用不同的样式，图中3以点状为例。
- Y轴：选取Y轴的统计方式，如图3-4所示。
- Y字段: 根据需求，填入对应的字段，本示例中填入的为tcp.analysis.bytes_in_flight，可以填入任意的过滤器，例如tcp，ip，http等等。
- 间隔: 根据需求，选择对应到时间间隔，本示例中，选取了缺省的1秒为时间间隔，由于选取的数据包发送时间密度较大，集中在1秒之内，所以出的图像很不明显，将时间间隔调整为0.01秒，图像图3-5所示。


<span style="color:purple">图3-4</span>   
![](http://qingdao.icean.cc:11234/Imgbed/wireshark/3-4.jpg)

<span style="color:purple">图3-5</span>   
![](http://qingdao.icean.cc:11234/Imgbed/wireshark/3-5.jpg)






