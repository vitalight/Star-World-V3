# Player Mode 流程评审

本记录为2026-10-23单关阶段的历史评审。2026-10-25扩展为三关章节及剧情后的现行接口、存档和回归结果见 [第一章评审](chapter_one.md) 与 game/player/README.md。

- 模块名称与路径：`game/player`，正式界面资源 `content/ui/player`。
- 职责：主菜单、选择已配置关卡、开始与释放战斗、关卡进度存取；不实现第二份战斗规则或表现，不接入开发调试窗。
- 输入、输出及依赖：直接组装已集成的 `game/battle/battle_scene.tscn`，监听 `exit_requested` 和 `observed`；预览使用 `content/scenes/scene_001/preview.tscn`，原始素材整理至 content。正式运行不引用 Human、devtools 或 temp。进度写到 `user://player_progress.cfg`，测试通过可配置 save_path 隔离到 temp。
- 独立入口：`game/player/player_mode.tscn`，项目默认入口；Developer Hub 增加 Player Mode 卡片。开发者 BAT 维持显式启动 Hub。
- 验证：Godot 4.7.2，使用环境变量 GODOT_PATH；`game/tests/player_flow_test.gd` 无界面与 OpenGL 原生鼠标/截图运行各 45 项零失败；现有 `battle_integration_test.gd` 116 项零失败。`git diff --check` 无空白错误。
- 覆盖：无存档、主界面/关卡/战斗往返、三种窗口尺寸、开发者入口、实际胜利/失败、重试、菜单退出、成功进度跨会话、损坏存档回退、无开发控件。所有截图在 temp/player_mode，下列为本次验证证据而非运行依赖。
- 参考图与证据：按 Human/StarterContent/ui 的四张素材与蓝图落实；`temp/player_mode/main.png`、`levels_1280x800.png`、`levels_960x600.png`、`levels_1600x900.png`、`battle.png`、`battle_deployed.png`、`victory.png`、`defeat.png`、`levels_completed.png`。日志：flow.log、visual.log、battle_regression.log。
- 已知限制：只呈现真实 scene_001；蓝图世界地图简化为单关卡路径和真实地形预览。存档只保存关卡和完成状态，不恢复进行中的战斗；不引入新剧情、奖励和后续解锁。界面为桌面横屏设计，已检查最小 960×600。
- 评审结论：实现和技术验证完成；主代理已查看主菜单、关卡页并确认布局与素材相符，最终技术复核由主代理完成。
- 评审人和日期：实现代理与主代理，2026-10-23。
- 集成位置：project.godot 默认入口及 devtools/hub 玩家入口；不更改共享 battle/feature 代码。
