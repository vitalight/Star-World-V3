# Battle 模块评审记录

- 模块：`features/battle/`，公共入口仍为 `battle.gd`。
- 日期：2026-10-21。
- 状态：本轮实现与验证完成，待独立评审；不代表已通过正式游戏集成评审。

## 本轮交付

从单种单位、单波攻击沙盒扩展为方舟式基础战斗模拟：地面/高台与四向格子范围、费用与上限、撤退和再部署、双方生命与攻击动作、近战阻挡和释放、敌方远程最新部署优先、对空、物理/法术/真实伤害、治疗、每四击强化、三种技力回复、主动持续强化、多路线波次及胜负。

Logic Test 提供6个专项关与1个综合关，共18个用例，支持预设命令回放、手动部署、暂停、单步、倍速、重置、独立规则结果与最近事件。综合关包含预设获胜、缺少对空、空场失败三个变体。

## 职责和依赖

- battle维护唯一玩法真相，不加载场景、美术、content或devtools。
- `config.gd`补齐受信任开发配置与基础约束；`navigation.gd`负责路径及阻挡；`combat.gd`负责索敌、动作、伤害治疗和技能；battle统一处理命令、时钟、波次、离场与胜负。
- devtools的配置、演示回放与观察检查只使用公共命令、快照及事件，不向内部状态写入。
- 快照、配置和公开ID查询返回深拷贝；事件消费也返回深拷贝。
- 公共部署接口由旧的槽位索引迁移为编队ID、格子和朝向；命令提供结构化失败原因。现有工作区与首页图形冒烟测试同步迁移。
- API和配置见 `features/battle/README.md`；结构化规则与场景说明现见 `features/battle/tests/README.md`。

## 验证证据

使用环境变量 `GODOT_PATH` 指向标准版 Godot 4.7.2，临时用户目录为 `temp/logic_test/`。各测试进程退出码均为0：

| 验证 | 结果 | 临时证据 |
| --- | --- | --- |
| battle模块自动测试 | 158项检查，0失败 | `temp/logic_test/battle.log` |
| Logic Test用例及生命周期集成测试 | 18个用例，98项检查，0失败 | `temp/logic_test/workspace.log` |
| 首页/工作区真实渲染与程序化鼠标输入回归 | 0失败 | `temp/logic_test/visual.log` |

核心测试覆盖部署拒绝与扣费、退款取整、再部署、快照隔离、生命与伤害、攻击动作与间隔、死亡清理、阻挡容量与抵达次序、高速移动不穿过阻挡、飞行与方向边界、剩余路线优先、自己的阻挡目标优先、最新部署优先与动作锁定、撤退/死亡落空、目标离开范围仍命中、治疗比例和并列规则、生命上限、被动换目标与空档、三种技力来源、主动技能不叠加与结束恢复、多波等待、路线转弯、漏怪胜负、终局冻结、固定步长及重置重放一致性。

工作区测试对18个预设逐项验收，并比较逐帧和大帧推进的结果；重复创建、切关、暂停、单步、重置、释放均通过。图形回归使用Godot实际渲染和鼠标输入管线部署近卫/射手/医疗，检查获胜和失败，并截图各专项组、综合关和800×650窄窗口。已查看综合关、远程关、窄窗口和滚动后的规则检查截图，未发现裁切导致的不可达内容。此记录不声称人工逐个操作Windows。

截图为 `temp/verification/logic_group_1.png` 至 `logic_group_7.png`，另有 `logic_running.png`、`logic_won.png`、`logic_lost.png`、`logic_rules.png`、`logic_narrow.png`、`logic_narrow_checks.png`。临时产物不纳入Git。

## 限制与后续集成

- 方舟式简化规则，不包含特殊职业、群攻、异常状态、位移、召唤物、复杂寻路或弹道。
- 配置是受信任开发数据，不提供面向玩家的编辑器和完整错误恢复。
- 同帧按稳定顺序结算，不提供同时伤害结算；固定步长和此顺序已写入接口文档。
- 每个用例到观察截止时间后停止，静止靶测试可能保持running＋paused；规则完成状态与战斗胜负分开。
- 未接入正式Game Test。独立评审通过后，由game/adapters将同一battle状态和事件关联正式表现。
- 本轮首次使用旧Mono可执行文件触发已有程序集访问/崩溃问题；最终全部验证改用项目约定的GODOT_PATH标准版，无项目解析或运行错误。导入时曾出现受限环境Safe save提示，最终核心、工作区与渲染测试日志均无该提示。

### 技能图标接入对应的规则扩展

新增可选 defense_multiplier 与 interval_multiplier，缺省均为1，旧配置行为保持不变。防御强化只影响物理伤害，保留最低伤害；攻速技能在起手时确定冷却，不短于前摇，结束后下一次起手恢复基础间隔。基础属性不被覆盖，充能、暂停、持续时间与重置继续复用原接口。UnitSpec 与配置归一化校验正倍率。

独立规则检查：battle_test 172 项通过，新增13项覆盖三种伤害类型下的防御强化与到期恢复、攻击次数、技能前后间隔及基础数值保留。跨模块五技能战斗验证纯逻辑与游戏快照一致且胜利，Logic Test 18 cases / 98 checks 与原关卡107项回归通过；本次扩展满足接入条件。日志 temp/verification/skill_battle.log、skill_integration.log、skill_logic_regression.log、skill_game_regression.log。

### Logic Test 界面退役与测试迁移

根据用户要求移除 Logic Test 页面、几何战场和开发者首页入口。原18个固定命令场景迁入 features/battle/tests/scenario_fixtures.gd，回放观察器迁入 scenario_replay.gd，驱动为 scenario_test.gd，均不加载Control／场景／美术。原98项中保留86项纯规则／确定性检查；12项旧界面生命周期检查随界面删除，暂停、单步、重置、胜负和离场释放继续由既有battle规则与Game Test集成／图形测试覆盖。

命令：GODOT_PATH --headless --path . --script res://features/battle/tests/scenario_test.gd。迁移后18用例／86检查通过，基础规则172项和游戏集成107项通过；日志 temp/verification/scenario_migration.log、logic_removed_rules.log、logic_removed_integration.log。前述 Logic Test 页面与旧路径记录为历史验收状态。
