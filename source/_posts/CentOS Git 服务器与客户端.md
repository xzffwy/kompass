---
title: CentOS Git 服务器与客户端使用
date: 2016/6/18 9:07:14 
description: CentOS Git 服务器与客户端使用
categories: 技术
tags: [git,linux]
---

### 1.git服务器搭建
####  软件安装
以root用户执行如下命令

	yum install python python-setuptools
	cd /usr/local/src
	git clone git://github.com/res0nat0r/gitosis.git
	cd gitosis
	python setup.py install  

显示Finished processing dependencies for gitosis==0.2即表示成功

####  上传客户端密钥
可以在客户端hosts文件中添加git服务器的解析，方便使用，下面都以qingdao为例

	192.168.1.1 qingdao

在客户端Linux主机上，执行如下命令，并将起产生的公钥复制下来，或者通过scp复制到git服务器。

	ssh-keygen -t rsa
	scp ~/.ssh/id_rsa.pub tailin@qingdao:/tmp/

#### git用户创建
创建git用户

	 useradd -c 'git version manage' -m -d /home/git -s /bin/bash  git

切换到git用户并初始化gitosis

	 su - git
	 gitosis-init < /tmp/id_rsa.pub

显示以下信息即表示成功

	Initialized empty Git repository in /home/git/repositories/gitosis-admin.git/
	Reinitialized existing Git repository in /home/git/repositories/gitosis-admin.git/

删除之前上传的客户端密钥，同时要保证git用户文件夹下.ssh文件夹的权限为700，.ssh/中所有的文件权限为644，否则无法免密码登陆。也不要擅自修改.ssh文件夹中文件的权限。


----------

### 2.客户端设置
####  导出管理项目
假设客户端为root@tokyo，在客户端的任意目录下，导出管理项目

	mkdir repo
	cd repo
	git clone git@qingdao:gitosis-admin.git

#### 增加及设置管理项目
在个人开发机增加及设置管理项目

	cd repo/gitosis-admin

查看git服务器已经上传密钥,root@tokyo.pub为已经上传的客户端生成的公钥。

	ls keydir  
	cat keydir/root@tokyo.pub  

编译项目管理配置文件

	vi gitosis.conf

在文件尾增加以下内容

	[group test]            # 具有写权限的组名称
	writable = test         # 该组可写的项目名称
	members = root@tokyo root2@tokyo    #该组的成员(密钥用户名) 多个用户协同开发时，以空格分隔

 如果要增加只读的组 参考如下

	[group test-readnoly]          # 具有都权限的组名称 
	readonly = test               # 该组只读的项目名称 
	members = root3@tokyo     # 该组的成员


在`repo/gitosis-admin/keydir`中加入公钥`root3@host.pub,root2@tokyo.pub`,注意**root2@tokyo**对应的公钥名称为**root2@host.pub**

提交修改，这样增加了一个test的git项目，并增加了一个root2@tokyo的可写权限成员，以及一个root3@tokyo的只读权限成员。

	git add .
	git commit -a -m "add test repo"
	git push

#### 初始，增加及使用项目test
在客户端初始化，增加以及使用test项目

	cd ~/repo  
	mkdir test  
	cd test 
	git init  
	touch readme  
	git add .   
	git commit -a -m "init test-git"  
	git remote add origin git@qingdao:test.git  
	git push origin master  

#### 添加项目管理员
添加名为root@ovzinp的管理员，添加members成员

	[group gitosis-admin]
	members = root@tokyo root@ovzinp                                                        
	writable = gitosis-admin

在`repo/gitosis-admin/keydir`中加入公钥root@ovzinp.pub,注意**root2@ovzinp**对应的公钥名称为**root2@host.pub**,然后提交修改。

	git add .
	git commit -a -m "add admin"
	git push

#### 项目管理员添加新项目
在root@ovzinp的主机上，首先导出管理的git项目，然后按照***增加及设置管理项目***中的步骤添加新的项目。

