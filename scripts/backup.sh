#!/bin/bash
# ============================================
# 备份脚本
# 用于备份 Instagram 代理配置和数据
# ============================================

set -e

# 配置
BACKUP_DIR="/opt/proxy-backup"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[*] 开始备份...${NC}"

# 创建备份目录
mkdir -p "$BACKUP_DIR/config/$DATE"
mkdir -p "$BACKUP_DIR/logs/$DATE"

# 备份配置文件
echo "[*] 备份配置文件..."
cp /etc/xray/config.json "$BACKUP_DIR/config/$DATE/" 2>/dev/null || true
cp /etc/nginx/nginx.conf "$BACKUP_DIR/config/$DATE/" 2>/dev/null || true
cp /etc/nginx/conf.d/default.conf "$BACKUP_DIR/config/$DATE/" 2>/dev/null || true
cp /etc/fail2ban/jail.local "$BACKUP_DIR/config/$DATE/" 2>/dev/null || true
cp /root/proxy-accounts.txt "$BACKUP_DIR/config/$DATE/" 2>/dev/null || true

# 备份日志（最近的）
echo "[*] 备份日志文件..."
find /var/log/xray -name "*.log" -mtime -1 -exec cp {} "$BACKUP_DIR/logs/$DATE/" \; 2>/dev/null || true
find /var/log/nginx -name "*.log" -mtime -1 -exec cp {} "$BACKUP_DIR/logs/$DATE/" \; 2>/dev/null || true

# 备份 Docker 配置（如果存在）
if [[ -d "docker" ]]; then
    mkdir -p "$BACKUP_DIR/docker/$DATE"
    cp -r docker/* "$BACKUP_DIR/docker/$DATE/" 2>/dev/null || true
fi

# 创建备份压缩包
echo "[*] 创建压缩包..."
cd "$BACKUP_DIR"
tar -czf "backup_${DATE}.tar.gz" "config/$DATE" "logs/$DATE" 2>/dev/null

# 清理临时目录
rm -rf "$BACKUP_DIR/config/$DATE" "$BACKUP_DIR/logs/$DATE" 2>/dev/null || true

# 清理旧备份
echo "[*] 清理超过 $RETENTION_DAYS 天的备份..."
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo -e "${GREEN}[+] 备份完成: $BACKUP_DIR/backup_${DATE}.tar.gz${NC}"
echo "[*] 备份文件列表:"
ls -lh "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null || echo "无备份文件"
