#!/bin/bash
# ============================================
# Instagram 代理流量中转 - 一键部署脚本
# 适用: Vultr / Ubuntu / Debian
# ============================================

set -e

# ============================================
# 颜色定义
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# 日志函数
# ============================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# ============================================
# 检查权限
# ============================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        echo -e "${YELLOW}请使用: sudo $0${NC}"
        exit 1
    fi
}

# ============================================
# 检查系统环境
# ============================================
check_system() {
    log_info "检查系统环境..."

    # 检查 OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        log_info "检测到操作系统: $OS $VER"
    else
        log_error "无法检测操作系统"
        exit 1
    fi

    # 支持的操作系统
    if [[ "$OS" != "ubuntu" && "$OS" != "debian" && "$OS" != "centos" && "$OS" != "rocky" ]]; then
        log_error "不支持的操作系统: $OS"
        log_info "支持的系统: Ubuntu, Debian, CentOS, Rocky Linux"
        exit 1
    fi

    # 检查 CPU 架构
    ARCH=$(uname -m)
    log_info "CPU 架构: $ARCH"

    # 检查内存
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    log_info "总内存: ${TOTAL_MEM}MB"

    if [[ $TOTAL_MEM -lt 512 ]]; then
        log_warn "内存小于 512MB，可能影响性能"
    fi
}

# ============================================
# 生成随机 UUID
# ============================================
generate_uuid() {
    cat /proc/sys/kernel/random/uuid
}

# ============================================
# 生成随机字符串
# ============================================
generate_random() {
    tr -dc 'a-z0-9' </dev/urandom | head -c 16
}

# ============================================
# 读取配置
# ============================================
load_config() {
    log_info "加载配置文件..."

    CONFIG_FILE="config/env.conf"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        log_info "将使用默认配置"
        SERVER_IP=$(curl -s ifconfig.me)
        WS_PATH="/instagram-ws-$(generate_random)"
        DOMAIN=""
        USE_DOMAIN=false
    else
        source "$CONFIG_FILE"
    fi

    # 设置默认值
    SERVER_IP=${SERVER_IP:-$(curl -s ifconfig.me)}
    WS_PATH=${WS_PATH:-"/instagram-ws-$(generate_random)"}

    log_info "服务器IP: $SERVER_IP"
    log_info "WebSocket 路径: $WS_PATH"
}

# ============================================
# 安装基础依赖
# ============================================
install_dependencies() {
    log_info "安装基础依赖..."

    export DEBIAN_FRONTEND=noninteractive

    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt update -qq
        apt install -y -qq \
            curl \
            wget \
            git \
            unzip \
            jq \
            socat \
            tar \
            gzip \
            ca-certificates \
            lsb-release \
            apt-transport-https \
            ca-certificates \
            gnupg \
            ufw \
            fail2ban \
            net-tools \
            iproute2 \
            iputils-ping \
            dnsutils \
            vim \
            htop \
            iftop \
            iotop \
            bc
    elif [[ "$OS" == "centos" || "$OS" == "rocky" ]]; then
        yum install -y -q \
            curl \
            wget \
            git \
            unzip \
            jq \
            socat \
            tar \
            gzip \
            ca-certificates \
            python3 \
            ufw \
            fail2ban \
            net-tools \
            iproute \
            iputils \
            bind-utils \
            vim \
            htop \
            iftop \
            iotop \
            bc
    fi

    log_success "基础依赖安装完成"
}

# ============================================
# 配置 SSH
# ============================================
configure_ssh() {
    log_info "配置 SSH 安全设置..."

    # 禁用密码登录（可选）
    # sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    # sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

    # 禁用 root 登录（可选）
    # sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

    # 重启 SSH 服务
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        systemctl restart sshd
    elif [[ "$OS" == "centos" || "$OS" == "rocky" ]]; then
        systemctl restart sshd
    fi

    log_success "SSH 配置完成"
}

# ============================================
# 安装 Docker
# ============================================
install_docker() {
    log_info "检查 Docker 安装状态..."

    if command -v docker &> /dev/null; then
        log_info "Docker 已安装: $(docker --version)"
        return
    fi

    log_info "安装 Docker..."

    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        curl -fsSL https://get.docker.com | sh

        # 安装 Docker Compose
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        systemctl enable docker
        systemctl start docker

    elif [[ "$OS" == "centos" || "$OS" == "rocky" ]]; then
        curl -fsSL https://get.docker.com | sh

        # 安装 Docker Compose
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        systemctl enable docker
        systemctl start docker
    fi

    # 添加当前用户到 docker 组
    if [[ -n "$SUDO_USER" ]]; then
        usermod -aG docker "$SUDO_USER"
    fi

    log_success "Docker 安装完成"
}

