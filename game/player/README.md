# Player Mode · 第一章

入口 `player_mode.tscn`，默认项目运行场景。第一章按 1-1A（剧情）、1-1B（战斗）至 1-4A／B／C（其中 1-4B、1-4C 为两场 Boss 战），最后是独立尾声 1-5A。首次读完或跳过剧情会保存完成状态并自动进入对应战斗；重玩已完成剧情后返回选关，直接选择战斗关会直接进入战斗。战斗胜利点击继续后进入下一剧情或下一场战斗，失败可重试。选关页显示已解锁关卡和最多一个不可选择的匿名锁定关卡；章节列表显示第一章和一个匿名锁定章节占位。关卡列表可滚动，详情面板随内容调整高度。

主菜单的“开始游戏”创建新的内存进度，从第一关开始；开始行动时保存新进度并覆盖现有存档。“读取存档”重新读取并恢复已有进度。从开发者首页进入 Player Mode，或运行 `scripts/run_game.bat -d`，会启用开发者模式：所有已配置关卡可选，完成状态仍按实际游玩记录，进度仅在本次运行中保存，不读取或覆盖普通存档。

角色／技能／敌人／波次和剧情编辑方式见 `content/campaign/README.md`。Player、Game Test 复用 `game/battle`；剧情复用 features/story 的 Session 和 View。Player 不依赖 devtools；开发者模式下战斗左下角直接展开轻量开发者面板，普通模式不显示。

音频：`_ready()` 创建一个常驻的 `AudioDirector`（`features/audio`），加载 `content/audio/cues.tres` 后注入给战斗场景。主菜单、选关、剧情和设置页共用 `music_main`，战斗使用 `music_battle`，切换时交叉淡入淡出；相同曲目重复请求不会重启。主菜单右上角「设置」页提供 BGM／音效两条滑块，改动立即作用到 `Music`／`SFX` 总线并写入 `user://audio_settings.cfg`（测试可用 `audio_settings_path` 重定向）。音量 0 即静音该总线。战斗音效由 `game/adapters/battle_audio.gd` 从战斗事件映射，未配置素材的 cue 静默。

存档仍是 `user://player_progress.cfg`。campaign version=3 保存 selected、completed、pending_after、started，player 区段保存持有与暂离干员。战斗胜利时先持久化 pending_after；继续或读档时结算角色事件、保存完成状态并进入下一剧情。剧情完成后保存再进入战斗。版本 1／2 旧存档映射为独立剧情和战斗关，保留队伍、已完成进度及待续接的胜利，不重复触发角色事件。已完成旧章节的存档会把新增的 1-4C 一并计入完成，保持章节完成状态；未完成的存档按新顺序推进到 1-4C。战斗中间状态不保存；重新出击从头开始。

旧 progress 区段被保留，scene_001 的完成状态不会解锁正式章节。非法或破损进度退回新游戏；已完成列表只接受顺序前缀。写入失败在返回关卡时显示“进度未能保存”，当次内存流程仍可继续。

第一场战斗在本次会话首次进入时显示居中的关卡提示，包含实际战斗截图与部署、守护基地和费用恢复说明；提示遮挡战场操作并暂停战斗和开场倒计时，确认后继续。玩法 UI 保留手动暂停、倍速、部署、技能、撤退和失败重试。1-4B、1-4C 均为清怪结束的 Boss 战；1-4B 在击败根节点核心后完成节点修复。

快速测试：开发者模式下点击战斗左下角的“跳过战斗并胜利”。此操作进入正常胜利结算，再点击“继续”；记录完成状态并直接进入下一关剧情，最后一战后播放独立尾声。面板不自动暂停，暂停中的战斗也可以跳过；已结束的战斗不能再次跳过或覆盖失败结果。面板没有单独的存档或解锁实现。

验证入口 `game/tests/player_flow_test.gd`（兼容入口，继承 chapter_flow_test），通过 GODOT_PATH 运行。加 `-- --capture` 并移除 headless 使用真实鼠标输入，截图及隔离存档输出到 `temp/chapter_one/`，不覆盖玩家存档。

选关列表和详情布局的针对性验证：`GODOT_PATH --headless --path . --script res://game/tests/level_selection_test.gd`。

模式和存档隔离验证：运行 `game/tests/developer_mode_test.gd`，分别不带参数及带 `-- --developer-mode` 执行。
