# 项目约定入口

## 角色入口

开始任务前，根据工作内容确定主要角色并读取对应文件；跨角色任务在修改前读取所有相关角色文件。

| 角色 | 适用任务 | 必读 |
| --- | --- | --- |
| Programmer（程序） | 代码、架构、工具、测试、资源接入 | [agents/programmer.md](agents/programmer.md) |
| Artist（美术） | 角色、敌人、背景、特效、UI 视觉及资产制作 | [agents/artist.md](agents/artist.md) |
| Game Designer（游戏设计） | 玩法、关卡、数值、剧情、引导与体验规划 | [agents/game-designer.md](agents/game-designer.md) |

## 通用约定

- 临时脚本、中间文件、日志和截图放项目根目录 `temp/`，该目录不纳入 Git，保留 `.gdignore`；正式运行不得依赖临时数据。
- 模块、资源、跨模块依赖及临时数据遵循 [程序角色](agents/programmer.md) 的架构约定。
- Godot 路径通过环境变量 `GODOT_PATH` 获取。
- Git 提交标题使用 `type(scope): description`，type 和 scope 为小写英文，scope 必填，description 使用简洁英文动词短语。
