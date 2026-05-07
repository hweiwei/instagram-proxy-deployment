#!/bin/bash
# ============================================
# iptables 防火墙规则配置
# 用于 Instagram 代理流量中转
# ============================================

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[*] 开始配置 iptables 防火墙规则...${NC}"

# 检查是否以 root 权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] 此脚本需要 root 权限运行${NC}"
   echo -e "${YELLOW}[!] 请使用: sudo $0${NC}"
   exit 1
fi

# 保存现有规则
echo -e "${YELLOW}[*] 保存现有 iptables 规则...${NC}"
mkdir -p /opt/backup
iptables-save > /opt/backup/iptables.backup.$(date +%Y%m%d_%H%M%S)

# 清除现有规则
echo -e "${YELLOW}[*] 清除现有规则...${NC}"
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# 设置默认策略
echo -e "${YELLOW}[*] 设置默认策略...${NC}"
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 允许 loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 允许已建立连接的流量
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ============================================
# SSH 连接
# ============================================
echo -e "${YELLOW}[*] 配置 SSH 规则...${NC}"
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# ============================================
# HTTP/HTTPS
# ============================================
echo -e "${YELLOW}[*] 配置 HTTP/HTTPS 规则...${NC}"
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# ============================================
# Xray 代理端口
# ============================================
echo -e "${YELLOW}[*] 配置代理端口规则...${NC}"
# VLESS
iptables -A INPUT -p tcp --dport 10086 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# Trojan
iptables -A INPUT -p tcp --dport 10087 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# VMess WS
iptables -A INPUT -p tcp --dport 10089 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# ============================================
# Cloudflare IP 白名单（如果使用 CF）
# ============================================
echo -e "${YELLOW}[*] 添加 Cloudflare IP 白名单...${NC}"
for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
    iptables -A INPUT -p tcp -s "$ip" --dport 443 -j ACCEPT
done

for ip in $(curl -s https://www.cloudflare.com/ips-v6); do
    iptables -A INPUT -p tcp -s "$ip" --dport 443 -j ACCEPT
done 2>/dev/null

# ============================================
# 限制连接数（防滥用）
# ============================================
echo -e "${YELLOW}[*] 配置连接限制...${NC}"
# 每个 IP 最大 50 个并发连接
iptables -A INPUT -p tcp --dport 10086 -m connlimit --connlimit-above 50 -j DROP
iptables -A INPUT -p tcp --dport 10087 -m connlimit --connlimit-above 50 -j DROP
iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 100 -j DROP

# ============================================
# 速率限制
# ============================================
echo -e "${YELLOW}[*] 配置速率限制...${NC}"
# 每分钟最多 30 个新连接
iptables -A INPUT -p tcp --dport 10086 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 10086 -m state --state NEW -m recent --update --seconds 60 --hitcount 30 -j DROP

# ============================================
# 地理位置限制（可选）
# ============================================
# 解注以下行以限制只有特定国家的 IP 访问
# iptables -A INPUT -p tcp --dport 443 -m geoip --src-cc CN -j ACCEPT
# iptables -A INPUT -p tcp --dport 443 -j DROP

# ============================================
# IG 特定端口（Instagram 爬虫场景）
# ============================================
echo -e "${YELLOW}[*] 配置 Instagram 相关端口...${NC}"
# 允许 Instagram 相关域名解析后的 IP
iptables -A INPUT -p tcp --dport 443 -m connbytes --connbytes-mode:both --connbytes 0:10485760 -j ACCEPT

# ============================================
# ICMP (Ping) 控制
# ============================================
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

# ============================================
# 防止端口扫描
# ============================================
echo -e "${YELLOW}[*] 防止端口扫描...${NC}"
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# ============================================
# IP 转发配置
# ============================================
echo -e "${YELLOW}[*] 配置 IP 转发...${NC}"
# 启用 IP 转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 持久化 IP 转发配置
if ! grep -q "net.ipv4.ip_forward" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi

# NAT 转发（用于透明代理）
iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.16.0.0/12 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -o eth0 -j MASQUERADE

# ============================================
# 日志记录可疑活动
# ============================================
echo -e "${YELLOW}[*] 配置日志记录...${NC}"
# 记录被拒绝的流量
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-DROP: " --log-level 4

# ============================================
# 保存规则
# ============================================
echo -e "${YELLOW}[*] 保存 iptables 规则...${NC}"
if [ -x "$(command -v iptables-save)" ]; then
    if [ -d "/etc/iptables" ]; then
        iptables-save > /etc/iptables/rules.v4
    elif [ -d "/etc/sysconfig/iptables" ]; then
        iptables-save > /etc/sysconfig/iptables
    else
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4
    fi
fi

# 设置内核参数优化
echo -e "${YELLOW}[*] 优化内核参数...${NC}"
cat >> /etc/sysctl.conf << 'EOF'
# Instagram Proxy 优化
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
EOF

sysctl -p > /dev/null 2>&1

echo ""
echo -e "${GREEN}[+] iptables 配置完成！${NC}"
echo ""
echo -e "${YELLOW}当前规则列表：${NC}"
iptables -L -n -v --line-numbers
echo ""
echo -e "${GREEN}如需恢复原规则，执行：${NC}"
echo -e "${YELLOW}  iptables-restore < /opt/backup/iptables.backup.*${NC}"
