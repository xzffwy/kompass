---
title: Centos 6.x Hadoop 安装
date: 2016/9/29 9:49:19 
description: Centos 6.x Hadoop 安装
categories: 技术
tags: [hadoop,linux]
---

### 1.简介 ###
Hadoop可分为**分布式安装**以及**伪分布式安装**，以分布式安装的方式安装Hadoop，可以更好地体验Hadoop的分布式工作的原理。然而，安装设备可能是一个问题，找不到那么多的Linux主机来安装Hadoop，以及要维护这些Linux主机之间的通信，这都是一系列问题。以下为我设计的Hadoop安装方案。

- 所需软件
  - VirtualBox
  - Xshell
  - XFTP

----------

### 2.逻辑拓扑 ###
Hadoop的结构为主从结构，即为master和slave，可能有一个master多个slave，也可能存在多个master节点，多个master节点中一个启用，其他的为备用。master节点维护Hadoop的namenode，维护着所存储文件的元数据，slave节点具体存储数据块。其中逻辑拓扑如图1-1所示。

<center>![图1-1](http://qingdao.icean.cc:11234/Imgbed/Hadoop/hadoop-tpg.png)</center> 
<center style="color:purple">**图1-1**</center>   

其中IP地址表为如表1-1所示。

| 主机名    | IP地址           | 备注             |
| ------ | -------------- | -------------- |
| MyPC   | 10.10.10.10/24 | windows换汇接口    |
| Master | 10.10.10.1/24  | 桥接到Windows环回接口 |
| Slave1 | 10.10.10.2/24  | 桥接到Windows环回接口 |
| Slave2 | 10.10.10.3/24  | 桥接到Windows环回接口 |

<center style="color:purple">**表1-1**</center>

----------
### 3.环境搭建 ###
使用VirtualBox创建三个CentOS 6.x的虚拟机，这里建议创建CentOS minimal虚拟机，这样可以节省计算机内存，鉴于Hadoop的所有安装都是在命令行下， 所以极力建议只安装纯命令行的虚拟机。可以先创建一个虚拟机，然后克隆其他两个虚拟机。在虚拟机创建成功之后，关闭虚拟机并修改虚拟机的网卡文件。

####  Windows环回端口 ####
添加Windows环回端口的意义在于可以把Windows加入到Hadoop虚拟机集群之间的局域网中，如何创建Windows环回端口，请自行Google或者Baidu，创建环回端口之后，设置环回端口的静态IP。如图2-1所示,将环回接口IP设置为10.10.10.10/24。

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/loopback.jpg)</center>
<center style="color:purple">**图2-1**</center>  

####  修改虚拟机网口接口 ####
为每个虚拟机添加三张网卡，第一张网卡VirtualBox配置如图2-2所示，网卡模式为NAT模式，用于虚拟机连接外网，对应CentOS的eth0。

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/vm-net1.jpg)</center>
<center style="color:purple">**图2-2**</center>   

第二张网卡如图2-3所示，对应CentOS的eth1，该网卡用于Windows SSH登录虚拟机，为host-only模式。
><span style="color:red">**提示：**</span>也可以通过其他网卡SSH登录虚拟机，例如下面介绍的第三个网卡。但是仍然推荐通过使用host-only网卡SSH登录虚拟机。

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/vm-net2.jpg)</center>
<center style="color:purple">**图2-3**</center> 

第三个网卡如图2-4所示，对应CentOS的eth2，用于Windows与Hadoop虚拟机集群之间的通信，也用于hadoop集群之间的通信，该网卡桥接到Windows之前创建的环回端口，这样在逻辑上，三台虚拟机和Windows都在一个局域网中了。   

><span style="color:red">**提示：**</span>该网卡也可以桥接到Windows的任何一张物理网卡，但是物理网卡可能用于上网，所以推荐桥接到Windows的环回接口，环回接口也不影响Windows正常上网。

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/vm-net3.jpg)</center>
<center style="color:purple">**图2-4**</center> 

####  虚拟机网卡设置 ####
删除克隆虚拟机网卡遗留信息，克隆的虚拟机会重置MAC地址，但是CentOS系统不会自动更新信息，需要清理清理历史网卡信息，删除如图2-5所示的文件。删除该文件之后，重启虚拟机。

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/hadoop-1.png)</center>   <center style="color:purple">**图2-5**</center>


以一台虚拟机为例，创建虚拟机网卡文件并修改其中的MAC地址以及IP地址，缺省只有eth0的文件，切换目录到网卡文件下,并创建其他两张网卡文件。

