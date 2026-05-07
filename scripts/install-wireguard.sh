#!/bin/bash
# ============================================
# WireGuard 安装脚本
# 适用于 TikTok 直播优化
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "需要 root 权限"
        exit 1
    fi
}

install_wireguard() {
    log_info "安装 WireGuard..."
    
    # Ubuntu/Debian
    if [[ -f /etc/debian_version ]]; then
        apt update
        apt install -y wireguard wireguard-tools
    # CentOS/Rocky
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y epel-release
        yum install -y wireguard-tools
    fi
    
    log_info "WireGuard 安装完成"
}

generate_keys() {
    log_info "生成 WireGuard 密钥..."
    
    cd /etc/wireguard
    
    # 生成服务器密钥
    wg genkey | tee server_private.key | wg pubkey > server_public.key
    
    # 生成客户端密钥（可以生成多个）
    wg genkey | tee client1_private.key | wg pubkey > client1_public.key
    wg genkey | tee client2_private.key | wg pubkey > client2_public.key
    
    # 设置权限
    chmod 600 *.key
    
    # 显示公钥
    echo ""
    log_info "服务器公钥:"
    cat server_public.key
    echo ""
    log_info "客户端1公钥 (用于客户端配置):"
    cat client1_public.key
    echo ""
}

setup_server_config() {
    log_info "配置 WireGuard 服务器..."
    
    SERVER_IP=$(curl -s ifconfig.me)
    
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/server_private.key)
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# 客户端1 - 手机
[Peer]
PublicKey = $(cat /etc/wireguard/client1_public.key)
AllowedIPs = 10.0.0.2/32

# 客户端2 - 电脑
[Peer]
PublicKey = $(cat /etc/wireguard/client2_public.key)
AllowedIPs = 10.0.0.3/32
EOF
    
    chmod 600 /etc/wireguard/wg0.conf
}

enable_ip_forward() {
    log_info "启用 IP 转发..."
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
}

start_service() {
    log_info "启动 WireGuard 服务..."
    
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    systemctl status wg-quick@wg0 --no-pager
    
    log_info "WireGuard 服务已启动"
}

show_client_config() {
    SERVER_IP=$(curl -s ifconfig.me)
    
    echo ""
    echo "========================================"
    echo "         客户端配置信息"
    echo "========================================"
    echo ""
    echo "【客户端1 - 手机设备】"
    echo ""
    cat << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/client1_private.key)
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = ${SERVER_IP}:51820
PersistentKeepalive = 25
AllowedIPs = 0.0.0.0/0, ::/0

EOF
    echo "【客户端2 - 电脑设备】"
    echo ""
    cat << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/client2_private.key)
Address = 10.0.0.3/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = ${SERVER_IP}:51820
PersistentKeepalive = 25
AllowedIPs = 0.0.0.0/0, ::/0

EOF
    echo "========================================"
    echo ""
    log_warn "请将以上配置保存到客户端设备"
    log_warn "配置已备份到 /etc/wireguard/clients/"
}

save_client_configs() {
    mkdir -p /etc/wireguard/clients
    
    SERVER_IP=$(curl -s ifconfig.me)
    
    # 客户端1配置
    cat > /etc/wireguard/clients/client1-mobile.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/client1_private.key)
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = ${SERVER_IP}:51820
PersistentKeepalive = 25
AllowedIPs = 0.0.0.0/0, ::/0
EOF
    
    # 客户端2配置
    cat > /etc/wireguard/clients/client2-desktop.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/client2_private.key)
Address = 10.0.0.3/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = ${SERVER_IP}:51820
PersistentKeepalive = 25
AllowedIPs = 0.0.0.0/0, ::/0
EOF
    
    cp /etc/wireguard/clients/*.conf /root/
    log_info "配置已保存到 /root/ 目录"
}

main() {
    echo ""
    echo "========================================"
    echo "   WireGuard TikTok 直播优化安装"
    echo "========================================"
    echo ""
    
    check_root
    install_wireguard
    generate_keys
    setup_server_config
    enable_ip_forward
    start_service
    save_client_configs
    show_client_config
    
    echo ""
    log_info "安装完成！"
    echo ""
    echo "下一步："
    echo "1. 将 /root/client1-mobile.conf 导入手机 WireGuard 客户端"
    echo "2. 将 /root/client2-desktop.conf 导入电脑 WireGuard 客户端"
    echo "3. 开启 VPN 测试 TikTok 直播"
    echo ""
}

main "$@"
