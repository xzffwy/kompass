---
title: IKEv2 用户配置手册（图文版）
date: 2017/1/29 9:07:14 
description: IKEv2用户手册图文版
categories: 用户手册
tags: [IKEv2,vpn]
---
### 提示 & FAQ

#### 提示
- <span style="color:red">红色字体</span>需要重点注意，带<span style="color:red">**\***</span>标注信息客服会提供
- 客服联系方式
  - QQ: 444080836
  - Telegram: Mniulso
  - Email: iceantale@gmail.com

#### FAQ
- Windows、Android、iOS和Mac OS X使用的证书是相同的吗？
  - 所有平台使用的证书均是同样的证书文件，不同平台导入方法不同而已。

---

### iOS

#### 系统版本要求

<span style="color:red">iOS 9</span>或者更高版本

#### 证书导入
- Safari浏览器中输入CA证书下载地址: https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
- 选择**安装证书**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/iOS/cert/cert-2.jpg)</center><center style="color:purple">**图1-1**</center>

- 输入iOS密码

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/iOS/cert/cert-3.jpg)</center><center style="color:purple">**图1-2**</center>

- 点击安装，导入证书

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/iOS/cert/cert-4.jpg)</center><center style="color:purple">**图1-3**</center>

#### VPN设置 ####
- 配置路径: **设置 -> VPN -> 添加配置**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/iOS/config/iOS-1.jpg)</center><center style="color:purple">**图1-4**</center>

- 类型: IKEv2
- 描述: 任意
- 用户鉴定: 用户名
- 服务器<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码
- 远程ID<span style="color:red">**\***</span>: VPN远程ID
- 本地ID: 留空

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/iOS/config/iOS-2.jpg)</center><center style="color:purple">**图1-5**</center>

- 设置完毕后，连接VPN

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/iOS/config/iOS-3.jpg)</center><center style="color:purple">**图1-6**</center>

---

### MAC OS X

#### 系统版本要求

<span style="color:red">OS X 10.11 ("El Capitan")</span>或者更高版本

#### 证书导入
- 下载CA证书到本地，下载地址为: https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
- 配置路径: **钥匙串访问 -> 钥匙串 -> 系统**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/cert/cert-1.jpg)</center><center style="color:purple">**图2-1**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/cert/cert-2.jpg)</center><center style="color:purple">**图2-2**</center>

- 选择要添加的证书文件

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/cert/cert-3.jpg)</center><center style="color:purple">**图2-3**</center>

- 导入证书

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/cert/cert-4.jpg)</center><center style="color:purple">**图2-4**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/cert/cert-5.jpg)</center><center style="color:purple">**图2-5**</center>

#### VPN设置

- 配置路径: **设置 -> 网络 ->添加网络连接**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/config/macosx-1.jpg)</center><center style="color:purple">**图2-6**</center>

- 接口: VPN
- VPN类型: IKEv2
- 服务名称: 任意

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/config/macosx-2.jpg)</center><center style="color:purple">**图2-7**</center>

- 服务器<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- 远程ID<span style="color:red">**\***</span>: VPN远程ID
- 本地ID: 留空
- 鉴定设置 -> 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 鉴定设置 -> 密码<span style="color:red">**\***</span>: 登录VPN密码

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/config/macosx-3.jpg)</center><center style="color:purple">**图2-8**</center>

- 选择连接VPN

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/config/macosx-4.png)</center><center style="color:purple">**图2-9**</center>

- 连接VPN成功

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/MacOSX/config/macosx-5.jpg)</center><center style="color:purple">**图2-10**</center>

---

### Android

#### 系统版本要求

<span style="color:red">Android 4</span>或者更高版本，需要安装[Strongswan客户端](http://pan.baidu.com/s/1gfkEXKB)，下载地址为：http://pan.baidu.com/s/1gfkEXKB

#### 证书导入
- 下载CA证书到本机，下载地址为: https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
- Strongswan客户端中导入服务器证书
- 配置路径: **CA certificates -> Import certificates**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/cert/cert-1.jpg)</center><center style="color:purple">**图3-1**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/cert/cert-2.jpg)</center><center style="color:purple">**图3-2**</center>

- 选择证书文件

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/cert/cert-3.jpg)</center><center style="color:purple">**图3-3**</center>

- 确认导入证书

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/cert/cert-4.jpg)</center><center style="color:purple">**图3-4**</center>

- 可以查看导入的CA证书

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/cert/cert-5.jpg)</center><center style="color:purple">**图3-5**</center>

#### VPN设置 ####
- 配置路径：**ADD VPN PROFILE**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/config/android-1.jpg)</center><center style="color:purple">**图3-6**</center>


- 服务器<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- VPN类型: IKEv2 EAP
- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/config/android-2.jpg)</center><center style="color:purple">**图3-7**</center>

- 添加完毕后，点击配置完毕的VPN

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/config/android-3.jpg)</center><center style="color:purple">**图3-8**</center>

- 连接VPN成功

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/android/config/android-4.jpg)</center><center style="color:purple">**图3-9**</center>

----------

### Windows

#### 系统版本要求

<span style="color:red">Win 7</span>或者更高版本

#### 证书导入
Windows使用IKEv2 VPN需要导入服务器CA证书到<span style="color:red">**信任根证书颁发机构**</span>，以Win10为例，Win7、Win8过程类似

