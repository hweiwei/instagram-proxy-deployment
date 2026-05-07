#!/bin/bash
# ============================================
# 健康检查脚本
# 用于监控 Instagram 代理服务状态
# ============================================

set -e

# 配置
CHECK_INTERVAL=30
ALERT_EMAIL="admin@localhost"
LOG_FILE="/var/log/health-check.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_service() {
    local service=$1
    local port=$2
    
    if systemctl is-active --quiet "$service"; then
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -e "${GREEN}✓${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ 服务运行但端口未监听${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗${NC}"
        return 2
    fi
}

main() {
    echo "========================================"
    echo "Instagram Proxy 健康检查"
    echo "时间: $(date)"
    echo "========================================"
    
    local all_ok=true
    
    # 检查 Xray
    echo -n "[1/5] Xray 服务: "
    if check_service "xray" "10086"; then
        log "Xray: OK"
    else
        log "Xray: FAILED"
        systemctl restart xray
        all_ok=false
    fi
    
    # 检查 Nginx
    echo -n "[2/5] Nginx 服务: "
    if check_service "nginx" "443"; then
        log "Nginx: OK"
    else
        log "Nginx: FAILED"
        systemctl restart nginx
        all_ok=false
    fi
    
    # 检查 Docker
    echo -n "[3/5] Docker 服务: "
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✓${NC}"
        log "Docker: OK"
    else
        echo -e "${YELLOW}⚠ 未运行${NC}"
        log "Docker: Not Running"
    fi
    
    # 检查端口连通性
    echo -n "[4/5] 端口连通性: "
    local port_ok=true
    for port in 80 443 10086 10087; do
        if ! netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -n "${port} "
            port_ok=false
        fi
    done
    if $port_ok; then
        echo -e "${GREEN}✓ 全部正常${NC}"
        log "Ports: All OK"
    else
        echo -e "${RED}存在问题${NC}"
        log "Ports: Some Failed"
        all_ok=false
    fi
    
    # 检查 SSL 证书
    echo -n "[5/5] SSL 证书: "
    local cert_file="/etc/letsencrypt/live/$(hostname)/fullchain.pem"
    if [[ -f "$cert_file" ]]; then
        local expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
        local days_left=$(($(date -d "$expiry" +%s) - $(date +%s) / 86400))
        if [[ $days_left -gt 30 ]]; then
            echo -e "${GREEN}✓ 有效 (${days_left}天)${NC}"
            log "SSL: OK ($days_left days)"
        else
            echo -e "${YELLOW}⚠ 即将过期 (${days_left}天)${NC}"
            log "SSL: Expiring Soon ($days_left days)"
        fi
    else
        echo -e "${YELLOW}⚠ 自签名证书${NC}"
        log "SSL: Self-signed"
    fi
    
    echo ""
    echo "========================================"
    
    if $all_ok; then
        echo -e "${GREEN}✓ 所有服务运行正常${NC}"
        exit 0
    else
        echo -e "${RED}✗ 存在问题，请检查${NC}"
        exit 1
    fi
}

main "$@"
