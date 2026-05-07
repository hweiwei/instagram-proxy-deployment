# 故障排查指南

## 目录

- [服务器端问题](#服务器端问题)
- [客户端连接问题](#客户端连接问题)
- [Instagram 访问问题](#instagram-访问问题)
- [性能问题](#性能问题)
- [常见错误代码](#常见错误代码)

---

## 服务器端问题

### 1. Xray 服务无法启动

**症状**: `systemctl start xray` 失败

**排查步骤**:

```bash
# 1. 查看详细错误日志
journalctl -u xray -n 50 --no-pager

# 2. 检查配置文件语法
xray run -test -config /etc/xray/config.json

# 3. 检查端口占用
netstat -tlnp | grep -E '(10086|10087|10088|10089)'

# 4. 检查日志目录权限
ls -la /var/log/xray/
chown -R nobody:nogroup /var/log/xray
```

**常见原因**:

| 原因 | 解决方法 |
|------|----------|
| 配置文件 JSON 语法错误 | 使用 `jq .` 验证 JSON 格式 |
| 端口被占用 | 更换端口或 kill 占用进程 |
| SSL 证书路径错误 | 检查 `/etc/ssl/certs/server.crt` 是否存在 |
| 权限不足 | `chmod 644 /etc/xray/config.json` |

### 2. Nginx 无法启动

**症状**: Nginx 服务启动失败

```bash
# 1. 测试配置语法
nginx -t

# 2. 查看错误日志
tail -20 /var/log/nginx/error.log

# 3. 检查端口占用
netstat -tlnp | grep -E '(80|443)'

# 4. 检查 SSL 证书
ls -la /etc/letsencrypt/live/ 2>/dev/null || ls -la /etc/ssl/certs/server.crt
```

### 3. 防火墙阻止连接

**症状**: 客户端连接超时

```bash
# 1. 检查 iptables 规则
iptables -L -n -v | grep -E '(10086|10087|443|80)'

# 2. 检查 UFW 状态
ufw status

# 3. 开放端口
ufw allow 10086/tcp
ufw allow 10087/tcp
ufw allow 443/tcp
ufw allow 80/tcp

# 4. 检查云服务商安全组（Vultr 控制台）
# 确保入站规则允许 10086, 10087, 80, 443
```

### 4. SSL 证书问题

**症状**: 浏览器显示证书无效

```bash
# 1. 检查证书是否过期
openssl x509 -in /etc/ssl/certs/server.crt -noout -dates

# 2. 检查证书内容
openssl x509 -in /etc/ssl/certs/server.crt -noout -subject -issuer

# 3. 重新生成自签名证书
openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout /etc/ssl/private/server.key \
    -out /etc/ssl/certs/server.crt \
    -subj "/C=US/ST=California/L=SF/O=Proxy/CN=你的服务器IP" \
    -days 3650

# 4. 重启服务
systemctl restart xray
systemctl restart nginx
```

### 5. Docker 容器问题

```bash
# 1. 查看容器状态
docker-compose ps

# 2. 查看容器日志
docker-compose logs xray
docker-compose logs nginx

# 3. 重启容器
docker-compose restart

# 4. 重新构建
docker-compose down
docker-compose up -d --force-recreate

# 5. 进入容器调试
docker exec -it instagram-xray /bin/sh
```

---

## 客户端连接问题

### 1. VLESS 连接失败

**症状**: 客户端显示连接失败

**排查清单**:

```
[ ] 确认服务器 IP 正确
[ ] 确认端口 10086 开放
[ ] 确认 UUID 正确
[ ] 确认 Flow 设置为 xtls-rprx-vision
[ ] 确认 TLS 指纹为 chrome
[ ] 检查客户端日志
```

**Windows (V2rayN) 日志**:

1. 右键任务栏图标 → 查看日志
2. 查看详细错误信息

**iOS (Shadowrocket) 日志**:

1. 设置 → 日志 → 开启详细日志
2. 查看连接失败原因

### 2. Trojan 连接失败

```bash
# 服务器端检查密码
grep -A5 "trojan" /etc/xray/config.json | grep password

# 客户端配置检查
协议: Trojan
服务器: IP地址
端口: 10087
密码: [UUID]
TLS: 开启
SNI: IP地址
```

### 3. WebSocket 连接失败

```bash
# 1. 检查 Nginx WebSocket 配置
grep -A10 "instagram-ws" /etc/nginx/conf.d/default.conf

# 2. 测试 WebSocket 端口
curl -v --http1.1 \
    -H "Connection: Upgrade" \
    -H "Upgrade: websocket" \
    -H "Sec-WebSocket-Version: 13" \
    -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
    https://你的服务器IP/instagram-ws
```

### 4. 常见客户端错误

| 错误代码 | 含义 | 解决方法 |
|----------|------|----------|
| `400 Bad Request` | 请求格式错误 | 检查配置参数 |
| `401 Unauthorized` | 认证失败 | 检查 UUID/密码 |
| `403 Forbidden` | 权限不足 | 检查账号配置 |
| `404 Not Found` | 路径错误 | 检查 WebSocket 路径 |
| `525 SSL Handshake Failed` | TLS 握手失败 | 检查证书和 SNI |
| `timeout` | 连接超时 | 检查防火墙和端口 |
| `connection refused` | 端口未开放 | 检查服务和防火墙 |

---

## Instagram 访问问题

### 1. Instagram 页面无法加载

**排查步骤**:

```bash
# 1. 测试服务器到 Instagram 的连通性
curl -I https://www.instagram.com

# 2. 检查 DNS 解析
nslookup www.instagram.com
dig www.instagram.com

# 3. 测试特定端点
curl -I https://graph.instagram.com
curl -I https://i.instagram.com
```

**可能原因**:

```
原因 1: DNS 污染
解决: 使用 1.1.1.1 或 8.8.8.8 DNS

原因 2: IP 被 Instagram 限制
解决: 更换服务器 IP

原因 3: 域名被墙
解决: 使用域名+CDN 方案
```

### 2. Instagram 登录失败

**检查清单**:

```
[ ] IP 是否在 Instagram 黑名单
[ ] 设备指纹是否与 IP 匹配
[ ] 时区设置是否正确
[ ] 是否有验证码要求
[ ] 账号是否被封禁
```

**解决步骤**:

1. 确认代理正常工作（访问 whoer.net 检查 IP）
2. 清除浏览器缓存和 Cookie
3. 更换 IP 尝试
4. 使用浏览器隐身模式登录

### 3. Instagram 功能受限

**症状**: 无法关注、点赞、评论

```python
# 检查是否被限流的简单测试
# 在浏览器控制台执行

// 测试 API 响应时间
fetch('https://www.instagram.com/')
  .then(r => console.log('Status:', r.status))
  .catch(e => console.log('Error:', e));

// 测试关注功能
// 尝试关注一个账号，观察返回
```

**应对策略**:

1. 立即停止所有自动化操作
2. 等待 24-72 小时
3. 恢复后降低操作频率
4. 考虑更换 IP

---

## 性能问题

### 1. 速度慢

**诊断**:

```bash
# 1. 测试服务器带宽
wget -O /dev/null https://speed.cloudflare.com/__down?bytes=100000000

# 2. 测试到 Instagram 的延迟
ping -c 10 graph.instagram.com

# 3. 测试 TLS 握手时间
curl -w "Time: %{time_appconnect}s\n" -o /dev/null -s https://www.instagram.com

# 4. 查看 Xray 连接数
netstat -an | grep 10086 | wc -l
```

**优化建议**:

```
优化 1: 启用 BBR 加速
bash <(curl -sL https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh)

优化 2: 更换更近的服务器节点
- 美西用户选择洛杉矶
- 亚洲用户选择日本/新加坡

优化 3: 优化 MTU
# 编辑 /etc/sysctl.conf
net.ipv4.tcp_mtu_probing = 1

优化 4: 使用更快的协议
推荐顺序: VLESS > Trojan > VMess
```

### 2. 高延迟

```bash
# 1. 路由追踪
traceroute -I graph.instagram.com

# 2. 查看当前 BBR 状态
sysctl net.ipv4.tcp_congestion_control

# 3. 检查丢包率
ping -c 100 -i 0.2 graph.instagram.com
```

### 3. 连接不稳定

```bash
# 1. 检查系统负载
top
htop
free -m
df -h

# 2. 检查连接数限制
cat /proc/sys/net/core/somaxconn
cat /proc/sys/net/ipv4/ip_local_port_range

# 3. 检查日志中的错误
grep -i error /var/log/xray/error.log | tail -20
```

---

## 常见错误代码

### Xray 错误代码

| 错误 | 含义 | 解决 |
|------|------|------|
| `Failed to create instance` | 配置文件错误 | 检查 JSON 语法 |
| `Failed to start` | 启动失败 | 查看 journalctl |
| `Invalid user` | 用户认证失败 | 检查 UUID |
| `Connection timeout` | 超时 | 检查防火墙 |
| `Connection refused` | 端口未监听 | 检查服务状态 |

### Nginx 错误代码

| 错误 | 含义 | 解决 |
|------|------|------|
| `nginx: [emerg] directive is not allowed here` | 配置位置错误 | 检查配置文件 |
| `host not found in upstream` | 上游服务器未找到 | 检查 upstream 配置 |
| `SSL_do_handshake() failed` | SSL 握手失败 | 检查证书 |

### Docker 错误代码

| 错误 | 含义 | 解决 |
|------|------|------|
| `Cannot connect to the Docker daemon` | Docker 未运行 | `systemctl start docker` |
| `port is already allocated` | 端口占用 | 更换端口 |
| `container exited with code 1` | 启动失败 | 查看日志 |

---

## 诊断命令速查

```bash
# 系统状态
systemctl status xray
systemctl status nginx
systemctl status docker

# 端口监听
netstat -tlnp | grep -E '(10086|10087|443|80)'

# 防火墙状态
ufw status
iptables -L -n -v

# 日志查看
journalctl -u xray -f
tail -f /var/log/xray/access.log
tail -f /var/log/nginx/error.log

# 连接测试
curl -I https://www.instagram.com
curl -I https://graph.instagram.com

# 网络测试
ping -c 5 www.instagram.com
traceroute www.instagram.com

# SSL 测试
openssl s_client -connect 服务器IP:443 -servername 服务器IP
```

---

## 获取帮助

如果以上方法都无法解决问题：

1. **收集诊断信息**:
```bash
# 生成诊断报告
cat > diagnostic.sh << 'EOF'
#!/bin/bash
echo "=== System Info ==="
uname -a
echo ""
echo "=== Service Status ==="
systemctl status xray --no-pager
systemctl status nginx --no-pager
echo ""
echo "=== Network ==="
netstat -tlnp | grep -E '(10086|10087|443|80)'
echo ""
echo "=== Firewall ==="
iptables -L -n -v
echo ""
echo "=== Logs ==="
tail -50 /var/log/xray/error.log
EOF
chmod +x diagnostic.sh
./diagnostic.sh > diagnostic_report.txt
```

2. **检查官方文档**: 
   - Xray 官方文档: https://xtls.github.io/
   - V2fly 社区: https://github.com/v2fly/v2ray-core

3. **社区支持**:
   - GitHub Issues
   - Telegram 群组
