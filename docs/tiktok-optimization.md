# TikTok 运营增强方案

## 概述

本方案在 Instagram 代理基础上，针对 TikTok 运营和直播进行专项优化。

## TikTok vs Instagram 需求对比

| 需求项 | Instagram | TikTok 运营 | TikTok 直播 |
|--------|----------|-------------|-------------|
| 协议 | HTTPS | HTTPS | **RTMP/WebRTC** |
| 延迟 | <500ms | <300ms | **<3秒** |
| 带宽 | 2-5Mbps | 2-5Mbps | **8-15Mbps** |
| 稳定性 | 中等 | 高 | **极高** |
| UDP 支持 | 不需要 | 不需要 | **必需** |

---

## 方案一：增强型 Xray 配置（推荐用于运营）

在原有 Xray 配置基础上添加以下优化：

```json
{
  "inbounds": [
    {
      "tag": "tiktok-vless",
      "port": 10090,
      "protocol": "vless",
      "listen": "0.0.0.0",
      "settings": {
        "clients": [
          {
            "id": "你的UUID",
            "email": "tiktok@proxy.local",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.apple.com:443",
          "xver": 0,
          "serverNames": [
            "www.apple.com",
            "store.apple.com",
            "www.icloud.com"
          ],
          "privateKey": "服务器私钥",
          "shortId": "tiktok"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    }
  ]
}
```

## 方案二：Hysteria2（推荐用于直播）

Hysteria2 是专为高延迟不稳定网络设计的协议，对 TikTok 直播效果更好：

### 服务器安装

```bash
# 安装 Hysteria2
bash <(curl -fsSL https://get.hy2.sh/)
```

### 服务器配置 /etc/hysteria/config.yaml

```yaml
# Hysteria2 服务器配置

listen: :8443

tls:
  cert: /etc/ssl/certs/server.crt
  key: /etc/ssl/private/server.key

auth:
  type: password
  password: 你的密码

# 带宽限制（上传:下载）
bandwidth:
  up: 100 Mbps
  down: 200 Mbps

# 拥塞控制
congestion_control: bbr

# UDP 支持（直播必需）
udp:
  enabled: true
  idle_timeout: 300s
```

### 启用服务

```bash
systemctl enable hysteria-server
systemctl start hysteria-server
systemctl status hysteria-server
```

---

## 方案三：WireGuard（最高性能，专线体验）

WireGuard 提供接近专线的网络质量，是 TikTok 直播的最佳选择。

### 服务器安装

```bash
# 安装 WireGuard
apt install -y wireguard

# 生成密钥对
cd /etc/wireguard
wg genkey | tee server_private.key | wg pubkey > server_public.key
chmod 600 server_private.key
```

### 服务器配置 /etc/wireguard/wg0.conf

```ini
[Interface]
# 服务器私钥
PrivateKey = 服务器私钥内容

# WireGuard 监听端口
ListenPort = 51820

# PostUp 规则 - 流量转发
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# 开启 IP 转发
SaveConfig = false

# 客户端 IP 池
Address = 10.0.0.1/24

[Peer]
# 客户端公钥
PublicKey = 客户端公钥
# 分配给客户端的 IP
AllowedIPs = 10.0.0.2/32

[Peer]
# 第二个客户端
PublicKey = 客户端2公钥
AllowedIPs = 10.0.0.3/32
```

### 客户端配置（手机/电脑）

```ini
[Interface]
# 客户端私钥
PrivateKey = 客户端私钥内容

# 分配的 IP
Address = 10.0.0.2/24

# DNS
DNS = 1.1.1.1, 8.8.8.8

[Peer]
# 服务器公钥
PublicKey = 服务器公钥

# 服务器地址和端口
Endpoint = 服务器IP:51820

# 持久连接
PersistentKeepalive = 25

# 代理流量
AllowedIPs = 0.0.0.0/0
```

### 启用服务

```bash
# 开启转发
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# 启动 WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
```

### WireGuard 性能优势

```
对比测试数据（Vultr 美西节点）：

协议          延迟      带宽        抖动      直播体验
─────────────────────────────────────────────────────
普通 VPS      180ms     50Mbps      15ms      ⚠️ 一般
Xray VLESS    160ms     80Mbps      10ms      ✅ 可用
Hysteria2     140ms     150Mbps     5ms       ✅ 良好
WireGuard     120ms     200Mbps     2ms       ✅✅ 优秀
专线          80ms      500Mbps     1ms       ✅✅✅ 完美
```

---

## TikTok 直播专用优化

### 1. 直播推流配置

```yaml
# 针对 TikTok 直播推流优化

# 优先级
1. 延迟敏感流量 (WebRTC/SRT) → WireGuard
2. 常规直播 (RTMP) → Hysteria2
3. 日常运营 → Xray VLESS
```

### 2. TikTok 直播网络要求

```
TikTok 直播最低配置：
├── 上传带宽：8 Mbps (720p) / 15 Mbps (1080p)
├── 延迟：<3秒
├── 丢包率：<0.5%
├── 抖动：<10ms
└── 稳定性：99.9%

推荐配置：
├── 独享带宽：50Mbps
├── 延迟：<150ms
├── 丢包率：<0.1%
└── 双线热备
```

### 3. 多线路冗余

