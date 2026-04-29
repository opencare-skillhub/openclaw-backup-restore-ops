<p align="center">
  <img src="https://img.shields.io/badge/version-2.0-blue" alt="version">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
  <img src="https://img.shields.io/badge/OpenClaw-v0.9.0+-purple" alt="openclaw">
</p>

<p align="center">
  <strong>🌐 Language / 语言 / Язык / 言語 / 언어</strong><br>
  <a href="#中文">🇨🇳 中文</a> · 
  <a href="#english">🇬🇧 English</a> · 
  <a href="#русский">🇷🇺 Русский</a> · 
  <a href="#日本語">🇯🇵 日本語</a> · 
  <a href="#한국어">🇰🇷 한국어</a>
</p>

---

# 🛡️ OpenClaw Backup Ops

> OpenClaw 系统全生命周期运维技能 — 零记忆丢失、零配置受损

---

## 中文

### 📖 简介

**OpenClaw Backup Ops** 是一套完整的 OpenClaw 系统运维技能，覆盖备份、升级、恢复三大场景。无论你是新手还是老手，本技能都能确保你的数据 100% 安全。

### ✨ 核心特性

| 特性 | 说明 |
|------|------|
| 🔒 零丢失保障 | 强制三阶段协议：备份验证 → 平滑升级 → 灾难恢复 |
| 🧠 记忆连续性 | SOUL.md、MEMORY.md、agents/ 全量保护 |
| ⚡ 智能合并 | 配置 Schema 变更时自动合并新旧配置，不丢字段 |
| 🆘 一键恢复 | 绝对路径还原（`-C /`），杜绝文件错位 |
| 🛡️ 红线机制 | 5 条不可违反的安全红线，违规即终止 |

### 🚀 快速开始

```bash
# 创建备份
openclaw backup create --verify --output ~/Documents/OpenClawBackups/

# 验证备份内容
tar -tzvf ~/Documents/OpenClawBackups/openclaw-backup-*.tar.gz | grep -E "(openclaw.json|SOUL.md|MEMORY.md)"

# 安全升级
openclaw update --channel stable
openclaw doctor --fix
```

### 📋 三阶段协议

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  阶段一     │ ──→ │  阶段二     │ ──→ │  阶段三     │
│  备份验证   │     │  平滑升级   │     │  灾难恢复   │
│  (必须通过) │     │  (智能合并) │     │  (绝对路径) │
└─────────────┘     └─────────────┘     └─────────────┘
```

### 🔴 安全红线

1. ❌ 备份校验未通过 → **禁止进入阶段二**
2. ❌ 直接覆盖旧配置 → **必须智能合并**
3. ❌ 恢复时不加 `-C /` → **文件必错位**
4. ❌ 恢复前不隔离现场 → **无法追溯故障**
5. ❌ 跳过 `doctor --fix` → **隐性错误必爆发**

---

## English

### 📖 Introduction

**OpenClaw Backup Ops** is a comprehensive OpenClaw system operations skill covering backup, upgrade, and disaster recovery scenarios. Whether you're a beginner or an expert, this skill ensures 100% data safety.

### ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔒 Zero-Loss Guarantee | Mandatory 3-phase protocol: Verify → Upgrade → Recover |
| 🧠 Memory Continuity | Full protection of SOUL.md, MEMORY.md, agents/ |
| ⚡ Smart Merge | Auto-merges old/new configs on Schema changes |
| 🆘 One-Click Recovery | Absolute path restore (`-C /`), no file misplacement |
| 🛡️ Red Lines | 5 inviolable safety rules; violation = abort |

### 🚀 Quick Start

```bash
# Create backup
openclaw backup create --verify --output ~/Documents/OpenClawBackups/

# Verify backup contents
tar -tzvf ~/Documents/OpenClawBackups/openclaw-backup-*.tar.gz | grep -E "(openclaw.json|SOUL.md|MEMORY.md)"

# Safe upgrade
openclaw update --channel stable
openclaw doctor --fix
```

### 📋 Three-Phase Protocol

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Phase 1    │ ──→ │   Phase 2    │ ──→ │   Phase 3    │
│   Backup &   │     │   Smooth     │     │   Disaster   │
│   Verify     │     │   Upgrade    │     │   Recovery   │
│ (MUST pass)  │     │ (Smart Merge)│     │(Abs. Paths)  │
└──────────────┘     └──────────────┘     └──────────────┘
```

