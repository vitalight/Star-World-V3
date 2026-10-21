# Art Test

从开发者首页进入 Art Test，再选择 Character、Effect 或 Battle Scene。四个 `.tscn` 均可独立 F6 运行，顶部提供返回首页和目录按钮。离开场景销毁其表现节点，停止动画与脉冲。

- Character：分别独查我方或敌方、双方对照；下拉选择正背面待机、攻击及两姿态循环；播放、暂停和单步。当前内容 ID 与动作始终显示。
- Effect：金色斩击，可循环或单次重播、静态检查原图、切换程序脉冲。
- Battle Scene：10 × 5 地块、双方单位、示例斩击、静态状态面板。没有移动、伤害、部署或波次计算。

## 素材检查与内容登记

已直接查看 StarterContent 全部七张 PNG（均为 1254 × 1254），以及 Human/ArtReference.jpg。每张图集按 4 × 4 网格，单元格为 313.5 × 313.5；AtlasTexture 使用浮点区域，保留源图边界，不重新采样原图。原始文件不覆盖。

| 内容 ID | 原始输入 | 本轮使用区域 |
| --- | --- | --- |
| character_001 | character/hero-atlas-01.png | 第 1 行四姿态，赤刃我方 |
| character_002 | character/enemy-atlas-01.png | 第 1 行四姿态，斥候敌方 |
| effect_001 | effects/effect-atlas-01.png | 第 1 行第 1 格，金色斩击 |
| terrain_001 | texture/texture-atlas-01.png | 浅色道路、草地及部署平台 |
| scene_001 | 上述地形组合 | 荒原哨站，field.tscn 提供具体地形实例 |

两方共用 character 类型编号序列，不因阵营另起编号。effect 使用相同 type_001 规则。content 内 atlas 是原图的正式内容副本，frames.tres / texture.tres 定义切片；没有运行时引用 Human 路径。

## 实际动画与限制

角色图集每行依次为正面待机、背面待机、正面攻击、背面攻击，行之间是不同人物。没有可信的连续行走、受击、死亡动画序列。提供的 front_preview / back_preview 为工具中明确标注的待机和攻击二姿态交替（2 FPS），四个独立姿态为静态检查，不将不同人物混成动画。

特效图集是八类效果的小型与大型变体，不是按格排列的连续时间帧。本轮仅展示金色斩击原图与程序缩放淡出。透明边缘存在原素材的彩色杂边，内容副本保留原貌供检查。英雄与敌人阴影、地形高度和 UI 均为比例草案，等待正式方向评审。

features/actor_view 接收 SpriteFrames；effects 接收 Texture2D；battlefield_view 接收图集；battle_hud 接收静态文字。四个表现模块不依赖具体 content、devtools 或 battle。devtools 负责注入内容及展示操作。
