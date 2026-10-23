# 职业图标

atlas.png 是 Human/StarterContent/icon/class-atlas-01.png 的正式运行时副本，4×4网格，1254×1254像素，每格313.5像素。以AtlasTexture切片，保留原素材。

| 资源 | 职业 | 图形 | 行/列（从1开始） |
| --- | --- | --- | --- |
| guard.tres | 近卫 | 交叉双剑 | 1/4 |
| tank.tres | 重装 | 盾牌 | 2/1 |
| sniper.tres | 射手 | 弓箭 | 2/3 |
| caster.tres | 术师 | 法杖 | 3/1 |
| medic.tres | 医疗 | 医疗十字 | 3/4 |

各角色appearance.tres通过class_icon引用图标。HUD只接收外观资源，不按战斗role推算职业，不直接引用content或Human路径。
