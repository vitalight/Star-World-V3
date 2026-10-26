# 内容加载接口

`content_catalog.gd` 位于 game：负责连接具体内容与 feature 协议。features 不读取 CSV、不认识任何章节或角色名。角色／敌人／技能源为 `.tres`，关卡／波次／背景源仍为 CSV。

- `reload(base=ROOT, data_base=DATA)`：重新读取 content/data/actors.tres 及全部依赖资源、关卡／波次／背景 CSV，返回公共错误。资源或表格错误会阻止组装；剧情错误保存在各关 diagnostics 中。
- `diagnostics(level_id)`：公共及该关剧情错误。
- `map_errors(level_id, map)`：加上地图几何和波次路线引用错误。
- `battle_operator_ids(level_id, operator_ids)`：1-1 固定返回大星、小黄；其余关卡沿用传入的当前队伍，未传列表时使用初始玩家队伍。不改变玩家持有或暂离状态。
- `configuration(level_id, map, operator_ids)`：将关卡环境／敌人／波次和解析后的出战干员列表组装成 Battle 字典。调用方先校验关卡与 `operator_errors(operator_ids)`；外观与技能图标使用同一出战规则。
- `appearances(level_id, operator_ids)`：提供当前玩家干员及本关敌人的 ID → ActorAppearance 映射。
- `skill_icons(level_id, operator_ids)`：提供当前玩家干员 ID → 技能图标映射。
- `story(path)`：解析线性 Markdown 为现有 StoryScript。背景／角色映射由 `story_textures()` 提供。

源文件编辑说明见 `content/campaign/README.md`。CSV 错误为 `path:line [field] reason`，行号按物理行计算；支持带引号的逗号、多行字段和 UTF-8 BOM。Resource 错误为 `path [field] reason`，指向资源和属性。重复／非法 ID、未注册技能、空引用、非法数值和缺失外观均阻止组装。资源使用 CACHE_MODE_IGNORE_DEEP 重载，外观映射也使用本次读取的资源；不会修改已创建战斗的配置。

`player_roster.csv` 定义新玩家初始干员及胜利续接时的加入／离队／回归事件。`campaign_progress.gd` 保存已获得干员与暂离状态；1-1 首次游玩和重打都固定为大星、小黄，其余关卡重打使用当前可出战干员，旧版本存档按已完成剧情迁移。已完成剧情的重播不重复发放干员或再次触发离队。
