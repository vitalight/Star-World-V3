# 角色、敌人、技能 Resource 迁移评审

- 范围：第一章5名角色、4类敌人、5个技能从 CSV 迁移为 `.tres`；原角色／敌人／技能 CSV 及对应导入文件移除。关卡、波次、背景 CSV 和对白 Markdown 保留。稳定 ID、顺序解锁及存档格式不变。
- 模块：battle 新增纯规则 BattleSkillSpec，UnitSpec 通过 skill_spec 转换为原战斗字典。底层仍兼容旧 skill 字典，正式角色与开发样例均引用独立技能。features/content_definitions 定义 ActorDefinition、ActorLibrary 和继承规则字段并增加 icon 的 SkillDefinition，只依赖 battle／actor_view 的资源类型；规则与表现均不反向依赖编辑入口。纯战斗配置不包含纹理或动画。
- 编辑：content/data/character_NNN.tres、enemy_NNN.tres 是 Inspector 入口，包含唯一 stats 与 appearance 子资源，引用原素材目录中的贴图；技能使用同目录的 skill_NNN.tres。content/data/actors.tres 显式注册正式资源，供加载、校验和导出使用。未注册技能、重复／非法 ID、空引用、非法数值和缺失外观均阻止组装。
- 重载：content_catalog 保留已有调用接口，ResourceLoader.CACHE_MODE_IGNORE_DEEP 重读数值、技能与外观依赖；输出独立字典供 battle 持有。正式玩家选关、战场与 Story Test 都使用本次加载的外观映射。已创建战斗不会随磁盘修改改变。

## 验证

通过 GODOT_PATH 指向的 Godot 4.7.2，命令行与真实 OpenGL 窗口验证。输出位于 temp/actor_migration，窗口截图沿用 temp/chapter_one。

| 验证 | 结果 |
| --- | --- |
| 迁移前后全部三关的标准化战斗配置比较 | 0差异 |
| 内容、三关胜败回放、中文多行、资源保存／重载、错误诊断 | 62项，0失败 |
| 原战斗规则 | 172项，0失败 |
| 回费、修复目标与开发者胜利规则 | 18项，0失败 |
| 真实窗口玩家流程／剧情／解锁／存档 | 103项，0失败 |
| 真实窗口 Game Test／Story Test 切换、重载与样例兼容 | 20项，0失败 |
| 空目录运行导出 PCK | 三场战斗、六段剧情，0失败 |

日志：content_final.log、parity.log、battle.log、campaign.log、player.log、tools.log、export.log、packed_final.log。已查看正式剧情的小黄与大星显示、Game Test 第三关编队／修复 HUD 截图。导出扫描成功注册 BattleSkillSpec、ActorDefinition、ActorLibrary；仍有此前已记录的编辑器设置 Safe save 环境警告，实际导出包独立读取通过。

- 结论：通过实现自评与集成回归，正式游戏和开发工具复用同一资源加载实现。
- 编辑说明：content/campaign/README.md、features/content_definitions/README.md。
- 日期：2026-10-25。未修改用户的 Human/Human.md，不自动提交。

## 技能图标归属修正

SkillDefinition 在同一个 skill.tres 中编辑技能规则与 icon；ActorAppearance 移除 skill_icon 属性与全部相关引用。game/content 单独提供 skill_icons(level_id)，Game Test、Player Mode 和 Art Test 的公共 HUD 接收该映射。SkillDefinition.configuration() 继承纯规则导出，不把贴图交给 battle。共享技能同时共享图标，保存重载会读取新图标；缺失图标给出字段诊断。

第一章 skill_001～005 保持 ID 与原图标；原开发样例的五个技能转为 skill_006～010，保留其行为和图标。BattleSkillSpec 增加已有规则支持的 defense_multiplier，确保重装样例的防御技能保持一致。

2026-10-25 验证：内容／资源／三关胜败回放71项，真实窗口技能与正式编队59项，Art／Game表现一致85项，均0失败；新导出 PCK 在空目录加载三场战斗和六段剧情通过。输出位于 temp/skill_icons；技能界面截图位于 temp/verification/skill_formal_roster.png。编辑器导出仍有已记录的 Safe save 环境警告，实际包读取通过。

## 集中命名与内嵌外观

2026-10-26 更新：所有可部署角色（含 scene_001 开发样例）各自使用一个 ActorDefinition `.tres`，内嵌 stats、appearance 和职业图标区域。角色图集直接引用整张 PNG 并按行生成姿态，无需独立切图或图标 `.tres`。关卡不引用玩家角色；开发工作区注入独立 test_roster，正式游戏使用玩家存档中的当前可出战干员。加入、暂离和回归规则位于 player_roster.csv，小黄在被带走后保留所有权但不可出战；重打旧关保留当前队伍，重放已完成剧情不重复触发队伍事件。旧版进度存档迁移时根据已完成剧情还原队伍。

本次验证：玩家队伍与回放19项、整章原生流程103项、开发者胜利流程72项、战斗集成116项、内容与资源73项、开发工作区图集引用15项，全部通过。记录位于 temp/ 下的 player_roster_test、player_chapter_flow、player_developer_victory、actor_battle_integration、actor_chapter 和 devtools_atlas 日志。

按用户约定，角色、敌人、技能配置集中到 content/data，分别使用 character_NNN.tres、enemy_NNN.tres、skill_NNN.tres；扩展名统一为 Godot 的 `.tres`。正式5名角色／4类敌人的 stats 和 appearance 都内嵌在各自文件中，不再维护单独的 stats.tres／appearance.tres，贴图按原路径引用。共享技能及其 icon 保持独立。注册索引迁到 content/data/actors.tres。

scene_001 的样例数值也迁入 data，保持原 UnitSpec 格式与内容 ID；关卡引用已更新。样例外观保留以兼容原编辑预览；正式游戏继续由 catalog 传入内嵌外观。源文件重载验证新增角色文件内 appearance.height 的保存与读取。

2026-10-25：集中命名后内容71项、原生玩家流程103项、Game Test／Story Test 20项通过。内嵌外观后内容73项、实机技能59项、Game Test／Story Test 20项通过；最新 PCK 在空目录加载三场战斗和六段剧情通过。日志位于 temp/data_layout，最终记录为 content_inline.log、skills_inline.log、tools_inline.log、player_capture.log、packed_inline.log。无 capture 参数的原生窗口缩放测试曾有4项时序失败；按文档的 capture 模式等待渲染后重跑103项通过，未更改产品流程或放宽断言。
