# Mac 客户端配置指南

## 目录

- [推荐客户端](#推荐客户端)
- [Surge 配置](#surge-配置)
- [ClashX 配置](#clashx-配置)
- [Clash Verge 配置](#clash-verge-配置)
- [系统代理设置](#系统代理设置)
- [浏览器配置](#浏览器配置)

---

## 推荐客户端

| 客户端 | 协议支持 | 价格 | 特点 |
|--------|----------|------|------|
| **Surge** | 全协议 | ¥328 (Mac) | 功能最强大，推荐 |
| **ClashX** | Clash | 免费 | 开源轻量 |
| **Clash Verge** | Clash | 免费 | 现代界面 |
| **V2rayU** | VLESS/VMess | 免费 | 界面简洁 |
| **Qv2ray** | 全协议 | 免费 | 功能完整 |

---

## Surge 配置

Surge 是 macOS 上最强大的代理工具，支持最多的协议和功能。

### 获取 Surge

1. App Store 搜索 Surge（开发者：@magic和工作）
2. 价格 ¥328（一次性购买）

### 基本配置

#### 1. 添加 VLESS 服务器

打开 Surge → 配置文件 → 编辑配置文件

```ini
# 基础设置
[General]
loglevel = notify
allow-wifi-access = true
http-listen = 0.0.0.0:1087
socks5-listen = 0.0.0.0:1086
port = 1080
socks5-port = 1086
enable-multi-pool = true
find-process-mode = always

# DNS 设置
[dns]
server = 1.1.1.1
server = 8.8.8.8
server = 223.5.5.5
server = 114.114.114.114
custom = domain:instagram.com,119.29.29.29
custom = domain:facebook.com,1.1.1.1

# 代理节点
[Proxy]
Instagram-VLESS = vless, 服务器IP, 10086, username=你的UUID, tls=true, sni=服务器IP, client-fingerprint=chrome, udp-relay=true

# 代理组
[Proxy Group]
Instagram = select, Instagram-VLESS, automatic
Domestic = select, DIRECT
Telegram = select, Instagram, automatic

# 规则
[Rule]
# Instagram 直连
DOMAIN-SUFFIX,instagram.com,Instagram
DOMAIN-SUFFIX,cdninstagram.com,Instagram
DOMAIN-SUFFIX,graph.instagram.com,Instagram
DOMAIN-SUFFIX,igcdn.com,Instagram
DOMAIN-SUFFIX,fbcdn.net,Instagram
DOMAIN-SUFFIX,facebook.com,Instagram
DOMAIN-SUFFIX,fb.com,Instagram

# IP 规则
IP-CIDR,157.240.0.0/16,Instagram
IP-CIDR,31.13.0.0/16,Instagram
IP-CIDR,185.60.0.0/16,Instagram

# 国内直连
GEOIP,CN,Domestic

# Telegram
DOMAIN-SUFFIX,telegram.org,Telegram
DOMAIN-KEYWORD,telegram,Telegram

# 默认规则
FINAL,Instagram
```

#### 2. 高级设置

```ini
[General]
# TCP 连接优化
tcp-fast-open = true

# UDP 转发
enable-udp-relay = true

# IPv6
ipv6 = false

# WiFi 策略
wifi-assist = true
always-fake-dns = false

[Replica]
hide-apple-update = true
disable-sticky-session = false

[MITM]
ca-passphrase = your-passphrase
```

### Surge 的优势

- 精确的规则系统
- 强大的脚本支持
- 完美的 macOS 集成
- 进程级代理控制
- 自动切换

---

## ClashX 配置

ClashX 是开源免费的 Clash 客户端。

### 安装

1. 下载 [ClashX](https://github.com/yichengchen/clashX/releases) 或 [ClashX Pro](https://github.com/SpongeNobody/ClashX-Pro/releases)
2. 解压到 Applications 文件夹
3. 首次运行时允许系统扩展

### 配置文件

创建 `~/.config/clash/config.yaml`：

```yaml
# Clash 配置

# 端口设置
port: 7890
socks-port: 7891
redir-port: 7892
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9090

# DNS 设置
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

# 代理服务器
proxies:
  - name: Instagram-VLESS
    type: vless
    server: 你的服务器IP
    port: 10086
    uuid: 你的UUID
    flow: xtls-rprx-vision
    network: tcp
    tls: true
    udp: true
    sni: 你的服务器IP
    client-fingerprint: chrome

  - name: Instagram-Trojan
    type: trojan
    server: 你的服务器IP
    port: 10087
    password: 你的密码
    tls: true
    sni: 你的服务器IP
    udp: true

# 代理组
proxy-groups:
  - name: Instagram-Account-1
    type: select
    proxies:
      - Instagram-VLESS
      - Instagram-Trojan
      - DIRECT

  - name: Instagram-Account-2
    type: select
    proxies:
      - Instagram-Trojan
      - Instagram-VLESS

  - name: Proxy
    type: select
    proxies:
      - Instagram-VLESS

  - name: Domestic
    type: select
    proxies:
      - DIRECT

# 规则
rules:
  # Instagram
  - DOMAIN-SUFFIX,instagram.com,Instagram-Account-1
  - DOMAIN-SUFFIX,cdninstagram.com,Instagram-Account-1
  - DOMAIN-SUFFIX,graph.instagram.com,Instagram-Account-1
  - DOMAIN-SUFFIX,igcdn.com,Instagram-Account-1
  - DOMAIN-SUFFIX,fbcdn.net,Instagram-Account-1
  - DOMAIN-SUFFIX,facebook.com,Instagram-Account-1
  - DOMAIN-SUFFIX,fb.com,Instagram-Account-1

  # IP 规则
  - IP-CIDR,157.240.0.0/16,Instagram-Account-1
  - IP-CIDR,31.13.0.0/16,Instagram-Account-1
  - IP-CIDR,185.60.0.0/16,Instagram-Account-1

  # 国内
  - GEOIP,CN,Domestic
  - DOMAIN-SUFFIX,cn,Domestic

  # 默认
  - MATCH,Proxy
```

### 使用

1. 打开 ClashX
2. 点击菜单栏图标
3. 选择 **配置** → **打开配置文件夹**
4. 将配置文件放入
5. 点击 **更新配置**
6. 选择节点并启用

---

## Clash Verge 配置

Clash Verge 是新一代 Clash 客户端，有更现代的界面。

### 安装

1. 下载 [Clash Verge](https://github.com/clash-verge-rev/clash-verge-rev/releases)
2. 安装并打开

### 配置

1. 打开设置 → 配置
2. 导入上述 Clash 配置
3. 或使用订阅链接

### 订阅设置

1. 设置 → 订阅
2. 添加订阅 URL
3. 设置自动更新

---

## 系统代理设置

### macOS 系统代理

1. 打开 **系统偏好设置** → **网络** → **高级** → **代理**
2. 勾选需要使用的代理协议：
   - ✅ 自动代理配置 (PAC)
   - ✅ SOCKS 代理
3. 设置代理地址：
   ```
   SOCKS 代理: 127.0.0.1:7891 (ClashX)
   或
   SOCKS 代理: 127.0.0.1:1086 (Surge)
   ```

### 为特定应用设置代理

#### Safari
- 直接使用系统代理设置

#### Chrome
- 使用 SwitchyOmega 扩展
- 或启动参数：`open -a "Google Chrome" --args --proxy-server="socks5://127.0.0.1:7891"`

#### Instagram App (如果使用)
- Surge 支持应用级代理
- 配置 `[General]` 中的 `find-process-mode`

---

## 浏览器配置

### Chrome 指纹设置

#### 安装扩展

- **SwitchyOmega** - 代理切换
- **User-Agent Switcher** - UA 伪装
- **Canvas Blocker** - 指纹保护

#### 时区设置

使用 **Timezone Manager** 扩展自动切换时区

```
推荐时区: America/Los_Angeles (如果服务器在美国西海岸)
```

#### 禁用 WebRTC

安装 **WebRTC Leak Prevent** 扩展

### Safari 指纹设置

Safari 对 WebRTC 支持有限，相对安全。

1. 偏好设置 → 隐私 → 网站追踪 → 勾选 "要求网站不追踪"
2. 偏好设置 → 隐私 → Cookies → 选择 "阻止跨网站追踪"

### 推荐浏览器配置

```
浏览器: Chrome (推荐)
版本: 最新稳定版
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36

时区: America/Los_Angeles (与服务器一致)
语言: en-US,en;q=0.9
```

---

## 常见问题

### Q1: macOS 提示无法连接网络

解决：
1. 检查系统代理是否正确配置
2. 检查代理客户端是否运行
3. 检查 Surge/Clash 规则是否正确

### Q2: 某些网站无法访问

解决：
1. 切换到全局模式测试
2. 检查规则是否正确
3. 查看客户端日志

### Q3: Safari 无法使用代理

解决：
1. 确保在系统代理设置中启用了代理
2. 使用 Surge 的增强模式

### Q4: ClashX 内存占用高

解决：
1. 减少同时连接数
2. 使用 Clash Verge (更高效)
3. 限制规则数量
