# Logic Test

从开发者首页进入 Logic Test，或直接运行 `logic_workspace.tscn`。

1. 点击场地内编号 1–4 的部署位置，放置青色方形单位。每格只能放置一次，波次进行中也可部署。
2. 点击 **Start wave**，观察珊瑚色敌人沿固定道路移动、绿色生命条下降、攻击连线及消灭结果。
3. 部署全部四格可以消灭 8 名敌人并胜利；不部署则在第三名敌人漏过后失败。允许少量漏怪，只要基地生命尚存且本波全部处理完毕仍胜利。
4. **Reset** 清除部署、敌人、攻击短线与结果，恢复基地生命 3。**Back to hub** 在独立运行时同样返回首页。

场地随可用窗口空间等比例缩放。编号框是合法部署位置；圆环是攻击范围。界面生命、剩余敌人、消灭和漏怪计数均来自 battle 状态快照，不另行计算玩法。

## 实现边界

- `features/battle/battle.gd` 是无场景依赖的 `RefCounted`，外部传入路径、部署位置和数值，提供 `deploy`、`start`、`advance`、`reset`、`snapshot`、`take_events`。
- 规则固定以 1/60 秒推进。移动后攻击；优先攻击范围内距离终点最近的存活敌人。到达终点的敌人不能再被攻击；扣生命后立即检查胜负。
- 调用方持有实例，退出场景后实例随之释放，无全局定时器、单例或后台活动。
- 公开配置是本阶段受信任的开发输入：要求路径至少两个点、总长度大于零，波次数量和生命为正整数，速度/间隔/伤害为正数。尚无可编辑配置校验器。
- 当前只有一种单位、一种直接命中攻击、一个固定波次；无阻挡、费用、升级、技能、暂停、存档或正式美术依赖。编号位置与数值是工作区测试配置，未占用正式内容 ID。
- 界面使用英文标签，说明文档使用中文。

## 自动验证

在项目根目录运行 Godot 4.x：

```powershell
# 本环境默认 user:// 写权限受限，重定向至项目临时目录。
New-Item -ItemType Directory -Force temp/logic_test | Out-Null
$env:APPDATA = (Resolve-Path temp/logic_test).Path
& 'D:/Program Files/Godot_v4.7-stable_mono_win64/Godot_v4.7-stable_mono_win64_console.exe' --headless --path . --script res://features/battle/tests/battle_test.gd
& 'D:/Program Files/Godot_v4.7-stable_mono_win64/Godot_v4.7-stable_mono_win64_console.exe' --headless --path . --script res://devtools/logic_test/workspace_test.gd
```

2026-10-21，Godot 4.7 stable Mono：核心 17 项检查、工作区集成检查均通过，退出码均为 0。核心检查包括部署合法性、快照隔离、伤害/冷却/射程、攻击事件消费、击杀胜利、漏怪后胜利、生命耗尽失败、待生成敌人阻止提前胜利、终态冻结、重置、路径拐点及时间分片一致性。工作区检查包括四格全灭、无部署失败，以及 3 次独立实例创建/释放和重置。

环境输出 `.NET: Assemblies not found`，本项目当前测试为 GDScript，仍执行并通过。默认 user:// 目录拒写时，Mono 引擎在开始测试前可能崩溃；以上重定向解决该环境问题。GUI 可见界面与真实输入验证由阶段整体验收记录补充。