### 🔴 Safety Red Lines

1. ❌ Backup verification failed → **Phase 2 blocked**
2. ❌ Direct config overwrite → **Must smart-merge**
3. ❌ Restore without `-C /` → **Files WILL misplace**
4. ❌ No isolation before restore → **Cannot trace faults**
5. ❌ Skip `doctor --fix` → **Hidden errors WILL explode**

---

## Русский

### 📖 Описание

**OpenClaw Backup Ops** — комплексный навык обслуживания системы OpenClaw, охватывающий резервное копирование, обновление и восстановление после сбоев. Независимо от вашего опыта, этот навык гарантирует 100% сохранность данных.

### ✨ Основные возможности

| Возможность | Описание |
|-------------|----------|
| 🔒 Гарантия нулевых потерь | Обязательный 3-фазный протокол: Проверка → Обновление → Восстановление |
| 🧠 Непрерывность памяти | Полная защита SOUL.md, MEMORY.md, agents/ |
| ⚡ Умное слияние | Автослияние старых/новых конфигов при изменении схемы |
| 🆘 Восстановление в один клик | Восстановление по абсолютным путям (`-C /`) |
| 🛡️ Красные линии | 5 нерушимых правил безопасности; нарушение = остановка |

### 🚀 Быстрый старт

```bash
# Создать резервную копию
openclaw backup create --verify --output ~/Documents/OpenClawBackups/

# Проверить содержимое备份
tar -tzvf ~/Documents/OpenClawBackups/openclaw-backup-*.tar.gz | grep -E "(openclaw.json|SOUL.md|MEMORY.md)"

# Безопасное обновление
openclaw update --channel stable
openclaw doctor --fix
```

### 📋 Трёхфазный протокол

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Фаза 1     │ ──→ │   Фаза 2     │ ──→ │   Фаза 3     │
│  Резервное   │     │   Плавное    │     │  Восстанов-  │
│  копирование │     │  обновление  │     │  ление после │
│ и проверка   │     │(умное слияние)│    │   сбоев      │
└──────────────┘     └──────────────┘     └──────────────┘
```

### 🔴 Красные линии безопасности

1. ❌ Проверка бэкапа не пройдена → **Фаза 2 заблокирована**
2. ❌ Прямая перезапись конфига → **Обязательно умное слияние**
3. ❌ Восстановление без `-C /` → **Файлы будут перепутаны**
4. ❌ Нет изоляции перед восстановлением → **Невозможно найти причину**
5. ❌ Пропуск `doctor --fix` → **Скрытые ошибки ВЗОРВУТСЯ**

---

## 日本語

### 📖 概要

**OpenClaw Backup Ops** は、バックアップ、アップグレード、災害復旧の3つのシナリオをカバーする OpenClaw システム運用スキルです。初心者でもベテランでも、データの100%安全性を保証します。

### ✨ 主な特徴

| 特徴 | 説明 |
|------|------|
| 🔒 ゼロロス保証 | 必須3フェーズプロトコル：検証 → アップグレード → 復旧 |
| 🧠 メモリ連続性 | SOUL.md、MEMORY.md、agents/ を完全保護 |
| ⚡ スマートマージ | スキーマ変更時に新旧設定を自動マージ |
| 🆘 ワンクリック復旧 | 絶対パス復元（`-C /`）、ファイル配置ミスなし |
| 🛡️ レッドライン | 5つの不可侵安全ルール；違反 = 中止 |

### 🚀 クイックスタート

```bash
# バックアップ作成
openclaw backup create --verify --output ~/Documents/OpenClawBackups/

# バックアップ内容の検証
tar -tzvf ~/Documents/OpenClawBackups/openclaw-backup-*.tar.gz | grep -E "(openclaw.json|SOUL.md|MEMORY.md)"

