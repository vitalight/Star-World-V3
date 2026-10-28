# 敌方外观登记

第一章共享 `enemy_001/atlas.png`，来自 `Human/StarterContent/character/enemy-atlas-101.png`。4×4 图集每格 256×256，四列分别为正／背面移动、正／背面攻击。移动列是单幅姿态。

| 配置 | 现有职责 | 行（从 1 起） | 美术身份 |
| --- | --- | --- | --- |
| content/data/enemy_001.tres | 基础近战 | 1 | 异常碎影 |
| content/data/enemy_002.tres | 疾行近战 | 2 | 裂隙疾犬 |
| content/data/enemy_003.tres | 重甲近战 | 4 | 裂甲卫士 |
| content/data/enemy_004.tres | 远程 | 3 | 节点投射者 |
| content/data/enemy_005.tres | 飞行 | 3 | 节点投射者（飞行变体） |
| content/data/enemy_006.tres | Boss | 4 | 裂甲卫士（Boss） |

保留现有 ID、显示名、数值、波次和战斗机制。每个正式配置内嵌 appearance，直接引用图集并设置 atlas_row，头像随第一列生成。

scene_001 历史样例 character_008／009／010 的 appearance.tres 和 portrait.tres 保留，依次使用第 2／3／4 行；飞行仍由样例规则与悬浮高度表现。旧独立 pose 切片已删除，正式与开发入口共享新图集。
