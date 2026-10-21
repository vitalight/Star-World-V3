# Battle Test 3D 表现评审

- 模块名称与路径：features/battlefield_view、features/actor_view、features/effects、features/battle_hud 的新增 3D / HUD 入口；content/scenes/scene_001；devtools/art_test/battle_stage.gd。
- 职责与明确不负责的内容：展示参考图风格的 3D 地形、2D 角色立片、展示特效和 HUD；不计算移动、部署、伤害、波次或胜负，不依赖 features/battle。
- 输入、输出、信号及资源依赖：地形接收 atlas、layout、decorations 和 graybox，surface_height 返回格子顶面高度；角色接收 texture、height、foot_offset、tint；特效接收 texture、width，通过 show_phase 接收外部时钟；HUD 接收读数、头像、费用、图标与冷却，发出 pause_requested、speed_requested、replay_requested、reset_speed_requested。读数可通过 set_readout 更新，播放状态可通过 set_playback 更新。feature 无具体 content 或 devtools 资源依赖。
- 独立运行场景 / 所属开发工作区：devtools/art_test/battle_preview.tscn，或 Developer Hub → Art Test → Battle。
- 验证步骤与结果：Godot 4.7.2，OpenGL Compatibility，RTX 3060 Ti。battle_visual_smoke 检查 10 个单位、五张卡、头像尺寸、主窗口坐标点击暂停/倍速、设置菜单、隐藏停渲染、暂停偏好、重播、恢复默认速度、恢复播放、两种窗口尺寸完整显示与输入及释放；workspace_smoke 回归四个工作区、独立入口、静态素材、动画控制与 Logic Test。两项结果均为 0 failures，运行时日志无脚本或渲染错误。编辑器导入阶段有环境相关 Safe save failed 提示，但资源导入和实际渲染验证完成，未修改用户编辑器设置。
- 参考图、截图或测试输出：Human/ArtReference.jpg；temp/verification/battle_canvas.png、battle_graybox.png、battle_1280x800.png、battle_960x600.png、battle_reference_comparison.png；temp/devtools/battle_visual.log、art_smoke.log。临时产物不纳入 Git。
- 已知限制：以构图和空间层次接近参考为目标，原图低分辨率无法推导精确镜头；已移除散放碎石与石柱，外围为不重叠的深灰岩石纹理方块围墙（多数与高台齐平，少量略高），墙体由 scene_001 内容场景组装，保持主网格和镜头不变，角色仅有静态姿态，原素材彩色边缘保留，草地按最新参考改为密集麦黄色草丛，恢复草地底纹；成簇草叶有弯折中线与两侧折面，根部深褐、叶尖浅黄，接受场景灯光和投影，采用稳定的随机高低与朝向分布。费用、生命、进度、血条、冷却均为固定展示值；不包含真实战斗。当前视觉效果已获用户确认。
- 评审结论：Battle Test 视觉验收通过，用户在当前对话确认效果并授权提交；正式 game 接入仍需对应集成评审。
- 评审人和日期：Codex 实施与自动验证，用户确认视觉效果，2026-10-21。
- 通过后集成位置：当前仅 Art Test 使用；本次未接入正式 game / Game Test。
