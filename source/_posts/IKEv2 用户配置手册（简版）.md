---
title: IKEv2 用户配置手册（简单版）
date: 2017/1/29 9:07:14 
description: IKEv2用户手册简单版
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
- 安装证书到设备
- 输入iOS密码

#### VPN设置 ####
- 配置路径: **设置 -> VPN -> 添加配置**
- 类型: IKEv2
- 描述: 任意
- 用户鉴定: 用户名
- 服务器<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码
- 远程ID<span style="color:red">**\***</span>: VPN远程ID
- 本地ID: 留空

---

### MAC OS X

#### 系统版本要求

<span style="color:red">OS X 10.11 ("El Capitan")</span>或者更高版本

#### 证书导入
- 下载CA证书到本地，下载地址为: https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
- 配置路径: **钥匙串访问 -> 钥匙串 -> 系统**
- 选择要添加的证书文件
- 导入证书

#### VPN设置

- 配置路径: **系统偏好设置 -> 网络 ->添加网络连接**
- 接口: VPN
- VPN类型: IKEv2
- 服务名称: 任意
- 服务器<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- 远程ID<span style="color:red">**\***</span>: VPN远程ID
- 本地ID: 留空
- 鉴定设置 -> 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 鉴定设置 -> 密码<span style="color:red">**\***</span>: 登录VPN密码

---

### Android

#### 系统版本要求

<span style="color:red">Android 4</span>或者更高版本，需要安装[Strongswan客户端](http://pan.baidu.com/s/1gfkEXKB)，下载地址为：http://pan.baidu.com/s/1gfkEXKB

#### 证书导入
- 下载CA证书到本机，下载地址为: https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
- 配置路径: **CA certificates -> Import certificates**
- 选择证书文件
- 确认导入证书

#### VPN设置 ####
- 配置路径: **ADD VPN PROFILE**
- 服务器<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- VPN类型: IKEv2 EAP
- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码

----------

### Windows

#### 系统版本要求

<span style="color:red">Win 7</span>或者更高版本

#### 证书导入
Windows使用IKEv2 VPN需要导入服务器[CA证书](https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem)到<span style="color:red">**信任根证书颁发机构**</span>

- 下载CA证书到本机，下载地址为: https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
- **开始**菜单搜索**mmc（Microsoft 管理控制台）**
- **文件** -> **添加/删除管理单元**添加**证书**单元
- 证书单元的弹出窗口中选**计算机账户**，之后选**本地计算机**，确定
- 在左边的**控制台根节点**下选择**证书** -> **受信任的根证书颁发机构** -> **证书**，右键 -> **所有任务** -> **导入**，打开证书导入窗口。
- 选择证书文件导入即可

#### VPN设置 ####

##### Win10/Win8

- 配置路径: **设置 -> 网络和Internet -> VPN -> 添加VPN**
- VPN提供商: Windows（内置）
- 连接名称: 任意
- 服务器名称或地址<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- VPN类型: IKEv2
- 登录信息类型: 用户名和密码
- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码

保存上述配置后，进行如下设置

- 配置路径: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**
- 在新建的 VPN 连接上右键**属性**
- 切换到**安全**选项卡，参数调整为如下，然后**确定**进行保存
  - VPN 类型: IKEv2
  - 数据加密选: 需要加密
  - 身份验证：EAP-MSCHAP v2
- 切换到**网络**选项卡
  - 双击**Internet协议版本 4 (TCP/IPv4)**
  - 选择**高级**
  - 确认勾选了**在远程网络上使用默认网关**，然后选择**确定**进行保存。

##### Win7

- 配置路径: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 连接新的网络或连接 -> 连接到工作区 -> 创建新连接 -> 使用我的Internet连接(VPN)**
- Internet 地址<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- 目标名称: 任意
- 用户名<span style="color:red">**\***</span>: 登录VPN用户名
- 密码<span style="color:red">**\***</span>: 登录VPN密码

设置完毕后，先不连接

- 配置路径: **控制面板 -> 网络和 Internet -> 网络和共享中心 -> 更改适配器设置**
- 在新建的 VPN 连接上右键**属性**
- 切换到**安全**选项卡
  - VPN 类型: IKEv2
  - 数据加密选: 需要加密
  - 身份验证: EAP-MSCHAP v2
- 切换到**网络**选项卡
  - 双击**Internet协议版本 4 (TCP/IPv4)**
  - 选择**高级**
  - 确认勾选了**在远程网络上使用默认网关**，然后选择**确定**进行保存。

win7/8/10连接VPN界面可能不同，但是大同小异。

----------
### Linux
Linux 的版本众多，认证方法与协议支持也非常丰富，详细方法请根据 Linux 版本查询连接方法。一般而言，Linux 通过 NetworkManager-strongswan连接。