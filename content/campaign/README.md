# 第一章内容编辑

正式来源是本目录的 UTF-8 CSV 和 `content/scenes/scene_002`～`scene_004` 的 Markdown／地图。无需先转换成 `.tres`；运行时由 `game/content/content_catalog.gd` 读取。CSV 可以用 Excel、LibreOffice 或文本编辑器打开，保存时选择 **CSV UTF-8**。保留列名；逗号、双引号、多行正文遵循标准 CSV 引号规则。Godot 的 `.csv.import` 保持 `importer="keep"`，避免把数值表导成翻译。

## 修改表格

| 文件 | 编辑内容 |
| --- | --- |
| characters.csv | 姓名、身份、职业、外观路径、战斗属性、费用、再部署、范围、技能 ID |
| skills.csv | 技能名称／说明、充能方式／需求／初始值、持续时间、攻击／治疗倍率、攻击间隔倍率、立即回费 |
| enemies.csv | 敌人名称、外观、生命、攻击、防御、移速、远程攻击与漏怪扣血 |
| levels.csv | 关卡显示、地图、固定编队、基地生命、费用、在场上限、修复时长、战前／战后剧情 |
| waves.csv | 关卡 ID、出怪时刻、数量、间隔、敌人 ID、路线、显示波次 |
| backgrounds.csv | 剧情背景 ID 与正式贴图路径 |

ID 使用 `type_001` 格式，分配后不随姓名变化，不回收。关卡表行序就是解锁顺序。`roster` 使用 `|` 分隔角色 ID。范围使用 `x:y|x:y`，朝右为基准，运行时旋转；`0:0|1:0` 表示自身格与前方一格。`role` 是规则类型 `melee/ranged/healer`，职业显示列 `class` 可以是中文；先锋／特种仍使用 melee。时间单位为秒。

例如：把大星的 `name` 改成新名字，战斗详情及剧情说话人会一起更新。把 `skill_001` 的 `multiplier` 从 `1.8` 改为 `2.0`，同时更新 `description` 中的百分比；说明文案由作者维护。把某波 `time` 从 `112` 改为 `120`，就将该组首怪延后8秒。`number` 只用于显示，不决定出怪顺序；`time` 为绝对战斗时刻，包含路线预告规则。

`defend_duration=0` 表示普通清怪关；大于0时必须等待计时结束并清完敌人，基地存活才能获胜。胡胡的 `cost_gain` 在技能成功释放时立即结算，受费用上限限制。`initial_sp` 不得超过 `required`；`interval_multiplier=0.55` 表示技能中攻击间隔为原来的55%。技能暂停期间仍可手动释放，与现有命令规则一致。

## 修改剧情

每段都明确填写背景、出场角色和说话人，不继承上一段。最多同时显示两名角色，角色姓名从角色表解析。旁白用 `narrator`。`> ` 开头的连续行组成一段多行正文；`---` 开始下一段。只支持线性剧情。

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

用 Godot 打开对应 `map.tscn`：在 Terrain 的 TileMapLayer 刷图，在 Routes 下编辑 Path2D。格子64像素，格心偏移32；路径手柄为零，线段沿格子轴向。地形、部署类型、路线仍只来自地图，不在表格另存一份。地图设置 `external_level=true`，正式数值从 CSV 读取。`tint` 调整该地图的地表配色。

新增关卡时：复制一份正式地图到未占用的 `scene_NNN` 目录，修改地形／路线，添加 before.md 与 after.md，再在 levels.csv 末尾新增一行、在 waves.csv 增加至少一组合法波次。无需增加 GDScript 分支。新增外观整理到对应角色／敌人 ID 目录，配置四种姿态、头像、职业图标和技能图标，再填写 appearance 路径。不要引用 Human 或 temp。

初版外观对应：大星复用 character_001，阿五复用004，月月复用006，胡胡使用 hero-atlas-02 第2行的四姿态切片；小黄为本次制作的橘猫 SVG 占位。背景为简化的家中、街道及东方明珠矢量场景。外观可以独立替换，不影响数值、存档或对白引用。

## 预览与验证

- Game Test：F3 调试窗的下拉框切换原开发样例及三关；“重新加载关卡”读取已保存 CSV 和地图并重置战斗。
- Story Test：下拉框选择六段正式剧情；“重新加载”读取已保存的 CSV／MD。原开发剧情样例保留。
- Player Mode：重新启动读取最新内容。战斗中不热更新；编辑后先在开发工具检查。
- 内容错误显示文件、行号、字段与原因；地图诊断使用场景文件入口行和 geometry 字段，实际问题指明格子／路线。

在项目根目录用 `GODOT_PATH` 运行：

```powershell
$env:APPDATA = Join-Path $PWD 'temp/chapter_one/user'
& $env:GODOT_PATH --headless --path . --script res://game/tests/chapter_content_test.gd
& $env:GODOT_PATH --headless --path . --script res://game/tests/content_tools_test.gd
& $env:GODOT_PATH --path . --script res://game/tests/player_flow_test.gd -- --capture
```

首次运行前创建 `temp/chapter_one` 和 `temp/.gdignore`。最后一项使用真实窗口输入验证并保存截图。三关参考部署与技能命令在 `game/tests/chapter_fixture.gd`；它只在测试中使用，不控制正式游戏。

`export_presets.cfg` 显式包含 CSV／MD。生成验证 PCK 时，把 `TEMP` 和 `TMP` 指向 `temp/chapter_one/export_tmp`，再运行 `--headless --export-pack "Windows Desktop" temp/chapter_one/chapter.pck`。编辑内容后需重新导出。完整章节目标时长15—25分钟；已验证的战斗回放约3分11秒、3分23秒和3分30秒，阅读及部署时间因人而异。
