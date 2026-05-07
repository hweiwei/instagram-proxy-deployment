# 移动端配置指南 (Android & iOS)

## 目录

- [Android 配置](#android-配置)
  - [推荐应用](#android-推荐应用)
  - [V2rayNG 配置](#v2rayng-配置)
  - [Shadowrocket 配置](#shadowrocket配置-android)
- [iOS 配置](#ios-配置)
  - [推荐应用](#ios-推荐应用)
  - [Shadowrocket 配置](#shadowrocket配置-ios)
  - [Stash 配置](#stash-配置)
- [Instagram App 特殊设置](#instagram-app-特殊设置)
- [设备指纹设置](#设备指纹设置)
- [常见问题](#常见问题)

---

## Android 配置

### Android 推荐应用

| 应用 | 协议支持 | 获取方式 | 特点 |
|------|----------|----------|------|
| **V2rayNG** | VLESS/VMess/Trojan | [GitHub](https://github.com/2dust/v2rayNG/releases) | 功能完整，免费开源 |
| **NekoBox** | VLESS/VMess/Trojan | [GitHub](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) | 支持 FakeIP DNS |
| **Kitsunebi** | VLESS/VMess/Trojan | Google Play / [GitHub](https://github.com/rranaiapp/Kitsunebi-for-Android/releases) | 界面简洁 |
| **Pharos** | VLESS/VMess/Trojan | Google Play | 轻量级 |

### V2rayNG 配置

#### 步骤 1: 下载安装

1. 访问 [V2rayNG GitHub](https://github.com/2dust/v2rayNG/releases)
2. 下载最新 APK 文件 (文件名含 `android-arm64-v8a` 或类似)
3. 安装 APK（可能需要允许未知来源）

#### 步骤 2: 添加服务器

##### 方法 A: 手动添加 VLESS 服务器

1. 打开 V2rayNG
2. 点击右上角 **+** 按钮
3. 选择 **手动输入 [VLESS]**
4. 填写配置：

```
备注:           Instagram-Proxy-M
地址 (Address):  你的服务器IP
端口 (Port):     10086
UUID:            你的UUID
流控 (Flow):     xtls-rprx-vision
传输协议:        tcp
安全 (Security): tls
TLS:             chrome (指纹)
别名:            Mobile-VLESS
```

5. 点击右上角 **保存**

##### 方法 B: 导入链接

1. 获取节点链接（格式：`vless://UUID@IP:PORT...?security=tls&flow=...`）
2. 点击右上角 **+** → **扫描二维码**
3. 或点击右上角 **+** → **剪贴板导入**

##### 方法 C: 订阅链接

1. 获取订阅地址
2. 点击右上角 **+** → **订阅设置**
3. 点击右上角 **+** 添加订阅 URL
4. 返回主界面，点击右上角 **菜单** → **更新订阅**

#### 步骤 3: 配置路由

1. 点击底部导航 **设置**
2. 进入 **路由设置**
3. 选择预设或自定义规则：

```
# Instagram 直连规则
domain:instagram.com -> 直接连接
domain:cdninstagram.com -> 直接连接
domain:graph.instagram.com -> 直接连接
domain:igcdn.com -> 直接连接
domain:fbcdn.net -> 直接连接

# 国内域名直连
domain:geosite:cn -> 直接连接

# 广告屏蔽
domain:geosite:category-ads-all -> 拦截
```

#### 步骤 4: 连接测试

1. 返回主界面
2. 选择刚才添加的服务器
3. 点击底部 **连接** 按钮
4. 观察通知栏 VPN 图标是否显示

#### 步骤 5: 分应用代理设置

1. 进入 **设置** → **分应用代理**
2. 启用需要代理的应用：
   - ✅ Instagram
   - ✅ Chrome
   - ✅ 其他社媒应用
3. 可以选择排除某些不需要代理的 App

### NekoBox 配置

NekoBox 界面与 V2rayNG 类似，但有以下特点：

1. **FakeIP DNS** - 更好的隐私保护
2. **更简洁的设置界面**
3. **内置广告拦截**

配置步骤：

1. 添加服务器方式与 V2rayNG 相同
2. 路由设置中启用 `绕过局域网和中国大陆`
3. DNS 设置选择 `FakeIP`

### Shadowrocket配置 (Android)

虽然 Shadowrocket 主要是 iOS 应用，但也有 Android 版本：

1. 从 Google Play 或 GitHub 下载 Android 版本
2. 导入节点（支持扫码、链接、订阅）
3. 配置路由规则

---

## iOS 配置

### iOS 推荐应用

| 应用 | 协议支持 | 价格 | 特点 |
|------|----------|------|------|
| **Shadowrocket** | VLESS/VMess/Trojan/SS | ¥38 (付费) | 功能完整，推荐 |
| **Stash** | VLESS/VMess/Trojan/SS | ¥58 (付费) | Clash 规则支持 |
| **Quantumult X** | VLESS/VMess/Trojan/SS | ¥88 (付费) | 强大的脚本功能 |
| **Loon** | VLESS/VMess/Trojan/SS | ¥58 (付费) | 界面美观 |
| **Surge** | VLESS/VMess/Trojan/SS | ¥328 (付费) | 功能最强大 |
| **sing-box** | 全协议支持 | 免费 (TestFlight) | 开源，可自签 |

### 获取应用

#### 方法 1: App Store 购买（推荐）

购买后可以正常从 App Store 更新：

- **Shadowrocket**: 搜索 "shadowrocket"（注意认准开发者）
- **Stash**: 搜索 "Stash"

#### 方法 2: AltStore 自签（免费，需要 Mac）

1. 下载 IPA 文件
2. 使用 AltServer 在 Mac 上签名安装
3. 需要每 7 天重新签名

#### 方法 3: 外区 Apple ID（免费）

1. 注册一个外区 Apple ID（如美国）
2. 在 iPhone 上切换 App Store 区域
3. 下载免费应用

### Shadowrocket配置 (iOS)

#### 步骤 1: 基本设置

1. 打开 Shadowrocket
2. 点击底部 **设置** 标签
3. 配置全局设置：

```
全局代理:        关闭 (建议使用分应用代理)
UDP 转发:        开启
IPv6 路由:       关闭 (Instagram 暂不需要)
DNS 域名解析:    fakeip
```

#### 步骤 2: 添加服务器

##### 方法 A: 扫码添加

1. 从服务器获取二维码
2. 点击右上角 **+** → **扫描二维码**
3. 对准屏幕扫描

##### 方法 B: 手动添加 VLESS

1. 点击右上角 **+**
2. 类型选择 **VLESS**
3. 填写配置：

```
服务器:       你的服务器IP
端口:         10086
UUID:         你的UUID
TLS:          开启
TLS 指纹:     chrome
Flow:         xtls-rprx-vision (如有)
备注:         Instagram-iOS
```

4. 点击 **保存**

##### 方法 C: 订阅链接

1. 点击右上角 **+**
2. 类型选择 **Subscribe**
3. 粘贴订阅 URL
4. 点击 **保存**
5. 返回主界面，点击 **更新** 同步节点

#### 步骤 3: 配置规则

##### 预设规则

1. 进入 **设置** → **路由规则设置**
2. 选择 **配置** → **代理** 或 **直连**
3. 或选择预设的 **Instagram** 规则集

##### 自定义规则

1. 进入 **设置** → **规则**
2. 点击右上角 **+** 添加规则

```
[Rule]
# Instagram 直连
DOMAIN-SUFFIX,instagram.com,PROXY
DOMAIN-SUFFIX,cdninstagram.com,PROXY
DOMAIN-SUFFIX,graph.instagram.com,PROXY
DOMAIN-SUFFIX,igcdn.com,PROXY
DOMAIN-SUFFIX,fbcdn.net,PROXY
DOMAIN-SUFFIX,facebook.com,PROXY

# Facebook 家族
DOMAIN-SUFFIX,fb.com,PROXY
DOMAIN-SUFFIX,meta.com,PROXY

# IP 范围
IP-CIDR,157.240.0.0/16,PROXY
IP-CIDR,31.13.0.0/16,PROXY
IP-CIDR,185.60.0.0/16,PROXY

# 国内直连
GEOIP,CN,DIRECT

# 默认代理
FINAL,PROXY
```

#### 步骤 4: 分应用代理

1. 进入 **设置** → **应用代理**
2. 启用 **VPN** 模式
3. 在应用列表中勾选 **Instagram**

#### 步骤 5: 连接

1. 返回主界面
2. 选择服务器节点
3. 点击底部开关开启连接
4. 状态栏显示 VPN 图标即连接成功

### Stash 配置

Stash 是支持 Clash 规则的 iOS 应用：

#### 配置文件示例

```yaml
# Stash Clash 配置
# 保存为 stash.yaml

port: 7890
socks-port: 7891
redir-port: 7892
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9090

dns:
  enable: true
  listen: 0.0.0.0:53
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - https://1.1.1.1/dns-query
    - https://dns.google/dns-query

proxies:
  - name: Instagram-iOS
    type: vless
    server: 你的服务器IP
    port: 10086
    uuid: 你的UUID
    flow: xtls-rprx-vision
    network: tcp
    tls: true
    udp: true

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - Instagram-iOS

rules:
  - DOMAIN-SUFFIX,instagram.com,Proxy
  - DOMAIN-SUFFIX,cdninstagram.com,Proxy
  - DOMAIN-SUFFIX,graph.instagram.com,Proxy
  - DOMAIN-SUFFIX,igcdn.com,Proxy
  - DOMAIN-SUFFIX,fbcdn.net,Proxy
  - DOMAIN-SUFFIX,facebook.com,Proxy
  - IP-CIDR,157.240.0.0/16,Proxy
  - IP-CIDR,31.13.0.0/16,Proxy
  - GEOIP,CN,DIRECT
  - MATCH,Proxy
```

---

## Instagram App 特殊设置

### Android Instagram 设置

1. **清除数据和缓存**
   - 设置 → 应用 → Instagram → 清除数据

2. **关闭后台数据节省**
   - 设置 → 网络 → 后台数据限制 → 关闭

3. **允许 VPN 应用运行**
   - 确保 VPN 应用有后台运行权限

4. **时区同步**
   - 安装 **Timezone Fixer** 或类似应用
   - 确保手机时区与代理 IP 一致

### iOS Instagram 设置

1. **关闭低数据模式**
   - 设置 → 蜂窝网络 → 蜂窝数据选项 → 低数据模式 → 关闭

2. **允许后台刷新**
   - 设置 → Instagram → 后台 App 刷新 → 开启

3. **时区设置**
   - 设置 → 通用 → 日期与时间 → 关闭自动设置
   - 手动选择与代理 IP 一致的时区

---

## 设备指纹设置

### 时区设置（关键）

Instagram 会检测设备时区与 IP 所在地是否一致。

| 服务器位置 | 推荐时区 | Android 设置 | iOS 设置 |
|------------|----------|--------------|----------|
| 美国西海岸 | Pacific Time | America/Los_Angeles | (GMT-8) Pacific Time |
| 美国东海岸 | Eastern Time | America/New_York | (GMT-5) Eastern Time |
| 日本 | Japan | Asia/Tokyo | (GMT+9) Tokyo |
| 新加坡 | Singapore | Asia/Singapore | (GMT+8) Singapore |
| 英国 | London | Europe/London | (GMT+0) London |

### Android 时区设置

方法 1: 系统设置
- 设置 → 通用管理 → 日期和时间 → 选择时区

方法 2: 使用应用
- 安装 **Clock Sync** 或 **Timezone Fixer**

### iOS 时区设置

- 设置 → 通用 → 日期与时间 → 关闭"自动设置" → 手动选择时区

### 语言设置

| 服务器位置 | 推荐语言 | 设置 |
|------------|----------|------|
| 美国 | English (US) | 设置 → 通用 → 语言 → English |
| 欧洲 | English (UK) 或本地语言 | 设置 → 通用 → 语言 |

---

## 常见问题

### Q1: iOS 应用无法连接

检查：
1. 确认应用有 VPN 配置权限
2. 检查证书是否安装（如使用自签）
3. 确认服务器端口是否正确

### Q2: Instagram 检测到异常活动

可能原因：
1. IP 与账号常用位置差异太大
2. 设备指纹不匹配
3. 行为模式异常

解决：
1. 更换 IP 前先让账号休息几天
2. 确保时区设置正确
3. 避免短时间内大量操作

### Q3: 移动端网速慢

优化：
1. 选择延迟更低的服务器节点
2. 尝试切换协议（VLESS ↔ Trojan）
3. 检查是否开启了 UDP 转发
4. 尝试更换 DNS 服务器

### Q4: 应用闪退

解决：
1. 更新到最新版本
2. 清除应用缓存
3. 重启手机
4. 重新安装应用

### Q5: 订阅更新失败

检查：
1. 确认订阅 URL 可访问
2. 检查服务器是否配置了订阅服务
3. 尝试手动更新

---

## 快速配置模板

### VLESS 连接信息模板

```
协议: VLESS
地址: 你的服务器IP
端口: 10086
UUID: 你的UUID
传输: TCP
TLS: TLS
指纹: chrome
Flow: xtls-rprx-vision
```

### Trojan 连接信息模板

```
协议: Trojan
地址: 你的服务器IP
端口: 10087
密码: 你的密码
TLS: 开启
SNI: 你的服务器IP
```

### 节点链接格式

**VLESS 链接格式：**
```
vless://UUID@服务器IP:10086?encryption=none&flow=xtls-rprx-vision&security=tls&sni=服务器IP&type=tcp#备注
```

**Trojan 链接格式：**
```
trojan://密码@服务器IP:10087?security=tls&sni=服务器IP#备注
```
