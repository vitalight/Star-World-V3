# 敌方外观登记

敌方资源按职责存放于 `content/enemies/<内容 ID>/`。character_008～character_010 从 characters 迁入，保留既有内容 ID，不重新编号。

| 内容 ID | Human/StarterContent/character 来源 | 行（从 1 起） |
| --- | --- | --- |
| character_008 | enemy-atlas-01.png | 2 |
| character_009 | enemy-atlas-01.png | 3 |
| character_010 | enemy-atlas-01.png | 4 |

pose.png 为对应行的正面待机切片，portrait.tres 引用同目录贴图。切片边界取原图尺寸的四分之一并四舍五入到像素，保留原有透明背景和杂色边缘；不包含战斗数值。

Game Test 集成另增 pose_0～pose_3.png 及 appearance.tres，分别为对应行的正／背面待机／攻击姿态，使用相同切片规则。content/data/enemy_008～010.tres 为独立样例战斗数据；character_008、009、010 分别绑定突击兵、远程兵、飞行敌人，飞行以游戏中的悬浮高度表现。原有 pose.png 与 portrait.tres 仍保留供 Art Test 使用。
# 第一章敌人

enemy_001～004 使用稳定敌人 ID 及独立 appearance 目录，分别复用 character_008／009／010／009 的四姿态。配置位于 content/data/enemy_NNN.tres，包含 stats 数值与 appearance 外观子资源；贴图仍引用原素材目录，在 content/data/actors.tres 注册；外观来源不决定是否远程／飞行。旧 character_008～010 样例资源保持原样。
