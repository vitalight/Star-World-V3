# Player Mode

正式入口 `player_mode.tscn`，流程：主界面 → 关卡选择 → 战斗 → 关卡选择 → 主界面。Developer Hub 的 Player Mode 卡片也能进入此流程。

关卡页仅展示已配置的 `scene_001`。地图预览复用该关卡的独立 3D 预览，开始行动直接加载 `game/battle/battle_scene.tscn`，与 Game Test 使用同一战斗规则和表现。退出战斗菜单及胜负面板均可返回关卡；战斗结束仍可重新挑战。产品界面不组装开发调试窗。

开始行动记录所选关卡，首次胜利记录完成状态，保存于 `user://player_progress.cfg`。读取存档回到已选关卡，重新出击从头开始；不保存战斗中间状态。没有存档时禁用读取按钮。写入失败时返回关卡页显示简短提示。当前只有一个关卡，未增加剧情、奖励、虚构关卡或解锁规则。

主菜单和关卡页按参考图 1672 × 941 设计，适配窗口时等比缩放控件并覆盖填充背景。菜单支持原生键盘焦点，关卡页 Esc 返回主界面。

验证：通过 `$env:GODOT_PATH` 启动 `--headless --path . --script res://game/tests/player_flow_test.gd`；截图验证移除 `--headless` 并加 `-- --capture`，输出至 `temp/player_mode/`。测试使用独立临时进度文件，不覆盖玩家存档。
