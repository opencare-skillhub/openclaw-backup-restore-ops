---
name: openclaw-backup-ops
description: OpenClaw 系统全生命周期运维操作（备份/升级/恢复）。当用户需要进行 OpenClaw 版本升级、环境迁移、系统灾难恢复，或要求"零记忆丢失"的安全操作时，自动使用此技能。本技能强制执行三阶段协议：1) 备份验证（必须通过才能继续）、2) 版本升级（含配置智能合并）、3) 灾难恢复（含绝对路径还原逻辑），确保 100% 数据安全，适合新手操作。
---

# OpenClaw 系统运维技能 (V2.0 加固版)

> **核心承诺**：零记忆丢失、零配置受损。任何升级/迁移操作前，必须完成强制性全量备份并通过哈希校验。

## 技能触发条件

**必须使用此技能的情况**：
- 用户提到 "OpenClaw 升级"、"openclaw update"、"版本更新"
- 用户要求 "备份 OpenClaw"、"恢复 OpenClaw"、"数据迁移"
- 用户说 "确保数据安全"、"零丢失"、"灾难恢复"
- 任何涉及 `~/.openclaw/`、`~/clawd/`、`~/.agents/skills/` 目录的操作
- 新手请求 OpenClaw 运维帮助

**不要使用的情况**：
- 仅查询 OpenClaw 版本信息（用普通对话即可）
- 单纯的技能使用问题（使用对应技能即可）

---

## 三阶段执行协议

### 📋 阶段一：强制性全量备份 (Pre-flight)

**⚠️ 红线规则**：若备份校验未通过，**严禁**进入阶段二。

#### 1.1 执行备份命令

```bash
# 创建备份目录（如果不存在）
mkdir -p ~/Documents/OpenClawBackups/

# 执行全量备份（带验证）
openclaw backup create --verify --output ~/Documents/OpenClawBackups/
```

#### 1.2 备份清单验证（必须逐项确认）

检查输出日志中是否包含：
- ✅ `Backup complete` - 备份流程结束标记
- ✅ `哈希校验通过` 或类似哈希验证成功信息
- ✅ 备份归档文件已生成（默认命名格式：`openclaw-backup-YYYYMMDD-HHMMSS.tar.gz`）

#### 1.3 核心文件核对

备份归档必须包含以下关键内容：
- `openclaw.json` - 核心配置文件
- `SOUL.md` - 助手人格定义（**极其重要**）
- `MEMORY.md` - 长期记忆资产
- `agents/` - 智能体目录（记忆资产）
- `.agents/skills/` - 自定义技能目录（如有）
- `clawd/` - 主工作区（如有）

**验证方法**：
```bash
tar -tzvf ~/Documents/OpenClawBackups/openclaw-backup-*.tar.gz | grep -E "(openclaw.json|SOUL.md|MEMORY.md|agents/|\.agents/skills/)"
```

**如果验证失败**：立即停止操作，向用户报告备份异常，**不得**继续。

---

### 🔄 阶段二：版本平滑升级 (Execution)

**前提条件**：阶段一备份校验**全部通过**。

#### 2.1 运行更新

```bash
openclaw update --channel stable
```

#### 2.2 健康诊断

升级完成后**立即**执行：
```bash
openclaw doctor --fix
```

修复所有检测到的配置问题、依赖缺失、权限异常。

#### 2.3 配置冲突处理（极其关键）

**场景**：`openclaw doctor` 提示配置 Schema 变更或版本不兼容。

**正确处理流程**：
1. **禁止直接覆盖**旧版 `openclaw.json`
2. 读取旧配置：`cat ~/.openclaw/openclaw.json`
3. **智能合并策略**：
   - 新增字段 → 填充默认值或根据旧配置推断
   - 变更字段 → 保留旧值并适配新 Schema 结构
   - 废弃字段 → 移至 `deprecated_fields` 备用区，不删除
4. 写入新配置前，**先备份当前配置**：
   ```bash
   cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d-%H%M%S)
   ```
