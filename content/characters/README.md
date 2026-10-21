# 角色外观登记

编号为稳定内容 ID。本次新增的 pose.png 是原始图集指定行的正面待机切片，没有重画或合成动作；portrait.tres 同时可供角色立片和 HUD 头像使用。

| 内容 ID | Human/StarterContent/character 来源 | 行（从 1 起） |
| --- | --- | --- |
| character_001 | hero-atlas-01.png，沿用已有 atlas / frames / view | 1 |
| character_002 | enemy-atlas-01.png，沿用已有 atlas / frames / view | 1 |
| character_003 | hero-atlas-01.png | 2 |
| character_004 | hero-atlas-01.png | 3 |
| character_005 | hero-atlas-01.png | 4 |
| character_006 | hero-atlas-02.png | 1 |
| character_007 | hero-atlas-02.png | 2 |

切片使用原图尺寸除以 4，边界四舍五入到像素；保留源图透明背景及原有杂色边缘。没有新增战斗数值配置。

character_008、character_009、character_010 的敌方外观已归入 `content/enemies/`，来源登记见 `../enemies/README.md`；内容 ID 保持不变。
