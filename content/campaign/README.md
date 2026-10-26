# 第一章内容编辑

角色、敌人、技能的唯一来源已改为 Godot `.tres`，在 Inspector 中编辑。关卡、波次、背景继续使用本目录 UTF-8 CSV；对白使用各 scene 的 Markdown，地图使用 TileMap／Path2D。没有需要手动同步的角色／敌人／技能 CSV。

## 编辑角色、敌人与技能

| 入口 | 编辑内容 |
| --- | --- |
| `content/data/character_NNN.tres` | 展开 stats 修改姓名／战斗属性，展开 appearance 查看和替换贴图；identity 为身份，profession 为展示职业 |
| `content/data/enemy_NNN.tres` | 展开 stats 修改姓名、战斗属性、移速、远程范围及漏怪伤害；appearance 为外观 |
| `content/data/skill_NNN.tres` | 技能图标 icon、名称／说明、充能类型、初始 SP、需求、持续时间、攻击／治疗倍率、攻击间隔倍率与回费 |
| `content/data/actors.tres` | 正式角色／敌人／技能资源列表；显式注册用于校验、关联与导出 |

在 Godot 文件系统中打开资源，Inspector 可以展开和跳转到外部资源；贴图可直接查看／替换。每个角色／敌人各有一个 `.tres` 文件，stats 与 appearance 都是文件内子资源。保存该角色／敌人文件即可保存数值、四种姿态、头像、显示高度和职业图标配置；不再维护单独的 stats.tres 或 appearance.tres。贴图仍引用 content 下的素材文件。技能通过 stats 的 **skill_spec** 引用独立资源，可复用；技能图标在技能资源的 **icon** 编辑，角色 appearance 不再保存技能图标。完整动作与战斗效果仍在 Art Test／Game Test 预览。

例如：打开 `content/data/character_011.tres`，展开 stats，把 **display_name** 从“大星”改成新名字。保存该角色文件后重载，战斗名称和剧情说话人会一起更新；不要改 **content_id**。打开 `content/data/skill_001.tres`，把 **multiplier** 从1.8改为2.0，更新 **description** 中的百分比并保存，所有引用该技能的角色重载后生效。技能说明支持多行中文。

**保存角色／敌人文件及修改过的独立技能资源后再重载。** Game Test 的“重新加载关卡”和 Story Test 的“重新加载”会绕过资源依赖缓存，读取最新数值、技能与外观；当前进行中的战斗不会被磁盘修改自动改变。当前生命、SP、冷却等运行状态仍由 battle 持有，不写回作者资源。

添加角色／敌人：在 content/data 复制一个对应 `.tres` 文件，按新 ID 命名为 character_NNN.tres／enemy_NNN.tres，修改文件内 stats.content_id，按需替换 appearance，再拖入 actors.tres 的 characters／enemies 列表。添加技能：复制并命名为 skill_NNN.tres，修改 content_id，在 actors.tres 的 skills 中注册，再赋给角色 stats.skill_spec。不能只改复制文件的名字而保留旧 ID。新内容资源类型可从 Inspector 创建 ActorDefinition、ActorLibrary、SkillDefinition；角色 stats 与 appearance 保留为文件内子资源。现有开发样例和正式角色均使用 skill_spec；底层仍兼容外部旧 skill 字典。

## 修改关卡与波次表

| 文件 | 编辑内容 |
| --- | --- |
| levels.csv | 关卡显示、地图、基地生命、费用、在场上限、修复时长、战前／战后剧情；不配置出战干员 |
| player_roster.csv | 初始干员、剧情完成后的加入／暂离／回归时点；玩家队伍的进度规则，与关卡定义分开 |
| waves.csv | 关卡 ID、出怪时刻、数量、间隔、敌人 ID、路线、显示波次 |
| backgrounds.csv | 剧情背景 ID 与正式贴图路径 |

CSV 用 Excel、LibreOffice 或文本编辑器打开，保存选择 **CSV UTF-8**。保留列名；逗号、双引号、多行正文遵循标准 CSV 引号规则。`.csv.import` 保持 `importer="keep"`，避免被导入为翻译。

ID 使用 `type_001` 格式，分配后不随姓名变化，不回收。关卡表行序是解锁顺序，关卡不保存出战队伍。`player_roster.csv` 每行一个干员 ID：join_after 留空表示初始获得，否则填写首次完成哪一关战后剧情后加入；leave_after／return_after 同理表示暂离／回归。新干员和可用状态写入玩家存档；选关、重打和战斗重试不会回退到历史队伍。小黄在 scene_002 战后暂离，保留所有权；第一章尚未配置回归时点。攻击范围在 stats.range_cells 中以 Vector2i 数组编辑，朝右为基准并在运行时旋转；(0,0)、(1,0) 表示自身格与前方一格。role 是规则类型 melee/ranged/healer；先锋／特种仍使用 melee。时间单位为秒。

