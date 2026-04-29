# OpenClaw 配置 Schema 迁移指南

本文档说明 OpenClaw 版本升级时配置文件 `openclaw.json` 的结构变更处理策略。

---

## 为什么需要智能合并？

OpenClaw 升级时，配置文件 Schema 可能发生以下变更：

| 变更类型 | 示例 | 风险 |
|---------|------|------|
| **新增必填字段** | `"ai_model": { "provider": "openai" }` | 旧配置缺失此字段，服务拒绝启动 |
| **字段重命名** | `"max_tokens"` → `"token_limit"` | 旧值丢失，新字段为默认值 |
| **类型变更** | `"port": 3000` (int) → `"port": "3000"` (string) | JSON 类型错误，解析失败 |
| **结构嵌套** | `"gateway": { "port": 3000 }` 替代 `"port": 3000` | 旧字段位置错误，服务找不到配置 |
| **字段废弃** | `"legacy_mode": true` → 移除 | 旧值保留无意义，但删除可能导致旧逻辑错误 |

**直接覆盖配置的后果**：
```bash
# 错误做法
cp /new/version/openclaw.json ~/.openclaw/openclaw.json
# → 丢失所有自定义 API keys、user preferences、个性化设置
```

---

## 智能合并策略

### 原则
1. **Schema 以新版为准**：结构完全采用新版本的 JSON Schema
2. **值以旧版为准**：能保留的旧值全部保留
3. **未知字段移至 deprecated**：旧版有但新版无的字段，不删除，移至 `deprecated_fields` 备用

### 合并算法（递归）

```
merge(old_config, new_schema):
  result = new_schema  # 以新结构为模板

  for each key in old_config:
    if key exists in new_schema:
      if both values are dict:
        result[key] = merge(old[key], new[key])  # 递归
      else:
        result[key] = old[key]  # 保留旧值（即使新值为 null）
    else:
      result["deprecated_fields"][key] = old[key]  # 移至废弃区

  return result
```

---

## 实际操作步骤

### 步骤 1：备份当前配置（双重保险）

```bash
# 备份 1：直接复制
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-pre-upgrade-$(date +%Y%m%d-%H%M%S)

# 备份 2：通过 openclaw backup（阶段一已做）
ls ~/Documents/OpenClawBackups/
```

### 步骤 2：识别 Schema 变更

```bash
# 方式 A：运行 doctor 查看差异
openclaw doctor --verbose 2>&1 | grep -A 10 "schema"

# 方式 B：对比默认配置（如有）
diff <(openclaw config show --defaults) <(cat ~/.openclaw/openclaw.json) | less
```

### 步骤 3：执行智能合并

**使用配套脚本**：
```bash
python3 ~/.agents/skills/openclaw-backup-ops/scripts/smart_merge_config.py \
  --old ~/.openclaw/openclaw.json.bak-pre-upgrade-$(date +%Y%m%d-%H%M%S) \
  --new ~/.openclaw/openclaw.json.new-template \  # 新版默认配置
  --output ~/.openclaw/openclaw.json.merged-$(date +%Y%m%d-%H%M%S)
```

**脚本输出示例**：
```
[INFO] 读取配置:
   旧配置: ~/.openclaw.json.bak-20260421-080000 (2345 字符)
   新配置: ~/.openclaw.json.new-template-20260421-090000 (2890 字符)

[INFO] 差异分析:
   废弃字段数: 2
   废弃字段列表: legacy_mode, old_encoding

[INFO] 智能合并中...
[✅] 保留旧值: gateway.port (3000 ← 新默认值 8080)
[✅] 保留旧值: ai_model.provider (anthropic ← 新默认值 openai)
[✅] 保留旧值: memory.max_sessions (100 ← 新默认值 50)

[INFO] 合并完成报告:
   旧配置字段数: 48
   新配置字段数: 52
   合并后字段数: 54 (含 2 个废弃字段)
   废弃字段保留: 2 个（已移至 deprecated_fields）

[✅] 新配置已保存: ~/.openclaw/openclaw.json
```

### 步骤 4：验证合并结果