>**提示：** 在首次添加git项目时候，需要配置用户名和邮箱，命令如下
>git config --global user.name "xxx"
>git config --global user.email "xxx@example.com"


----------

### 3.Git常用命令
#### 远程仓库相关命令

- 检出仓库：        $ git clone git://github.com/jQuery/jquery.git

- 查看远程仓库：$ git remote -v

- 添加远程仓库：$ git remote add [name] [url]

- 删除远程仓库：$ git remote rm [name]

- 修改远程仓库：$ git remote set-url --push [name] [newUrl]

- 拉取远程仓库：$ git pull [remoteName] [localBranchName]

- 推送远程仓库：$ git push [remoteName] [localBranchName]

如果想把本地的某个分支test提交到远程仓库，并作为远程仓库的master分支，或者作为另外一个名叫test的分支，如下：

	$git push origin test:master         // 提交本地test分支作为远程的master分支
	$git push origin test:test              // 提交本地test分支作为远程的test分支


#### 分支(branch)操作相关命令

- 查看本地分支：$ git branch

- 查看远程分支：$ git branch -r

- 创建本地分支：$ git branch [name] ----注意新分支创建后不会自动切换为当前分支

- 切换分支：$ git checkout [name]

- 创建新分支并立即切换到新分支：$ git checkout -b [name]

- 删除分支：$ git branch -d [name] ----d选项只能删除已经参与了合并的分支，对于未有合并的分支是无法删除的。如果想强制删除一个分支，可以使用-D选项

- 合并分支：$ git merge [name] ----将名称为[name]的分支与当前分支合并

- 创建远程分支(本地分支push到远程)：$ git push origin [name]

- 删除远程分支：$ git push origin :heads/[name] 或 $ gitpush origin :[name] 


创建空的分支：(执行命令之前记得先提交你当前分支的修改，否则会被强制删干净没得后悔)

	$git symbolic-ref HEAD refs/heads/[name]
	$rm .git/index
	$git clean -fdx


#### 版本(tag)操作相关命令

- 查看版本：$ git tag

- 创建版本：$ git tag [name]

- 删除版本：$ git tag -d [name]

- 查看远程版本：$ git tag -r

- 创建远程版本(本地版本push到远程)：$ git push origin [name]

- 删除远程版本：$ git push origin :refs/tags/[name]

- 合并远程仓库的tag到本地：$ git pull origin --tags

- 上传本地tag到远程仓库：$ git push origin --tags

- 创建带注释的tag：$ git tag -a [name] -m 'yourMessage'


#### 子模块(submodule)相关操作命令

- 添加子模块：$ git submodule add [url] [path]
 如：$git submodule add git://github.com/soberh/ui-libs.git src/main/webapp/ui-libs

- 初始化子模块：$ git submodule init  ----只在首次检出仓库时运行一次就行

- 更新子模块：$ git submodule update ----每次更新或切换分支后都需要运行一下

- 删除子模块：（分4步走哦）
	1) $ git rm --cached [path]
	2) 编辑“.gitmodules”文件，将子模块的相关配置节点删除掉
	3) 编辑“ .git/config”文件，将子模块的相关配置节点删除掉
	4) 手动删除子模块残留的目录


#### 忽略一些文件、文件夹不提交
在仓库根目录下创建名称为“.gitignore”的文件，写入不需要的文件夹名或文件，每个元素占一行即可，如
target
bin
*.db

----------

### 4.Git命令详解
- **git pull**：从其他的版本库（既可以是远程的也可以是本地的）将代码更新到本地，例如：'git pull origin master'就是将origin这个版本库的代码更新到本地的master主枝，该功能类似于SVN的update

- **git add**：是将当前更改或者新增的文件加入到Git的索引中，加入到Git的索引中就表示记入了版本历史中，这也是提交之前所需要执行的一步，例如'git add app/model/user.rb'就会增加app/model/user.rb文件到Git的索引中，该功能类似于SVN的add

