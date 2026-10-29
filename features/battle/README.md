# Battle

`battle.gd` 是无场景依赖的 `RefCounted`。调用方拥有实例、提交命令、推进时间并读取状态；依赖仅限本模块与 Godot 内建类型。

## 接口

```gdscript
var battle = preload("res://features/battle/battle.gd").new(config)
battle.deploy(roster_id, cell, facing)
battle.start()
battle.advance(delta)
battle.snapshot()
battle.take_events()
battle.retreat(unit_id)
battle.activate_skill(unit_id)
battle.set_paused(true)
battle.step()
battle.reset()
```

- `deploy`、`retreat`、`activate_skill` 返回 `{ok, reason, id}`；只有部署成功时 `id` 为新实例 ID，其余为 -1。`facing` 的 0／1／2／3 依次为右／下／左／上。
- `deployment_check(roster_id, cell, facing)` 以相同规则只读检查，不扣费、不生成单位。
- 部署失败原因：`finished`、`unknown_unit`、`invalid_facing`、`redeploy_cooldown`、`wrong_terrain`、`already_deployed`、`occupied`、`deploy_limit`、`insufficient_cost`。
- `start()` 只接受准备态。`advance(delta)` 以 1/60 秒固定步长推进，忽略非正时间、暂停和终局，保留不足一帧的余量。`set_paused` 冻结模拟，暂停仍允许命令；`step()` 仅在暂停的运行态推进一帧。
- `reset()` 恢复同一配置的初始状态。`snapshot()`、`configuration()`、`find_unit()`、`find_enemy()` 返回深拷贝；`take_events()` 深拷贝并消费事件。
- `debug_finish_victory()` 仅接受 ready／running，立即置为 victory；不伪造击杀或推进时间。

## 配置

配置是受信任的开发输入，初始化会补齐默认值并断言基础约束。时间单位为秒，位置和距离单位为格。

| 字段 | 内容 |
| --- | --- |
| `terrain` | `Vector2i -> "ground" / "high"`；未列出的格子不可部署 |
| `routes` | 路线 ID -> `Array[Vector2]`，至少两个点，相邻点不重复 |
| `roster` | 编队 ID -> 干员定义；同一条目同时只能有一个实例 |
| `enemies` | 敌人模板 ID -> 敌人定义 |
| `waves` | `{time, count, interval, enemy, route, number?}`；time 为绝对战斗时间 |
| `life` / `initial_cost` / `cost_cap` / `cost_regen` / `deploy_limit` | 基地生命与费用规则；默认 3 / 30 / 99 / 1 / 8 |
| `route_warning_duration` | 出怪预告时长；原始字典默认 0，正式 Level 默认 2 秒 |
| `defend_duration` | 大于 0 时，清完全部波次和敌人后仍需守住该时长 |

双方公共数值默认：`max_hp=200, attack=20, defense=0, resistance=0, damage_type="physical", interval=1, windup=0.2`。

干员额外字段：`name`、`role`（melee／ranged／healer）、`cost`、`redeploy_time`、`block`、`anti_air`、`range`（朝右的格子偏移模板）、`passive`、`skill`。近战部署地面，其余部署高台；`passive=true` 时每三次有效普通攻击强化下一击。

敌人额外字段：`speed`、`ranged`、`range`（连续距离）、`flying`、`leak_damage`。飞行只改变受击资格和阻挡，仍沿配置路线前进。

`skill` 支持 `recovery`（auto／attack／hit）、`required`、`initial_sp`、`duration`、`multiplier`、`defense_multiplier`、`interval_multiplier`、`cost_gain`；倍率只在技能持续期间生效。`trigger` 为 manual（默认）或 automatic；自动技能充满后自行释放，持续期不充能。`duration=0` 为瞬发。`forward_range` 按朝向延伸最前列，`hit_count` 为每次攻击的独立伤害次数；后续命中在前一次命中后发射，目标死亡或消失时取消，整个连击只计一次攻击和充能，`heal_damage_reduction` 和 `heal_buff_duration` 指定治疗后附加的减伤及持续时间；重复治疗刷新效果。

## 状态与事件

快照包含 `phase / paused / time / life / cost / wave / spawned / killed / escaped / remaining / units / enemies / redeploy / route_warnings`；`phase` 为 ready／running／victory／defeat，有防守目标时另含 `objective`。`remaining` 包含未出生敌人，`route_warnings` 无预告时为空数组。

事件统一含 `type / time`，双方实例 ID 在同一次战斗内共用且单调递增：

| 事件 | 主要载荷 |
| --- | --- |
| deploy / retreat | source、roster_id；部署另含 cell／facing |
| spawn | source、template、route |
| attack_start | source、target、from、to、friendly |
| damage / heal | source、target、from、to、amount、damage_type、friendly、enhanced、attack_count |
| block / unblock | source 为阻挡干员，target 为敌人 |
| death | source；干员含 roster_id，敌人含 side="enemy" |
| skill_start / skill_end | source；开始含 duration |
| cost_gain | source、实际增加 amount |
| route_warning | id、route、wave、start、spawn_at、duration |
| miss | source |
| escape | source、剩余 life |
| finished | phase |

路线预告从首个出怪前 `route_warning_duration` 秒开始，首个实际出怪时刻为 `max(wave.time, route_warning_duration)`；同组后续敌人沿用 interval。伤害事件 amount 为公式计算结果，可大于剩余生命；治疗事件 amount 为实际恢复量。同一配置、同一命令时间表和同一步长得到一致状态与事件。

## 测试

模块测试见 [tests/README.md](tests/README.md)；集成与表现验证使用 Game Test。规则细节以测试和代码为准。