```bash
# 语法检查
python3 -m json.tool ~/.openclaw/openclaw.json > /dev/null
if [[ $? -ne 0 ]]; then
  echo "[ERROR] JSON 语法错误，请检查合并结果"
  exit 1
fi

# Schema 验证
openclaw doctor --fix
```

### 步骤 5：启动测试

```bash
openclaw gateway start
sleep 3
openclaw gateway status
```

如果状态不是 `active`，查看日志：
```bash
openclaw gateway logs --tail 30
```

---

## 常见 Schema 变更模式与处理

### 模式 1：新增嵌套结构

**旧配置**：
```json
{
  "port": 3000,
  "max_tokens": 4000
}
```

**新 Schema**：
```json
{
  "gateway": {
    "port": 8080,
    "host": "0.0.0.0"
  },
  "ai_model": {
    "max_tokens": 8000
  }
}
```

**合并结果**：
```json
{
  "gateway": {
    "port": 3000,       ← 保留旧值
    "host": "0.0.0.0"   ← 使用新默认值
  },
  "ai_model": {
    "max_tokens": 4000  ← 保留旧值
  },
  "deprecated_fields": {
    "port": 3000,       ← 旧字段已废弃，保留原始值
    "max_tokens": 4000
  }
}
```

**关键点**：
- 旧字段 `port` 和 `max_tokens` 在新结构中不存在 → 移至 `deprecated_fields`
- 新结构中对应的嵌套位置 → 填充旧值

---

### 模式 2：字段类型变更

**旧配置**：
```json
{
  "token_limit": 4000  ← 整数
}
```

**新 Schema**：
```json
{
  "token_limit": "4000"  ← 字符串
}
```

**合并结果**（智能转换）：
```json
{
  "token_limit": "4000"  ← 自动转为字符串
}
```

**智能转换规则**：
- int → string：自动 `str()`
- string → int：尝试 `int()`，失败则保留旧值
- number → string：保留数值，不添加引号（JSON 序列化自动处理）

---

### 模式 3：枚举值变更

**旧配置**：
```json
{
  "log_level": "info"
}
```

**新 Schema**：
```json
{
  "log_level": {
    "type": "enum",
    "enum": ["debug", "info", "warn", "error"]
  }
}
```

**如果旧值 `"verbose"` 不在新枚举中**：
```json
{
  "log_level": "info",  ← 降级为最近的有效值
  "deprecated_fields": {
    "log_level_original": "verbose"
  }
}
```

**处理策略**：
1. 检查旧值是否在新枚举列表中
2. 是 → 保留
3. 否 → 使用新默认值，原始值存入 `deprecated_fields.log_level_original`

---

### 模式 4：字段合并

**旧配置 A**：
```json
{
  "api_key": "sk-xxx",
  "api_base": "https://api.example.com"
}
```

**旧配置 B**：
```json
{
  "provider": {
    "api_key": "sk-xxx",
    "api_base": "https://api.example.com"
  }
}
```

**新 Schema**：
```json
{
  "ai_provider": {
    "type": "openai",
    "credentials": {
      "api_key": "...",
      "api_base": "..."
    }
  }
}
```

**合并策略**（多级映射）：
需预先定义字段映射表（`smart_merge_config.py` 扩展）：

```python
FIELD_MAPPING = {
  ("api_key", "credentials.api_key"): lambda v: v,
  ("api_base", "credentials.api_base"): lambda v: v,
}
```

---

## 手动合并工作流

如果脚本无法处理复杂场景，使用手动流程：

### 1. 使用 diff 工具对比

```bash
# 生成差异报告
diff -u \
  <(jq '.' ~/.openclaw/openclaw.json.bak) \
  <(jq '.' ~/.openclaw/openclaw.json.new) \
  > ~/config-schema-diff.patch

# 可视化工（推荐）
meld ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json.new &
```

### 2. 逐项迁移

创建合并配置文件 `openclaw.json.merged`：

