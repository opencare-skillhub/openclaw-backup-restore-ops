#!/bin/bash
#
# OpenClaw 全量备份与验证脚本
# 用途：执行强制性全量备份，自动校验关键文件完整性
# 使用：./backup_and_verify.sh [output_dir]（可选，默认 ~/Documents/OpenClawBackups/）
# 返回：成功返回 0，失败返回非 0
#

set -e  # 任何命令失败立即退出

# ============ 配置区 ============
BACKUP_DIR="${1:-$HOME/Documents/OpenClawBackups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="openclaw-backup-${TIMESTAMP}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# 关键文件清单（必须存在于备份中）
REQUIRED_FILES=(
  ".openclaw/openclaw.json"
  ".openclaw/SOUL.md"
  ".openclaw/MEMORY.md"
  ".openclaw/agents/"
  ".agents/skills/"
  "clawd/"
)

# ============ 工具函数 ============
log_info() {
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

log_success() {
  echo "[✅ OK] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# ============ 前置检查 ============
log_info "========== OpenClaw 备份验证开始 =========="

# 检查备份目录
if [[ ! -d "$BACKUP_DIR" ]]; then
  log_info "创建备份目录: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
fi

# 检查磁盘空间（至少需要 2GB 可用）
AVAIL_SPACE=$(df -k "$BACKUP_DIR" | tail -1 | awk '{print $4}')
REQUIRED_SPACE=2097152  # 2GB in KB
if [[ "$AVAIL_SPACE" -lt "$REQUIRED_SPACE" ]]; then
  log_error "磁盘空间不足（可用 ${AVAIL_SPACE}KB，需要 2GB 以上）"
  exit 1
fi

# 检查 openclaw 命令
if ! command -v openclaw &> /dev/null; then
  log_error "未找到 openclaw 命令，请检查 PATH 配置"
  exit 1
fi

# ============ 阶段一：执行备份 ============
log_info "阶段一：执行全量备份（带验证）"

if ! openclaw backup create --verify --output "$BACKUP_DIR"; then
  log_error "openclaw backup 命令执行失败"
  exit 1
fi

# 查找刚生成的备份文件
BACKUP_PATH=$(ls -t "${BACKUP_DIR}/${BACKUP_NAME}".tar.gz 2>/dev/null | head -1)
if [[ -z "$BACKUP_PATH" ]]; then
  log_error "备份文件未找到于 $BACKUP_DIR"
  exit 1
fi

log_success "备份文件已生成: $(basename "$BACKUP_PATH")"
log_info "文件大小: $(du -h "$BACKUP_PATH" | cut -f1)"

# ============ 阶段二：清单验证 ============
log_info "阶段二：验证备份完整性"

# 检查是否包含 Backup complete 标记
if ! tar -tzf "$BACKUP_PATH" &>/dev/null; then
  log_error "备份文件损坏或格式错误"
  exit 1
fi

# 验证关键文件是否存在
MISSING_FILES=()
for req in "${REQUIRED_FILES[@]}"; do
  if ! tar -tzf "$BACKUP_PATH" "$req" &>/dev/null; then
    MISSING_FILES+=("$req")
  fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  log_error "以下关键文件缺失："
  for f in "${MISSING_FILES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

log_success "所有关键文件校验通过："
for req in "${REQUIRED_FILES[@]}"; do
  echo "  ✅ $req"
done

# ============ 阶段三：哈希校验（如果备份支持） ============
log_info "阶段三：验证备份哈希（如果可用）"

# 尝试从备份包内读取校验信息（某些 openclaw 版本会生成 .sha256 文件）
if tar -tzf "$BACKUP_PATH" | grep -q '\.sha256$'; then
  log_info "检测到哈希清单文件，执行验证..."

  # 提取校验文件到临时目录
  TMP_DIR=$(mktemp -d)
  tar -xzf "$BACKUP_PATH" -C "$TMP_DIR" .*.sha256 2>/dev/null || true

  if [[ -n "$(find "$TMP_DIR" -name "*.sha256" 2>/dev/null)" ]]; then
    cd "$TMP_DIR"
    if sha256sum -c *.sha256 2>/dev/null | grep -q "FAILED"; then
      log_error "哈希校验失败！备份文件可能已损坏"
      rm -rf "$TMP_DIR"
      exit 1
    else
      log_success "哈希校验通过"
    fi
    rm -rf "$TMP_DIR"
  else
    log_info "未找到哈希文件，跳过哈希校验"
  fi
else
  log_info "当前备份版本未生成哈希清单，跳过哈希校验"
fi

# ============ 完成报告 ============
log_success "========== 备份验证全部通过 =========="
log_info "备份文件位置: $BACKUP_PATH"
log_info "请妥善保存此文件，建议上传至安全存储"

exit 0
