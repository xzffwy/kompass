---
title: AWK 学习
date: 2017/1/16 9:07:14 
description:  AWK 学习
categories: 学习
tags: [shell,linux]
---

### 1. 示例文件

示例文件内容如下

~~~bash
$ cat file
Unix,10,A
Linux,30,B
Solaris,40,C
Fedora,20,D
Ubuntu,50,E
~~~

----------

### 2. 操作
#### 在原第一列前处添加新的一列 

~~~bash
$ awk -F, '{$1=++i FS $1;}1' OFS=, file
1,Unix,10,A
2,Linux,30,B
3,Solaris,40,C
4,Fedora,20,D
5,Ubuntu,50,E
~~~

**F**代表分隔符，使用的分割符为 **,** ，将**\$1**替换为**++i** 的结果 加**FS**（分隔符）加原**\$1**，可以理解为`\$1=(++i) + FS + $1`。后面的**1**代表打印全部。可以通过下面方式设置**i**的初始值。**OFS**代表输出的分隔符，也为 **,** 

~~~bash
$ awk -F,  -v=10 '{$1=++i FS $1;}1' OFS=, file
$ awk -F,   '{$1=++i FS $1;}1' i=10 OFS=, file
~~~

如果不只是添加数字，还要添加个前缀，如下

~~~bash
$ awk -F, '{$1="VM"++i FS $1;}1' OFS=, file
~~~

#### 在原最后一列后添加一列

~~~bash
$ awk -F, '{$(NF+1)=++i;}1' OFS=, file
Unix,10,A,1
Linux,30,B,2
Solaris,40,C,3
Fedora,20,D,4
Ubuntu,50,E,5
~~~

**NF**代表一行的列数，**NF+1**列为循环产生的数字，然后打印出来

#### 在原最后一列后添加两列 

~~~bash
$ awk -F, '{$(NF+1)=++i FS "X";}1' OFS=, file
Unix,10,A,1,X
Linux,30,B,2,X
Solaris,40,C,3,X
Fedora,20,D,4,X
Ubuntu,50,E,5,X
~~~

#### 在原倒数第二列前添加一列 

~~~bash
$ awk -F, '{$(NF-1)=++i FS $(NF-1);}1' OFS=, file
Unix,1,10,A
Linux,2,30,B
Solaris,3,40,C
Fedora,4,20,D
Ubuntu,5,50,E
~~~

**NF-1**指倒数第二列

#### 更新一列的内容 

~~~bash
$ awk -F, '{$2+=10;}1' OFS=, file
Unix,20,A
Linux,40,B
Solaris,50,C
Fedora,30,D
Ubuntu,60,E
~~~

#### 大小写转化

~~~bash
$ awk -F, '{$1=toupper($1)}1' OFS=, file
UNIX,10,A
LINUX,30,B
SOLARIS,40,C
FEDORA,20,D
UBUNTU,50,E
~~~

#### 字符串截取

~~~bash
$ awk -F, '{$1=substr($1,0,3)}1' OFS=, file
Uni,10,A
Lin,30,B
Sol,40,C
Fed,20,D
Ubu,50,E
~~~

#### 清空某一列 

~~~bash
$ awk -F, '{$2="";}1' OFS=, file
Unix,,A
Linux,,B
Solaris,,C
Fedora,,D
Ubuntu,,E
~~~

#### 删除某一列

~~~bash
$ awk -F, '{for(i=1;i<=NF;i++) if(i!=x) f=f?f FS $i:$i; print f; f=""}' x=2 file
Unix,A
Linux,B
Solaris,C
Fedora,D
Ubuntu,E
~~~

**for(i=1;i<=NF;i++)**处理每一行的每一列， **if(i!=x)**判断当前列号是否要删除，如果要删除的，不执行下面的步骤。 **f=f?f FS \$i:\$i**，如果f没被赋值，则是**$i**，如果已经赋值了，则为**f FS \$i**

#### 修改分隔符

~~~bash
$ awk -F, '{$2=$2":"$x; for(i=1;i<=NF;i++) if(i!=x) f=f?f FS $i:$i; print f;f=""}' x=3 file
Unix,10:A
Linux,30:B
Solaris,40:C
Fedora,20:D
Ubuntu,50:E
~~~
---

### 3. 拓展

- head和tail如果选择多个范围

---

### 4. 例子

~~~bash
awk  '{$(NF+1)="z52-vm"++i; $(NF+1)="130.5.70."++j;print}' j=131 floating_ip_disassociate.sh
~~~