- 下载CA证书到本机，下载地址为: https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
- 开始菜单搜索**mmc（Microsoft 管理控制台）**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-1.jpg)</center><center style="color:purple">**图4-1**</center>

- **文件**-**添加/删除管理单元**，添加**证书**单元

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-2.jpg)</center><center style="color:purple">**图4-2**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-3.jpg)</center><center style="color:purple">**图4-3**</center>

- 证书单元的弹出窗口中选**计算机账户**，然后选择**下一步**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-4.jpg)</center><center style="color:purple">**图4-4**</center>

- 选择**本地计算机/运行此控制台的计算机**，然后选择**确定**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-5.jpg)</center><center style="color:purple">**图4-5**</center>

- 在左边的**控制台根节点**下选择**证书** -> **受信任的根证书颁发机构** -> **证书**
- 右键点击**证书** -> **所有任务** -> **导入**，打开证书导入窗口。

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-6.jpg)</center><center style="color:purple">**图4-6**</center>

<center>![![img](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-7.jpg)](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-7.jpg)</center><center style="color:purple">**图4-7**</center>

- 选择证书文件导入即可

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-8.jpg)</center><center style="color:purple">**图4-8**</center>



<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/cert/cert-9.jpg)</center><center style="color:purple">**图4-9**</center>

#### VPN设置 ####

##### Win10/Win8

- 配置路径: **设置 -> 网络和Internet -> VPN -> 添加VPN**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-1.jpg)</center><center style="color:purple">**图4-10**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-2.jpg)</center><center style="color:purple">**图4-11**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-3.jpg)</center><center style="color:purple">**图4-12**</center>

- VPN提供商: Windows（内置）
- 连接名称: 任意
- 服务器名称或地址<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- VPN类型: IKEv2
- 登录信息类型: 用户名和密码
- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-4.jpg)</center><center style="color:purple">**图4-13**</center>


保存上述配置后，进行如下设置

- 配置路径: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**，
- 在新建的 VPN 连接上右键**属性**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-9.jpg)</center><center style="color:purple">**图4-14**</center>

- 切换到**安全**选项卡，参数调整为如下，然后**确定**进行保存
  - VPN 类型: IKEv2
  - 数据加密选: 需要加密
  - 身份验证：EAP-MSCHAP v2

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-10.jpg)</center><center style="color:purple">**图4-15**</center>

- 切换到**网络**选项卡，双击**Internet协议版本 4 (TCP/IPv4)**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-11.jpg)</center><center style="color:purple">**图4-16**</center>

- 选择**高级**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-12.jpg)</center><center style="color:purple">**图4-17**</center>

- 确认勾选了**在远程网络上使用默认网关**，然后选择**确定**。

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-13.jpg)</center><center style="color:purple">**图4-18**</center>

- 切换到路径**设置 -> 网络和Internet -> VPN** ，连接VPN

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-5.jpg)</center><center style="color:purple">**图4-19**</center>

- 继续连接，信任证书

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-6.jpg)</center><center style="color:purple">**图4-20**</center>

- 连接VPN成功

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-7.jpg)</center><center style="color:purple">**图4-21**</center>

- 可以通过路径**控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**，查看VPN虚拟网卡信息

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win10/win10-8.jpg)</center><center style="color:purple">**图4-22**</center>

##### Win7

 配置路径: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 连接新的网络或连接 -> 连接到工作区 -> 创建新连接 -> 使用我的Internet连接(VPN)**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-1.jpg)</center><center style="color:purple">**图4-23**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-2.jpg)</center><center style="color:purple">**图4-24**</center>

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-3.jpg)</center><center style="color:purple">**图4-25**</center>

- Internet 地址<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- 目标名称: 任意

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-4.jpg)</center><center style="color:purple">**图4-26**</center>

- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-5.jpg)</center><center style="color:purple">**图4-27**</center>

- 设置完毕后，先不连接

  <center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-6.jpg)</center><center style="color:purple">**图4-28**</center>

- 进入配置路径: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**
- 在新建的 VPN 连接上右键**属性**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-7.jpg)</center><center style="color:purple">**图4-29**</center>

- 切换到**安全**选项卡，参数调整为如下，然后**确定**进行保存
  - VPN 类型: IKEv2
  - 数据加密选: 需要加密
  - 身份验证：EAP-MSCHAP v2

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-8.jpg)</center><center style="color:purple">**图4-30**</center>

- 切换到**网络**选项卡，双击**Internet协议版本 4 (TCP/IPv4)**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-11.jpg)</center><center style="color:purple">**图4-31**</center>

- 选择**高级**

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-12.jpg)</center><center style="color:purple">**图4-32**</center>

- 确认勾选了**在远程网络上使用默认网关**，然后选择**确定**进行保存。

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-13.jpg)</center><center style="color:purple">**图4-33**</center>

- 进入路径**控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**，双击VPN适配器，连接VPN

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-9.jpg)</center><center style="color:purple">**图4-34**</center>

- 连接VPN成功

<center>![](http://qingdao.icean.cc:11234/Imgbed/ikev2-user/Windows/win7/win7-10.jpg)</center><center style="color:purple">**图4-35**</center>

----------

### Linux
Linux 的版本众多，认证方法与协议支持也非常丰富，详细方法请根据 Linux 版本查询连接方法。一般而言，Linux 通过 NetworkManager-strongswan连接。
