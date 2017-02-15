---
title: Linux文件分割
date: 2016/6/24 19:35
description: Linux文件分割
categories: 学习
tags: [shell,linux]
---

### 1. 两个文件的交集、并集

前提条件：取出两个文件的并集(重复的行只保留一份)

{0}. 取出两个文件的并集(重复的行只保留一份)
{0}. 取出两个文件的交集(只留下同时存在于两个文件中的文件)
{0}. 删除交集，留下其他的行


```shell
cat file1 file2 | sort | uniq > file3
cat file1 file2 | sort | uniq -d > file3
cat file1 file2 | sort | uniq -u > file3
```

----------

### 2. 两个文件合并

一个文件在上，一个文件在下

```shell
cat file1 file2 > file3
```

一个文件在左，一个文件在右

```shell
paste file1 file2 > file3
```

----------

### 3. 去掉重复的行
```shell
sort file | uniq
```

注意：重复的多行记为一行，也就是说这些重复的行还在，只是全部省略为一行

```shell
sort file | uniq -u
```

上面的命令可以把重复的行全部去掉，也就是文件中的非重复行。具体细节可以查看，cat，sort，uniq等命令的详细介绍

----------

### 4. 文件分割成多个小文件
#### split分割 

```shell
语法：split [-<行数>][-b <字节>][-C <字节>][-l <行数>][要切割的文件][输出文件名]
gunzip log.txt.gz                                                                            #一定要先解压，否则分割的文件是不能cat/zcat显示；
wc -l log.txt                                                                                   #计算一个文件的总行数；
  
split -l 120000 log.txt newlog                                                       #通过指定行数，将日志分割成两个文件；
du -sh *50M     log.txt

 file *                                                                                              #分割后的文件与原文件属性一样
gzip newlogaa newlogab                                                              #将分割后的文件进行压缩，以便传输
```

#### dd分割 

```shell
gunzip log.txt.gz                                                                             #一定要先解压，否则分割的文件是不能cat/zcat显示
dd bs=20480 count=1500 if=log.txt of=newlogaa                       #按大小分第一个文件
dd bs=20480 count=1500 if=log.txt of=newlogab skip=1500     #将大小之后的生成另一个文件#file *
```

分割没问题，但会出现同一行分到不同文件的情况。

#### head+tail 分割 

```shell
gzip log.txt.gz                                                                                 #如不解压缩，下面请用zcat。
wc -l log.txt                                                                                     #统计一个行数
head -n `echo $((208363/2+1))` log.txt > newloga.txt                   #前x行重定向输出到一个文件中；
tail –n `echo $((208363-208362/2-1))` log.txt >newlogb.txt          #后x行重定向输出到一个文件中；
gzip newloga.txt newlogb.txt                                                         #将两个文件进行压缩
```

#### awk分割 

```shell
 gzip log.txt.gz
 awk  '{if (NR<120000) print $0}' log.txt >newloga.txt
 awk  '{if (NR>=120000) print $0}' log.txt >newlogb.txt
#以上两个命令，都要遍历整个文件，所以考虑到效率，应使用合并成：
awk  '{if (NR<120000) print $0 >"newloga.txt"; if (NR>=120000) print $0>"newlogb.txt"}' log.txt
```

以上四种方法，除了dd之外的三种方式都可以很好的整行分割日志文件。进行分割时，应考虑在读一次文件的同时完成，如不然，按下面的方式分割：

```shell
Cat log.txt | head –12000 >newloga.txt
Cat log.txt | tail –23000 >newlogb.txt
```

如用此方法分割文件的后一部分，那么执行第二行命令文件时，前x行是白白读一遍的，执行的效率将很差，如文件过大，还可能出现内存不够的情况。