```shell
cd /etc/sysconfig/network-script
cp ifcfg-eth0 ifcfg-eth1
cp ifcfg-eth0 ifcfg-eth2
```


修改ifcfg-eth0
​	
```shell
vi ifcfg-eth0
```

```shell
DEVICE=eth0
HWADDR=08:00:27:B4:01:1F
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
```

MAC地址修改为VirtualBox网卡的MAC地址，该MAC为图2-2中的MAC地址。ONBOOT=yes是必要的，这样网卡会开机启动，获取地址的方式为DHCP。

修改ifcfg-eth1

```shell
vi ifcfg-eth0 
```

```shell
DEVICE=eth1
HWADDR=08:00:27:CB:C7:DE
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
```

修改ifcfg-eth2

```shell
vi ifcfg-eth0 
```

```shell
DEVICE=eth2
HWADDR=08:00:27:9D:D9:4C
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=none
IPADDR=10.10.10.1
NETMASK=255.255.255.0
```

该网卡地址为静态IP地址。

设置好三张网卡的信息之后，重启网络服务。
​	
```shell
service network restart
```

#### SSH到虚拟机 ####
在VirtualBox下查看虚拟机eth1的IP地址
​	
```shell
ifconfig eth1
```

通过查询的到的IP地址，在Windows下使用xshell SSH到虚拟机，这样可以在xhell下更方便地操作命令行。

#### 测试网络通信 ####
在Windows cmd模式下分别ping其他三台虚拟机IP地址，若可以ping通，则进入Hadoop安装的环节，若ping不通，可能的原因如下：

- 虚拟机防火墙：关闭虚拟机的防火墙；
- IP地址配置错误：查看虚拟机eth2的IP信息；
- Windows环回接口IP地址与虚拟机eth2的IP不在一个网段。


----------

