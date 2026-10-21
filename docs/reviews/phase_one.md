# 第一阶段交付与验收

日期：2026-10-21。实现与自动运行验证已完成；视觉方向等待用户选择，表现模块与 battle 模块等待独立评审，未组装正式 game。

## 交付

| 范围 | 结果 |
| --- | --- |
| Developer Hub | 默认启动入口；四个用途明确的按钮；按需切换场景，离开时销毁工作区 |
| Blueprint | A / B 原图完整等比展示，切换与返回可用；生成原图、方向说明、完整提示词均保留 |
| Art Test | Character / Effect / Battle Scene 四个入口与子场景可独立运行；content 副本及切片，不覆盖 Human 输入 |
| Logic Test | 纯规则模块 + 几何显示；合法部署、固定路径、单波、攻击/生命、胜败、重置 |
| Game Test | 可进入与返回，明确待集成 |

Blueprint 使用内置 imagegen 生成。已查看 ArtReference，参考其视角、方格战场、单位与 HUD，通过文字传递视觉目标。两图仅用于视觉评审；A 为日照砂岩台地，B 为夜间水渠桥梁，未选定方案。

## 验证与证据

使用现有 Godot 4.7 stable Mono，Compatibility / OpenGL，实际渲染设备 RTX 3060 Ti。未新增插件或下载引擎。

- 资源导入成功，所有新增 PNG 已生成 `.import`，脚本已生成 `.uid`。
- 战斗核心：17 检查、0 失败；工作区测试：0 失败，包含胜负、3 次独立创建释放和重置。
- 渲染与导航：0 失败；两轮四入口往返，旧场景弱引用失效，未遗留活动实例。
- 实际控件位置鼠标事件验证首页按钮、返回、Blueprint 切换、四个部署槽、开始波次；并检查角色循环帧推进及暂停保持。
- 三个 Art 子页的播放、暂停、单步、独查、特效重播等按钮经触发检查。已直接查看首页、A/B、角色、特效、战场、运行中、胜利、失败的真实视口截图，1280×800 下内容可见且无裁切。
- 胜利：基地生命 3，8 敌全灭；失败：空场漏怪，基地生命 0；重置后重新开始。

日志和检查截图统一保存在被 Git 忽略的 `temp/verification/`；导入日志 `temp/import_verified.log`。脚本不会在游戏运行时依赖这些输出。

复验（PowerShell；预先设置 `GODOT_PATH` 为本机引擎可执行文件路径）：

```powershell
$godotExe = $env:GODOT_PATH
New-Item -ItemType Directory -Force temp/godot_user | Out-Null
$env:APPDATA = (Resolve-Path temp/godot_user).Path
& $godotExe --headless --path . --editor --import --quit
& $godotExe --headless --path . --script res://features/battle/tests/battle_test.gd
& $godotExe --headless --path . --script res://devtools/logic_test/workspace_test.gd
& $godotExe --path . --script res://devtools/hub/tests/workspace_smoke.gd
```

最后一个命令需要可渲染桌面，使用 Godot 自身的输入管线与真实视口截图；按钮输入与规则断言由脚本驱动，再人工查看截图，不宣称人工逐个操作 Windows。Windows computer-use 应用访问未获批准，未用该接口控制 Godot。

## 环境与项目限制

- 沙箱内首次导入无法创建默认用户目录，并报告 .NET assemblies 不可用；切换为获准的沙箱外引擎运行并将 APPDATA 定向 temp 后，资源导入与 GDScript 运行均完成。配套文件实际存在，推断为受限执行环境的访问/路径可见性问题，未定位到唯一根因。详细证据与处理方式统一见 [常见问题 / 踩坑记录](../troubleshooting.md)。
- Mono 编辑器仍报告缺少指定 .NET SDK（8.0.27）；这是 C# 编辑器扩展环境提示。本项目仅使用 GDScript；最终三个验证进程无项目解析或运行错误。可用标准 Godot GDScript 版或配置好 SDK 的 Mono 版打开。
- 原图提供四个角色姿态与特效大小变体，没有可信连续走路/受击/死亡序列；两姿态循环及缩放淡出明确标注为程序演示。源素材彩边未重绘。
- Art Battle Scene 是静态模拟，Logic Test 是一种攻击/一条路径/一波；没有技能、正式内容数值或 game 适配器。
- 本轮未提交或推送 Git；保留开始任务前已有的用户修改。

## 待评审

表现能力见 art_test.md，战斗能力见 battle.md。实现者自动验证通过不代替独立模块评审；正式 Game Test 集成仍应遵循架构流程。用户可直接在 Blueprint 查看两版后给出 A / B 选择。