5. 保存合并后的配置并验证 JSON 格式
6. 再次运行 `openclaw doctor --fix` 确认无错误

---

### 🚨 阶段三：灾难恢复逻辑 (Disaster Recovery)

**使用场景**：
- 升级失败、配置损坏、服务无法启动
- 数据异常、记忆丢失、技能失效
- 任何需要回滚到备份时刻的状态

#### 3.1 停止冲突进程

```bash
# 方式1：通过 openclaw 命令
openclaw gateway stop

# 方式2：强制终止（如果方式1失败）
pkill -f openclaw
```

#### 3.2 隔离受损现场（**关键步骤，防止二次破坏**）

```bash
# 重命名配置目录
mv ~/.openclaw ~/.openclawbroken-$(date +%Y%m%d-%H%M%S)

# 重命名工作区
mv ~/clawd ~/clawdbroken-$(date +%Y%m%d-%H%M%S)
```

**目的**：保留受损现场供后续分析，同时释放原有路径供还原操作使用。

#### 3.3 绝对路径还原（**生死命门**）

**⚠️ 严禁警告**：
- **禁止**：`tar -xzvf backup.tar.gz`（相对路径解压会错位）
- **禁止**：`tar -xzvf backup.tar.gz -C ~/`（tilde 不会被 shell 展开到 home）
- **禁止**：手动复制文件（路径易错，风险极高）

**✅ 正确操作**：
```bash
# 进入备份文件所在目录
cd ~/Documents/OpenClawBackups/

# 绝对路径解压至根目录（-C / 是核心）
tar -xzvf openclaw-backup-YYYYMMDD-HHMMSS.tar.gz -C /

# 验证还原结果
ls -la ~/.openclaw/openclaw.json
ls -la ~/clawd/
```

**为什么必须用 `-C /`**：
- 备份包内文件存储的是**绝对路径**（如 `/Users/username/.openclaw/...`）
- 使用 `-C /` 让 tar 将文件释放到系统根目录，路径自动匹配
- 如果省略 `-C /`，文件会解压到当前目录，路径结构被破坏，还原失败

#### 3.4 重新初始化与验证

```bash
# 运行健康诊断
openclaw doctor --fix

# 重启网关
openclaw gateway start

# 等待服务就绪（约 5-10 秒）
sleep 8

# 验证网关状态
openclaw gateway status
```

**期望输出**：`active` 或 `running`

---

## ✅ 交付标准与验证清单

### 网关状态验证
```bash
openclaw gateway status
```
**预期结果**：`active` 或 `running`

### 记忆连续性验证
```bash
openclaw sessions list
```
**预期结果**：可查询到历史对话记录（即使部分会话为空，记录结构必须存在）

### 身份一致性验证
```bash
cat ~/.openclaw/SOUL.md
```
**预期结果**：助手人格定义与备份时刻一致（对比备份包内的 SOUL.md 文件）

### 核心功能验证（可选但建议）
- 运行一次简单对话，确认助手正常响应
- 检查自定义技能目录是否完整：`ls ~/.agents/skills/`

---

## 🔴 绝对红线（任何情况不得违反）

| 红线序号 | 内容 | 后果 |
|---------|------|------|
| 1 | 备份校验未通过时进入升级阶段 | **可能导致数据永久丢失** |
| 2 | 升级时直接覆盖旧配置文件（未做智能合并） | **配置 Schema 不匹配导致服务无法启动** |
| 3 | 恢复时未使用 `-C /` 参数 | **绝对路径还原失败，文件错位，系统瘫痪** |
| 4 | 恢复时未先隔离受损现场 | **新旧文件混杂，无法追溯故障原因** |
| 5 | 跳过 `openclaw doctor --fix` 步骤 | **隐性错误累积，后续必爆发** |

**任何违反红线操作，必须立即终止并报告用户。**

---

## 📁 备份文件管理策略

