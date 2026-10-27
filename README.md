# Star World

基于 Godot 的塔防项目，参考明日方舟。
需求大纲：[Human/Human.md](Human/Human.md)。

## 运行

双击 [`scripts/run_devtools.bat`](scripts/run_devtools.bat) 一键导入资源并启动开发者首页。

项目默认入口为 `game/player/player_mode.tscn`：主界面 → 独立剧情关 → 独立战斗关 → 下一剧情关，章末播放独立尾声关。直接运行项目即可进入 Player Mode；开发者首页仍由上述脚本启动，也提供 Player Mode 卡片。玩家流程和存档说明见 [Player Mode](game/player/README.md)。背景音乐与音效由 [音频内容](content/audio/README.md) 的 cue 清单驱动，主菜单右上角可调 BGM／音效音量。

第一章「上海」包含家中异常、路边救援、东方明珠主节点，以及五名角色。角色、技能、敌人通过 Godot Inspector 编辑 `.tres`，关卡与波次继续使用 CSV，对白使用 Markdown，地形与路线仍用 Godot 地图编辑器；说明与例子见 [内容编辑](content/campaign/README.md)。Game Test 的 F3 调试窗可切换正式三关，Story Test 可选择三段关卡剧情与章末尾声并重新加载。

Game Test 已接入完整战斗：从首页进入后可部署干员、开始防守、释放技能、撤退和重开；F3 打开内嵌调试窗。地图使用 TileMapLayer 编辑并生成 3D 战场，路线和波次均可在编辑器配置。操作、编辑与验证说明见 [Game Test](devtools/game_test/README.md)。

## 目录结构

采用 **Feature-oriented + Data-driven + Composition**。

```text
StarWorldV3/
├── project.godot
├── core/                       # 已有实际复用需求的稳定基础设施
├── features/                   # 独立开发与验证的能力
│   ├── battle/                 # 战斗模拟：状态与规则
│   │   ├── units/
│   │   ├── deployment/
│   │   ├── targeting/
│   │   ├── navigation/
│   │   ├── waves/
│   │   └── tests/
│   ├── actor_view/             # 通用角色展示与动画播放
│   ├── content_definitions/    # Inspector 内容编辑入口与资源索引
│   ├── effects/                # 通用特效播放
│   ├── battlefield_view/       # 地图展示
│   ├── battle_hud/             # 战斗 UI 展示及操作意图
│   └── audio/                  # 音乐与音效播放、音量设置
├── content/                    # 具体内容实例与专属资源
│   ├── characters/             # 角色贴图及原样例外观
│   ├── enemies/                # 敌人贴图及原样例外观
│   ├── data/                   # 角色／敌人／技能 .tres 与注册索引
│   ├── campaign/               # 正式章节关卡／波次／背景表
│   ├── audio/                  # 音乐、音效与 cue 清单
│   └── scenes/                 # 地图、路线、剧情与场景外观
├── devtools/                   # 开发工具及人工验证入口
│   ├── hub/                    # 开发者首页，独立启动
│   ├── blueprint/images/       # 概念图及版本
│   ├── art_test/               # 表现模块 + 模拟数据
│   ├── game_test/              # 加载真实游戏组装场景
│   └── story_test/             # 剧情样例验证
├── game/                       # 最终组装、启动和流程
│   ├── player/                 # 默认玩家入口与菜单、关卡流程
│   ├── battle/                 # 战斗场景和生命周期
│   ├── adapters/               # 状态、事件与表现之间的适配
│   ├── content/                # 资源／表格／剧情加载与校验
│   └── tests/                  # 跨模块集成验证
├── agents/                     # 按角色组织的项目约定
├── temp/                       # 临时数据，不纳入 Git
└── Human/                      # 人工需求和原始参考
    └── StarterContent/         # 外部输入的初始素材，保留原始内容
```

- 角色职责、架构、验证和提交约定见 [项目约定入口](AGENTS.md)。
- 新文件和目录使用 `snake_case`。外部输入目录 `Human/StarterContent/` 保留指定大小写。
- Godot 的 `.uid` 和素材 `.import` 元数据纳入版本管理，`.godot/` 缓存不提交。

战斗规则使用无界面代码测试，运行方式见 [Battle 测试](features/battle/tests/README.md)。手动战斗验证统一进入 Game Test。
