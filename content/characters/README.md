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

Game Test 集成补充：character_001、003、004、005、006 增加 pose_0～pose_3.png（同一行的正面待机、背面待机、正面攻击、背面攻击），边界仍按四分之一尺寸四舍五入。appearance.tres 关联四种姿态、既有头像和显示高度；stats.tres 单独保存近卫、重装、射手、术师、医疗数值，不引用美术。上述“没有新增战斗数值配置”描述的是此前 Art Test 阶段。

character_008、character_009、character_010 的敌方外观已归入 `content/enemies/`，来源登记见 `../enemies/README.md`；内容 ID 保持不变。
# 第一章正式角色

character_011 大星复用001；character_012 小黄为猫形 SVG 占位；character_013 阿五复用004；character_014 胡胡使用 hero-atlas-02 第2行的四姿态正式切片；character_015 月月复用006。新角色各有独立 appearance，数值仅在 content/campaign/characters.csv；技能仅在 skills.csv。旧 ID 和样例 stats 保留。