# ============================================
# 安装 Docker Compose 独立版本
# ============================================
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose 已安装"
        return
    fi

    log_info "安装 Docker Compose..."

    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    log_success "Docker Compose 安装完成: $(docker-compose --version)"
}

# ============================================
# 配置 BBR 加速
# ============================================
enable_bbr() {
    log_info "配置 BBR 加速..."

    # 检查 BBR 模块
    if ! sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        modprobe tcp_bbr
        echo "tcp_bbr" >> /etc/modules-load.d/bbr.conf
    fi

    # 配置 sysctl
    cat >> /etc/sysctl.conf << 'EOF'
# BBR 加速配置
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_forward = 1
EOF

    sysctl -p > /dev/null 2>&1

    log_success "BBR 加速配置完成"
    log_info "当前拥塞控制: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
}

# ============================================
# 配置防火墙
# ============================================
configure_firewall() {
    log_info "配置防火墙..."

    # UFW 默认规则
    ufw default deny incoming
    ufw default allow outgoing

    # 允许 SSH
    ufw allow ${SSH_PORT:-22}/tcp

    # 允许 HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # 允许代理端口
    ufw allow 10086/tcp
    ufw allow 10087/tcp
    ufw allow 10088/tcp
    ufw allow 10089/tcp

    # 启用防火墙
    if ! ufw status | grep -q "Status: active"; then
        echo "y" | ufw enable
    fi

    # 配置 iptables
    chmod +x config/iptables-rules.sh
    ./config/iptables-rules.sh

    log_success "防火墙配置完成"
}

# ============================================
# 安装 Xray
# ============================================
install_xray() {
    log_info "安装 Xray..."

    # 下载安装脚本
    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install --beta

    # 创建配置目录
    mkdir -p /etc/xray
    mkdir -p /var/log/xray
    mkdir -p /etc/ssl/certs
    mkdir -p /etc/ssl/private

    # 复制配置文件
    if [[ -f "config/xray-config.json" ]]; then
        cp config/xray-config.json /etc/xray/config.json
    fi

    # 生成 SSL 证书（自签名，用于测试）
    log_info "生成自签名 SSL 证书..."
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/ssl/private/server.key \
        -out /etc/ssl/certs/server.crt \
        -subj "/C=US/ST=California/L=San Francisco/O=Instagram Proxy/OU=Proxy/CN=$SERVER_IP" \
        -days 3650 2>/dev/null

    # 生成账号 UUID
    USER_UUID_1=$(generate_uuid)
    USER_UUID_2=$(generate_uuid)
    USER_UUID_3=$(generate_uuid)

    # 更新 Xray 配置中的用户
    if command -v jq &> /dev/null; then
        # 添加 VLESS 用户
        jq --arg uuid "$USER_UUID_1" \
           --arg email "mobile@proxy.local" \
           '.inbounds[2].settings.clients += [{"id": $uuid, "email": $email, "flow": "xtls-rprx-vision"}]' \
           /etc/xray/config.json > /tmp/xray-config.json && mv /tmp/xray-config.json /etc/xray/config.json

        # 添加 Trojan 用户
        jq --arg password "$USER_UUID_2" \
           --arg email "desktop@proxy.local" \
           '.inbounds[3].settings.clients += [{"password": $password, "email": $email}]' \
           /etc/xray/config.json > /tmp/xray-config.json && mv /tmp/xray-config.json /etc/xray/config.json
    fi

    # 创建日志目录权限
    chown -R nobody:nogroup /var/log/xray

    # 启动 Xray
    systemctl enable xray
    systemctl restart xray

    # 检查状态
    if systemctl is-active --quiet xray; then
        log_success "Xray 安装并启动成功"
    else
        log_error "Xray 启动失败，请检查日志"
        journalctl -u xray -n 50
        exit 1
    fi

    # 保存账号信息
    save_account_info
}

