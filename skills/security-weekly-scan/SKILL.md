# 🔒 OpenClaw 自动化安全扫描技能

**技能名称:** security-weekly-scan  
**版本:** 1.0.0  
**创建时间:** 2026-03-11  
**执行频率:** 每周一次（周日凌晨 2:00）

---

## 📋 功能说明

本技能提供 OpenClaw 系统的自动化安全扫描和修复功能：

1. **漏洞扫描** - 使用 `npm audit` 检查依赖漏洞
2. **自动升级** - 升级到最新 OpenClaw 版本
3. **依赖修复** - 自动修复第三方依赖漏洞
4. **服务重启** - 重启 Gateway 服务确保更新生效
5. **报告生成** - 生成详细的安全周报
6. **日志管理** - 自动清理旧日志（保留最近 10 次）

---

## 🗓️ 定时任务配置

**Cron 表达式:** `0 2 * * 0`  
**执行时间:** 每周日凌晨 2:00  
**日志位置:** `~/Library/Logs/Cron/security-weekly-scan.log`

### 修改执行频率

```bash
# 查看当前 crontab
crontab -l

# 编辑 crontab
crontab -e

# 常见频率示例：
# 每天凌晨 2 点：0 2 * * *
# 每周一凌晨 2 点：0 2 * * 1
# 每月 1 号凌晨 2 点：0 2 1 * *
# 每 12 小时：0 */12 * * *
```

---

## 📁 文件结构

```
/Users/huangjie/.openclaw/workspace/
├── scripts/
│   └── security-weekly-scan.sh      # 主扫描脚本
├── logs/
│   └── security/
│       ├── security-scan-*.log      # 扫描日志
│       ├── audit-*.json             # 漏洞扫描结果
│       └── cron-security.log        # Cron 执行日志
├── SECURITY_WEEKLY_REPORT.md        # 周报（每次更新）
└── SKILLS/security-weekly-scan/
    └── SKILL.md                     # 本文件
```

---

## 🔧 手动执行

如需手动触发安全扫描：

```bash
# 执行扫描脚本
/Users/huangjie/.openclaw/workspace/scripts/security-weekly-scan.sh

# 或从工作区执行
cd ~/.openclaw/workspace
./scripts/security-weekly-scan.sh
```

---

## 📊 查看报告

### 最新周报
```bash
cat ~/.openclaw/workspace/SECURITY_WEEKLY_REPORT.md
```

### 历史日志
```bash
# 查看最近一次扫描日志
ls -lt ~/.openclaw/workspace/logs/security/ | head -5

# 查看特定日期的漏洞扫描
cat ~/.openclaw/workspace/logs/security/audit-2026-03-11_*.json | jq '.vulnerabilities'
```

### Cron 执行日志
```bash
tail -f ~/.openclaw/workspace/logs/security/cron-security.log
```

---

## ⚙️ 配置选项

### 修改扫描频率

编辑 crontab：
```bash
crontab -e
```

### 修改日志保留数量

编辑脚本中的清理逻辑（默认保留 10 次）：
```bash
# 在 security-weekly-scan.sh 中
ls -t security-scan-*.log 2>/dev/null | tail -n +11 | xargs rm -f
# 将 11 改为你想保留的数量 +1
```

### 添加通知功能

在脚本末尾添加通知逻辑（如发送邮件、消息等）：
```bash
# 示例：发送完成通知
echo "✅ 安全扫描完成！版本：$NEW_VERSION" | mail -s "OpenClaw 安全周报" your@email.com
```

---

## 🚨 故障排除

### Cron 未执行

1. **检查 Cron 服务状态:**
```bash
sudo systemctl status cron  # Linux
sudo launchctl list | grep cron  # macOS
```

2. **检查 Cron 日志:**
```bash
# macOS
log show --predicate 'process == "cron"' --last 1h

# Linux
grep CRON /var/log/syslog | tail -20
```

3. **验证脚本权限:**
```bash
ls -l ~/.openclaw/workspace/scripts/security-weekly-scan.sh
# 应有 x 权限：-rwxr-xr-x
chmod +x ~/.openclaw/workspace/scripts/security-weekly-scan.sh
```

### 升级失败

1. **检查网络连接:**
```bash
ping npmjs.com
```

2. **手动执行升级:**
```bash
cd ~/Documents/trae_projects/202220/openclaw
npm install openclaw@latest
```

3. **检查 Gateway 状态:**
```bash
openclaw gateway status
```

### 报告未生成

检查脚本执行日志：
```bash
tail -50 ~/.openclaw/workspace/logs/security/cron-security.log
```

---

## 📈 扩展建议

### 1. 添加 GitHub API 检查

可以调用 GitHub API 获取最新的 Security Advisories：

```bash
# 在脚本中添加
curl -s "https://api.github.com/repos/openclaw/openclaw/security-advisories" \
  | jq '.[] | {id, severity, published_at}'
```

### 2. 添加通知渠道

- **邮件通知:** 使用 `mail` 命令
- **微信通知:** 调用企业微信机器人 webhook
- **钉钉通知:** 调用钉钉机器人 webhook
- **Telegram:** 调用 Telegram Bot API

### 3. 添加健康检查

在扫描后添加系统健康检查：
```bash
# 检查 Gateway 响应
curl -s http://127.0.0.1:18789/health

# 检查磁盘空间
df -h | grep -v tmpfs

# 检查内存使用
free -h
```

### 4. 添加回滚机制

如果升级失败，自动回滚到上一个版本：
```bash
# 备份当前版本
npm list openclaw --depth=0 > backup-version.txt

# 回滚命令
npm install openclaw@$(cat backup-version.txt | cut -d'@' -f2)
```

---

## 🔐 安全注意事项

1. **脚本权限:** 确保脚本只有所有者可写
2. **日志敏感信息:** 定期清理日志中的敏感数据
3. **Cron 安全:** 使用绝对路径，避免环境变量问题
4. **升级前备份:** 重要配置定期备份

---

## 📚 相关文档

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [GitHub Security Advisories](https://github.com/openclaw/openclaw/security/advisories)
- [npm audit 文档](https://docs.npmjs.com/cli/commands/npm-audit)
- [Cron 表达式生成器](https://crontab.guru/)

---

**维护者:** OpenClaw Agent  
**最后更新:** 2026-03-11 17:50 CST
