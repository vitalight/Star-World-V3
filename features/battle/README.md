# Battle 公共接口与配置

`battle.gd` 是无场景依赖的 `RefCounted`。调用方拥有实例、显式提交命令、推进时间、读取状态。依赖仅限本模块与 Godot 内建类型。

## 调用接口

```gdscript
var battle = preload("res://features/battle/battle.gd").new(config)
var result = battle.deploy("guard", Vector2i(6, 3), 2)
battle.start()
battle.advance(1.0 / 60.0)
var state = battle.snapshot()
var events = battle.take_events()
battle.activate_skill(result.id)
battle.retreat(result.id)
battle.set_paused(true)
battle.step()
battle.reset()
```

- `deploy(roster_id: String, cell: Vector2i, facing: int = 0)`、`retreat(unit_id: int)`、`activate_skill(unit_id: int)` 返回 `{ok: bool, reason: String, id: int}`；仅部署成功时 `id` 为新实例ID，其余为-1。拒绝命令不改变费用及战斗状态。
- `deployment_check(roster_id, cell, facing=0)` 以同一规则只读检查部署，返回同结构结果，成功 id 仍为 -1；不扣费、不生成单位、不发事件。正式 deploy 也调用该校验，供界面精确预览可部署格。
- 部署失败原因包括 `finished`、`unknown_unit`、`invalid_facing`、`redeploy_cooldown`、`wrong_terrain`、`already_deployed`、`occupied`、`deploy_limit`、`insufficient_cost`。多项同时非法时只报告一项，不保证所有失败原因的优先级。
- 技能还可能返回 `not_running`、`skill_active`、`no_skill`、`insufficient_sp`。
- `start() -> bool` 只接受准备态。准备态允许部署和撤退，但不推进费用和再部署时间。
- `advance(delta)` 以1/60秒固定步长推进，忽略非正时间、暂停和终局。保留不足一帧的余量。`set_paused(bool)` 冻结模拟时钟；暂停仍允许玩家命令，`step()` 仅在暂停的运行态推进一帧，不消耗余量。
- `reset()` 恢复同一配置的全部初始状态，包括事件、ID、费用、波次、技能和计数。
- `snapshot()`、`configuration()`、`find_unit(id)`、`find_enemy(id)` 返回深拷贝，外部不能通过读取结果修改模拟。不存在的ID返回空字典。`take_events()` 深拷贝并消费事件。
- 原接口 `deploy(slot)` 和单种单位旧配置已迁移，调用方必须使用编队ID、格子和朝向。

## 配置

配置是受信任的开发输入，不提供运行时配置编辑器。初始化会补齐默认值，并断言基础约束。所有时间单位为秒，位置和距离单位为格，生命/伤害/费用/技力使用浮点。

| 字段 | 内容 |
| --- | --- |
| `terrain` | `Vector2i -> "ground" / "high"`；未列出的格子不可部署 |
| `routes` | 路线字符串ID -> `Array[Vector2]`，至少两个点，相邻点不重复 |
| `roster` | 编队字符串ID -> 干员定义；同一条目同时只能有一个实例 |
| `enemies` | 敌人模板字符串ID -> 敌人定义 |
| `waves` | `{time, count, interval, enemy, route, number?}` 数组；time为绝对战斗时间，count正整数，interval正数 |
| `life` | 初始基地生命，默认3，必须大于零 |
| `initial_cost / cost_cap / cost_regen` | 默认30 / 99 / 每秒1；初始费用不能大于上限 |
| `deploy_limit` | 在场干员上限，默认8 |

双方公共数值默认：`max_hp=200, attack=20, defense=0, resistance=0, damage_type="physical", interval=1, windup=0.2`。伤害类型为 `physical / arts / true`；要求生命和间隔为正、攻击非负、`0 ≤ windup ≤ interval`。

干员额外字段：

- `name` 默认编队ID；`role="melee" / "ranged" / "healer"`，默认近战。近战地面，其余高台；`terrain` 如果显式提供必须符合职业。
- `cost=10, redeploy_time=5`；`block` 默认近战1，其余0；`anti_air=false`。
- `range` 为朝右的格子偏移模板，默认 `[Vector2i.ZERO, Vector2i.RIGHT]`；运行快照包含旋转后的 `range_cells` 供显示层直接使用。
- `passive=false, passive_multiplier=2`；启用后三次普通有效攻击后下一次强化。
- `skill={enabled:false, recovery:"auto", required:5, initial_sp:0, duration:3, multiplier:2}`；recovery支持 `auto / attack / hit`，初始技力裁剪至合法区间。

敌人额外字段：`speed=1, ranged=false, range=3, flying=false, leak_damage=1`。`range` 为连续距离。飞行只改变受击资格和阻挡；默认仍沿配置路线前进，不自动攻击干员，除非启用ranged。

具体规则、18个命令回放场景与无界面运行方式见 `tests/README.md`。测试配置仅存放于 tests，正式模块不加载它。手动验证使用 Game Test。

