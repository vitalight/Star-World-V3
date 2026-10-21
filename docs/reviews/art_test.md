# Art Test 表现模块评审记录

- 模块名称与路径：features/actor_view、features/effects、features/battlefield_view、features/battle_hud。
- 职责：外部传入资源的角色姿态播放、特效脉冲、地形绘制、静态 UI。不计算战斗或查找战斗内部节点。
- 输入与依赖：SpriteFrames、Texture2D、图集和文字；仅依赖 Godot 标准节点。Battle 使用 content 图集和切片配置；全量素材浏览由 devtools 目录直接切片 StarterContent，未增加正式内容 ID。
- 独立运行：devtools/art_test 下的 character_preview.tscn、effect_preview.tscn、animation_preview.tscn、battle_preview.tscn，入口 art_workspace.tscn。
- 素材检查结果：已实际查看全部七张 StarterContent 图集和 ArtReference；角色为四姿态，特效为大小变体。未虚构连续源动画。详情见工作区 README。
- 验证：2026-10-21 使用 Godot 4.7.2 标准版实际渲染，更新后的 workspace_smoke.gd 为 0 失败。覆盖 16 列角色 × 4 姿态、32 静态特效、96 唯一切片、静态像素稳定、全部动态预览暂停、播放／重播、切页暂停及恢复、离开释放、四个独立入口、统一路径、首页往返、Blueprint B 和 Logic Test 胜负；检查默认 1280×800 与窄窗口 800×650 截图。日志 temp/devtools/art_smoke.log，截图 temp/verification/。
- 已知限制：缺少连续动作帧；两姿态循环和脉冲为明确标注的程序演示。静态 UI 数值为模拟展示数据。
- 评审结论：待评审。
- 记录日期：2026-10-21；本轮为实现者自查记录，不代替人工美术评审。
- 通过后集成位置：game/adapters 注入表现数据，Game Test 组装；本轮未接入。

- 本轮导入环境提示：编辑器导入退出码 0，但启动时出现 Safe save failed 提示；实际渲染验证无项目脚本解析或运行错误。导入日志 temp/devtools/art_import.log。
