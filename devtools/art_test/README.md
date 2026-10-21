# Art Test

从 Developer Hub 进入后默认打开 Character，固定提供 Character / Effect / Animation / Battle 四个 tab。顶部路径统一为 `Star World/Developer Hub/Art Test`，点击 Developer Hub 返回首页。首页及 Blueprint、Logic Test、Game Test 复用相同路径组件。

- Character：全部 16 个角色按英雄、敌人、图集编号和行号排序。每列一个角色，依次显示正面待机、背面待机、正面攻击、背面攻击；水平滚动浏览，较矮窗口支持垂直滚动。来源与角色行号随列显示。
- Effect：两张特效图集全部 32 个静态切片，包括大小变体；卡片随窗口宽度换行，垂直滚动浏览，显示来源及行列。此页不播放动画。
- Animation：32 个角色方向预览（每个角色正背面各一项）与 32 个特效预览；默认循环播放，支持统一播放、暂停和重播。隐藏页面停止更新，返回后恢复原先播放／暂停状态；重播从开头开始并播放。
- Battle：16:9 自适应 3D 荒原哨站，10×6 地块、道路与高台、有受光层次的麦黄色草丛、岩石围墙、红蓝出入口、6 名我方和 4 名敌方角色立片；HUD 使用模拟读数和五张角色卡。没有移动、伤害、部署或波次计算。小窗口完整缩放战场并留边。

`art_workspace.tscn`、`character_preview.tscn` 默认 Character；`effect_preview.tscn`、`animation_preview.tscn`、`battle_preview.tscn` 分别直接打开对应 tab，均可独立 F6 运行。离开场景销毁其表现节点。

## 素材来源与切片

浏览目录在 `asset_catalog.gd`，开发预览直接引用 Human/StarterContent：角色 hero-atlas-01、hero-atlas-02、enemy-atlas-01、enemy-atlas-02；特效 effect-atlas-01、effect-atlas-02。每张按 4 × 4 网格切片，按实际图片尺寸除以四计算浮点区域（当前为 313.5 × 313.5），不重新采样或覆盖原图，也不为原始素材浏览批量分配正式内容 ID。

Battle 引用正式 content：character_001～character_010、effect_001、terrain_001 和 scene_001。原有 ID 保持稳定；character_008～character_010 的敌方资源存放于 `content/enemies/`，其余沿用原目录。来源登记见 `content/characters/README.md` 和 `content/enemies/README.md`；新增姿态图只提取所用切片，不复制整张图集。scene_001 现在为 3D 地图；旧 2D battlefield_view 与 actor_view 入口保留。

## Battle 展示控制

右上 1×/2× 仅调整展示特效速度，暂停仅冻结特效。左上菜单提供重播展示、恢复 1×。血条、费用、进度与冷却均为固定模拟值，角色卡只有悬停反馈。切到其他页签停止动画和 SubViewport 持续渲染，返回时保留暂停与速度偏好；离开工作区释放整个 3D 世界。

战场组装在 `battle_stage.gd`；实际布局和围墙在 scene_001，具体资源由调用方传入表现 feature。地形使用独立顶面、倒角侧壁、单格纹理和真实方向光阴影；scene_001 外围用一圈不重叠的深灰岩石纹理方块围合，四角只放置一次；36 块中 31 块与内层高台同高（0.42），5 块略高（0.60），没有额外墙脚、扶壁或压顶；角色使用深度裁切立片与软接触阴影，斩击使用外部展示时钟。HUD 使用 1280×720 设计坐标，随战场等比缩放。

## 动画限制与模块依赖

角色图集每行是同一角色的四种姿态，不含可信的连续行走、受击、死亡帧。Animation 的角色预览明确标注为 2 FPS 待机／攻击姿态循环；特效的大小变体也不作为连续时间帧，动态预览标注为程序缩放淡出脉冲。素材彩色杂边保留原貌。

角色与特效动态预览复用 features/actor_view 和 features/effects，Battle 另复用 battlefield_view、battle_hud。表现模块不依赖具体 content、devtools 或 battle；浏览目录、导航和播放控制属于 devtools。

## 验证

`devtools/hub/tests/workspace_smoke.gd` 使用引擎原生鼠标事件及视口截图，检查四个工作区导航、独立入口、tab 切换、素材数量及切片唯一性、静态像素稳定、播放状态、隐藏暂停、释放，以及默认／窄窗口滚动和网格换行；同时回归 Blueprint 与 Logic Test。日志位于 `temp/devtools/art_smoke.log`，截图位于 `temp/verification/`。

Battle 专项：用真实 Compatibility 渲染器运行 `--script res://devtools/art_test/battle_visual_smoke.gd`，检查通过主窗口缩放路径点击暂停和倍速、隐藏视口停渲染、播放偏好、重播、释放及 1280×800 / 960×600 适配。截图包括 `battle_canvas.png`、`battle_graybox.png`、`battle_1280x800.png` 和 `battle_960x600.png`，日志为 `temp/devtools/battle_visual.log`。请勿使用 headless 模式做视觉验收。
