# Player Mode · 第一章

入口 `player_mode.tscn`，默认项目运行场景。流程：主菜单 → 三关顺序解锁 → 战前剧情 → 实际战斗 → 战后剧情 → 下一关。选关页只显示已解锁关卡，尚未解锁的关卡不显示入口或名称。第三关剧情结束后显示第一章完成，定位到海洋信号。已完成关卡可重新选择，播放原剧情。

角色／技能／敌人／波次和剧情编辑方式见 `content/campaign/README.md`。Player、Game Test 复用 `game/battle`；剧情复用 features/story 的 Session 和 View。Player 不依赖 devtools；战斗左上菜单提供独立的轻量开发者面板。

音频：`_ready()` 创建一个常驻的 `AudioDirector`（`features/audio`），加载 `content/audio/cues.tres` 后注入给战斗场景。主菜单、选关、剧情和设置页共用 `music_main`，战斗使用 `music_battle`，切换时交叉淡入淡出；相同曲目重复请求不会重启。主菜单右上角「设置」页提供 BGM／音效两条滑块，改动立即作用到 `Music`／`SFX` 总线并写入 `user://audio_settings.cfg`（测试可用 `audio_settings_path` 重定向）。音量 0 即静音该总线。战斗音效由 `game/adapters/battle_audio.gd` 从战斗事件映射，未配置素材的 cue 静默。

存档仍是 `user://player_progress.cfg`。新的 campaign 区段 version=1，保存 selected、completed、pending_after、started。读取存档优先续接待播放的战后剧情；胜利时先持久化 pending_after，看完或跳过战后剧情才写入完成并解锁下一关。中途返回关卡不丢弃 pending_after。战斗中间状态不保存；重新出击从头开始。

旧 progress 区段被保留，scene_001 的完成状态不会解锁正式章节。非法或破损进度退回新游戏；已完成列表只接受顺序前缀。写入失败在返回关卡时显示“进度未能保存”，当次内存流程仍可继续。

第一关首次进入时给出可关闭的简短提示，战斗默认自动播放；提示的显示与关闭不改变暂停状态。玩法 UI 保留手动暂停、倍速、部署、技能、撤退和失败重试。第三关显示模拟时钟驱动的节点修复进度。

快速测试：战斗左上角 ☰ → 开发者面板 → 跳过战斗并胜利。此操作进入正常胜利结算，再点击“继续”；看完／跳过战后剧情后保存完成状态并解锁下一关。打开面板不自动暂停，暂停中的战斗也可以跳过；已结束的战斗不能再次跳过或覆盖失败结果。面板没有单独的存档或解锁实现。

验证入口 `game/tests/player_flow_test.gd`（兼容入口，继承 chapter_flow_test），通过 GODOT_PATH 运行。加 `-- --capture` 并移除 headless 使用真实鼠标输入，截图及隔离存档输出到 `temp/chapter_one/`，不覆盖玩家存档。
