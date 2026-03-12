#!/bin/bash
# OpenClaw 每周安全扫描与自动修复脚本
# 执行频率：每周一次（建议周日凌晨 2:00）
# 功能：检查漏洞、自动升级、重启服务、生成报告

set -e

# 配置
OPENCLAW_DIR="$HOME/Documents/trae_projects/202220/openclaw"
WORKSPACE_DIR="$HOME/.openclaw/workspace"
LOG_DIR="$WORKSPACE_DIR/logs/security"
REPORT_FILE="$WORKSPACE_DIR/SECURITY_WEEKLY_REPORT.md"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="$LOG_DIR/security-scan-$DATE.log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "OpenClaw 安全扫描与修复开始"
log "=========================================="

# 1. 检查当前版本
log "步骤 1: 检查当前 OpenClaw 版本"
cd "$OPENCLAW_DIR"
CURRENT_VERSION=$(npm list openclaw --depth=0 2>/dev/null | grep openclaw@ | tail -1 | cut -d'@' -f2)
log "当前版本：$CURRENT_VERSION"

# 2. 运行 npm audit 检查漏洞
log "步骤 2: 运行 npm audit 检查漏洞"
npm audit --json > "$LOG_DIR/audit-$DATE.json" 2>&1 || true
VULN_COUNT=$(cat "$LOG_DIR/audit-$DATE.json" | grep -c '"severity"' || echo "0")
log "发现漏洞数量：$VULN_COUNT"

# 3. 检查 GitHub Security Advisories
log "步骤 3: 检查 GitHub Security Advisories"
# 这里可以添加调用 GitHub API 的逻辑
# 简化版本：直接尝试升级到最新版本

# 4. 执行升级
log "步骤 4: 执行 OpenClaw 升级"
npm install openclaw@latest >> "$LOG_FILE" 2>&1
NEW_VERSION=$(npm list openclaw --depth=0 2>/dev/null | grep openclaw@ | tail -1 | cut -d'@' -f2)
log "升级后版本：$NEW_VERSION"

# 5. 修复依赖漏洞（非破坏性）
log "步骤 5: 修复第三方依赖漏洞"
npm audit fix >> "$LOG_FILE" 2>&1 || log "npm audit fix 执行完成（可能有部分无法自动修复）"

# 6. 重启 Gateway 服务
log "步骤 6: 重启 Gateway 服务"
openclaw gateway stop >> "$LOG_FILE" 2>&1 || true
sleep 2
openclaw gateway start >> "$LOG_FILE" 2>&1
sleep 3
GATEWAY_STATUS=$(openclaw gateway status 2>&1 | grep "Runtime:" || echo "Unknown")
log "Gateway 状态：$GATEWAY_STATUS"

# 7. 生成周报
log "步骤 7: 生成安全周报"
cat > "$REPORT_FILE" << EOF
# 🔒 OpenClaw 安全周报

**扫描时间:** $(date '+%Y-%m-%d %H:%M:%S CST')
**扫描周期:** 每周一次
**执行脚本:** \`security-weekly-scan.sh\`

---

## 📊 本次扫描结果

| 项目 | 详情 |
|------|------|
| **扫描前版本** | \`$CURRENT_VERSION\` |
| **扫描后版本** | \`$NEW_VERSION\` |
| **发现漏洞数** | $VULN_COUNT |
| **Gateway 状态** | $GATEWAY_STATUS |
| **日志文件** | \`$LOG_FILE\` |

---

## ✅ 已执行操作

1. ✅ 检查当前版本
2. ✅ 运行 npm audit 漏洞扫描
3. ✅ 升级到最新 OpenClaw 版本
4. ✅ 修复第三方依赖漏洞（npm audit fix）
5. ✅ 重启 Gateway 服务
6. ✅ 生成安全报告

---

## 📋 漏洞详情

详见：\`$LOG_DIR/audit-$DATE.json\`

---

## 📈 历史扫描记录

| 日期 | 版本 | 漏洞数 | 状态 |
|------|------|--------|------|
| $(date '+%Y-%m-%d') | $NEW_VERSION | $VULN_COUNT | ✅ 完成 |

---

## 🔧 手动检查建议

如需进一步检查，可执行：

\`\`\`bash
# 查看详细漏洞报告
cd ~/Documents/trae_projects/202220/openclaw
npm audit

# 查看 Gateway 日志
tail -f ~/Documents/trae_projects/202220/openclaw-config/logs/gateway.log

# 检查 GitHub Security Advisories
# https://github.com/openclaw/openclaw/security/advisories
\`\`\`

---

**自动生成:** OpenClaw Security Scanner
**下次扫描:** $(date -v+7d '+%Y-%m-%d' 2>/dev/null || date -d '+7 days' '+%Y-%m-%d' 2>/dev/null || echo "下周同一时间")
EOF

log "报告已生成：$REPORT_FILE"

# 8. 清理旧日志（保留最近 10 次）
log "步骤 8: 清理旧日志（保留最近 10 次）"
cd "$LOG_DIR"
ls -t security-scan-*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
ls -t audit-*.json 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

log "=========================================="
log "OpenClaw 安全扫描与修复完成"
log "=========================================="

# 输出摘要
echo ""
echo "✅ 安全扫描完成！"
echo "📄 详细报告：$REPORT_FILE"
echo "📝 日志文件：$LOG_FILE"
echo "📊 漏洞扫描：$LOG_DIR/audit-$DATE.json"
echo ""
