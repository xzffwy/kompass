---
title: CentOS 批量添加 sftp 用户
date: 2016/9/9 14:59:17
description: CentOS 批量添加 sftp 用户
categories: 技术
tags: [linux]
---

### 1.开启 SFTP服务
#### 需求
- 用户只能通过sftp访问，不能登录SSH
- 用户要被锁定在特定的目录下，没有读写其它目录的权限

#### ssh配置文件修改

~~~
#Subsystem sftp /usr/lib/openssh/sftp-server
Subsystem sftp internal-sftp 
~~~
该行(上面这行)注释掉，并添加新配置
~~~
Match group sftp
~~~
匹配sftp组，如为单个用户可用：Match user 用户名;  设置此用户登陆时的shell设为/bin/false,这样它就不能用ssh只能用sftp
~~~
ChrootDirectory /home/
~~~
指定用户被锁定到的那个目录，为了能够chroot成功，该目录必须属主是root，并且其他用户或组不能写

----------

### 2.添加sftp用户
#### 创建sftp用户组
创建sftp用户组，并查看group ID
~~~
groupadd sftp
cat /etc/group | grep sftp | awk -F ':' '{print $3}'
~~~


#### 添加用户
添加用户,并分配给sftp用户组
~~~
useradd -d /home/test -m -s /bin/false -g sftp test
~~~

#### 修改密码
修改添加用户的密码

----------

### 3.批量添加sftp用户
#### 查看sftp组id
查看sftp的组id，假设组id是502
~~~
cat /etc/group | grep sftp | awk -F ':' '{print $3}'
502
~~~
#### 添加用户
根据`/etc/passwd`中的格式，批量添加用户，其中**503**为**用户id**，**502**为**组id**，将如下内容保存到一个文件**userlis**t中。
~~~
asbd:x:503:502::/home/asbd:/bin/false
baowentao:x:504:502::/home/baowentao:/bin/false
fuzhangbin:x:505:502::/home/fuzhangbin:/bin/false
hourui:x:506:502::/home/hourui:/bin/false
ncis:x:507:502::/home/ncis:/bin/false
network:x:508:502::/home/network:/bin/false
network-system:x:509:502::/home/network-system:/bin/false
storage:x:510:502::/home/storage:/bin/false
yueyinliang:x:511:502::/home/yueyinliang:/bin/false
~~~

执行 newusers命令，添加用户
~~~
newusers userlist
~~~

#### 修改用户密码
创建用户密码文件，内容如下，保存到名为**passwd**文件中
~~~
asbd:123456
baowentao:123456
fuzhangbin:123456
hourui:123456
ncis:123456
network:123456
network-system:123456
storage:123456
yueyinliang:123456
~~~

执行命令`/usr/sbin/pwunconv`，将/etc/shadow产生的shadow密码解码，然后回写到/etc/passwd中， 并将`/etc/shadow的shadow`密码栏删掉。这是为了方便下一步的密码转换工作，即先取消shadow password功能，关闭影子文件
~~~
pwunconv
~~~

用`chpasswd`批量修改密码
~~~
chpasswd < passwd
~~~

恢复影子文件，保证安全
~~~
pwconv
~~~

#### 4.脚本 ####
添加用户
~~~
#!/bin/bash
newusers userlist
pwunconv
chpasswd < passwd
pwconv
~~~

更新密码
~~~
pwunconv
chpasswd < passwd
pwconv
~~~
