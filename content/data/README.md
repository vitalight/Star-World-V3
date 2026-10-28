# 游戏配置数据

第一章的 skill_001～005 各自使用 `content/data/skill_NNN.tres`，类型为 SkillDefinition（继承纯规则 BattleSkillSpec，并增加 icon）。直接在 Godot Inspector 编辑图标、名称、说明、充能和效果数值；说明支持多行文本。

在 `content/data/actors.tres` 的 skills 数组注册独立技能，再将资源赋给角色文件内 stats 的 skill_spec。多个角色可以引用同一技能；修改后所有引用者在重载时生效。content_id 保持稳定，显示名称可自由修改。

技能资源同时保存规则和 icon，图标不属于角色外观。向 battle 导出的配置只包含规则，不包含贴图；当前 SP 和持续时间仍由 battle 维护。skill_006～010 保留原开发样例的技能行为与图标，通过样例 stats 直接引用，不加入第一章列表。详细操作见 `content/campaign/README.md`。

正式角色使用 character_NNN.tres，敌人使用 enemy_NNN.tres；两者的 stats 与 appearance 都是文件内子资源，可在同一 Inspector 入口编辑。贴图等素材仍留在 content/characters、content/enemies；无需单独的外观配置文件。关卡／波次／背景表保留在 content/campaign。第一章敌人使用 enemy_001～006：enemy_005 为飞行敌人（stats.flying），只受 anti_air 干员攻击，波次需配置到带 `flying` Metadata 的路线；enemy_006 为根节点 Boss。scene_001 的 character_001／003～006 也各用一个 ActorDefinition 文件，内嵌 stats 和 appearance；关卡不引用这些角色；test_roster.tres 保留给 Art Test 和固定数值测试；Game Test 的 game_test_roster.tres 引用正式角色文件。正式玩家的干员 ID 与暂离状态保存在玩家存档。enemy_008～010 暂保留 UnitSpec 格式；其技能引用本目录的 skill_006～010.tres。旧敌人样例的内容 ID 仍保留 character_008～010，避免改变原样例标识。
