# Game Test

Game Test 是正式战斗场景的开发者工作区，用于检查资产、表现和关卡配置的集成效果。默认项目入口是 Player Mode；从 Developer Hub 进入，或在 Godot 中 F6 运行 `game/battle/battle_scene.tscn`。

## 调试窗

F3 或左下角“F3”打开。窗口可拖动、缩放，输入不会传给战场。提供：

- 关卡选择：开发样例与正式关卡；选择后重置战斗。
- 重新加载关卡：读取已保存的 `.tres`、CSV 和地图。
- 开始、暂停、单步（运行态且暂停时）、1×／2×／4×、重置。
- 网格、路线、攻击范围显示。
- 选中单位快照与最近事件。
- 跳过战斗并胜利。

Game Test 的“跳过战斗并胜利”只展示胜利结果；Player Mode 的开发者面板使用正常胜利流程记录待播放剧情。已结束的战斗不能覆盖结果。正式关卡使用完整干员列表，可直接验证飞行与反空。

## 关卡编辑

- 开发样例：`content/scenes/scene_001/map.tscn`（地图）与同目录 `level.tres`（数值、敌人、波次）。
- 正式关卡的 Terrain、Routes、TileSet 自定义数据和飞行路线规范见 `content/campaign/README.md`。
- 3D 预览：打开 `content/scenes/scene_001/preview.tscn`，选中 Field 后刷新 TileMap 预览；也可 F6 运行。
- 运行中的 Game Test 用“重新加载关卡”读取已保存资源；未保存的编辑器改动不会生效。
- 配置错误会显示原因并阻止开始，修复后可再次重新加载。

## 验证

在项目根目录使用 `GODOT_PATH`，临时用户目录和输出留在 `temp/`：

```powershell
New-Item -ItemType Directory -Force temp/game_test | Out-Null
if (-not (Test-Path temp/.gdignore)) { New-Item -ItemType File temp/.gdignore | Out-Null }
$env:APPDATA = (Resolve-Path temp/game_test).Path
& $env:GODOT_PATH --headless --path . --script res://game/tests/battle_integration_test.gd --log-file temp/game_integration.log
& $env:GODOT_PATH --path . --script res://game/tests/battle_visual_test.gd --log-file temp/game_visual.log
```

`battle_integration_test` 比较纯逻辑与组装场景；`battle_visual_test` 使用真实渲染和原生输入，验证部署、选择、技能、暂停、调试窗与窗口尺寸。图形验收不能使用 headless。角色遮挡、部署、特效、路线预告等专项测试位于 `game/tests/`。
