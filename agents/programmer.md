# Programmer（程序）

## 开始前

修改模块前读取其 README 和公共接口；战斗、内容和玩家流程分别参考 [Battle](../features/battle/README.md)、[内容编辑](../content/campaign/README.md)、[配置数据](../content/data/README.md) 和 [Player Mode](../game/player/README.md)。跨角色任务同时读取对应角色文件。

## 架构与资源

| 目录 | 职责与依赖 |
| --- | --- |
| `core` | 已有实际复用需求的基础设施，不依赖其他层 |
| `features` | 可独立验证的能力，可依赖 core 和明确记录的其他 feature 公共接口；禁止循环依赖 |
| `content` | 具体内容和资源，可依赖 feature 的资源类型及通用场景 |
| `game` | 加载内容、组装模块和管理游戏流程 |
| `devtools` | 调试、预览与验证，可依赖正式层；正式模块不依赖 devtools |

- feature 不依赖 game，也不硬编码具体 content 路径；具体资源由调用方注入。战斗状态与规则由 battle 持有，表现消费快照和事件，操作意图交给 battle 验证。
- 模块的脚本、场景、资源与专属测试就近存放；按实际变化原因拆分，避免预建未复用的基础设施。`scripts/` 只放项目级命令行入口。
- `Human/StarterContent/` 保留外部输入；正式资源归入 `content/`，概念图归入 `devtools/blueprint/images/`。具体格式与注册方式以内容文档为准，避免维护数据副本。
- 内容实体 ID 使用小写类型前缀和至少三位编号，如 `scene_001`、`character_001`、`terrain_001`；同类唯一，分配后保持稳定，删除的 ID 不复用。

## 测试与验证

- 使用环境变量 `GODOT_PATH` 调用 Godot。规则测试用无界面模式；渲染、截图及窗口输入用真实窗口，音频听感通过实际播放检查。等待渲染帧的测试不能用 `--headless`。
- 专属测试放在 `features/<module>/tests/`，集成测试放在 `game/tests/`；从公共接口验证可观察行为。按改动选择 [Art Test](../devtools/art_test/README.md)、[Story Test](../devtools/story_test/README.md)、[Game Test](../devtools/game_test/README.md) 或玩家流程验证，共享表现复用同一实现。
- 集成模块时检查职责、输入输出、依赖、验证结果和已知限制；报告实际检查及未覆盖项。评审不能代替测试。
