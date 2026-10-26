# 职业图标

atlas.png 是 Human/StarterContent/icon/class-atlas-01.png 的正式运行时副本，4×4网格，1254×1254像素，每格313.5像素。所有职业均通过角色外观配置内嵌的 AtlasTexture 直接读取此图集的区域，不使用独立图标 `.tres` 或切图图片。在角色 appearance 的 class_icon 中编辑 Atlas / Region 即可选择图集区域。

| 标识 | 职业 | 图形 | 行/列（从1开始） |
| --- | --- | --- | --- |
| guard | 近卫 | 交叉双剑 | 1/4 |
| tank | 重装 | 盾牌 | 2/1 |
| sniper | 射手 | 弓箭 | 2/3 |
| caster | 术师 | 法杖 | 3/1 |
| medic | 医疗 | 医疗十字 | 3/4 |
| specialist | 特种 | 三向飞刃 | 4/4 |
| vanguard | 先锋 | 向上长矛与双折线 | 1/2 |

各角色appearance.tres通过class_icon引用图标。HUD只接收外观资源，不按战斗role推算职业，不直接引用content或Human路径。