### 自动命名规则
备份文件生成于 `~/Documents/OpenClawBackups/`，命名格式：
```
openclaw-backup-YYYYMMDD-HHMMSS.tar.gz
# 示例：openclaw-backup-20260421-083000.tar.gz
```

### 保留策略（建议）
- **最近 7 天**：每日备份，全部保留
- **第 8-30 天**：保留每周日备份
- **30 天以上**：仅保留每月 1 号备份

清理命令示例：
```bash
# 删除 30 天前的备份（除每月 1 号外）
find ~/Documents/OpenClawBackups/ -name "*.tar.gz" -mtime +30 \
  -not -name "*01-*.tar.gz" -delete
```

---

## 🆘 故障处理速查表

| 症状 | 可能原因 | 诊断命令 | 解决方案 |
|------|---------|----------|----------|
| `openclaw: command not found` | PATH 未配置 | `which openclaw` | 重新安装 OpenClaw 或添加 PATH |
| 备份失败 | 磁盘空间不足 | `df -h ~` | 清理空间后重试 |
| 哈希校验失败 | 备份文件损坏 | `tar -tzvf <backup>` | 删除损坏备份，重新执行阶段一 |
| 升级后服务无法启动 | 配置 Schema 不匹配 | `openclaw doctor --fix` | 执行配置智能合并（2.3 节） |
| 恢复后文件未归位 | 未使用 `-C /` | `ls ~/.openclaw/` | 删除错位文件，**严格按 3.3 节重做** |

---

## 🛠️ 辅助脚本说明

本技能配套提供以下辅助脚本（位于 `scripts/` 目录）：

### `scripts/backup_and_verify.sh`
执行全量备份并自动校验关键文件。
**用法**：`scripts/backup_and_verify.sh [output_dir]`

### `scripts/smart_merge_config.py`
当配置 Schema 变更时，智能合并新旧配置文件。
**用法**：`python scripts/smart_merge_config.py --old <old.json> --new <new.json> --output <merged.json>`

### `scripts/disaster_recovery.sh`
一键灾难恢复脚本，自动执行隔离、绝对路径还原、重启全流程。
**用法**：`scripts/disaster_recovery.sh <backup_file>`
**⚠️ 注意**：此脚本会自动停止服务、重命名现有目录，使用前需二次确认。

---

## 📖 使用示例

### 场景 1：新手首次升级 OpenClaw

**用户输入**：
```
我想升级 OpenClaw 到最新版，但担心数据丢失，请帮我安全升级。
```

**助手执行流程**：
1. 读取本技能，确认属于"版本升级"场景
2. 进入阶段一：执行备份 → 校验 → 汇报结果
3. 备份通过后，进入阶段二：执行 `openclaw update --channel stable`
4. 运行 `openclaw doctor --fix`，处理任何配置警告
5. 验证服务状态，交付成功报告

---

### 场景 2：升级失败，需要回滚

**用户输入**：
```
升级后 OpenClaw 无法启动，请恢复到升级前的状态。
```

**助手执行流程**：
1. 确认属于"灾难恢复"场景
2. 询问用户最后一次成功备份的时间点（或自动查找最新备份）
3. **严格按阶段三执行**：停止服务 → 隔离现场 → 绝对路径还原 → 重启验证
4. 汇报恢复结果，包括记忆连续性和身份一致性验证

---

### 场景 3：迁移环境到新机器

**用户输入**：
```
我要把 OpenClaw 从旧电脑迁移到新电脑，怎么保证数据完整？
```

**助手执行流程**：
1. 在旧机器执行阶段一（备份 + 验证 + 拷贝备份文件到新机器）
2. 在新机器安装 OpenClaw 基础版本
3. 在新机器执行阶段三的 3.2-3.4 步（还原 + 重启）
4. 跨机器验证身份一致性和记忆完整性

---

## 🔄 与相关技能的边界

