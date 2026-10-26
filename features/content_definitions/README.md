# 内容资源定义

`actor_roster.gd` 表示玩家／开发预览的干员列表，使用 `actors` 字典引用完整角色定义，并导出数值、外观和技能图标。该列表独立于关卡；scene_001 不引用出战角色。Art Test 与 Game Test 使用外部注入的 `content/data/test_roster.tres` 作为开发玩家样例，正式游戏由玩家存档提供当前可出战 ID。battle 不反向依赖本模块。

`ActorDefinition` 是角色／敌人的 Inspector 编辑入口：引用 battle 的纯数值 `UnitSpec` 和 actor_view 的 `ActorAppearance`，另存身份与职业展示文案。`ActorLibrary` 显式注册角色、敌人与独立技能，供 game/content 校验和组装，也保证导出包通过资源引用包含依赖。

正式文件集中在 content/data，命名 character_NNN.tres、enemy_NNN.tres、skill_NNN.tres；ActorDefinition 的 stats 与 appearance 均保存为文件内子资源；贴图仍是独立素材，按原路径引用。资源索引为同目录的 actors.tres。

本模块只定义可复用的内容结构，不读取章节、不运行模拟、不加载具体 content，也不被 battle 或 actor_view 反向依赖。允许依赖：battle 的 UnitSpec／BattleSkillSpec 和 actor_view 的 ActorAppearance。content 使用这些类型创建实例；game 将其转换为战斗字典和外观映射。

`SkillDefinition` 继承 `features/battle/skill_spec.gd` 的规则字段，并在同一个技能编辑入口增加 icon。基础 BattleSkillSpec 不引用贴图，configuration() 只返回规则；game 单独向 HUD 注入技能图标映射。ActorAppearance 不再提供 skill_icon。资源仅保存作者配置，当前生命、费用、SP 等运行状态由 battle 持有。