把某波 time 从112改为120，将该组首怪延后8秒。number 只用于显示，time 为绝对战斗时刻，包含路线预告规则。defend_duration=0 表示普通清怪关；大于0时必须计时结束、清完敌人且基地存活才能获胜。技能 cost_gain 成功释放时立即结算并受费用上限限制；initial_sp 不得超过 required；interval_multiplier=0.55 表示技能中攻击间隔为原来的55%。

## 修改剧情

每段都明确填写背景、出场角色和说话人，不继承上一段。最多同时显示两名角色，角色姓名从角色 stats.display_name 解析。旁白用 `narrator`。`> ` 开头的连续行组成一段多行正文；`---` 开始下一段。只支持线性剧情。

```md
# 家中异常 · 行动前

---
background: background_001
actors: character_011|character_012
speaker: character_011
> 小黄，跟紧我。
> 我们一起守住这里。

---
background: background_001
actors:
speaker: narrator
> 窗外的灯光突然熄灭。
```

开头标题仅用于预览；`speaker` 必须是出场角色 ID 或 narrator。所有正文，包括叙述动作，都写在 `> ` 后。

## 地图与新增关卡

用 Godot 打开对应 `map.tscn`：在 Terrain 的 TileMapLayer 刷图，在 Routes 下编辑 Path2D。格子64像素，格心偏移32；路径手柄为零，线段沿格子轴向。地形、部署类型、路线仍只来自地图，不在表格另存一份。地图设置 `external_level=true`，正式关卡／波次数值从 CSV 读取，单位从 .tres 读取。`tint` 调整该地图的地表配色。

新增关卡时：复制一份正式地图到未占用的 `scene_NNN` 目录，修改地形／路线，添加 before.md 与 after.md，再在 levels.csv 末尾新增一行、在 waves.csv 增加至少一组合法波次。无需增加 GDScript 分支。新增外观整理到对应角色／敌人 ID 目录，配置四种姿态、头像、职业图标，在 content/data 的角色／敌人文件中展开 appearance，设置四种姿态、头像、职业图标和显示高度。技能图标在 skill_NNN.tres 中配置。不要引用 Human 或 temp。

初版外观对应：大星复用 character_001，阿五复用004，月月复用006，胡胡使用 hero-atlas-02 第2行的四姿态切片；小黄为本次制作的橘猫 SVG 占位。背景为简化的家中、街道及东方明珠矢量场景。外观可以独立替换，不影响数值、存档或对白引用。

## 预览与验证

- Game Test：F3 调试窗的下拉框切换原开发样例及三关；“重新加载关卡”读取已保存 .tres、关卡／波次 CSV 和地图并重置战斗。
- Story Test：下拉框选择六段正式剧情；“重新加载”读取已保存的角色／技能／外观资源、背景 CSV 和 MD。原开发剧情样例保留。
- Player Mode：重新启动读取最新内容。战斗中不热更新；编辑后先在开发工具检查。
- 内容错误显示文件、字段与原因；CSV／MD 另附行号；地图诊断使用场景文件入口行和 geometry 字段，实际问题指明格子／路线。

在项目根目录用 `GODOT_PATH` 运行：

```powershell
$env:APPDATA = Join-Path $PWD 'temp/chapter_one/user'
& $env:GODOT_PATH --headless --path . --script res://game/tests/chapter_content_test.gd
& $env:GODOT_PATH --headless --path . --script res://game/tests/content_tools_test.gd
& $env:GODOT_PATH --path . --script res://game/tests/player_flow_test.gd -- --capture
```

首次运行前创建 `temp/chapter_one` 和 `temp/.gdignore`。最后一项使用真实窗口输入验证并保存截图。三关参考部署与技能命令在 `game/tests/chapter_fixture.gd`；它只在测试中使用，不控制正式游戏。

`.tres` 通过资源索引显式关联，随资源一起导出；`export_presets.cfg` 另显式包含 CSV／MD。生成验证 PCK 时，把 `TEMP` 和 `TMP` 指向 `temp/chapter_one/export_tmp`，再运行 `--headless --export-pack "Windows Desktop" temp/chapter_one/chapter.pck`。编辑内容后需重新导出。完整章节目标时长15—25分钟；已验证的战斗回放约3分11秒、3分23秒和3分30秒，阅读及部署时间因人而异。

## 第一章正式背景

`background_001～003` 依次绑定 scene_002～004 的 `background.png`，来源为 `Human/StarterContent/story/chapter01/` 的 home_anomaly_v1、roadside_rescue_v2、oriental_pearl_node_v2 PNG。旧占位 background.svg 已移除；剧情背景 ID 与对白引用保持稳定。
