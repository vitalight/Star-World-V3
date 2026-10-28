# 第一章内容编辑

角色、敌人、技能使用 Godot `.tres`；关卡、波次、背景使用 UTF-8 CSV；对白使用场景目录下的 Markdown；地图使用 TileMap／Path2D。本目录是关卡与波次的唯一来源，不维护角色／敌人／技能 CSV。

## 角色、敌人与技能

- `content/data/character_NNN.tres`、`enemy_NNN.tres`：stats 保存姓名与战斗数值，appearance 保存贴图、头像、显示高度与职业图标；两者均为文件内子资源。
- `content/data/skill_NNN.tres`：技能规则与图标；角色通过 `stats.skill_spec` 引用，可复用。
- `content/data/actors.tres`：显式注册正式角色、敌人与技能；内容加载、关联与导出都以此为准。
- `content_id` 使用 `type_NNN`，分配后保持稳定；不要只改文件名而保留旧 ID。
- 新增角色／敌人时复制同类 `.tres`，修改文件名与 `content_id`，替换 appearance，再加入 `actors.tres` 对应列表。新增技能同样命名 `skill_NNN.tres`，注册后再赋给角色。
- 保存资源后在 Game Test／Story Test 中重新加载。运行中的生命、SP、冷却由 battle 持有，不写回资源。

## 关卡、波次与背景

| 文件 | 内容 |
| --- | --- |
| levels.csv | 关卡显示、类型及对应的剧情文件或战斗地图和数值；不配置出战干员 |
| waves.csv | 关卡 ID、出怪时刻、数量、间隔、敌人 ID、路线、显示波次 |
| player_roster.csv | 初始干员与剧情完成后的加入／暂离／回归时点 |
| backgrounds.csv | 剧情背景 ID 与正式贴图路径 |

CSV 保存为 UTF-8（Excel 选择 CSV UTF-8），保留列名；`.csv.import` 保持 `importer="keep"`。

- 正式关卡 ID 使用 `scene_0101A` 格式；levels.csv 行序即解锁顺序，关卡不保存出战队伍。
- `type=story` 只填写 story；`type=battle` 填写 map 与战斗数值，story 留空。
- `waves.csv` 的 `time` 为绝对战斗时刻（秒），`number` 只用于显示，`interval` 为同组出怪间隔；每关至少一组波次。
- `defend_duration=0` 表示普通清怪关；大于 0 时需计时结束、清空敌人并守住基地才能获胜。
- backgrounds.csv 只登记正式贴图，不要引用 Human 或 temp。

## 玩家队伍

`player_roster.csv` 每行一个干员：`join_after` 留空表示初始可用，否则填写首次完成该关后续接时加入；`leave_after`／`return_after` 表示暂离与回归。1-1B（scene_0101B）固定由大星、小黄出战；其余关卡沿用存档中当前可用队伍。

角色 `stats.range_cells` 以朝右为基准，运行时按朝向旋转；`role` 为 melee／ranged／healer。

## 剧情 Markdown

每段以 `---` 开始，字段不继承上一段。

- `background:`：背景 ID。
- `actors:`：本段出场角色／敌人，使用 `|` 分隔，最多两名。
- `speaker:`：说话人 ID；留空或省略表示旁白，填写时必须是本段出场角色。
- `framing:`：`wide` 或 `left_close`。
- 以 `> ` 开头的连续行组成一段正文，可多行；只支持线性剧情。
- 怪物出现、围困和交战时配置对应 `enemy_NNN`，退场后显式移除。

演出字段：

- `anim_screen_shake: true`：画面震动。
- `anim_actor_shake:`、`anim_actor_flip:`、`anim_actor_exit_left:`／`anim_actor_exit_right:`：只影响指定出场角色／敌人。
- `actor_mirror:`：本段最终镜像朝向；需要保留朝向时显式填写。

上述列表只接受本段已出场且不重复的 ID，可与震动同时配置。换段、跳过和重播会复位。

## 地图与路线

- 地图 `map.tscn` 中，`Terrain` 为 TileMapLayer，`Routes` 下每个 Path2D 即一条路线，节点名为路线 ID。
- 格子 64 像素，格心为 `(32 + 64*x, 32 + 64*y)`。控制点对齐格心，线段沿横／纵轴，曲线的入／出手柄保持为零。首点为出生点，末点为基地。
- 地图设置 `external_level=true`，数值从 CSV 读取；`terrain_atlas`、`background_texture`、`perimeter_style`、`tint` 控制外观，背景不影响规则。
- TileSet 自定义数据：`appearance` 为 R／H／G／W／B／D，另有 `height`、`deployment`（ground／high／none）和 `walkable`。地形规则只来自 TileSet，不能仅靠贴图改变。
- 普通路线必须全程经过可通行地面（R）。飞行路线在 Path2D 的 Metadata 中添加布尔键 `flying = true`，可越过非通行地形，出生点可放在高台；普通敌人使用飞行路线会被内容诊断拒绝。波次按敌人类型选择地面或飞行路线。

## 新增内容

- 新剧情关：创建独立目录 `scene_XXXXA/` 与同编号 `story_scene_XXXXA.md`，在 levels.csv 添加 `type=story` 行。
- 新战斗关：创建独立目录 `scene_XXXXB/`（同一关卡可继续使用 C 等后缀）与 `map.tscn`，在 levels.csv 添加 `type=battle` 行并配置地图和数值，在 waves.csv 添加至少一组波次。
- ID 分配后不复用；行序决定解锁顺序。正式资源只放在 `content/`，不要引用 Human 或 temp。

## 预览与验证

- Game Test：F3 切换开发样例与正式关卡；章节关卡使用完整干员列表。“重新加载关卡”读取保存的 `.tres`、CSV 和地图。
- Story Test：选择剧情关后“重新加载”。
- Player Mode：重新启动读取最新内容；战斗中不热更新。
- 编辑正式关卡后必须在 Game Test 实际检查。内容错误会显示文件、字段与行号；地图诊断会指明格子或路线。

在项目根目录使用 `GODOT_PATH` 运行（首次先创建 `temp/chapter_one` 和 `temp/.gdignore`）：

```powershell
$env:APPDATA = Join-Path $PWD 'temp/chapter_one/user'
& $env:GODOT_PATH --headless --path . --script res://game/tests/chapter_authoring_test.gd
& $env:GODOT_PATH --headless --path . --script res://game/tests/chapter_content_test.gd
& $env:GODOT_PATH --headless --path . --script res://game/tests/content_tools_test.gd
& $env:GODOT_PATH --path . --script res://game/tests/player_flow_test.gd -- --capture
```

- `chapter_content_test` 使用 `game/tests/fixtures/chapter/` 的固定夹具回放，不随正式关卡变化；`chapter_authoring_test` 校验当前正式内容。最后一项使用真实窗口输入。
- `.tres` 随资源索引导出；CSV／MD 由 `export_presets.cfg` 显式包含。编辑内容后需重新导出验证。
