#!/bin/bash
#
# OpenClaw 灾难恢复一键脚本
# 用途：当升级失败或系统损坏时，从备份文件恢复到健康状态
# ⚠️  高危操作，会自动停止服务、重命名现有目录、执行绝对路径还原
#
# 使用前必须确认：
#   [1] 已联系用户确认要恢复
#   [2] 已备份当前受损现场（本脚本会自动重命名）
#   [3] 备份文件已验证哈希通过
#
# 用法：./disaster_recovery.sh <backup_file.tar.gz>
# 示例：./disaster_recovery.sh ~/Documents/OpenClawBackups/openclaw-backup-20260421-083000.tar.gz
#

set -e  # 遇到错误立即退出（但部分步骤需要允许失败，后续会临时关闭）

# ============ 配置区 ============
BACKUP_FILE="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]$(date '+%Y-%m-%d %H:%M:%S')${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]$(date '+%Y-%m-%d %H:%M:%S')${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]$(date '+%Y-%m-%d %H:%M:%S')${NC} $1"
}

log_critical() {
  echo -e "${RED}[CRITICAL]$(date '+%Y-%m-%d %H:%M:%S')${NC} $1" >&2
}

# ============ 前置检查 ============
log_info "========== OpenClaw 灾难恢复开始 (V2.0 加固版) =========="

# 检查参数
if [[ -z "$BACKUP_FILE" ]]; then
  log_error "用法: $0 <backup_file.tar.gz>"
  log_error "示例: $0 ~/Documents/OpenClawBackups/openclaw-backup-20260421-083000.tar.gz"
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  log_error "备份文件不存在: $BACKUP_FILE"
  exit 1
fi

# 确认操作（二次确认，高危）
echo ""
log_critical "⚠️  警告：此操作将执行以下动作："
echo "  1. 停止 OpenClaw 网关服务"
echo "  2. 将当前 ~/.openclaw 重命名为 ~/.openclawbroken-${TIMESTAMP}"
echo "  3. 将当前 ~/clawd 重命名为 ~/clawdbroken-${TIMESTAMP}"
echo "  4. 从备份文件绝对路径还原至根目录 (tar -xzvf ... -C /)"
echo "  5. 重启服务并验证"
echo ""
read -p "是否继续？(yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  log_info "操作已取消"
  exit 0
fi

# ============ 阶段一：停止冲突进程 ============
log_info "阶段一：停止 OpenClaw 服务"

if command -v openclaw &>/dev/null; then
  log_info "尝试 graceful shutdown..."
  openclaw gateway stop || true
  sleep 3
fi

# 强制终止残留进程
if pgrep -f "openclaw" &>/dev/null; then
  log_warn "检测到残留进程，强制终止..."
  pkill -9 -f openclaw || true
  sleep 2
fi

log_success "服务已停止"

# ============ 阶段二：隔离受损现场 ============
log_info "阶段二：隔离受损现场（保留证据）"

BACKUP_SUFFIX="${TIMESTAMP}"

# 重命名配置目录
if [[ -d "$HOME/.openclaw" ]]; then
  mv "$HOME/.openclaw" "${HOME}/.openclawbroken-${BACKUP_SUFFIX}"
  log_success "已隔离: ~/.openclaw → ~/.openclawbroken-${BACKUP_SUFFIX}"
else
  log_warn "未找到 ~/.openclaw 目录，跳过"
fi

# 重命名工作区
if [[ -d "$HOME/clawd" ]]; then
  mv "$HOME/clawd" "${HOME}/clawdbroken-${BACKUP_SUFFIX}"
  log_success "已隔离: ~/clawd → ~/clawdbroken-${BACKUP_SUFFIX}"
else
  log_warn "未找到 ~/clawd 目录，跳过"
fi

# ============ 阶段三：绝对路径还原（核心步骤） ============
log_info "阶段三：执行绝对路径还原（生死命门 -C /）"

log_info "备份文件: $BACKUP_FILE"
log_info "解压目标: 系统根目录 (/)"

# 验证备份文件可读
if ! tar -tzf "$BACKUP_FILE" &>/dev/null; then
  log_error "备份文件损坏或不是有效的 tar.gz 归档"
  exit 1
fi

# 关键步骤：-C / 必须放在最后
log_warn "即将执行：tar -xzvf $BACKUP_FILE -C /"
read -p "最后一次确认？(yes/no): " FINAL_CONFIRM
if [[ "$FINAL_CONFIRM" != "yes" ]]; then
  log_error "操作取消。注意：当前已进入恢复流程，目录已被重命名。"
  log_error "如需手动处理，请检查 ~/.openclawbroken-* 和 ~/clawdbroken-* 目录"
  exit 1
fi

log_info "开始还原..."
if ! tar -xzvf "$BACKUP_FILE" -C /; then
  log_error "tar 还原失败！请检查错误信息"
  log_error "可能原因：权限不足（需要 sudo？）或备份文件损坏"
  exit 1
fi

log_success "还原完成"

# ============ 阶段四：重新初始化验证 ============
log_info "阶段四：重新初始化与健康诊断"

# 等待文件系统稳定
sleep 2

# 检查关键文件是否还原
CRITICAL_FILES=(
  "$HOME/.openclaw/openclaw.json"
  "$HOME/.openclaw/SOUL.md"
  "$HOME/.openclaw/MEMORY.md"
)

log_info "验证关键文件..."
for f in "${CRITICAL_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    log_success "✅ 存在: $f"
  else
    log_error "❌ 缺失: $f"
    exit 1
  fi
done

# 运行健康诊断
if command -v openclaw &>/dev/null; then
  log_info "执行 openclaw doctor --fix ..."
  if ! openclaw doctor --fix; then
    log_error "健康诊断发现未修复问题"
    exit 1
  fi
  log_success "健康诊断通过"
else
  log_warn "未找到 openclaw 命令，跳过健康诊断（请手动检查）"
fi

# ============ 阶段五：重启与验证 ============
log_info "阶段五：重启网关服务"

if command -v openclaw &>/dev/null; then
  openclaw gateway start || true
  sleep 8  # 等待服务就绪

  # 检查状态
  if openclaw gateway status 2>/dev/null | grep -qi "active\|running"; then
    log_success "网关状态: active/running ✅"
  else
    log_error "网关状态异常，请手动检查: openclaw gateway status"
    exit 1
  fi
else
  log_warn "未找到 openclaw 命令，请手动启动网关"
fi

# ============ 完成报告 ============
echo ""
echo "=========================================="
echo -e "${GREEN}✅ 灾难恢复完成！${NC}"
echo "=========================================="
echo ""
echo "恢复摘要："
echo "  备份文件: $BACKUP_FILE"
echo "  隔离目录:"
echo "    ~/.openclawbroken-${BACKUP_SUFFIX}"
echo "    ~/clawdbroken-${BACKUP_SUFFIX}"
echo ""
echo "验证建议："
echo "  1. 检查记忆连续性: openclaw sessions list"
echo "  2. 验证身份一致性: cat ~/.openclaw/SOUL.md"
echo "  3. 测试基本对话功能"
echo ""
echo "⚠️  如果功能异常，请检查："
echo "  - 是否有权限问题（chmod 修复）"
echo "  - 是否需重启机器（部分库文件加载缓存）"
echo "=========================================="

exit 0