```json
{
  // 1. 复制新 Schema 框架
  "$schema": "https://openclaw.org/schema/v0.9.0.json",
  "version": "0.9.0",

  // 2. 填充旧值到新位置
  "gateway": {
    "port": 3000,          ← 从旧配置复制
    "host": "127.0.0.1"    ← 新默认值
  },

  // 3. 处理废弃字段
  "deprecated_fields": {
    "legacy_mode": false,  ← 从旧配置移入
    "old_encoding": "utf-8"
  }
}
```

### 3. 语法与 Schema 验证

```bash
# JSON 语法
python3 -m json.tool openclaw.json.merged > /dev/null

# OpenClaw Schema 验证（如果提供）
openclaw config validate openclaw.json.merged

# 试运行
openclaw doctor --config openclaw.json.merged --dry-run
```

### 4. 应用并测试

```bash
# 备份当前配置
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.before-merge-$(date +%s)

# 覆盖
cp openclaw.json.merged ~/.openclaw/openclaw.json

# 测试
openclaw doctor --fix
openclaw gateway start
openclaw gateway status
```

---

## 自动化脚本使用说明

### `smart_merge_config.py` 参数

```bash
# 基本用法
python3 scripts/smart_merge_config.py \
  --old /path/to/old.json \
  --new /path/to/new.json \
  --output /path/to/merged.json

# 预览模式（不写入文件）
python3 scripts/smart_merge_config.py \
  --old old.json --new new.json --dry-run

# 详细模式
python3 scripts/smart_merge_config.py \
  --old old.json --new new.json --output merged.json --verbose
```

### 脚本输出说明

**正常输出**：
```
[INFO] 读取配置: 旧 2345 字符 / 新 2890 字符
[INFO] 差异分析: 废弃字段数 2
[INFO] 智能合并中...
[✅] 保留旧值: gateway.port (3000 ← 8080)
[✅] 保留旧值: ai_model.provider (anthropic ← openai)
[✅] 保留旧值: memory.max_sessions (100 ← 50)
[✅] 合并完成: 旧 48 字段 → 新 52 字段 → 合并后 54 字段
[✅] 已保存: ~/.openclaw/openclaw.json
```

**错误输出**：
```
[ERROR] 无法读取 old.json: No such file or directory
[ERROR] JSON 语法错误: Expecting ',' delimiter: line 42 column 5
```

---

## 配置迁移清单

每次升级后，检查以下配置项是否保留：

| 配置路径 | 重要性 | 迁移后验证方法 |
|---------|--------|---------------|
| `gateway.port` | 高 | `openclaw config get gateway.port` |
| `ai_model.provider` | 高 | 确认 AI 服务商设置正确 |
| `ai_model.api_key` | 极高 | **确保未丢失**（敏感信息） |
| `memory.max_sessions` | 中 | 查看会话数量限制 |
| `skills.enabled[]` | 中 | `openclaw skills list` |
| `custom_prompts.*` | 低 | 测试自定义 prompt 是否生效 |

---

## 回滚策略

如果合并后服务无法启动：

```bash
# 1. 立即回滚到备份配置
cp ~/.openclaw/openclaw.json.bak-pre-upgrade-YYYYMMDD-HHMMSS \
   ~/.openclaw/openclaw.json

# 2. 验证回滚后是否正常
openclaw doctor --fix
openclaw gateway start

# 3. 如果回滚成功，保留当前版本，暂不升级
#    分析合并脚本的不足，手动修复后重试
```

---

## 版本对应关系

| OpenClaw 版本 | Schema 版本 | 重大变更 |
|--------------|------------|---------|
| v0.8.x | 未标准化 | 无 Schema 验证 |
| v0.9.0 | v0.9.0 | 引入 `gateway` 嵌套结构 |
| v0.9.5 | v0.9.5 | `ai_model` 字段重组 |
| v1.0.0 | v1.0.0 | 废弃 `legacy_mode` |

**查看当前 Schema 版本**：
```bash
openclaw config get '$schema' 2>/dev/null || echo "未设置"
```

---

**维护建议**：
- 每次升级前执行阶段一备份
- 保留至少 3 个版本的备份（`keep 3` 策略）
- 重大版本升级（主版本号变更）前，先在测试环境验证合并流程