- **git rm**：从当前的工作空间中和索引中删除文件，例如'git rm app/model/user.rb'，该功能类似于SVN的rm、del

- **git commit**：提交当前工作空间的修改内容，类似于SVN的commit命令，例如'git commit -m story #3, add user model'，提交的时候必须用-m来输入一条提交信息，该功能类似于SVN的commit

- **git push**：将本地commit的代码更新到远程版本库中，例如'git push origin'就会将本地的代码更新到名为orgin的远程版本库中
- **git log**：查看历史日志，该功能类似于SVN的log

- **git revert**：还原一个版本的修改，必须提供一个具体的Git版本号，例如'git revert bbaf6fb5060b4875b18ff9ff637ce118256d6f20'，Git的版本号都是生成的一个哈希值

上面的命令几乎都是每个版本控制工具所公有的，下面就开始尝试一下Git独有的一些命令：

- **git branch**：对分支的增、删、查等操作，例如'git branch new_branch'会从当前的工作版本创建一个叫做new_branch的新分支，'git branch -D new_branch'就会强制删除叫做new_branch的分支，'git branch'就会列出本地所有的分支

- **git checkout**：Git的checkout有两个作用，其一是在不同的branch之间进行切换，例如'git checkout new_branch'就会切换到new_branch的分支上去；另一个功能是还原代码的作用，例如'git checkout app/model/user.rb'就会将user.rb文件从上一个已提交的版本中更新回来，未提交的内容全部会回滚

- **git rebase**：用下图解释会比较清楚一些，rebase命令执行后，实际上是将分支点从C移到了G，这样分支也就具有了从C到G的功能

