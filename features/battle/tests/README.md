# Battle 自动化测试

模块内用例通过 battle 公共接口执行，不依赖场景、地形或美术资源，可使用 `--headless` 运行。规则与配置语义见 [Battle 公共接口](../README.md)，本文件只记录测试入口。

| 入口 | 覆盖 |
| --- | --- |
| `battle_test.gd` | 部署、阻挡、伤害／治疗、技能、暂停单步、终局与重置等基础规则和边界 |
| `scenario_test.gd` | 固定命令回放场景；配置在 `scenario_fixtures.gd`，提交逻辑在 `scenario_replay.gd`；逐帧分片重放比对最终状态 |
| `game/tests/battle_integration_test.gd` | 地图与场景组装、关卡配置、重载、胜负和生命周期 |
| `game/tests/battle_visual_test.gd` | 真实渲染与原生输入 |

```powershell
& $env:GODOT_PATH --headless --path . --script res://features/battle/tests/battle_test.gd
& $env:GODOT_PATH --headless --path . --script res://features/battle/tests/scenario_test.gd
& $env:GODOT_PATH --headless --path . --script res://game/tests/battle_integration_test.gd
```

日志和截图写入根目录 `temp/`。图形验收不能使用 headless；手动验证统一使用 Game Test。
