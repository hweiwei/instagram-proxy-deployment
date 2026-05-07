# Windows 客户端配置指南

## 目录

- [推荐客户端](#推荐客户端)
- [V2rayN 配置](#v2rayn-配置)
- [Clash 配置](#clash-配置)
- [浏览器配置](#浏览器配置)
- [Instagram 浏览器指纹设置](#instagram-浏览器指纹设置)

---

## 推荐客户端

| 客户端 | 协议支持 | 下载地址 |
|--------|----------|----------|
| **V2rayN** | VLESS/VMess/Trojan | [GitHub](https://github.com/2dust/v2rayN/releases) |
| **Clash Verge** | Clash (代理链) | [GitHub](https://github.com/clash-verge-rev/clash-verge-rev/releases) |
| **NekoBox** | VLESS/VMess/Trojan | [GitHub](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) |

## V2rayN 配置

### 步骤 1: 下载安装

1. 访问 [V2rayN GitHub Releases](https://github.com/2dust/v2rayN/releases)
2. 下载最新版本的 `v2rayN-windows.zip`
3. 解压到 `C:\Program Files\V2rayN` 或你喜欢的位置
4. 运行 `v2rayN.exe`

### 步骤 2: 添加服务器

#### 方法 A: 手动添加 VLESS 服务器

1. 点击主界面的 **服务器** → **添加 VLESS 服务器**
2. 填写以下信息：

```
地址 (Address):      你的服务器IP
端口 (Port):         10086
用户ID (UUID):       你的UUID (见 /root/proxy-accounts.txt)
流控 (Flow):         xtls-rprx-vision
传输 (Network):      tcp
安全 (Security):     chrome
别名 (Remarks):      Instagram-Proxy
```

3. 点击 **确定**

#### 方法 B: 导入链接

1. 获取订阅链接或节点链接
2. 点击 **服务器** → **从剪贴板导入**
3. 或点击 **服务器** → **分享链接导入**

### 步骤 3: 配置路由规则

1. 点击 **设置** → **路由设置**
2. 选择或创建路由规则：

```
# Instagram 相关域名 - 直连
domain:instagram.com -> DIRECT
domain:cdninstagram.com -> DIRECT
domain:graph.instagram.com -> DIRECT
domain:igcdn.com -> DIRECT
domain:fbcdn.net -> DIRECT
domain:facebook.com -> DIRECT

# 国内域名 - 直连
domain:geosite:cn -> DIRECT
domain:geosite:category-ads-all -> REJECT

# 默认代理
geoip:private -> DIRECT
default -> Proxy
```

### 步骤 4: 设置系统代理

1. 点击主界面的 **系统代理** → **自动配置系统代理**
2. 或右键任务栏图标 → **系统代理模式** → **全局模式/规则模式**

---

## Clash 配置

### 步骤 1: 下载安装

1. 访问 [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev/releases)
2. 下载 `.exe` 安装包并安装

### 步骤 2: 创建配置文件

创建 `profiles/custom-profile.yaml`：

```yaml
# Instagram Proxy - Clash 配置
# ⚠️ 请修改为你的实际服务器信息

mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9090

# DNS 配置
dns:
  enable: true
  listen: 0.0.0.0:53
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - https://1.1.1.1/dns-query
    - https://dns.google/dns-query
  fallback:
    - https://doh.dns.sb/dns-query
    - tls://1.0.0.1:853

# VLESS 服务器节点
proxies:
  - name: "Instagram-VLESS"
    type: vless
    server: 你的服务器IP
    port: 10086
    uuid: 你的UUID
    flow: xtls-rprx-vision
    network: tcp
    tls: true
    udp: true
    sni: 你的服务器IP
    alpn:
      - h2
      - http/1.1

  - name: "Instagram-Trojan"
    type: trojan
    server: 你的服务器IP
    port: 10087
    password: 你的密码
    tls: true
    sni: 你的服务器IP
    alpn:
      - h2
      - http/1.1
    udp: true

# 代理组
proxy-groups:
  - name: "Instagram-Account-1"
    type: select
    proxies:
      - Instagram-VLESS
      - Instagram-Trojan

  - name: "Instagram-Account-2"
    type: select
    proxies:
      - Instagram-Trojan
      - Instagram-VLESS

  - name: "Instagram-Account-3"
    type: select
    proxies:
      - Instagram-VLESS

  - name: "Proxy"
    type: select
    proxies:
      - Instagram-VLESS
      - Instagram-Trojan

  - name: "Domestic"
    type: select
    proxies:
      - DIRECT

# 路由规则
rules:
  # Instagram 直连
  - DOMAIN-SUFFIX,instagram.com,Instagram-Account-1
  - DOMAIN-SUFFIX,cdninstagram.com,Instagram-Account-1
  - DOMAIN-SUFFIX,graph.instagram.com,Instagram-Account-1
  - DOMAIN-SUFFIX,igcdn.com,Instagram-Account-1
  - DOMAIN-SUFFIX,fbcdn.net,Instagram-Account-1
  - DOMAIN-SUFFIX,facebook.com,Instagram-Account-1
  - DOMAIN-SUFFIX,fb.com,Instagram-Account-1

  # IP 直连
  - IP-CIDR,157.240.0.0/16,Instagram-Account-1
  - IP-CIDR,31.13.0.0/16,Instagram-Account-1
  - IP-CIDR,185.60.0.0/16,Instagram-Account-1

  # 国内直连
  - DOMAIN-SUFFIX,cn,Domestic
  - DOMAIN-KEYWORD,baidu,Domestic
  - DOMAIN-KEYWORD,qq,Domestic
  - GEOIP,CN,Domestic

  # 默认代理
  - MATCH,Proxy
```

### 步骤 3: 配置浏览器指纹

安装 **Chrome** 或 **Firefox**，配合代理扩展使用：

#### 安装 SwitchyOmega 扩展

1. 在 Chrome Web Store 搜索安装 SwitchyOmega
2. 配置代理情景模式：

```
情景模式名称: Instagram-Proxy
代理协议: SOCKS5
代理服务器: 127.0.0.1
代理端口: 7890 (Clash) 或 10808 (V2rayN)
```

3. 创建自动切换规则：

```
规则列表 URL (示例):
https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt
```

---

## 浏览器配置

### Chrome 浏览器指纹设置

#### 1. 安装 Chrome 扩展

- **SwitchyOmega** - 代理切换
- **User-Agent Switcher** - UA 伪装
- **Canvas Blocker** - Canvas 指纹保护
- **WebRTC Leak Prevent** - WebRTC 泄漏防护

#### 2. 伪装 User-Agent

Instagram 推荐 User-Agent（桌面 Chrome）：

```
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36
```

Instagram 推荐 User-Agent（移动端 Chrome）：

```
Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36
```

#### 3. 禁用 WebRTC

在 Chrome 地址栏输入：`chrome://flags/#enable-webrtc`

- WebRTC with multiple routing: Disabled
- WebRTC: Disabled

#### 4. 安装额外保护扩展

推荐安装：
- **CanvasFingerprintDefend** - 防止 Canvas 指纹追踪
- **AudioContext Fingerprint Defend** - 音频指纹防护
- **Privacy Badger** - 隐私保护
- **uBlock Origin** - 广告屏蔽

---

## Instagram 浏览器指纹设置

### 推荐指纹配置

| 设置项 | 推荐值 |
|--------|--------|
| **时区** | 与服务器 IP 所在地一致 (如 America/New_York) |
| **语言** | en-US,en;q=0.9 |
| **屏幕分辨率** | 1920x1080 或 1366x768 |
| **颜色深度** | 24-bit |
| **时区偏移** | 根据服务器地理位置 |
| **字体** | 不要使用罕见字体 |
| **Canvas** | 启用指纹保护或随机化 |

### 时区设置（重要）

Instagram 会检测时区是否与 IP 所在地一致。

```
服务器位置          推荐时区              UTC 偏移
美国洛杉矶          America/Los_Angeles   UTC-8
美国纽约            America/New_York      UTC-5
日本东京            Asia/Tokyo           UTC+9
新加坡              Asia/Singapore        UTC+8
英国伦敦            Europe/London         UTC+0
```

### 设置方法

1. 安装 **Timezone Manager** 扩展
2. 或在 SwitchyOmega 中设置代理规则时自动切换

---

## 常见问题

### Q1: 连接成功但无法访问 Instagram

检查：
1. 确认浏览器代理已启用
2. 检查路由规则是否正确
3. 尝试切换为全局模式

### Q2: Instagram 检测到异常登录

解决方案：
1. 确保 IP 与账号注册时一致或相近
2. 更换 IP 时使用不同的账号
3. 避免频繁更换 IP

### Q3: 网速很慢

优化：
1. 启用 BBR 加速
2. 更换到延迟更低的服务器节点
3. 检查是否开启了完整的 TLS 1.3

### Q4: V2rayN 导入节点失败

解决方案：
1. 检查 UUID 格式是否正确
2. 确认端口号是否匹配
3. 检查服务器防火墙是否开放对应端口

---

## 快速检查清单

部署完成后，在 Windows 上进行以下检查：

```powershell
# 1. 测试代理端口连通性
Test-NetConnection -ComputerName 你的服务器IP -Port 10086

# 2. 测试 SSL 证书
curl -v https://你的服务器IP

# 3. 浏览器测试
# 访问 https://whoer.net 检查 IP 和指纹信息
```