# ============================================
# 保存账号信息
# ============================================
save_account_info() {
    log_info "生成并保存账号配置..."

    ACCOUNTS_FILE="/root/proxy-accounts.txt"

    cat > "$ACCOUNTS_FILE" << EOF
===============================================
Instagram 代理账号信息
生成时间: $(date '+%Y-%m-%d %H:%M:%S %Z')
服务器: $SERVER_IP
===============================================

【账号 - 移动设备 (推荐)】
协议: VLESS + TLS
地址: $SERVER_IP
端口: 10086
UUID: $USER_UUID_1
传输: TCP
TLS: chrome
Flow: xtls-rprx-vision
别名: Mobile-Device

【账号 - 电脑设备】
协议: Trojan
地址: $SERVER_IP
端口: 10087
密码: $USER_UUID_2
SNI: $SERVER_IP
别名: Desktop-Device

【账号 - 备用账号】
协议: VMess WebSocket
地址: $SERVER_IP
端口: 443 (通过 Nginx)
路径: $WS_PATH
UUID: $USER_UUID_3
TLS: chrome
别名: Backup-Device

===============================================
【订阅信息】
订阅地址: https://$SERVER_IP/api/v1/subscribe
（需要配置 Nginx 和订阅服务）

===============================================
【连接参数】
WebSocket 路径: $WS_PATH
TLS 指纹: chrome (推荐)
域名伪装: www.google.com (推荐)

===============================================
请妥善保管以上信息，切勿泄露！
===============================================
EOF

    log_success "账号信息已保存到: $ACCOUNTS_FILE"
    echo ""
    cat "$ACCOUNTS_FILE"
    echo ""
    log_warn "请务必备份账号信息到安全位置！"
}

