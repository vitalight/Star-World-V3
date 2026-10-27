# Player Mode · 第一章

入口 `player_mode.tscn`，默认项目运行场景。第一章按 1-1A（剧情）、1-1B（战斗）至 1-4A／B 顺序解锁，1-5A 为独立尾声。首次读完或跳过剧情会保存完成状态并自动进入对应战斗；重玩已完成剧情后返回选关，直接选择战斗关会直接进入战斗。战斗胜利点击继续后进入下一剧情，失败可重试。选关页只显示已解锁关卡。

角色／技能／敌人／波次和剧情编辑方式见 `content/campaign/README.md`。Player、Game Test 复用 `game/battle`；剧情复用 features/story 的 Session 和 View。Player 不依赖 devtools；战斗左上菜单提供独立的轻量开发者面板。

音频：`_ready()` 创建一个常驻的 `AudioDirector`（`features/audio`），加载 `content/audio/cues.tres` 后注入给战斗场景。主菜单、选关、剧情和设置页共用 `music_main`，战斗使用 `music_battle`，切换时交叉淡入淡出；相同曲目重复请求不会重启。主菜单右上角「设置」页提供 BGM／音效两条滑块，改动立即作用到 `Music`／`SFX` 总线并写入 `user://audio_settings.cfg`（测试可用 `audio_settings_path` 重定向）。音量 0 即静音该总线。战斗音效由 `game/adapters/battle_audio.gd` 从战斗事件映射，未配置素材的 cue 静默。

存档仍是 `user://player_progress.cfg`。campaign version=3 保存 selected、completed、pending_after、started，player 区段保存持有与暂离干员。战斗胜利时先持久化 pending_after；继续或读档时结算角色事件、保存完成状态并进入下一剧情。剧情完成后保存再进入战斗。版本 1／2 旧存档映射为独立剧情和战斗关，保留队伍、已完成进度及待续接的胜利，不重复触发角色事件。战斗中间状态不保存；重新出击从头开始。

旧 progress 区段被保留，scene_001 的完成状态不会解锁正式章节。非法或破损进度退回新游戏；已完成列表只接受顺序前缀。写入失败在返回关卡时显示“进度未能保存”，当次内存流程仍可继续。

第一关首次进入时给出可关闭的简短提示，战斗默认自动播放；提示的显示与关闭不改变暂停状态。玩法 UI 保留手动暂停、倍速、部署、技能、撤退和失败重试。1-4B 显示模拟时钟驱动的节点修复进度。

快速测试：战斗左上角 ☰ → 开发者面板 → 跳过战斗并胜利。此操作进入正常胜利结算，再点击“继续”；保存完成状态并直接进入下一关剧情，最后一战后播放独立尾声。打开面板不自动暂停，暂停中的战斗也可以跳过；已结束的战斗不能再次跳过或覆盖失败结果。面板没有单独的存档或解锁实现。

验证入口 `game/tests/player_flow_test.gd`（兼容入口，继承 chapter_flow_test），通过 GODOT_PATH 运行。加 `-- --capture` 并移除 headless 使用真实鼠标输入，截图及隔离存档输出到 `temp/chapter_one/`，不覆盖玩家存档。
