# 内容加载接口

`content_catalog.gd` 位于 game：负责连接具体内容与 feature 协议。features 不读取 CSV、不认识任何章节或角色名。

- `reload(base=ROOT)`：重新读取全部 CSV，返回公共错误。表格错误会阻止组装；剧情错误保存在各关 diagnostics 中。
- `diagnostics(level_id)`：公共及该关剧情错误。
- `map_errors(level_id, map)`：加上地图几何和波次路线引用错误。
- `configuration(level_id, map)`：输出 Battle 原字典协议，额外提供 defend_duration。调用方须先通过前两项校验。
- `appearances(level_id)`：提供 ID → ActorAppearance 映射，供 game/adapters 消费。
- `story(path)`：解析线性 Markdown 为现有 StoryScript。背景／角色映射由 `story_textures()` 提供。

源文件编辑说明见 `content/campaign/README.md`。错误为 `path:line [field] reason`。CSV 行号按物理行计算，支持带引号的逗号、多行字段和 UTF-8 BOM。
