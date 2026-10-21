# 第一阶段交付与验收

日期：2026-10-21。实现与自动运行验证已完成；视觉方向等待用户选择，表现模块与 battle 模块等待独立评审，未组装正式 game。

## 交付

| 范围 | 结果 |
| --- | --- |
| Developer Hub | 默认启动入口；四个用途明确的按钮；所有工作区复用顶部路径，点击 Developer Hub 返回首页；离开时销毁工作区 |
| Blueprint | A / B 原图完整等比展示，切换与返回可用；生成原图、方向说明、完整提示词均保留 |
| Art Test | Character / Effect / Animation / Battle 四个 tab；默认 Character，16 个角色四姿态、32 张静态特效与全量动态演示；保留独立入口与 Battle 组合 |
| Logic Test | 纯规则模块 + 几何显示；合法部署、固定路径、单波、攻击/生命、胜败、重置 |
| Game Test | 可进入与返回，明确待集成 |

Blueprint 使用内置 imagegen 生成。已查看 ArtReference，参考其视角、方格战场、单位与 HUD，通过文字传递视觉目标。两图仅用于视觉评审；A 为日照砂岩台地，B 为夜间水渠桥梁，未选定方案。

## 验证与证据

使用现有 Godot 4.7 stable Mono，Compatibility / OpenGL，实际渲染设备 RTX 3060 Ti。未新增插件或下载引擎。

- 资源导入成功，所有新增 PNG 已生成 `.import`，脚本已生成 `.uid`。
- 战斗核心：17 检查、0 失败；工作区测试：0 失败，包含胜负、3 次独立创建释放和重置。
- 渲染与导航：0 失败；两轮四入口往返，旧场景弱引用失效，未遗留活动实例。
- 实际控件位置鼠标事件验证首页按钮、返回、Blueprint 切换、四个部署槽、开始波次；并检查角色循环帧推进及暂停保持。
- Art Test 更新复验：四个 tab 及独立入口、96 个唯一源切片、静态页像素稳定、动态播放／暂停／重播和隐藏暂停恢复均通过；已查看默认 1280×800 与窄窗口 800×650 的角色、特效、动画和 Battle 截图。当前日志 temp/devtools/art_smoke.log；导入编辑器退出码 0，出现 Safe save failed 环境提示，渲染运行无项目错误。
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

## 子工作区视觉整理（2026-10-21）

Blueprint、Art Test、Logic Test、Game Test 复用 devtools/ui/workspace_style.gd 的深色背景、卡片、按钮、tab、滚动条及统一路径布局；四个入口分别沿用首页的砂金、青绿、浅蓝、淡紫强调色。Blueprint 保持原图等比展示并突出当前方案，Art Test 保留切片边框与播放状态，Logic Test 整理操作与状态区域并提供中文说明，Game Test 使用待集成说明卡片。

Godot 4.7.2 实际渲染冒烟验证 0 失败（temp/devtools/workspace_polish.log）；默认 1280×800 与窄窗口 800×650 已检查真实截图。窄窗口布局验证 0 失败（temp/devtools/workspace_layout.log），Logic Test 支持滚动查看完整战场及图例。截图统一位于 temp/verification/。