## 状态与事件

快照包含 `phase / paused / time / life / cost / wave / spawned / killed / escaped / remaining / units / enemies / redeploy`。`remaining` 包括未出生敌人。units包含编队ID、实例ID、部署顺序、位置朝向、生命、冷却、当前action与target、阻挡列表、有效攻击累计数、技力及技能剩余时间。enemies包含路线进度、生命、阻挡者、攻击动作与目标。

事件统一含 `type / time`，实例ID在同一次战斗内双方共用且单调递增：

| 事件 | 主要载荷 |
| --- | --- |
| deploy / retreat | source、roster_id；部署另含cell/facing |
| spawn | source、template、route |
| attack_start | source、target、from、to、friendly |
| damage / heal | source、target、from、to、amount、damage_type、friendly、enhanced、attack_count |
| block / unblock | source为阻挡干员，target为敌人 |
| death | source；干员含roster_id，敌人含side="enemy" |
| skill_start / skill_end | source；开始含duration |
| miss | source；表示原锁定目标在命中前离场 |
| escape | source、剩余life |
| finished | phase |

伤害事件amount为公式计算的伤害，可大于剩余生命；生命下限为零。治疗事件amount为实际恢复量。`attack_count` 是有效攻击总数，强化周期由其模4计算。

同一配置、同一命令时间表和同一步长数得到一致状态与事件。到期出怪按time排序，同一时间按配置顺序；同帧角色按稳定插入顺序执行。每帧依次推进时钟与出怪、技能/攻击冷却、敌方攻击动作、移动与阻挡、我方攻击动作、离场清理、胜负。不同帧分片不改变模拟；命令必须在相同模拟时刻提交。

模块专属自动测试：`tests/battle_test.gd`。Game Test 集成仍需独立模块评审。

`unit_spec.gd`、`wave_spec.gd`、`level_spec.gd` 是 Inspector 可编辑的纯数据 Resource，输出上述同一份字典协议；battle 本身仍不加载场景和这些具体资源。地图采集、输入与表现适配位于对应表现 feature 和 game，不改动模拟规则。


## 路线预告与生成时序

配置 `route_warning_duration` 为预告时长；原始字典未提供时默认 0 保持既有纯规则用例，正式 Level Resource 默认 2 秒，scene_001 明确设为 2。

每个波次 Resource 是一组出怪：首个实际出怪时刻为 `max(wave.time, route_warning_duration)`，预告从首个出怪前 `route_warning_duration` 秒开始。同组后续敌人沿用 interval，不重复预告。开始时到期的预告在 `start()` 立即进入快照；后续预告与生成都由固定步长推进，暂停冻结，单步推进。多条路线可同时预告。

快照 `route_warnings` 保存当前预告字典数组：id、route、wave、start、spawn_at、duration。事件 `route_warning` 在开始预告时发出一次；`spawn` 仅在完整预告结束后发出。结束、重置清理当前预告。该时序属于 battle，表现层不能延迟或直接生成敌人。

## 技能倍率

skill 可提供 name、description（显示文案）、multiplier（攻击／治疗倍率，默认2）、defense_multiplier（物理防御倍率，默认1）、interval_multiplier（攻击间隔倍率，默认1）。三种倍率必须大于零，只在 skill_left > 0 时读取；不修改基础属性。防御倍率只影响物理伤害，保留5%最低伤害；间隔最短为原攻击前摇。当前一次攻击使用起手时确定的冷却间隔，到期后下一次起手使用基础间隔。其余充能、持续时间、暂停、撤退和再部署规则保持原协议。

## 回费与防守目标

`skill.cost_gain` 默认0，必须非负。技能成功释放时立即增加费用，受 cost_cap 限制；事件 `cost_gain` 包含 source 和实际增加 amount，仅在实际增加大于0时发出。重复／非法释放不结算费用。可在暂停时执行合法技能命令，和既有技能规则一致。

配置 `defend_duration` 默认为0，LevelSpec 也可编辑。大于0时，清完全部波次仍需等待该模拟时间，基地存活才胜利；完成计时不会跳过尚未处理的敌人。snapshot 此时额外包含 `objective: {duration, elapsed}`，elapsed 上限为 duration。准备态、暂停和终局不推进；单步推进一帧，reset归零。没有防守目标的旧配置不增加 objective 快照字段。

验证：`features/battle/tests/campaign_rules_test.gd`；章节数值加载与流程属于 game，不由 battle 读取 CSV 或具体角色路径。

## 开发者跳过

`debug_finish_victory() -> bool` 是显式开发命令：仅接受 ready／running（包括暂停态），立即置为 victory，清除路线预告，发出一次 `finished {phase:"victory", debug:true}`。不伪造击杀、不推进时间；终局拒绝再次执行，reset 恢复原配置。game/battle 的 `debug_victory()` 调用该接口后按正常 refresh／observed 通路更新表现和产品进度。UI 只发出请求，不直接改写战斗快照或存档。
