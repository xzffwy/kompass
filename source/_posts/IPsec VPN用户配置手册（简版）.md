---
title: IPsec 用户配置手册（简单版）
date: 2017/1/29 9:07:14 
description: IPsec用户手册简单版
categories: 用户手册
tags: [IPsec,vpn]
---

### 提示
- <span style="color:red">红色字体</span>需要重点注意，带<span style="color:red">**\***</span>标注信息客服会提供
- 客服联系方式
  - QQ: 444080836
  - Telegram: Mniulso
  - Email: iceantale@gmail.com

---

### iOS
- 配置路径: **设置 -> VPN -> 添加配置 -> IPSec**
- 描述: 任意
- 用户鉴定: 用户名
- 服务器<span style="color:red">**\***</span>: VPN服务器URL或者IP地址
- 用户名<span style="color:red">**\***</span>: 登录VPN所用账户
- 密码<span style="color:red">**\***</span>: 登录VPN所用密码
- 密钥<span style="color:red">**\***</span>: IPsec VPN预共享密钥

----------

### MAC OS X
- 配置路径: **系统偏好设置 -> 网络 ->添加网络连接**
- 接口: VPN
- VPN类型: Cisco IPsec
- 服务器地址<span style="color:red">**\***</span>: 服务器URL或者IP地址
- 账户名称<span style="color:red">**\***</span>: 登录VPN所用账户
- 密码<span style="color:red">**\***</span>: 登录VPN所用密码
- 鉴定设置 -> 共享的密钥<span style="color:red">**\***</span>: IPsec VPN预共享密钥

----------

### Android

- 配置路径: **设置 -> 其它连接方式 -> VPN -> 添加 VPN**
- 名称: 任意
- 服务器地址<span style="color:red">**\***</span>: 服务器URL或者IP地址
- 类型: IPSec Xauth PSK
- IPsec 标识符: 不更改
- 预共享密钥<span style="color:red">**\***</span>: IPsec VPN预共享密钥
- 用户名<span style="color:red">**\***</span>: 登录VPN所用账户
- 密码<span style="color:red">**\***</span>: 登录VPN所用密码

----------

### Windows

<span style="color:red">Windows系统推荐使用IKEv2 VPN<span>

----------

### Linux
Linux 的版本众多，认证方法与协议支持也非常丰富，详细方法请根据 Linux 版本查询连接方法。一般而言，Linux 通过 NetworkManager-strongswan。