***图4-1***
![](http://i.imgur.com/BPXfTmi.png)

- **git reset**：将当前的工作目录完全回滚到指定的版本号，假设如图4-2，我们有A-G五次提交的版本，其中C的版本号是 bbaf6fb5060b4875b18ff9ff637ce118256d6f20，我们执行了'git reset bbaf6fb5060b4875b18ff9ff637ce118256d6f20'那么结果就只剩下了A-C三个提交的版本
	- git reset –soft 只撤销commit，保留working tree和index file。

	- git reset –hard 撤销commit、index file和working tree，即撤销销毁最近一次的commit
	
	- git reset –mixed 撤销commit和index file，保留working tree
	
	- git reset和git reset –mixed完全一样

	- git reset –用于删除登记在index file里的某个文件

***图4-2***
![](http://i.imgur.com/nmpak8V.png)

- **git stash**：将当前未提交的工作存入Git工作栈中，时机成熟的时候再应用回来，这里暂时提一下这个命令的用法，后面在技巧篇会重点讲解

- **git config**：利用这个命令可以新增、更改Git的各种设置，例如'git config branch.master.remote origin'就将master的远程版本库设置为别名叫做origin版本库，后面在技巧篇会利用这个命令个性化设置你的Git，为你打造独一无二的 Git

- ** git tag**：可以将某个具体的版本打上一个标签，这样你就不需要记忆复杂的版本号哈希值了，例如你可以使用'git tag revert_version bbaf6fb5060b4875b18ff9ff637ce118256d6f20'来标记这个被你还原的版本，那么以后你想查看该版本时，就可以使用 revert_version标签名，而不是哈希值了


----------

### 5.Git服务器搭建排错
####  Untracked working tree file 'external/broadcom/Android.mk' would be overwritten by merge.  Aborting
需要执行下面的命令才能修复：

	git reset --hard HEAD    
	git clean -f -d    
	git pull    

####  Please, commit your changes or stash them before you can merge.
如果希望保留生产服务器上所做的改动,仅仅并入新配置项, 处理方法如下:

	git stash
	git pull
	git stash pop

然后可以使用Git diff -w +文件名 来确认代码自动合并的情况.

反过来,如果希望用代码库中的文件完全覆盖本地工作版本. 方法如下:

	git reset --hard
	git pull

其中git reset是针对版本,如果想针对文件回退本地修改,使用

	git checkout HEAD file/to/restore    

####  does not appear to be a git repository
路径错误，可以分别尝试绝对路径或者相对路径

如果是把另一个服务器的纯仓库弄到服务器，也会出现这种情况。我的临时做法是把另一个服务器的内容clone到本地服务器，然后在本地服务器创建纯仓库，放到repository的路径下，就可以了。有关这个错误，我在这篇文章里尝试寻找原因：

[http://blog.csdn.net/xzongyuan/article/details/9366873](http://blog.csdn.net/xzongyuan/article/details/9366873)

#### ERROR:gitosis.serve.main:Repository read access denied
修改本地gitosis-admin的gitosis-conf后（如下），push到仓库中，还会遇到该问题

	[group customer]
	members = nexus b
	readonly = box_4.2

**原因1：gitosis.conf写错**
gitosis.conf中的members与keydir中的用户名不一致，如gitosis中的members = foo@bar，但keydir中的公密名却叫foo.pub
解决
使keydir的名称与gitosis中members所指的名称一致。
改为members = foo 或 公密名称改为foo@bar.pub

参考
[http://blog.csdn.net/lixinso/article/details/6526643](http://blog.csdn.net/lixinso/article/details/6526643)

注意，中间如果遇到这样的错误，很可能是gitosis.conf配置的不对
ERROR:gitosis.serve.main:Repository read access denied
fatal: The remote end hung up unexpectedly

有可能是：

- gitosis 中写的用户名，和keydir里面的key的名字没有完全对应上
- 有的地方写错了，比如我把members写成了member


****原因2：地址错误：**

虽然有时候，地址错误时，会提示did not apear to be a git repositry。但我也遇到这个错误，写错了相对路径，就会提示没有权限，因为gitosis.conf根本就没有这个文件的配置嘛。可以看看我的记录：

第一次，写错相对路径，自己不知道：

	norton@norton-laptop:~/work$ git clone git@192.168.0.3:/repositories/gitosis-admin.git
	Initialized empty Git repository in /home/norton/work/gitosis-admin/.git/
	ERROR:gitosis.serve.main:Repository read access denied
	fatal: The remote end hung up unexpectedly

第二次，故意写个不存在的路径

	norton@norton-laptop:~/work$ git clone git@192.168.0.3:/repositories/gitosis-admin.git2
	Initialized empty Git repository in /home/norton/work/gitosis-admin.git2/.git/
	ERROR:gitosis.serve.main:Repository read access denied
	fatal: The remote end hung up unexpectedly

第三次，写对相对路径。可见，相对路径的根目录是/home/git/repositories，记得不要多写了不必要的路径。提示一下，repositories是在初始化gitosis前就已经手动建立的，是一个软链接，链接到/home/repo。如果没做这一步，初始化的时候就会建立一个repositories文件夹，那么gitosis-admin这个仓库就会在这个实在的文件夹下，而不会通过软连接放到/home/repo中

	norton@norton-laptop:~/work$ git clone git@192.168.0.3:gitosis-admin.git
	Initialized empty Git repository in /home/norton/work/gitosis-admin/.git/
	remote: Counting objects: 5, done.
	remote: Compressing objects: 100% (5/5), done.
	remote: Total 5 (delta 0), reused 5 (delta 0)
	Receiving objects: 100% (5/5), done.

**原因3：开错账户**

有时候，头脑不清醒了，就会弄错账户，所以犯这个错，要思考下是不是搞错账户了，在主帐号admin中，不断地测试下载，而我的目的其实是用b的帐号测试下载。如配置如下（并没有给admin读取teamwork的权限，而我却一直在clone teamwork）

	[gitosis]
	
	[group gitosis-admin]
	members = admin
	writable = gitosis-admin test
	
	[group RK_Download]
	members = b nexus
	readonly = teamwork box_4.2  

                             
测试结果

	admin@admin:~/work/test$ git clone git@192.168.0.3:test.git
	Initialized empty Git repository in /home/admin/work/test/test/.git/
	remote: Counting objects: 3, done.
	remote: Total 3 (delta 0), reused 0 (delta 0)
	Receiving objects: 100% (3/3), done.
	admin@admin:~/work/test$ git clone git@192.168.0.3:teamwork.git
	Initialized empty Git repository in /home/admin/work/test/teamwork/.git/
	ERROR:gitosis.serve.main:Repository read access denied
	fatal: The remote end hung up unexpectedly
	
	admin@admin:~/work/test$ git clone git@192.168.0.3:teamwork.git
	Initialized empty Git repository in /home/admin/work/test/teamwork/.git/
	ERROR:gitosis.serve.main:Repository read access denied
	fatal: The remote end hung up unexpectedly
	
	admin@admin:~/work/test$ git clone git@192.168.0.3:teamwork.git
	Initialized empty Git repository in /home/admin/work/test/teamwork/.git/
	ERROR:gitosis.serve.main:Repository read access denied
	fatal: The remote end hung up unexpectedly 


刚记录完，又犯傻逼了，clone 了N次test，都不行，结果发现，自己根本没有把给b设定test的权限。再次说明头脑要清醒。

	$ git clone git@192.168.0.3:test.git
	Initialized empty Git repository in /tmp/test/.git/
	ERROR:gitosis.serve.main:Repository read access denied
	fatal: The remote end hung up unexpectedly

修改后
	
	Initialized empty Git repository in /tmp/teamwork/test/.git/
	remote: Counting objects: 3, done.
	remote: Total 3 (delta 0), reused 0 (delta 0)
	Receiving objects: 100% (3/3), done.

**原因4： 不能写绝对路径**

暂时不知道为啥，反正路径写了git@<Server IP>:/home/repo/xxx.git就会出现这个错误。貌似如果你如果密钥验证失败，要求你输入密码的情况下，是输入绝对路径的，而如果密钥验证成功，输入绝对路径，它就不认了。我想，这是为了保证系统安全，不让客户端用git账户乱clone不在repositories下的文件，即限定在repositories下了，所以只能用相对路径。

#### SSH: The authenticity of host <host> can't be established
0 down vote
This message is just SSH telling you that it's never seen this particular host key before, so it isn't able to truly verify that you're connecting to the host you think you are. When you say "Yes" it puts the ssh key into your known_hosts file, and then on subsequent connections will compare the key it gets from the host to the one in the known_hosts file.

There was a related article on stack overflow showing how to disable this warning,http://stackoverflow.com/questions/3663895/ssh-the-authenticity-of-host-hostname-cant-be-established.



#### unrecognized command 'gitosis-serve b' && 每次登录要求输入密码

	$ git clone git@192.168.0.3:/home/repo/teamwork.git
	Initialized empty Git repository in /home/b/work/teamwork/.git/
	fatal: unrecognized command 'gitosis-serve b'
	fatal: The remote end hung up unexpectedly

遇到这个问题，b是我一个普通账户，而另一个admin每次登录都要求输入密码（ssh有两种登录方式：要求输入密码，和不需要输入密码——利用密钥），我就怀疑，gitosis的配置已经给我弄乱了，所以无法识别正确的密钥。
这个时候，我已经改了好多次密钥对，gitosis已经配置过好多次。通过gitosis-init是不会修复该问题的，于是，我删掉/home/git/下和repository有关的文件夹，包括.ssh下的authoritykey。还要删掉在/home/repo下的gitosis-admin.git。这样重新gitosis-init一下，就可以了。

如果server端的/etc/passwd中git的账户设置中，git使用的是/usr/bin/git-shell，而不是/bin/sh，也会报这个错误。

#### Agent admitted failure to sign using the key.
通过图形界面切换到b用户时，遇到这个问题，在原来到界面中，su b是可以clone的。
解決方式 使用 ssh-add 指令将私钥 加进来 （根据个人的密匙命名不同更改 id_rsa）

	ssh-add   ~/.ssh/id_rsa 

----------



