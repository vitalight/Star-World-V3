# 敌方外观登记

敌方资源按职责存放于 `content/enemies/<内容 ID>/`。character_008～character_010 从 characters 迁入，保留既有内容 ID，不重新编号。

| 内容 ID | Human/StarterContent/character 来源 | 行（从 1 起） |
| --- | --- | --- |
| character_008 | enemy-atlas-01.png | 2 |
| character_009 | enemy-atlas-01.png | 3 |
| character_010 | enemy-atlas-01.png | 4 |

pose.png 为对应行的正面待机切片，portrait.tres 引用同目录贴图。切片边界取原图尺寸的四分之一并四舍五入到像素，保留原有透明背景和杂色边缘；不包含战斗数值。
