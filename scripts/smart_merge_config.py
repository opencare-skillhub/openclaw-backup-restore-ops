#!/usr/bin/env python3
"""
OpenClaw 配置智能合并工具
用途：当 openclaw.json Schema 变更时，基于旧配置智能合并新配置
保留旧配置值，适配新结构，避免手动合并出错
"""

import json
import sys
import argparse
from pathlib import Path
from datetime import datetime

def load_json(path):
    """加载 JSON 文件"""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"[ERROR] 无法读取 {path}: {e}")
        sys.exit(1)

def save_json(data, path):
    """保存 JSON 文件，自动创建备份"""
    backup_path = f"{path}.bak-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    if Path(path).exists():
        Path(path).rename(backup_path)
        print(f"[INFO] 旧配置已备份至: {backup_path}")

    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"[✅] 新配置已保存: {path}")

def deep_update(old, new):
    """
    递归合并字典
    - new 中的键：若旧配置存在则保留旧值，不存在则使用新默认值
    - 仅更新结构，不覆盖已有数据
    """
    if not isinstance(old, dict) or not isinstance(new, dict):
        return new  # 类型不一致，以新为准

    merged = new.copy()  # 以新配置的 Schema 为基础

    for key, old_val in old.items():
        if key in merged:
            if isinstance(old_val, dict) and isinstance(merged[key], dict):
                merged[key] = deep_update(old_val, merged[key])
            else:
                # 保留旧值（除非新值为 None 且旧值非 None）
                if merged[key] is None and old_val is not None:
                    merged[key] = old_val
                else:
                    merged[key] = old_val
        else:
            # 旧键在新 Schema 中不存在，移至 deprecated 区
            print(f"[⚠️ ] 字段 '{key}' 已废弃，移至 deprecated_fields 保存")
            if 'deprecated_fields' not in merged:
                merged['deprecated_fields'] = {}
            merged['deprecated_fields'][key] = old_val

    return merged

def find_deprecated_fields(old, new, path=""):
    """递归查找所有废弃字段"""
    deprecated = {}
    for key in old:
        full_key = f"{path}.{key}" if path else key
        if key not in new:
            deprecated[full_key] = old[key]
        elif isinstance(old[key], dict) and isinstance(new.get(key, {}), dict):
            deprecated.update(find_deprecated_fields(old[key], new[key], full_key))
    return deprecated

def main():
    parser = argparse.ArgumentParser(
        description="OpenClaw 配置智能合并工具 - 升级时保留旧配置值，安全适配新 Schema"
    )
    parser.add_argument('--old', required=True, help='旧配置文件路径')
    parser.add_argument('--new', required=True, help='新配置文件路径（升级后生成）')
    parser.add_argument('--output', required=True, help='合并后输出路径')
    parser.add_argument('--dry-run', action='store_true', help='仅预览合并结果，不写入文件')
    args = parser.parse_args()

    print("=" * 60)
    print("OpenClaw 配置智能合并工具")
    print("=" * 60)

    # 加载配置
    old_config = load_json(args.old)
    new_config = load_json(args.new)

    print(f"\n[1] 读取配置:")
    print(f"   旧配置: {args.old} ({len(json.dumps(old_config))} 字符)")
    print(f"   新配置: {args.new} ({len(json.dumps(new_config))} 字符)")

    # 分析差异
    print(f"\n[2] 差异分析:")
    old_keys = set(str(k) for k in json.dumps(old_config))
    new_keys = set(str(k) for k in json.dumps(new_config))

    # 简单统计（更精确的分析可递归对比）
    deprecated = find_deprecated_fields(old_config, new_config)
    print(f"   废弃字段数: {len(deprecated)}")
    if deprecated:
        print(f"   废弃字段列表: {', '.join(deprecated.keys())}")

    # 执行合并
    print(f"\n[3] 智能合并中...")
    merged = deep_update(old_config, new_config)

    # 统计合并结果
    changes = []
    for key in old_config:
        if key in merged and merged[key] != new_config.get(key):
            changes.append(f"  ✅ 保留旧值: {key}")

    print(f"   保留旧值字段: {len(changes)} 处")
    for c in changes[:10]:  # 只显示前 10 个
        print(c)
    if len(changes) > 10:
        print(f"   ... 以及另外 {len(changes)-10} 处")

    # 预览
    if args.dry_run:
        print(f"\n[DRY-RUN] 合并结果预览（前 500 字符）:")
        preview = json.dumps(merged, indent=2, ensure_ascii=False)[:500]
        print(preview + "..." if len(json.dumps(merged)) > 500 else preview)
        print("\n[提示] 使用 --output 指定输出文件以保存合并结果")
        return 0

    # 保存
    save_json(merged, args.output)

    # 最终报告
    print(f"\n[4] 合并完成报告:")
    print(f"   旧配置字段数: {count_fields(old_config)}")
    print(f"   新配置字段数: {count_fields(new_config)}")
    print(f"   合并后字段数: {count_fields(merged)}")
    print(f"   废弃字段保留: {len(deprecated)} 个（已移至 deprecated_fields）")

    return 0

def count_fields(d):
    """递归统计字段数"""
    if not isinstance(d, dict):
        return 0
    count = len(d)
    for v in d.values():
        if isinstance(v, dict):
            count += count_fields(v)
    return count

if __name__ == '__main__':
    sys.exit(main())
