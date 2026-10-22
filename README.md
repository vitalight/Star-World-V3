# Star World

基于 Godot 的塔防项目，参考明日方舟。
需求大纲：[Human/Human.md](Human/Human.md)。

## 运行

双击 [`scripts/run_devtools.bat`](scripts/run_devtools.bat) 一键导入资源并启动开发者首页。

项目默认入口为 `devtools/hub/developer_hub.tscn`。

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
│   ├── effects/                # 通用特效播放
│   ├── battlefield_view/       # 地图展示
│   └── battle_hud/             # 战斗 UI 展示及操作意图
├── content/                    # 具体内容实例与专属资源
│   ├── characters/             # 角色数值、外观、专属贴图
│   ├── enemies/                # 敌人数值和外观
│   └── levels/                 # 关卡、路径、波次配置
├── devtools/                   # 开发工具及人工验证入口
│   ├── hub/                    # 默认启动场景
│   ├── blueprint/images/       # 概念图及版本
│   ├── art_test/               # 表现模块 + 模拟数据
│   ├── game_test/              # 加载真实游戏组装场景
│   └── story_test/             # 剧情样例验证
├── game/                       # 最终组装、启动和流程
│   ├── battle/                 # 战斗场景和生命周期
│   ├── adapters/               # 状态、事件与表现之间的适配
│   └── tests/                  # 跨模块集成验证
├── docs/                       # 架构与评审记录
├── temp/                       # 临时数据，不纳入 Git
└── Human/                      # 人工需求和原始参考
    └── StarterContent/         # 外部输入的初始素材，保留原始内容
```

- 具体归属、依赖和验证规则见 [docs/architecture.md](docs/architecture.md)。
- 场景、角色、地形内容 ID 分别使用 `scene_001`、`character_001`、`terrain_001` 格式，详细规则见架构约定的“内容 ID”。
- 评审模板见 [docs/module_review.md](docs/module_review.md)，具体记录存入 `docs/reviews/`。
Git 提交使用 `type(scope): description`，详见 [提交约定](docs/git_conventions.md)。
- 新文件和目录使用 `snake_case`。外部输入目录 `Human/StarterContent/` 保留指定大小写。
- Godot 的 `.uid` 和素材 `.import` 元数据纳入版本管理，`.godot/` 缓存不提交。

战斗规则使用无界面代码测试，运行方式见 [Battle 测试](features/battle/tests/README.md)。手动战斗验证统一进入 Game Test。
