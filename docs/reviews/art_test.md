# Art Test 表现模块评审记录

- 模块名称与路径：features/actor_view、features/effects、features/battlefield_view、features/battle_hud。
- 职责：外部传入资源的角色姿态播放、特效脉冲、地形绘制、静态 UI。不计算战斗或查找战斗内部节点。
- 输入与依赖：SpriteFrames、Texture2D、图集和文字；仅依赖 Godot 标准节点。content 提供具体图集和切片配置，devtools 组装。
- 独立运行：devtools/art_test 下的 character_preview.tscn、effect_preview.tscn、battle_preview.tscn，入口 art_workspace.tscn。
- 素材检查结果：已实际查看全部七张 StarterContent 图集和 ArtReference；角色为四姿态，特效为大小变体。未虚构连续源动画。详情见工作区 README。
- 验证：2026-10-21 Godot 4.7 完成资源导入；四个独立场景正常启动并检查实际渲染截图。自动验证姿态帧推进、暂停保持、播放/单步/独查/双方对照/特效按钮；入口及返回使用控件位置鼠标事件验证，离开后旧场景释放。详见 phase_one.md，渲染验证 0 失败。Windows 桌面自动化未获应用访问权限，改用引擎原生输入与视口截图检查。
- 已知限制：缺少连续动作帧；两姿态循环和脉冲为明确标注的程序演示。静态 UI 数值为模拟展示数据。
- 评审结论：待评审。
- 记录日期：2026-10-21；本轮为实现者自查记录，不代替人工美术评审。
- 通过后集成位置：game/adapters 注入表现数据，Game Test 组装；本轮未接入。
