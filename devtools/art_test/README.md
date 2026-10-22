# Art Test

从 Developer Hub 进入后默认打开 Character，固定提供 Character / Effect / Animation / Battle / Skill 五个 tab。顶部路径统一为 `Star World/Developer Hub/Art Test`，点击 Developer Hub 返回首页。首页及 Blueprint、Game Test、Story Test 复用相同路径组件。

- Character：全部 16 个角色按英雄、敌人、图集编号和行号排序。每列一个角色，依次显示正面待机、背面待机、正面攻击、背面攻击；水平滚动浏览，较矮窗口支持垂直滚动。来源与角色行号随列显示。
- Effect：两张特效图集全部 32 个静态切片，包括大小变体；卡片随窗口宽度换行，垂直滚动浏览，显示来源及行列。此页不播放动画。
- Animation：32 个角色方向预览（每个角色正背面各一项）与 32 个特效预览；默认循环播放，支持统一播放、暂停和重播。隐藏页面停止更新，返回后恢复原先播放／暂停状态；重播从开头开始并播放。
- Battle：16:9 自适应 3D 荒原哨站，10×6 地块、道路与高台、有受光层次的麦黄色草丛、岩石围墙、红蓝出入口、使用正式编队的 5 名干员和 3 类敌人模拟快照（开始先展示 2 秒路线预告，再出现敌人）；角色、血条、HUD、镜头与入口标记复用 Game Test 显示实现，已部署卡片按同一规则隐藏。没有移动、伤害、部署或波次计算。小窗口完整缩放战场并留边。

- Skill：仅展示16张技能图标、素材编号和图集行列位置，支持窄窗口换行与纵向滚动。

`art_workspace.tscn`、`character_preview.tscn` 默认 Character；`effect_preview.tscn`、`animation_preview.tscn`、`battle_preview.tscn`、`skill_preview.tscn` 分别直接打开对应 tab，均可独立 F6 运行。离开场景销毁其表现节点。

## 素材来源与切片

浏览目录在 `asset_catalog.gd`，开发预览直接引用 Human/StarterContent：角色 hero-atlas-01、hero-atlas-02、enemy-atlas-01、enemy-atlas-02；特效 effect-atlas-01、effect-atlas-02。每张按 4 × 4 网格切片，按实际图片尺寸除以四计算浮点区域（当前为 313.5 × 313.5），不重新采样或覆盖原图，也不为原始素材浏览批量分配正式内容 ID。

Battle 引用正式 content：关卡编队中的 character_001、003～006，敌人 character_008～010，以及 effect_001、terrain_001 和 scene_001。原有 ID 保持稳定；character_008～character_010 的敌方资源存放于 `content/enemies/`，其余沿用原目录。来源登记见 `content/characters/README.md` 和 `content/enemies/README.md`；新增姿态图只提取所用切片，不复制整张图集。scene_001 现在为 3D 地图；旧 2D battlefield_view 与 actor_view 入口保留。

## Battle 展示控制

右上 1×/2× 仅调整展示特效速度，暂停仅冻结特效。左上菜单通过“重新开始”重播展示；点击右上倍速切换 1×／2×。血条、费用、进度与冷却均来自模拟快照，默认五名干员均在场，因此卡片按共用规则隐藏。切到其他页签停止动画和 SubViewport 持续渲染，返回时保留暂停与速度偏好；离开工作区释放整个 3D 世界。

战场组装在 `battle_stage.gd`；实际布局和围墙在 scene_001，具体资源由调用方传入表现 feature。地形使用独立顶面、倒角侧壁、单格纹理和真实方向光阴影；scene_001 外围使用断续深灰岩石废墟，保留 0.42／0.60 的高低层次；角色使用深度裁切立片与软接触阴影，斩击使用外部展示时钟。HUD 使用与 Game Test 相同的边缘锚定排布，预览画布随工作区等比缩放。

## 动画限制与模块依赖

角色图集每行是同一角色的四种姿态，不含可信的连续行走、受击、死亡帧。Animation 的角色预览明确标注为 2 FPS 待机／攻击姿态循环；特效的大小变体也不作为连续时间帧，动态预览标注为程序缩放淡出脉冲。素材彩色杂边保留原貌。

角色与特效动态预览复用 features/actor_view 和 features/effects，Battle 另复用 battlefield_view、battle_hud。表现模块不依赖具体 content、devtools 或 battle；浏览目录、导航和播放控制属于 devtools。

## 验证

`devtools/hub/tests/workspace_smoke.gd` 使用引擎原生鼠标事件及视口截图，检查四个工作区导航、独立入口、tab 切换、素材数量及切片唯一性、静态像素稳定、播放状态、隐藏暂停、释放，以及默认／窄窗口滚动和网格换行；同时回归 Blueprint、Game Test 与 Story Test。日志位于 `temp/devtools/art_smoke.log`，截图位于 `temp/verification/`。

Battle 专项：用真实 Compatibility 渲染器运行 `--script res://devtools/art_test/battle_visual_smoke.gd`，检查通过主窗口缩放路径点击暂停和倍速、隐藏视口停渲染、播放偏好、重播、释放及 1280×800 / 960×600 适配。截图包括 `battle_canvas.png`、`battle_graybox.png`、`battle_1280x800.png` 和 `battle_960x600.png`，日志为 `temp/devtools/battle_visual.log`。请勿使用 headless 模式做视觉验收。


## 与 Game Test 共用显示

Battle 页通过 `game/adapters/battle_presentation.gd` 消费模拟快照，使用 `features/battle_hud/playable_hud.gd`；不创建 battle 模拟器。正式关卡的 TileMap、编队数值与 appearance 资源作为展示输入。`features/battlefield_view/battlefield_stage.gd` 共用环境光、镜头构图与路线端点标记：红色敌方入口 `ec5743`、蓝色基地 `63c6f5`，沿用原 Art Test 的 0.85 格、12 条细边框样式。入口位置取当前地图路线，不保留旧预览的手写坐标。

角色使用相同 billboard、朝向、飞行高度和生命／技力／技能持续时间条。Battle 页仍支持暂停、倍速、菜单重播和隐藏停止渲染；保留 Art Test 的整页导航和 16:9 预览容器。运行 `game/tests/presentation_parity_test.gd` 可用相同快照校验两边的角色、HUD、构图和标记一致性，截图与日志写入 temp。


Battle 攻击展示使用周期性模拟 attack_start／damage／heal 事件，通过共用适配器播放子弹、刀光、受击、治疗与攻击姿态；不执行伤害计算。暂停、倍速和重播作用于这些特效的同一展示时钟，重播清除进行中的效果和动作。


重播 Battle 会先重置为五名干员与两条路线预告，不显示敌人；2 秒后移除预告并显示三类敌人，然后播放模拟攻击事件。路线光效通过同一 route_guide feature 由模拟快照驱动，暂停／倍速同样生效。

## Skill

新增第五个 Skill 页签，可 F6 运行 skill_preview.tscn 独立打开。仅按原图行列顺序展示全部16张图标、素材编号和来源行列。此页不加载干员数值配置，不展示技能名称、效果、充能方式或其他玩法文案。图标使用正式 AtlasTexture 切片。窄窗口自动换行并可纵向滚动；素材来自 Human/StarterContent/icon/skill-atlas-01.png，正式副本与切片位于 content/ui/skill_icons。
