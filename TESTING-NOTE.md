# Skill 测试说明

## 测试环境配置
- 使用 Mock OpenClaw 环境，不执行实际操作
- Mock 脚本位置: ~/mock-openclaw-test/openclaw
- 测试时 PATH 会临时指向 mock 环境

## 安全保证
✅ 不会修改 ~/.openclaw/ 目录
✅ 不会修改 ~/clawd/ 目录
✅ 不会执行 tar 解压操作
✅ 不会停止或重启任何服务

## 测试流程
1. 使用 skill-creator 运行 eval
2. 子进程使用 mock openclaw
3. 验证输出是否符合预期格式
4. 不产生任何实际系统变更

## 预期结果
- with_skill 运行：应该显示三阶段协议的执行计划
- without_skill 运行：可能缺少步骤或格式混乱
- 断言检查：with_skill 应该通过更多断言