### 4.Hadoop安装 ###
#### 准备工作 ####
将`hadoop-2.6.0.tar.gz`和`jdk-7u75-linux-x64.tar`以及相关xml文件通过xftp传送不过到虚拟机/root目录下，三台虚拟机都如此操作。文件下载地址请点[这里](http://pan.baidu.com/s/1gdJgh4B)。

#### 创建hadoop账户 ####
在三台虚拟机上均创建hadoop账户。

```shell
useradd hadoop
passwd hadoop
```



#### JDK安装 ####
Hadoop需要JDK的支持，需要在所有的虚拟机节点上安装JDK环境，首先解压安装JDK。

```shell
cd /opt/
cp /root/jdk-7u75-linux-x64.tar.gz  ./
tar xzf jdk-7u75-linux-x64.tar.gz
cd /opt/jdk1.7.0_75/
alternatives --install /usr/bin/java java /opt/jdk1.7.0_75/bin/java 2
alternatives --config java
alternatives --install /usr/bin/jar jar /opt/jdk1.7.0_75/bin/jar 2
alternatives --install /usr/bin/javac javac /opt/jdk1.7.0_75/bin/javac 2
alternatives --set jar /opt/jdk1.7.0_75/bin/jar
alternatives --set javac /opt/jdk1.7.0_75/bin/javac
```

设置设置环境变量。

```shell
echo 'export JAVA_HOME=/opt/jdk1.7.0_75' >> /etc/profile
echo 'export JRE_HOME=/opt/jdk1.7.0_75/jre' >> /etc/profile
echo 'export PATH=$PATH:/opt/jdk1.7.0_75/bin:/opt/jdk1.7.0_75/jre/bin' >> /etc/profile
```

#### Hadoop基础安装 ####
首先解压文件。

```shell
cd /home/hadoop
cp /root/hadoop-2.6.0.tar.gz ./
tar -zxvf hadoop-2.6.0.tar.gz
rm -rf hadoop-2.6.0.tar.gz
mv hadoop-2.6.0 hadoop
```

创建tmp文件夹以及节点数据存储文件夹。

```shell
cd hadoop
mkdir tmp hadoopdata hadoopdata/hdfs hadoopdata/hdfs/datanode1 hadoopdata/hdfs/datanode2 
mkdir hadoopdata/hdfs/namenode1 hadoopdata/hdfs/namenode2
```

配置环境变量。

```shell
echo 'export HADOOP_INSTALL=/home/hadoop/hadoop' >>/etc/profile 
echo 'export PATH=${PATH}:${HADOOP_INSTALL}/bin:${HADOOP_INSTALL}/sbin' >>/etc/profile 
echo 'export HADOOP_MAPRED_HOME=${HADOOP_INSTALL}' >>/etc/profile 
echo 'export HADOOP_COMMON_HOME=${HADOOP_INSTALL}' >>/etc/profile 
echo 'export HADOOP_HDFS_HOME=${HADOOP_INSTALL}' >>/etc/profile 
echo 'export YARN_HOME=${HADOOP_INSTALLL}' >>/etc/profile 
echo 'export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_INSTALL}/lib/natvie' >>/etc/profile 
echo 'export HADOOP_OPTS="-Djava.library.path=${HADOOP_INSTALL}/lib:${HADOOP_INSTALL}/lib/native"' >>/etc/profile 
source /etc/profile
```

很重要，否则无法启动hadoop进程。

```shell
echo 'export JAVA_HOME=/opt/jdk1.7.0_75' >> hadoop/etc/hadoop/hadoop-env.sh
echo 'export HADOOP_HOME_WARN_SUPPRESS=1' >> hadoop/etc/hadoop/hadoop-env.sh
echo 'export JAVA_HOME=/opt/jdk1.7.0_75' >> hadoop/etc/hadoop/yarn-env.sh
```

#### master节点配置 ####
对master节点进行一些配置。
​	
关闭iptables，防止其阻碍hadoop节点之间通信。

```shell
service iptables stop
chkconfig iptables off
```

修改主机hostname为master

```shell
HOSTNAME=master
hostname $HOSTNAME
sed -i "s/^HOSTNAME=.*/HOSTNAME=$HOSTNAME/g" /etc/sysconfig/network
```

备份配置文件。

```shell
cd /home/hadoop/hadoop/etc/hadoop
mv masters masters.bak
mv slaves slaves.bak
mv core-site.xml core-site.xml.bak
mv hdfs-site.xml hdfs-site.xml.bak
mv mapred-site.xml mapred-site.xml.bak
mv yarn-site.xml yarn-site.xml.bak
```

拷贝新的配置文件。

```shell
cp /root/xml/core-site.xml ./
cp /root/xml/hdfs-site.xml ./
cp /root/xml/mapred-site.xml ./
cp /root/xml/yarn-site.xml ./
```

><span style="color:red">**提示：**</span>配置文件的内容，请自行参考官网，在这里不进行赘述，配置文件中涉及的参数过多，本文只修改其中一些比较重要的参数。


根据主机的IP地址，修改配置文件，将配置文件core-site.xml、mapred-site.xml、hdfs-site.xml、yarn-site.xml中master_ipaddr字段替换为eth2的IP地址。

```shell
master_ip=$(ifconfig eth2 | awk -F':' '/inet addr/{split($2,_," ");print _[1]}')
sed -i "s/master_ipaddr/$master_ip/g" core-site.xml mapred-site.xml hdfs-site.xml  yarn-site.xml
```

修改hdfs-site.xml中的replications字段为2，鉴于有两个slave节点，实际生产环境数量一般为3。

```shell
sed -i "s/replications/2/g" hdfs-site.xml
```

修改hosts文件。

```shell
mv /etc/hosts /etc/hosts.bak
echo "10.10.10.1 master
10.10.10.2 slave1
10.10.10.3 slave2">>/etc/hosts
```

修改master、slave的IP列表。

```shell
cd /home/hadoop/etc/hadoop
echo "10.10.10.1">>masters
echo "10.10.10.2
10.10.10.3">>slaves
```

#### slave节点配置 ####
步骤与master节点配置基本一致，只有在主机名配置不太一样，$1在执行脚本时手动指定。

```shell
HOSTNAME=$1
hostname $HOSTNAME
sed -i "s/^HOSTNAME=.*/HOSTNAME=$HOSTNAME/g" /etc/sysconfig/network
```

#### 修改文件属主以及所属组群 ####
将hadoop的属组以及组群设置为hadoop。

```shell
cd /home/hadoop
chown -R hadoop:hadoop hadoop
chgrp -R hadoop hadoop
```

#### 免密码SSH登录 ####
hadoop集群要求master节点可以免密码SSH登录slave节点，slave节点也可以免密码登录master
节点。以master主机为例，首先切换到hadoop账户下。

```shell
su hadoop
```

生成一对公私钥，全部回车即可，生成的目录在~/.ssh下。

```shell
ssh-keygen
```

将生成的公钥 id_rsa.pub 追加到 ~/.ssh/authorized_keys中

```shell
cat ~/.ssh/id_rsa.pub>> ~/.ssh/authorized_keys
```

修改~/.ssh文件权限为600，否则无法免密码登录。这样，master主机就可ssh免密码登录本机，如图3-1所示。

```shell
ssh master
```

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/hadoop-5.jpg)</center> 
<center style="color:purple">**图3-1**</center> 

