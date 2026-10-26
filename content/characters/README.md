# 角色外观登记

## 直接使用 4×4 图集

在 `content/data/character_NNN.tres` 的 `appearance` 子资源中设置 `atlas` 为整张图集，`atlas_row` 选择第 1～4 行（从上到下）。无需先导出单张 PNG，内部通过 `AtlasTexture` 按等分网格读取选中行，从左到右依次为 `idle_front_left`、`idle_back_left`、`attack_front_left`、`attack_back_left`。右向姿态继续由显示模块镜像。

设置图集后，`poses` 自动提供这四种姿态；未设置图集时沿用现有独立贴图配置。`portrait` 留空时使用选中行第一列，填写后使用指定头像。更换行时若希望头像跟随，应清空旧的 `portrait`。

正式资源将整张图集整理至 `content/characters/` 对应目录后引用；外部原件保留在 `Human/StarterContent/character/`。这里只配置引用和行号，不需要额外切图文件。

```ini
[ext_resource type="Texture2D" path="res://content/characters/character_001/atlas.png" id="atlas"]

; appearance 子资源内（保留原有 script、height、class_icon 等配置）
atlas = ExtResource("atlas")
atlas_row = 2
```

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

Game Test 当前使用 `content/data/character_001、003～006.tres`，每个文件内嵌 stats 与 appearance（含图集、行号、头像和职业图标区域），不再保存这些角色的独立 appearance.tres。旧 pose PNG 仅作为历史素材保留。上述“没有新增战斗数值配置”描述的是此前 Art Test 阶段。

character_008、character_009、character_010 的敌方外观已归入 `content/enemies/`，来源登记见 `../enemies/README.md`；内容 ID 保持不变。
# 第一章正式角色

正式角色均直接引用各自目录中的整张 `atlas.png`，选择第一行，不再引用独立姿态切片；头像随第一列待机姿态自动生成。

Art Test 的 Battle 页和 Game Test 使用 scene_001 的开发样例。其 character_001、003、004、005、006 外观依次引用下表 character_011～015 的图集第一行；样例数值、职业图标与旧素材文件保留。

| 内容 ID | 角色 | Human/StarterContent/character 来源 | 行 |
| --- | --- | --- | --- |
| character_011 | 大星 | hero-atlas-101.png | 1 |
| character_012 | 小黄 | hero-atlas-102.png | 1 |
| character_013 | 阿五 | hero-atlas-103.png | 1 |
| character_014 | 胡胡 | hero-atlas-104.png | 1 |
| character_015 | 月月 | hero-atlas-105.png | 1 |

角色配置集中在 content/data/character_NNN.tres，数值和外观分别是文件内的 stats／appearance 子资源，贴图引用素材目录；stats.skill_spec 引用 content/data/skill_NNN.tres。content/data/actors.tres 注册正式角色与技能，CSV 副本已移除。旧 ID 和开发样例保留。
