# Star World

基于 Godot 的塔防项目，参考明日方舟。需求大纲见 [Human/Human.md](Human/Human.md)。

## 运行

设置 `GODOT_PATH` 为 Godot 可执行文件路径：

- [`scripts/run_game.bat`](scripts/run_game.bat)：启动 Player Mode；加 `-d` 进入开发者模式。
- [`scripts/run_devtools.bat`](scripts/run_devtools.bat)：启动 Developer Hub。

项目默认入口是 `game/player/player_mode.tscn`。玩家流程与存档见 [Player Mode](game/player/README.md)；音频见 [音频内容](content/audio/README.md)。

## 架构

采用 Feature-oriented + Data-driven + Composition。目录职责与依赖规则见 [AGENTS.md](AGENTS.md) 和 [程序角色](agents/programmer.md)：

- `core`：已有实际复用需求的稳定基础设施。
- `features`：可独立验证的能力。
- `content`：具体内容与资源。
- `game`：加载内容、组装模块和管理游戏流程。
- `devtools`：调试、预览与验证，正式模块不依赖。

## 约定

- 新文件和目录使用 `snake_case`；`Human/StarterContent/` 保留外部输入的原始大小写。
- Godot 的 `.uid` 与素材 `.import` 元数据纳入版本管理；`.godot/` 缓存和 `temp/` 不提交。
- 临时脚本、日志和截图放入 `temp/`，正式运行不依赖临时数据。
- 战斗规则使用无界面测试验证，入口见 [Battle 测试](features/battle/tests/README.md)；手动战斗验证统一进入 Game Test。