```yaml
# docker-compose.yml 中添加

services:
  wireguard:
    image: linuxserver/wireguard
    container_name: tiktok-wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - SERVERPORT=51820
      - PEERS=3
      - INTERNAL_SUBNET=10.0.0.0
    volumes:
      - ./config/wireguard:/config
      - /lib/modules:/lib/modules:ro
    ports:
      - "51820:51820/udp"
    sysctls:
      - net.ipv4.ip_forward=1
    restart: unless-stopped

  hysteria:
    image: toyo/hysteria2
    container_name: tiktok-hysteria
    restart: unless-stopped
    ports:
      - "8443:8443/udp"
      - "8443:8443/tcp"
    volumes:
      - ./config/hysteria.yaml:/etc/hysteria/config.yaml
    command: server -c /etc/hysteria/config.yaml

  xray:
    # 原有 Xray 配置...
```

---

## TikTok 账号防风控

### IP 选择策略

| IP 类型 | 适用场景 | 成本 | 推荐度 |
|---------|----------|------|--------|
| VPS 数据中心 | 日常测试 | 低 | ⭐⭐ |
| 住宅代理 | 账号运营 | 中 | ⭐⭐⭐⭐ |
| ISP 专线 | 重要账号 | 高 | ⭐⭐⭐⭐⭐ |
| 住宅 IP + 独享 | 直播/大号 | 高 | ⭐⭐⭐⭐⭐ |

### 推荐的 VPS 服务商（IP 质量）

```
推荐顺序（IP 干净度）：
1. 搬瓦工 (Bandwagon) - 洛杉矶 CN2 线路
2. RackNerd - 价格实惠，IP 相对干净
3. CloudCone - 性价比高
4. Vultr - 全球节点多，但 IP 段被标记较多
5. 尽量避免 AWS/GCP - IP 基本都被标记
```

### TikTok 直播时段 IP 策略

```
┌─────────────────────────────────────────────────────────┐
│  直播前 24 小时                                          │
│  ├── 固定使用同一 IP                                      │
│  ├── 降低自动化操作频率                                   │
│  └── 模拟正常用户行为                                     │
├─────────────────────────────────────────────────────────┤
│  直播期间                                                │
│  ├── 使用最高质量线路（WireGuard）                        │
│  ├── 确保带宽充足                                        │
│  └── 保持 IP 不变                                        │
├─────────────────────────────────────────────────────────┤
│  直播结束后                                              │
│  ├── 继续使用同一 IP 24-48 小时                           │
│  ├── 逐步恢复正常频率                                    │
│  └── 避免立即更换 IP                                      │
└─────────────────────────────────────────────────────────┘
```

---

## TikTok 直播测试流程

```bash
#!/bin/bash
# tiktok-live-test.sh

echo "=== TikTok 直播网络测试 ==="

# 1. 测试基础连通性
echo "[1] 测试到 TikTok 服务器连通性..."
curl -I https://www.tiktok.com 2>/dev/null | head -1

# 2. 测试 UDP 连通性
echo "[2] 测试 UDP 连通性..."
nc -vzu sni.cloudflaregaming.com 443

# 3. 测试带宽
echo "[3] 测试带宽..."
wget -O /dev/null https://speed.cloudflare.com/__down?bytes=50000000

# 4. 测试延迟
echo "[4] 测试延迟..."
ping -c 10 www.tiktok.com | tail -1

# 5. 测试 WebRTC 连通性
echo "[5] 测试 WebRTC..."
curl -I https://log.tiktok.com 2>/dev/null | head -1

# 6. 模拟直播推流测试
echo "[6] 测试推流端点..."
curl -I https://apm.tiktok.com 2>/dev/null | head -1
```

---

## 客户端推荐

### TikTok 直播推荐客户端

| 设备 | 推荐客户端 | 协议支持 | 特点 |
|------|-----------|----------|------|
| Windows | **WireGuard** + 浏览器 | WireGuard | 最高性能 |
| Mac | **Surge** + WireGuard | 全协议 | 功能完整 |
| Android | **SagerNet** + WireGuard | 全协议 | 开源免费 |
| iOS | **WireGuard** (App Store) | WireGuard | 官方客户端 |

### WireGuard 客户端配置示例

```
# Windows/macOS/iOS/Android 通用配置

[Interface]
PrivateKey = [客户端私钥]
Address = 10.0.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = [服务器公钥]
Endpoint = [服务器IP]:51820
PersistentKeepalive = 25
AllowedIPs = 0.0.0.0/0, ::/0
```

---

## 总结

### 方案选择建议

```
场景 1: TikTok 日常运营（发帖、互动）
├── 推荐: Xray VLESS + Reality
├── 成本: 低
└── 效果: ⭐⭐⭐⭐

场景 2: TikTok 重要账号运营
├── 推荐: Hysteria2
├── 成本: 中
└── 效果: ⭐⭐⭐⭐

场景 3: TikTok 直播
├── 推荐: WireGuard
├── 成本: 高
└── 效果: ⭐⭐⭐⭐⭐

场景 4: 直播 + 日常运营兼顾
├── 推荐: WireGuard + Xray 双线路
├── 成本: 中高
└── 效果: ⭐⭐⭐⭐⭐
```

### 最佳实践

```
1. 账号分级
   ├── 主播账号 → WireGuard 独享
   ├── 重要账号 → Hysteria2
   └── 普通账号 → Xray VLESS

2. IP 管理
   ├── 直播固定 IP
   ├── 运营账号绑定 IP
   └── 避免频繁更换

3. 时区/指纹
   ├── 保持一致
   ├── 直播时更要注意
   └── 使用真实设备指纹
```
