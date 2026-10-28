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
| levels.csv | 关卡显示、类型及对应的剧情文件或战斗地图和数值；不配置出战干员 |
| player_roster.csv | 初始干员、剧情完成后的加入／暂离／回归时点；玩家队伍的进度规则，与关卡定义分开 |
| waves.csv | 关卡 ID、出怪时刻、数量、间隔、敌人 ID、路线、显示波次 |
| backgrounds.csv | 剧情背景 ID 与正式贴图路径 |

CSV 用 Excel、LibreOffice 或文本编辑器打开，保存选择 **CSV UTF-8**。保留列名；逗号、双引号、多行正文遵循标准 CSV 引号规则。`.csv.import` 保持 `importer="keep"`，避免被导入为翻译。

角色等 ID 使用 `type_001` 格式，正式关卡使用 `scene_0101A` 格式，分配后不随姓名变化，不回收。关卡表行序是解锁顺序，关卡不保存出战队伍。`player_roster.csv` 每行一个干员 ID：join_after 留空表示初始获得，否则填写首次完成哪一关的胜利续接时加入；leave_after／return_after 同理表示暂离／回归。新干员和可用状态写入玩家存档；1-1B（scene_0101B）首次游玩、重打和重试均固定由大星、小黄出战，不改变存档中的队伍与暂离状态；其余关卡沿用当前可出战队伍。小黄在 scene_0101B 战后暂离，保留所有权；第一章尚未配置回归时点。攻击范围在 stats.range_cells 中以 Vector2i 数组编辑，朝右为基准并在运行时旋转；(0,0)、(1,0) 表示自身格与前方一格。role 是规则类型 melee/ranged/healer；先锋／特种仍使用 melee。时间单位为秒。

把某波 time 从112改为120，将该组首怪延后8秒。number 只用于显示，time 为绝对战斗时刻，包含路线预告规则。defend_duration=0 表示普通清怪关；大于0时必须计时结束、清完敌人且基地存活才能获胜。技能 cost_gain 成功释放时立即结算并受费用上限限制；initial_sp 不得超过 required；interval_multiplier=0.55 表示技能中攻击间隔为原来的55%。

## 修改剧情