# 安全なアップグレード
openclaw update --channel stable
openclaw doctor --fix
```

### 📋 3フェーズプロトコル

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  フェーズ1   │ ──→ │  フェーズ2   │ ──→ │  フェーズ3   │
│  バックアップ│     │  スムーズな  │     │  災害復旧    │
│  & 検証      │     │  アップグレード│    │ (絶対パス)   │
│ (必須通過)   │     │(スマートマージ)│   │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

### 🔴 安全レッドライン

1. ❌ バックアップ検証失敗 → **フェーズ2進入禁止**
2. ❌ 設定直接上書き → **スマートマージ必須**
3. ❌ `-C /` なし復元 → **ファイル配置ミス必発**
4. ❌ 復元前隔離なし → **障害原因追跡不能**
5. ❌ `doctor --fix` スキップ → **隠れエラーが爆発**

---

## 한국어

### 📖 소개

**OpenClaw Backup Ops**는 백업, 업그레이드, 재해 복구 시나리오를 다루는 OpenClaw 시스템 운영 스킬입니다. 초보자든 베테랑이든 데이터 100% 안전을 보장합니다.

### ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| 🔒 제로 로스 보장 | 필수 3단계 프로토콜: 검증 → 업그레이드 → 복구 |
| 🧠 메모리 연속성 | SOUL.md, MEMORY.md, agents/ 완전 보호 |
| ⚡ 스마트 머지 | 스키마 변경 시 신구 설정 자동 병합 |
| 🆘 원클릭 복구 | 절대 경로 복원 (`-C /`), 파일 위치 오류 없음 |
| 🛡️ 레드라인 | 5가지 불가침 안전 규칙; 위반 = 중단 |

### 🚀 빠른 시작

```bash
# 백업 생성
openclaw backup create --verify --output ~/Documents/OpenClawBackups/

# 백업 내용 검증
tar -tzvf ~/Documents/OpenClawBackups/openclaw-backup-*.tar.gz | grep -E "(openclaw.json|SOUL.md|MEMORY.md)"

# 안전한 업그레이드
openclaw update --channel stable
openclaw doctor --fix
```

### 📋 3단계 프로토콜

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   단계 1     │ ──→ │   단계 2     │ ──→ │   단계 3     │
│  백업 & 검증 │     │  원활한      │     │  재해 복구   │
│  (반드시 통과)│    │  업그레이드  │     │ (절대 경로)  │
│              │     │(스마트 머지) │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

### 🔴 안전 레드라인

1. ❌ 백업 검증 실패 → **단계 2 진입 금지**
2. ❌ 설정 직접 덮어쓰기 → **스마트 머지 필수**
3. ❌ 복원 시 `-C /` 누락 → **파일 위치 오류 확정**
4. ❌ 복원 전 격리 없음 → **장애 원인 추적 불가**
5. ❌ `doctor --fix` 건너뛰기 → **숨은 에러 폭발**

---

<p align="center">

### 📁 프로젝트 구조 / 项目结构 / Project Structure

```
openclaw-backup-ops/
├── SKILL.md                          # 메인 스킬 정의
├── README.md                         # 이 파일
├── references/
│   ├── schema-migration-guide.md     # 설정 스키마 마이그레이션 가이드
│   ├── troubleshooting.md            # 문제 해결 핫시트
│   └── openclaw-commands.md          # OpenClaw 명령어 참조
└── scripts/
    ├── backup_and_verify.sh          # 자동 백업 & 검증
    ├── smart_merge_config.py         # 지능형 설정 병합
    └── disaster_recovery.sh          # 원클릭 재해 복구
```

</p>

---

<p align="center">

**🏷️ Version:** V2.0-REINFORCED · **🔒 Security Level:** A (Mandatory Verification) · **📅 Updated:** 2026-04-21

**🏷️ 버전:** V2.0-REINFORCED · **🔒 보안 수준:** A (필수 검증) · **📅 업데이트:** 2026-04-21

**🏷️ 版本:** V2.0-加固版 · **🔒 安全等级:** A（强制验证） · **📅 更新:** 2026-04-21

**🏷️ Версия:** V2.0-УСИЛЕННАЯ · **🔒 Уровень безопасности:** A (Обязательная проверка) · **📅 Обновлено:** 21.04.2026

**🏷️ バージョン:** V2.0-強化版 · **🔒 セキュリティレベル:** A（必須検証） · **📅 更新:** 2026-04-21

</p>

---

<p align="center">
  <sub>Made with ❤️ by Hermes Agent</sub>
</p>