# ============================================
# 配置 Nginx
# ============================================
install_nginx() {
    log_info "安装 Nginx..."

    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt install -y -qq nginx
    elif [[ "$OS" == "centos" || "$OS" == "rocky" ]]; then
        yum install -y -q nginx
    fi

    # 完全清理默认配置
    rm -f /etc/nginx/conf.d/*.conf
    rm -f /etc/nginx/sites-enabled/*

    # 配置 Nginx 主文件（限流已直接写入 http 块）
    cat > /etc/nginx/nginx.conf << 'NginxMainConfig'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
    multi_accept on;
}

http {
    # 基础设置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # 限流 zone 定义（必须在 server 块之前）
    limit_req_zone $binary_remote_addr zone=proxy_limit:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    # MIME 类型
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss;

    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NginxMainConfig

    # 配置 Nginx SSL 站点
    if [[ -f "config/nginx-ssl.conf" ]]; then
        cp config/nginx-ssl.conf /etc/nginx/conf.d/default.conf
    fi

    # 替换域名占位符
    sed -i "s/your-domain/$SERVER_IP/g" /etc/nginx/conf.d/default.conf

    # 创建日志目录
    mkdir -p /var/log/nginx

    # 生成自签名 SSL 证书（必须在 nginx 测试之前）
    log_info "生成自签名 SSL 证书..."
    mkdir -p /etc/ssl/certs /etc/ssl/private
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/ssl/private/server.key \
        -out /etc/ssl/certs/server.crt \
        -subj "/C=US/ST=California/L=San Francisco/O=Instagram Proxy/OU=Proxy/CN=$SERVER_IP" \
        -days 3650 2>/dev/null

    # 测试配置
    nginx -t

    # 启动 Nginx
    systemctl enable nginx
    systemctl restart nginx

    log_success "Nginx 安装并启动成功"
}

# ============================================
# 配置 SSL 证书（Let's Encrypt）
# ============================================
install_ssl_cert() {
    if [[ "$USE_DOMAIN" == "true" && -n "$DOMAIN" ]]; then
        log_info "申请 Let's Encrypt SSL 证书..."

        # 安装 certbot
        if [[ "$OS" == "ubuntu" ]]; then
            apt install -y -qq python3-certbot-nginx
        elif [[ "$OS" == "debian" ]]; then
            apt install -y -qq python3-certbot-nginx
        elif [[ "$OS" == "centos" || "$OS" == "rocky" ]]; then
            yum install -y -q certbot python3-certbot-nginx
        fi

        # 申请证书
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL" --redirect

        # 设置自动续期
        echo "0 0 * * * root certbot renew --quiet" >> /etc/crontab

        log_success "SSL 证书申请完成"
    else
        log_info "跳过域名配置，使用 IP 访问"
    fi
}

# ============================================
# 配置 Docker 部署
# ============================================
deploy_docker() {
    log_info "部署 Docker 容器..."

    # 创建必要目录
    mkdir -p logs/xray logs/nginx logs/fail2ban
    mkdir -p data/prometheus data/grafana data/uptime-kuma
    mkdir -p html certs backup

    # 复制配置文件
    cp config/xray-config.json docker/config/
    cp config/nginx-ssl.conf docker/config/
    cp config/nginx-limit.conf docker/config/

    # 替换配置中的 IP
    sed -i "s/YOUR_SERVER_IP/$SERVER_IP/g" docker/config/xray-config.json
    sed -i "s/your-domain/$SERVER_IP/g" docker/config/nginx-ssl.conf

    # 生成 SSL 证书
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout certs/server.key \
        -out certs/server.crt \
        -subj "/C=US/ST=California/L=San Francisco/O=Instagram Proxy/OU=Proxy/CN=$SERVER_IP" \
        -days 3650 2>/dev/null

    # 生成新 UUID
    USER_UUID_DOCKER=$(generate_uuid)

    # 更新 Xray 配置
    if command -v jq &> /dev/null; then
        jq --arg uuid "$USER_UUID_DOCKER" \
           '.inbounds[2].settings.clients += [{"id": $uuid, "email": "docker@proxy.local", "flow": "xtls-rprx-vision"}]' \
           docker/config/xray-config.json > /tmp/xray-docker.json && mv /tmp/xray-docker.json docker/config/xray-config.json
    fi

    # 启动容器
    cd docker
    docker-compose up -d
    cd ..

    log_success "Docker 容器部署完成"
}

# ============================================
# 安装 Fail2ban
# ============================================
install_fail2ban() {
    log_info "配置 Fail2ban 防暴力破解..."

    # 创建配置
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sender = fail2ban@localhost
action = %(action_mwl)s

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5

[xray-vless]
enabled = true
port = 10086
filter = xray-vless
logpath = /var/log/xray/access.log
maxretry = 10
bantime = 7200

[xray-trojan]
enabled = true
port = 10087
filter = xray-trojan
logpath = /var/log/xray/access.log
maxretry = 10
bantime = 7200
EOF

    # 创建 Xray 过滤器
    cat > /etc/fail2ban/filter.d/xray-vless.conf << 'EOF'
[Definition]
failregex = ^.*Rejected xray-core connection from <HOST>.*$
ignoreregex =
EOF

    cat > /etc/fail2ban/filter.d/xray-trojan.conf << 'EOF'
[Definition]
failregex = ^.*invalid password from <HOST>.*$
ignoreregex =
EOF

    # 启动 fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban

    log_success "Fail2ban 配置完成"
}

# ============================================
# 性能优化
# ============================================
optimize_system() {
    log_info "系统性能优化..."

    # 增大文件描述符限制
    if ! grep -q "fs.file-max" /etc/sysctl.conf; then
        cat >> /etc/sysctl.conf << 'EOF'
# 文件描述符限制
fs.file-max = 6553600
fs.nr_open = 6553600
EOF
    fi

    # 设置 limits
    if ! grep -q "* soft nofile" /etc/security/limits.conf; then
        cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 6553600
* hard nofile 6553600
root soft nofile 6553600
root hard nofile 6553600
EOF
    fi

    # 应用配置
    sysctl -p > /dev/null 2>&1

    log_success "系统优化完成"
}

# ============================================
# 配置监控
# ============================================
setup_monitoring() {
    log_info "配置系统监控..."

    # 创建健康检查脚本
    cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
# Xray 健康检查脚本

if systemctl is-active --quiet xray; then
    if curl -s -f http://127.0.0.1:10085/stats > /dev/null 2>&1; then
        echo "OK"
        exit 0
    fi
fi

echo "FAILED"
exit 1
EOF
    chmod +x /usr/local/bin/health-check.sh

    # 添加到 crontab
    echo "*/5 * * * * root /usr/local/bin/health-check.sh || systemctl restart xray" >> /etc/crontab

    log_success "监控配置完成"
}

# ============================================
# 创建订阅服务（可选）
# ============================================
setup_subscription() {
    log_info "配置订阅服务..."

    cat > /var/www/html/api/v1/subscribe << 'EOF'
#!/bin/bash
# 简单的订阅服务（生产环境建议使用更安全的实现）

# 这里返回 base64 编码的配置
# 实际使用时应该添加认证和限流

cat /etc/xray/config.json | base64 -w0
EOF
    chmod +x /var/www/html/api/v1/subscribe

    log_success "订阅服务配置完成"
}