将master主机的公钥 id_rsa.pub 拷贝到所有slave节点上。

```shell
scp ~/.ssh/id_rsa.pub hadoop@slave1:~/
scp ~/.ssh/id_rsa.pub hadoop@slave2:~/
```

在slave节点下， 把master的 id_rsa.pub 追加到 ~/.ssh/authorized_keys中并删除master 公钥。
​	
```shell
cat ~/id_rsa.pub>> ~/.ssh/authorized_keys
rm -rf ~/id_rsa.pub
```

这样master节点可以免密码ssh登录所有的slave节点了，如图3-2，图3-3所示。

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/hadoop-6.jpg)</center>
<center style="color:purple">**图3-2**</center>  

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/hadoop-7.jpg)</center> 
<center style="color:purple">**图3-3**</center>  

同样的道理，slave节点也生成一对公私钥，并把公钥追加到master的~/.ssh/authorized_keys中，这样slave节点均可免密码ssh登录master节点了。

><span style="color:red">**提示：**</span>以上关于免密码SSH登录的配置均在master和slave的hadoop账户下进行的， 免密码登录的是主机之间的hadoop账户，若需要root账户之间免密码登录，需要另行配置。还有很重要的一点是~/.ssh文件夹的权限必须是700

----------

### 5.hadoop启动运行 ###
#### 脚本启动hadoop ####
以下操作均在master节点下   
格式化master节点，即格式化namenode

```shell
~/hadoop/bin/hdfs namenode -format
```

启动HDFS服务

```shell
~/hadoop/sbin/start-dfs.sh
```

服务启动成功之后，在浏览器地址栏输入[http://10.10.10.1:50070](http://10.10.10.1:50070)进入hdfs管理页面。如图4-1所示

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/hadoop-9.jpg)</center>
<center style="color:purple">**图4-1**</center> 

启动yarn服务,用于任务管理。
​	
	~/hadoop/sbin/start-yarn.sh
服务启动成功之后，在浏览器地址栏输入[http://10.10.10.1:8088](http://10.10.10.1:50070)进入mapreduce任务管理页面，如图4-2所示。

<center>![](http://qingdao.icean.cc:11234/Imgbed/Hadoop/hadoop-10.jpg)</center> 
<center style="color:purple">**图4-2**</center>  

><span style="color:red">**提示：**</span>在主机下可以使用jps命令查看hadoop的相关进程。


#### hadoop相关操作 ####

假设HADOOP_HOME已经写入环境变量，则以下操作可以在任何路径执行，若hadoop命令无法执行，请执行source /etc/profile。

查看文件列表，找到了hdfs中/user下的文件。

```shell
hadoop fs -ls /user
```

可以列出hdfs中/user目录下的所有文件（包括子目录下的文件）。

```shell
hadoop fs -lsr /user
```

创建文件目录，查看hdfs中/user目录下再新建一个叫做newDir的新目录。

```shell
hadoop fs -mkdir /user/newDir
```

删除文件，删除hdfs中/user目录下一个名叫needDelete的文件

```shell
hadoop fs -rm /user/needDelete
```

删除hdfs中/user目录以及该目录下的所有文件

```shell
hadoop fs -rmr /user
```

上传文件，上传一个本机/home/admin/newFile的文件到hdfs中/user目录下

```shell
hadoop fs –put /home/admin/newFile /user/
```

下载文件，下载hdfs中/user目录下的newFile文件到本机/home/admin/newFile中

```shell
hadoop fs –get /user/newFile /home/admin/newFile
```

查看文件，可以直接在hdfs中直接查看文件，功能与类是cat类似，查看hdfs中/user目录下的newFile文件

```shell
hadoop fs –cat /home/admin/newFile
```

提交MAPREDUCE JOB，原则上说，Hadoop所有的MapReduce Job都是一个jar包。运行一个/home/admin/hadoop/job.jar的MapReduce Job

```shell
hadoop jar ~/hadoop/job.jar [jobMainClass] [jobArgs]
```

杀死某个正在运行的JOB，假设Job_Id为：job_201005310937_0053

```shell
hadoop job -kill job_201005310937_0053
```

><span style="color:red">**提示：**</span>完整Hadoop安装脚本轻点击[这里](http://pan.baidu.com/s/1dDdSF9R)