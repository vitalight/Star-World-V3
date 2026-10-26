# 角色外观登记

正式原件位于 `Human/StarterContent/character/`，运行贴图整理至本目录。4×4 图集每格 256×256；四列依次为正面待机、背面待机、正面攻击、背面攻击。右向由显示模块镜像，头像默认取对应行第一列。

| 正式 ID | 角色 | 原件 | 行（从 1 起） | 运行贴图 |
| --- | --- | --- | --- | --- |
| character_011 | 大星 | hero-atlas-101-v2.png | 1 | character_011/atlas.png |
| character_012 | 小黄 | hero-atlas-101-v2.png | 2 | character_011/atlas.png |
| character_013 | 阿五 | hero-atlas-101-v2.png | 3 | character_011/atlas.png |
| character_014 | 胡胡 | hero-atlas-101-v2.png | 4 | character_011/atlas.png |
| character_015 | 月月 | hero-atlas-102-v2.png | 1 | character_015/atlas.png |

同图集角色共享贴图，不重复复制。配置在 `content/data/character_NNN.tres`，stats 与 appearance 分别保存数值和外观。此次替换保持数值、技能、队伍规则和内容 ID。

scene_001 开发样例 character_001、003～006 依次使用上述五名角色相同的图集与行号。旧 portrait.tres、frames.tres、view.tscn 入口保留并改用正式图集：character_001 为大星、003 为小黄、004 为阿五、005 为胡胡、006 为月月、007 为 Tiger（102-v2 第 2 行）。character_002 为敌方历史样例，使用 enemy-atlas-101 第 1 行。旧独立 pose PNG／SVG 与重复旧图集已删除。

其余输入由 Art Test 展示全部行，新增角色的战斗配置与解锁规则仍按剧情需要另行配置。
