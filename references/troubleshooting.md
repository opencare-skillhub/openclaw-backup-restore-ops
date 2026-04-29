# OpenClaw 故障排除指南

本指南针对 OpenClaw 运维过程中的常见故障提供诊断流程和解决方案。

---

## 快速诊断流程图

```
启动失败?
├─> 运行: openclaw doctor --fix
│   ├─ 报告配置错误 → 执行智能合并或手动修复 openclaw.json
│   ├─ 报告权限错误 → 修复 ~/.openclaw/ 和 ~/clawd/ 权限
│   └─ 报告依赖缺失 → 运行 openclaw doctor --fix --install-deps
│
├─> 仍失败?
│   └─> 查看日志: openclaw gateway logs
│       ├─ 端口占用 → kill 占用进程 或 修改配置 port
│       ├─ 内存不足 → 释放内存 或 增加 swap
│       └─ 其他错误 → 搜索错误关键词 + "OpenClaw"
│
└─> 所有方法无效?
    └─> 执行灾难恢复（按技能阶段三流程）
```

---

## 故障场景 1：备份失败

### 症状
```
[ERROR] Backup failed: insufficient disk space
[ERROR] Hash verification failed
[ERROR] openclaw: command not found
```

### 诊断步骤

**1.1 检查磁盘空间**
```bash
df -h ~/Documents/OpenClawBackups/
# 需要至少 2GB 可用空间（备份文件大小 × 2）
```

**解决方案**：
- 清理 `~/Documents/OpenClawBackups/` 中旧备份（30 天前）
- 清理 `~/.openclaw/` 中的临时文件
- 迁移备份到外置硬盘

**1.2 检查哈希失败**
```bash
# 手动验证备份文件
tar -tzf ~/Documents/OpenClawBackups/openclaw-backup-*.tar.gz > /dev/null
echo $?  # 应该返回 0
```

**解决方案**：
- 备份文件损坏 → 删除该文件，重新执行 `backup_and_verify.sh`
- 存储介质错误 → 检查磁盘健康度 `diskutil verifyVolume /` (macOS)

**1.3 找不到 openclaw 命令**
```bash
which openclaw
echo $PATH | tr ':' '\n' | grep openclaw
```

**解决方案**：
```bash
# 临时添加 PATH
export PATH="$HOME/.openclaw/bin:$PATH"

# 永久添加（添加到 ~/.zshrc）
echo 'export PATH="$HOME/.openclaw/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## 故障场景 2：升级后配置 Schema 不匹配

### 症状
```
[ERROR] Configuration schema validation failed
[ERROR] Unknown field "xxx" in openclaw.json
[ERROR] Missing required field "yyy"
```

### 诊断步骤

**2.1 查看具体错误**
```bash
openclaw doctor --verbose 2>&1 | grep -A 5 "schema\|validation"
```

**2.2 备份当前配置**
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d)
```

**2.3 执行智能合并**
```bash
# 假设新版本生成了默认配置
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.new-$(date +%Y%m%d)

# 使用脚本合并
python3 ~/.agents/skills/openclaw-backup-ops/scripts/smart_merge_config.py \
  --old ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d-%H%M%S) \
  --new ~/.openclaw/openclaw.json.new-$(date +%Y%m%d-%H%M%S) \
  --output ~/.openclaw/openclaw.json
```

**2.4 手动合并（如果脚本失败）**

使用文本编辑器对比：
```bash
# macOS
opendiff ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json.new

# Linux
meld ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json.new &
```

**手动合并规则**：
1. 保留所有自定义值（API keys、user preferences）
2. 新字段如果非必需 → 设为 null 或默认值
3. 删除已废弃字段 → 记录到 `deprecated_fields`
4. 保存前 JSON 格式化验证：`python -m json.tool ~/.openclaw/openclaw.json`

**2.5 最终验证**
```bash
openclaw doctor --fix
```

---

## 故障场景 3：灾难恢复后服务仍无法启动

### 症状
执行阶段三恢复后，`openclaw gateway status` 显示 `error` 或 `stopped`。

### 诊断步骤

**3.1 检查关键文件是否存在**
```bash
ls -la ~/.openclaw/openclaw.json
ls -la ~/.openclaw/SOUL.md
ls -la ~/.openclaw/MEMORY.md
```

**可能问题**：
- 文件权限错误 → `chmod 644 ~/.openclaw/*`
- 所有者错误 → `chown -R $(whoami) ~/.openclaw`

**3.2 检查日志**
```bash
openclaw gateway logs --tail 50
```

**常见日志关键词**：

| 错误信息 | 可能原因 | 解决方案 |
|---------|---------|---------|
| `permission denied` | 文件权限不足 | `chmod -R u+rw ~/.openclaw ~/clawd` |
| `port 3000 already in use` | 端口冲突 | `lsof -ti:3000 \| xargs kill -9` |
| `module not found` | 依赖缺失 | `openclaw doctor --fix --install-deps` |
| `JSON parse error` | 配置文件语法错误 | `python -m json.tool ~/.openclaw/openclaw.json` |
| `memory allocation failed` | 内存不足 | 释放内存或增加 swap |

**3.3 验证还原完整性**
```bash
# 检查是否所有关键文件都在
tar -tzf ~/Documents/OpenClawBackups/your-backup.tar.gz | grep -E "(openclaw.json|SOUL.md|MEMORY.md)" | wc -l
# 应该输出 3
```

**可能问题**：
- 备份文件本身损坏 → 尝试其他备份
- 还原时未使用 `-C /` → 文件路径错位，需重新按正确方式还原

**3.4 尝试安全模式启动**
```bash
# 某些 OpenClaw 版本支持安全模式（忽略配置错误）
openclaw gateway start --safe-mode
```