每段明确填写背景与出场角色，角色对白填写说话人；不继承上一段。最多同时显示两名角色，actors 可以填写已注册的 character_NNN 或 enemy_NNN，姓名从对应 stats.display_name 解析。旁白的 `speaker:` 留空或省略。`> ` 开头的连续行组成一段多行正文；`---` 开始下一段。只支持线性剧情。`framing: left_close` 将背景左侧放大，`framing: wide` 或省略表示全景；不继承上一段。1-1 在空洞被提及前使用近景。环境叙述可不显示角色，单人动作只显示该角色；两人交谈或角色与怪物对峙、扑击时可以同时出场。怪物出现、围困和交战时必须配置对应 enemy_NNN，退场后显式移除；旁白不显示姓名。

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
speaker:
> 窗外的灯光突然熄灭。
```

开头标题仅用于预览；`speaker` 留空或省略表示旁白；填写时必须是出场角色 ID。所有正文，包括叙述动作，都写在 `> ` 后。

## 地图与新增关卡

用 Godot 打开对应 `map.tscn`：在 Terrain 的 TileMapLayer 刷图，在 Routes 下编辑 Path2D。格子64像素，格心偏移32；路径手柄为零，线段沿格子轴向。地形、部署类型、路线仍只来自地图，不在表格另存一份。地图设置 `external_level=true`，正式关卡／波次数值从 CSV 读取，单位从 .tres 读取。`tint` 调整该地图的地表配色。

第一章四张战斗地图和 Game Test 默认开发样例共用 `content/terrains/terrain_002` 城市地形。地图的 `terrain_atlas` 指定运行时 4×4 图集，`background_texture` 指定战场外围背景，`perimeter_style` 指定外围样式；选关预览和战斗读取同一配置。背景仅作装饰，不改变地图或路线，未指定时沿用原背景。城市 TileSet 的 R/H/G/W/B/D 分别配置外观、高度、部署与通行属性，不能仅凭贴图改变规则。

城市 TileSet 的 (1,3) 是不可部署高台（B）：浅色高台地面配黄黑警示边，保持高台高度；(2,3) 是不可部署地面（D），使用深色盖板并保持地面高度。两者均不可部署、不可通行，运行时分别使用 `atlas_blocked_v2.png` 第四行第四格与第三行第四格。1-1B 使用 6×4 地图，第一列下方三格采用不可部署高台；敌人从左上进入，沿地面前往右下目标。1-2B 保留原地图和波次，后续关卡玩法设计时再评估。

新增剧情关时，在独立目录（如 `scene_0101A`）添加同编号文件 `story_scene_0101A.md`，在 levels.csv 添加 type=story 的行，只填写 story，不填写地图和战斗数值。新增战斗关时，复制地图到独立目录（如 `scene_0101B`），在 levels.csv 添加 type=battle 的行并配置地图和战斗数值，在 waves.csv 添加至少一组波次；story 留空。行序决定解锁顺序。背景贴图在 backgrounds.csv 注册，不要引用 Human 或 temp。

初版外观对应：大星复用 character_001，阿五复用004，月月复用006，胡胡使用 hero-atlas-02 第2行的四姿态切片；小黄为本次制作的橘猫 SVG 占位。背景使用已整理的家中、街道及东方明珠手绘环境图。外观可以独立替换，不影响数值、存档或对白引用。

## 预览与验证

- Game Test：F3 调试窗的下拉框切换原开发样例及四关；“重新加载关卡”读取已保存 .tres、关卡／波次 CSV 和地图并重置战斗。
- Story Test：下拉框选择五个独立剧情关；“重新加载”读取已保存的角色／技能／外观资源、背景 CSV 和 MD。默认打开正式 1-1，不保留开发剧情样例。
- Player Mode：重新启动读取最新内容。战斗中不热更新；编辑后先在开发工具检查。
- 内容错误显示文件、字段与原因；CSV／MD 另附行号；地图诊断使用场景文件入口行和 geometry 字段，实际问题指明格子／路线。

在项目根目录用 `GODOT_PATH` 运行：

```powershell
$env:APPDATA = Join-Path $PWD 'temp/chapter_one/user'
& $env:GODOT_PATH --headless --path . --script res://game/tests/chapter_content_test.gd
& $env:GODOT_PATH --headless --path . --script res://game/tests/chapter_authoring_test.gd
& $env:GODOT_PATH --headless --path . --script res://game/tests/content_tools_test.gd
& $env:GODOT_PATH --path . --script res://game/tests/player_flow_test.gd -- --capture
```

首次运行前创建 `temp/chapter_one` 和 `temp/.gdignore`。最后一项使用真实窗口输入验证并保存截图。章节内容测试的地图、波次和回放使用 `game/tests/fixtures/chapter/` 与 `game/tests/chapter_fixture.gd` 中的固定夹具，不随正式关卡编辑变化；章节内容检查则检查当前正式关卡和路线是否合法，不限定具体布局。编辑正式关卡后仍需在 Game Test 实际检查。

`.tres` 通过资源索引显式关联，随资源一起导出；`export_presets.cfg` 另显式包含 CSV／MD。生成验证 PCK 时，把 `TEMP` 和 `TMP` 指向 `temp/chapter_one/export_tmp`，再运行 `--headless --export-pack "Windows Desktop" temp/chapter_one/chapter.pck`。编辑内容后需重新导出。既有三场战斗的历史回放约3分11秒、3分23秒和3分30秒；新增家中清理战斗后章节总时长需重新体验评估，阅读及部署时间因人而异。

## 第一章正式背景

剧情背景由 backgrounds.csv 注册，剧情关和战斗关各自拥有独立目录。第一章依次为 1-1A／B、1-2A／B、1-3A／B、1-4A／B 和剧情尾声 1-5A。小黄在 1-1B 胜利续接时暂离，阿五、胡胡加入；月月在 1-3B 胜利续接时加入。旧存档中的对应进度和队伍状态会迁移。

新增背景与精确生成 prompt、验收状态见根目录 `asset_todo.md`。当前演出支持静态背景切换和角色出入场，扑击、空洞闭合、仪器提示等连续事件暂以简短旁白表达；旁白姓名不显示，角色不烘焙进环境图。
## 剧情震动

每段可独立配置 `anim_screen_shake: true`（约0.55秒的衰减画面震动，背景与角色共同移动）和 `anim_actor_shake: character_011|character_012`（约0.36秒的衰减角色震动，只影响指定出场角色，也支持 enemy_NNN）。画面与角色抖动均为横向8次／秒、纵向6次／秒。允许同时配置；省略表示无效果，不继承上一段。对白、选择和继续按钮保持稳定。换段、结束、跳过会复位；重播重新触发；窗口缩放按新布局重新计算，不累积偏移。背景在画面震动期间略微扩展以防露边。

```md
---
background: background_001
actors:
speaker:
anim_screen_shake: true
> 空洞突然再次震动。

---
background: background_001
actors: character_011
speaker: character_011
anim_actor_shake: character_011
> 小黄！！
```

只在需要强调的异动、撞击或激动台词上配置，普通对话不震动。anim_actor_shake 的目标必须在同段 actors 中，不能重复；anim_screen_shake 只接受 true/false，内容加载时会诊断错误。

## 角色翻转与离场

- `anim_actor_flip: enemy_001`：约0.24秒横向收窄、转身再展开，只影响指定角色。
- `actor_mirror: enemy_001`：本段的最终镜像朝向。与 anim_actor_flip 同时设置时，角色从相反朝向转到该最终朝向；单独设置则直接保持该朝向。省略时双角色镜头默认左侧镜像、右侧原图朝向，单角色居中时默认镜像朝右；actor_mirror 令指定角色镜像，未列出的角色保留默认朝向，空列表不改变默认朝向。后续镜头需要保留朝向时也显式填写，避免继承造成重播差异。
- `anim_actor_exit_left: enemy_001|character_012`：先停顿0.3秒，再用约0.45秒向左移出并淡出。`anim_actor_exit_right` 用于向右离场；完成后隐藏。多个角色可同步离场，同一角色不能同时配置左右离场。下一段若仍应不在场，actors 应移除它们。

上述列表均只接受本段已出场、不重复的 ID，也支持角色与怪物组合，可与震动同时配置。切段、跳过和重播会重置位置、透明度、可见性和翻转进度，窗口缩放不会让已离场角色重新出现。

```md
---
background: background_001
actors: enemy_001|character_011
speaker:
anim_actor_flip: enemy_001
actor_mirror: enemy_001
> 怪物转向大星。

---
background: background_001
actors: enemy_001|character_012
speaker:
actor_mirror: enemy_001
anim_actor_exit_left: enemy_001|character_012
> 小黄扑向怪物。
```
