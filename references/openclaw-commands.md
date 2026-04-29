# OpenClaw 核心命令参考

本文档汇总 OpenClaw 运维操作中使用的核心命令。

## 备份相关

### `openclaw backup create`
创建全量备份。

**常用参数**：
```bash
openclaw backup create                    # 默认输出到 ~/.openclaw/backups/
openclaw backup create --output /path     # 指定输出目录
openclaw backup create --verify           # 备份后自动校验
openclaw backup create --verify --output ~/Documents/OpenClawBackups/
```

**输出示例**：
```
Backup complete: openclaw-backup-20260421-083000.tar.gz
Hash: sha256:abc123...
Size: 245.6 MB
```

### `openclaw backup list`
列出所有可用备份。

### `openclaw backup restore <file>`
从备份文件恢复（**不推荐直接使用**，建议按技能中的阶段三手动操作以确保安全）。

---

## 版本管理

### `openclaw update`
更新 OpenClaw 到最新版本。

**参数**：
```bash
openclaw update                    # 默认稳定版
openclaw update --channel beta     # 测试版
openclaw update --channel nightly  # 每晚构建版
openclaw update --version v0.9.5   # 指定版本
```

### `openclaw version`
查看当前版本。

---

## 健康诊断

### `openclaw doctor`
运行系统自检。

```bash
openclaw doctor                    # 仅检查，不修改
openclaw doctor --fix              # 自动修复发现的问题
```

**检查项**：
- 配置文件语法（JSON Schema 验证）
- 依赖项完整性
- 目录权限（~/.openclaw/, ~/clawd/）
- 端口占用（默认 3000）
- 环境变量配置

### `openclaw doctor --export`
导出诊断报告为 JSON。

---

## 网关服务管理

### `openclaw gateway`
网关控制命令集合。

```bash
openclaw gateway status            # 查看状态
openclaw gateway start             # 启动
openclaw gateway stop              # 优雅关闭
openclaw gateway restart           # 重启
openclaw gateway logs              # 查看实时日志
openclaw gateway logs --file       # 输出到日志文件
```

**状态值**：
- `active` / `running` - 正常运行
- `stopped` / `inactive` - 已停止
- `error` - 运行异常（需查看日志）

---

## 配置管理

### `openclaw config show`
显示当前配置（JSON 格式）。

### `openclaw config get <key>`
读取特定配置项，支持点号分隔路径：
```bash
openclaw config get gateway.port
openclaw config get memory.max_sessions
```

### `openclaw config set <key> <value>`
修改配置（**会直接写入 openclaw.json，谨慎使用**）。
建议先备份，再用文本编辑器修改。

---

## 会话与记忆

### `openclaw sessions list`
列出历史会话 ID。

### `openclaw sessions show <session_id>`
查看特定会话内容。

### `openclaw sessions export <session_id>`
导出会话为 JSON/Markdown。

### `openclaw memory export`
导出所有长期记忆（MEMORY.md 及关联文件）。

---

## 技能管理

### `openclaw skills list`
列出已安装技能。

### `openclaw skills info <skill_name>`
查看技能详情（描述、版本、依赖）。

### `openclaw skills disable <skill_name>`
临时禁用技能（不移除）。

### `openclaw skills enable <skill_name>`
重新启用技能。

---

## 系统信息

### `openclaw env`
显示环境信息：
- OpenClaw 版本
- 安装路径
- 运行模式（本地/远程）
- 依赖库版本

### `openclaw doctor --json`
输出机器可读的诊断结果（用于自动化脚本）。

---

## 高级操作

### 手动备份（不使用 openclaw 命令）
```bash
# 压缩核心目录
tar -czf ~/Documents/OpenClawBackups/manual-backup-$(date +%Y%m%d).tar.gz \
  ~/.openclaw/openclaw.json \
  ~/.openclaw/SOUL.md \
  ~/.openclaw/MEMORY.md \
  ~/.openclaw/agents/ \
  ~/.agents/skills/ \
  ~/clawd/

# 验证归档
tar -tzf ~/Documents/OpenClawBackups/manual-backup-*.tar.gz | head
```

### 手动恢复（绝对路径还原）
```bash
# 停止服务
openclaw gateway stop
pkill -f openclaw

# 隔离现场
mv ~/.openclaw ~/.openclawbroken
mv ~/clawd ~/clawdbroken

# 绝对路径还原（关键）
tar -xzvf backup.tar.gz -C /

# 重启
openclaw doctor --fix
openclaw gateway start
```

---

## 故障排查速查

| 问题 | 命令 | 预期输出 |
|------|------|----------|
| 服务无法启动 | `openclaw gateway status` | 显示 `error` |
| 查看详细错误 | `openclaw gateway logs` | 显示堆栈跟踪 |
| 配置错误 | `openclaw doctor` | 标记出错的配置项 |
| 端口占用 | `lsof -i :3000` | 显示占用进程 |
| 权限问题 | `ls -la ~/.openclaw/` | 检查 owner/group |

---

## 命令别名建议（添加到 ~/.zshrc 或 ~/.bashrc）

```bash
# OpenClaw 快捷命令
alias oc='openclaw'
alias oc-status='openclaw gateway status'
alias oc-logs='openclaw gateway logs -f'
alias oc-backup='openclaw backup create --verify --output ~/Documents/OpenClawBackups/'
alias oc-doctor='openclaw doctor --fix'
alias oc-restart='openclaw gateway restart'
```

---

**参考**：本命令表基于 OpenClaw v0.9.0+ 编写，不同版本可能存在差异。
