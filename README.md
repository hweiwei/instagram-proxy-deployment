# Instagram/TikTok 代理流量中转部署方案

## 项目概述

本方案为 Vultr 海外服务器设计的社交媒体账号运营流量中转系统，支持 **Instagram** 和 **TikTok** 账号运营，同时支持 **TikTok 直播**。

支持手机和电脑设备，具备防风控能力。

## 新手入门

**如果你对网络和代理完全不了解，请先阅读：**
📖 **[新手完整指南](docs/beginners-guide.md)** - 从零开始，图文并茂教你搭建和使用

## 功能支持

| 平台 | 日常运营 | 直播推流 | 推荐方案 |
|------|----------|----------|----------|
| **Instagram** | ✅ 完全支持 | ⚠️ 基本支持 | Xray VLESS |
| **TikTok** | ✅ 完全支持 | ✅ 良好支持 | Xray + Hysteria2 + WireGuard |

## 核心特性

- **多协议支持**: VLESS、VMess、Trojan、WebSocket
- **TikTok 直播优化**: WireGuard、Hysteria2 高性能方案
- **防风控设计**: TLS 指纹混淆、设备指纹管理
- **账号隔离**: 多账号独立 IP 和端口
- **BBR 加速**: 优化的 TCP 拥塞控制

## 目录结构

```
instagram-proxy-deployment/
├── README.md                          # 项目说明文档
├── deploy.sh                          # 一键部署脚本
├── config/
│   ├── env.conf                       # 环境变量配置
│   ├── xray-config.json               # Xray 代理配置
│   ├── nginx-ssl.conf                 # Nginx SSL 配置
│   ├── nginx-limit.conf               # Nginx 限流配置
│   └── iptables-rules.sh              # 防火墙规则
├── client/
│   ├── android-guide.md               # Android 配置指南
│   ├── ios-guide.md                   # iOS 配置指南
│   ├── windows-guide.md               # Windows 配置指南
│   └── mac-guide.md                   # Mac 配置指南
├── docker/
│   └── docker-compose.yml             # Docker 部署配置
├── scripts/
│   ├── install-xray.sh                # Xray 安装脚本
│   ├── install-docker.sh              # Docker 安装脚本
│   ├── setup-ssl.sh                   # SSL 证书配置
│   ├── health-check.sh                # 健康检查脚本
│   └── backup.sh                      # 备份脚本
├── monitoring/
│   └── prometheus.yml                 # 监控配置
├── docker/
│   └── Dockerfile                     # 自定义 Docker 镜像
└── docs/
    ├── instagram-best-practices.md    # Instagram 运营最佳实践
    ├── troubleshooting.md             # 故障排查指南
    └── architecture.md                # 系统架构说明
```

## 技术架构

### 核心组件

1. **Xray Core** - 多协议代理，支持 VMess/VLESS/Trojan
2. **Nginx** - 反向代理，提供 SSL/TLS 加密
3. **Docker** - 容器化部署，简化环境配置
4. **Cloudflare** - CDN 隐藏真实 IP

### 防护机制

- 真实浏览器指纹模拟
- TLS 指纹混淆
- 流量加密与混淆
- IP 轮换机制
- 请求间隔随机化

## 快速开始

```bash
# 1. 下载部署脚本
git clone <repository-url>
cd instagram-proxy-deployment

# 2. 配置参数
vim config/env.conf

# 3. 一键部署
chmod +x deploy.sh
./deploy.sh
```

## 安全注意事项

⚠️ 本工具仅供正常业务使用，请遵守当地法律法规