---

## 故障场景 4：记忆丢失或技能失效

### 症状
- `openclaw sessions list` 为空
- `openclaw skills list` 不显示自定义技能
- 助手人格与之前不一致

### 诊断步骤

**4.1 检查记忆文件**
```bash
cat ~/.openclaw/MEMORY.md | head -20
ls -la ~/.openclaw/agents/
```

**4.2 检查技能目录**
```bash
ls -la ~/.agents/skills/
# 应该看到自定义技能文件夹
```

**4.3 对比备份包内容**
```bash
tar -tzf ~/Documents/OpenClawBackups/your-backup.tar.gz | grep -E "(MEMORY.md|agents/|\.agents/skills/)" | head
```

**可能问题**：
1. **还原不完整**：某些目录未还原
   - 解决：重新执行 `tar -xzvf backup.tar.gz -C /`，加上 `--overwrite` 参数

2. **权限问题**：
   ```bash
   chmod -R u+rw ~/.openclaw ~/.agents
   ```

3. **缓存问题**（OpenClaw 可能缓存记忆）：
   ```bash
   openclaw cache clear
   openclaw gateway restart
   ```

---

## 故障场景 5：无法连接到网关

### 症状
```
Error: connection refused
Error: gateway not responding
```

### 诊断步骤

**5.1 检查网关进程**
```bash
ps aux | grep openclaw | grep -v grep
```

**无输出**：服务未启动 → 尝试 `openclaw gateway start`

**有输出但端口不通**：
```bash
# 检查端口监听
lsof -i :3000  # 默认端口 3000，查看 openclaw config get gateway.port 确认
```

**5.2 检查防火墙**
```bash
# macOS
pfctl -s all | grep 3000

# Linux
sudo iptables -L | grep 3000
```

**5.3 检查配置文件端口**
```bash
openclaw config get gateway.port
```

---

## 高级恢复：当备份文件也损坏

### 场景
- 备份文件本身 tar 解压失败
- 哈希校验不通过
- 多个备份均损坏

### 解决方案

**方案 A：使用增量恢复（如果有多个备份）**
```bash
# 找到最近一个健康的备份
ls -lt ~/Documents/OpenClawBackups/
# 找到最新的 Backup complete 日志对应的备份
```

**方案 B：仅恢复关键文件（手动提取）**
```bash
# 创建临时目录
mkdir /tmp/openclaw-recovery
cd /tmp/openclaw-recovery

# 尝试从损坏备份中提取关键文件
tar -xzvf /path/to/damaged-backup.tar.gz --warning=no-timestamp \
  ~/.openclaw/openclaw.json \
  ~/.openclaw/SOUL.md \
  ~/.openclaw/MEMORY.md 2>/dev/null || true

# 手动复制回原位
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.recovered-$(date +%s)
# 手动检查内容是否完整
```

**方案 C：从 ~/.openclawbroken-* 恢复**
如果执行了阶段三但还原失败，受损现场被重命名为 `~/.openclawbroken-*`：
```bash
# 查看可用的备份
ls -ld ~/.openclawbroken-*

# 恢复最近的一个
cp -r ~/.openclawbroken-20260421-100000 ~/.openclaw
chmod -R u+rw ~/.openclaw
openclaw doctor --fix
openclaw gateway start
```

---

## 权限问题专项

### 症状
```
[ERROR] Cannot write to ~/.openclaw/
[ERROR] Permission denied
```

### 修复命令
```bash
# 修复目录所有权（假设用户为 sam）
sudo chown -R sam:staff ~/.openclaw ~/clawd ~/.agents

# 修复权限（目录 755，文件 644）
find ~/.openclaw -type d -exec chmod 755 {} \;
find ~/.openclaw -type f -exec chmod 644 {} \;
chmod 600 ~/.openclaw/openclaw.json  # 敏感配置私密

# 修复技能目录
find ~/.agents/skills -type d -exec chmod 755 {} \;
find ~/.agents/skills -type f -exec chmod 644 {} \;
```

---

## 环境变量问题

### 常见问题
- `OPENCLAW_HOME` 未设置 → 默认使用 `~/.openclaw`
- `PATH` 不包含 `openclaw` 可执行文件路径

### 检查与修复
```bash
echo $OPENCLAW_HOME
which openclaw

# 修复（添加到 ~/.zshrc）
echo 'export OPENCLAW_HOME="$HOME/.openclaw"' >> ~/.zshrc
echo 'export PATH="$OPENCLAW_HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## 日志位置

OpenClaw 日志通常位于：
```bash
~/.openclaw/logs/gateway.log          # 网关日志
~/.openclaw/logs/agent.log            # 代理日志
~/clawd/logs/                          # 工作区日志（如有）
```

使用 `journalctl`（Linux）或 `log show`（macOS）查看系统日志：
```bash
# macOS
log show --predicate 'process == "openclaw"' --last 1h

# Linux（systemd）
journalctl -u openclaw.service -n 50
```

---

## 联系支持

如果所有方法均无效：

1. 收集诊断信息：
   ```bash
   openclaw doctor --json > ~/openclaw-diag.json
   openclaw gateway logs --tail 100 > ~/openclaw-logs.txt
   tar -czf ~/openclaw-support-$(date +%Y%m%d).tar.gz \
     ~/openclaw-diag.json ~/openclaw-logs.txt ~/.openclaw/openclaw.json
   ```

2. 提交 Issue：
   - OpenClaw GitHub Issues
   - 附上 `openclaw-support-*.tar.gz`（注意脱敏敏感信息）

---

**最后手段**：执行完整灾难恢复（阶段三），从最近健康备份还原。