| 技能名称 | 与本技能的关系 |
|---------|---------------|
| `openclaw-gateway-manager` | 本技能调用 `openclaw gateway start/stop/status` 命令完成操作 |
| `openclaw-config-editor` | 当需要修改 `openclaw.json` 时，可能调用该技能进行安全编辑 |
| `file-backup-utility` | 本技能不处理通用文件备份，专注 OpenClaw 生态特定路径 |
| `system-recovery-toolkit` | 本技能是系统恢复 toolkit 的子集，专精 OpenClaw 场景 |

---

## 📋 快速检查清单（操作前必读）

- [ ] 已确认 `openclaw` 命令在 PATH 中可用
- [ ] 已确认 `~/Documents/OpenClawBackups/` 目录可写
- [ ] 已确认磁盘剩余空间 > 备份文件预期大小的 2 倍
- [ ] 已告知用户本次操作的风险与回滚方案
- [ ] **阶段一完成后**：已确认 `Backup complete` 和哈希校验通过
- [ ] **阶段二配置合并时**：已备份旧配置文件为 `*.bak-*` 格式
- [ ] **阶段三恢复前**：已获得用户二次确认（因会重命名现有目录）

---

## 🎯 技能输出格式

执行完成后，助手必须提供结构化报告：

```markdown
## OpenClaw 运维操作报告

**操作类型**：版本升级 / 灾难恢复 / 环境迁移  
**执行时间**：YYYY-MM-DD HH:MM:SS  
**耗时**：X 分 X 秒  

### 阶段一：备份验证
- 备份文件：`openclaw-backup-20260421-083000.tar.gz`
- 文件大小：XXX MB
- 哈希校验：✅ 通过
- 核心文件完整性：✅ 通过（openclaw.json, SOUL.md, MEMORY.md, agents/, skills/）

### 阶段二：版本升级（仅升级场景）
- 旧版本：vX.Y.Z
- 新版本：vA.B.C
- 配置合并：✅ 智能合并完成（变更字段 X 处，新增字段 Y 处）
- 健康诊断：✅ 无错误

### 阶段三：灾难恢复（仅恢复场景）
- 隔离目录：`.openclawbroken-YYYYMMDD-HHMMSS`、`clawdbroken-YYYYMMDD-HHMMSS`
- 还原方式：绝对路径 (`tar -xzvf ... -C /`)
- 还原验证：✅ 关键文件已归位

### 最终验证
- 网关状态：✅ active
- 记忆连续性：✅ 可查询历史会话
- 身份一致性：✅ SOUL.md 匹配备份时刻

**操作结果**：✅ 成功  
**建议后续操作**：（如有）
```

---

## 🧠 设计哲学与最佳实践

### 为什么要分三阶段？
1. **备份阶段不可跳过**：确保任何时候都能回到安全点
2. **验证阶段必须自动化**：人工检查容易遗漏，用 `--verify` 标志强制校验
3. **恢复阶段绝对路径还原**：历史血泪教训——相对路径解压导致无数 OpenClaw 事故

### 为什么强调 `-C /`？
OpenClaw 备份包使用 `tar` 的 `-P`（绝对路径）选项打包，文件路径在归档内以 `/Users/...` 形式存储。若解压时不指定 `-C /`，文件会以子目录形式落在当前路径，路径层级错乱，还原后 OpenClaw 无法找到配置文件。

### 为什么隔离受损现场？
- 保留证据：便于后续分析故障原因
- 防止覆盖：万一恢复失败，旧数据仍有第二次机会
- 时间戳标记：`~/.openclawbroken-YYYYMMDD-HHMMSS` 命名明确，避免混淆

---

## 📚 参考资料

本技能基于以下文档设计：
- OpenClaw 官方备份/恢复文档
- 社区常见运维事故案例分析（2024-2025）
- "根目录解压 (-C /) 生死命门" 加固规范

---

## 🏷️ 元数据

- **技能版本**：V2.0-REINFORCED
- **适用 OpenClaw 版本**：v0.9.0+
- **最后更新**：2026-04-21
- **安全等级**：A级（强制性验证）
- **操作风险**：中（升级失败可完全回滚）
- **新手友好度**：⭐⭐⭐⭐⭐（步骤明确，红线警示）