# ============================================
# 最终检查
# ============================================
final_check() {
    log_info "执行最终检查..."

    echo ""
    echo "========================================"
    echo -e "${CYAN}         部署完成 - 最终检查${NC}"
    echo "========================================"
    echo ""

    # 检查服务状态
    local all_ok=true

    echo -e "${YELLOW}[1] Xray 服务${NC}"
    if systemctl is-active --quiet xray; then
        echo -e "    ${GREEN}[OK] 运行中${NC}"
    else
        echo -e "    ${RED}[FAIL] 未运行${NC}"
        all_ok=false
    fi

    echo -e "${YELLOW}[2] Nginx 服务${NC}"
    if systemctl is-active --quiet nginx; then
        echo -e "    ${GREEN}[OK] 运行中${NC}"
    else
        echo -e "    ${RED}[FAIL] 未运行${NC}"
        all_ok=false
    fi

    echo -e "${YELLOW}[3] Docker 服务${NC}"
    if systemctl is-active --quiet docker; then
        echo -e "    ${GREEN}[OK] 运行中${NC}"
    else
        echo -e "    ${YELLOW}[SKIP] 未运行（未启用 Docker 模式）${NC}"
    fi

    echo -e "${YELLOW}[4] Fail2ban${NC}"
    if systemctl is-active --quiet fail2ban; then
        echo -e "    ${GREEN}[OK] 运行中${NC}"
    else
        echo -e "    ${YELLOW}[SKIP] 未运行${NC}"
    fi

    echo ""
    echo -e "${YELLOW}[5] 端口监听${NC}"
    netstat -tlnp | grep -E '(10086|10087|443|80)' | while read line; do
        echo -e "    ${GREEN}[OK] $line${NC}"
    done

    echo ""
    echo -e "${YELLOW}[6] BBR 加速${NC}"
    local bbr_status=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    if [[ "$bbr_status" == "bbr" ]]; then
        echo -e "    ${GREEN}[OK] 已启用 BBR${NC}"
    else
        echo -e "    ${YELLOW}[WARN] 当前: $bbr_status${NC}"
    fi

    echo ""
    echo "========================================"

    if $all_ok; then
        log_success "所有核心服务运行正常！"
    else
        log_warn "部分服务可能需要检查"
    fi

    echo ""
    log_info "账号配置文件: ${CYAN}/root/proxy-accounts.txt${NC}"
    echo ""
}

# ============================================
# 显示使用指南
# ============================================
show_usage() {
    echo ""
    echo "========================================"
    echo -e "${CYAN}         使用指南${NC}"
    echo "========================================"
    echo ""
    echo -e "${YELLOW}查看账号信息:${NC}"
    echo "    cat /root/proxy-accounts.txt"
    echo ""
    echo -e "${YELLOW}查看 Xray 状态${NC}"
    echo "    systemctl status xray"
    echo ""
    echo -e "${YELLOW}查看 Xray 日志:${NC}"
    echo "    journalctl -u xray -f"
    echo ""
    echo -e "${YELLOW}查看访问日志:${NC}"
    echo "    tail -f /var/log/xray/access.log"
    echo ""
    echo -e "${YELLOW}重启 Xray:${NC}"
    echo "    systemctl restart xray"
    echo ""
    echo -e "${YELLOW}查看 Fail2ban 状态${NC}"
    echo "    fail2ban-client status"
    echo ""
    echo -e "${YELLOW}客户端配置文件夹:${NC}"
    echo "    ./client/"
    echo ""
    echo "========================================"
}

# ============================================
# 主函数
# ============================================
main() {
    echo ""
    echo "========================================"
    echo -e "${CYAN} Instagram 代理流量中转 - 一键部署${NC}"
    echo -e "${CYAN}           适用: Vultr 服务器${NC}"
    echo "========================================"
    echo ""

    # 执行部署步骤
    check_root
    check_system
    load_config
    install_dependencies
    configure_ssh
    enable_bbr
    configure_firewall
    install_nginx
    install_xray
    install_fail2ban
    optimize_system
    setup_monitoring
    # install_ssl_cert  # 取消注释以使用 Let's Encrypt
    # deploy_docker     # 取消注释以使用 Docker 部署

    final_check
    show_usage

    echo ""
    log_success "部署完成！"
    echo ""
}

# 执行主函数
main "$@"
