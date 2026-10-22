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


## 2026-10-22 Art / Game Battle 显示统一

- Art Test Battle 移除预览专用的手写生命条、HUD、镜头／光照与入口绘制，改用模拟快照接入同一个 BattlePresentation 和 playable_hud。样例与正式编队对齐为五类干员、三类敌人；不创建 battle 模拟器，也不计算战斗规则。
- battlefield_stage 统一相机创建／适配、环境与路线端点标记。Game Test 敌方入口和基地采用原 Art Test 红色 ec5743／蓝色 63c6f5、0.85 格十二边线框样式；两边端点由当前地图路线生成。敌人共用同一 appearance、朝向、飞行高度和状态条显示。
- 保留 Art Test 的页签导航、16:9 预览、暂停／倍速、重播、隐藏停渲染和释放；Game Test 保留全窗口、部署鼠标定向、技能、撤退与内嵌调试。
- 实际 Godot 4.7.2 Compatibility / RTX 3060 Ti 渲染验证：显示一致性 90 项、完整游戏图形 461 项、部署交互 38 项、角色遮挡 21 项检查全通过；headless 战斗集成 81 项通过；Art Battle 与工作区导航均 0 failures。图形回归覆盖 1280×800、960×600、1600×900；Art 页缩放与输入由其专项检查覆盖。
- 输出：temp/presentation_parity.log、temp/art_shared.log、temp/game_visual.log、temp/deployment_view.log、temp/actor_occlusion.log、temp/game_integration.log、temp/game_regression_workspaces.log。相同快照截图：temp/verification/art_shared_battle.png、temp/verification/game_shared_battle.png。
- 检查结论：两边消费同一快照时角色、HUD、构图、状态条和入口标记一致；生产代码未引入对 devtools 或 temp 的依赖；未修改 Human/Human.md。


## 2026-10-22 攻击、受击特效

远程干员及远程敌人的 attack_start 创建朝目标飞行的子弹；近战单位的 attack_start 创建攻击者前方刀光。damage 在目标处播放受击闪光并保留原有角色闪烁，heal 使用绿色治疗图，skill_start 使用强化图。全部复用 effect_001 原图集的 AtlasTexture，不生成或修改原图片。

效果通过 BattlePresentation 单一事件入口创建，位置考虑地形、飞行高度与 billboard 身体锚点；子弹跟踪目标，damage／miss 清除对应子弹。effects 使用外部模拟时钟，暂停冻结、倍速与固定步长一致，重开／退出清理；不增加伤害计算，也不改变结算时机。命中闪光采用较高渲染优先级确保立片上可读。Art Test Battle 改用模拟攻击与伤害事件进入同一适配器，并在重播时清理效果和攻击姿态。

验证：combat_effects_test 使用真实 Godot Compatibility 渲染，185 项检查通过，覆盖敌我双方远程／近战、伤害／治疗、命中／落空、暂停／2×、重开及实际像素可见性；普通获胜编队之外，用单重装对单近战敌人的实际战斗确认阻挡后刀光。显示一致性 90 项、战斗集成 106 项、完整游戏图形 461 项通过，Art Battle 专项 0 failures。原 battle 规则代码未修改。

日志：temp/combat_effects.log、temp/presentation_parity.log、temp/game_integration.log、temp/game_visual.log、temp/art_shared.log。实际渲染截图：temp/verification/combat_projectile.png、combat_slash.png、combat_impact.png。新增接口见 features/effects/README.md。


## 2026-10-22 技能就绪与干员操作

- 在场干员主动技能充满时显示金色立片轮廓亮光与头顶菱形，自动回技力达标即时更新。播放相位由 advance_visual 的战斗时钟驱动；释放、离场、终局和待部署预览清除／隐藏提示。轮廓只改变现有不透明像素颜色，不修改 billboard 几何或深度。
- 选中干员详情增加可点击的技能图标及金色就绪边框，显示充能、就绪、持续中和无主动技能状态。技力不足、技能持续中和未开始战斗时禁用。appearance 新增可选 skill_icon，近卫复用现有强化图，未生成图片。
- 撤退继续使用 battle 公共命令；详情显示返费和冷却。验证返还一半费用（向下取整、上限截断）、卡片恢复、冷却期间部署拒绝、冷却结束再次部署与重开清理。
- 实际 Compatibility 渲染鼠标操作专项 operator_actions_test 26 项通过；战斗集成 106 项、完整游戏图形 461 项、角色遮挡 21 项、Art/Game 显示一致性 90 项及 Art Battle 专项通过。遮挡测试与生命条一样排除头顶状态 UI，只测角色轮廓的真实深度遮挡。
- 日志 temp/operator_actions.log、temp/game_integration.log、temp/game_visual.log、temp/actor_occlusion.log、temp/presentation_parity.log、temp/art_shared.log；截图 temp/verification/operator_skill_ready.png。


## 2026-10-22 出怪前路线预告

- scene_001 配置 route_warning_duration=2。每组 Wave 的首怪时刻为 max(time,2)，提前完整 2 秒播放该路线预告；同组后续 count 保持 interval，不重复播放。不同路线可同时预告。时序由 battle 管理，start 时立即激活到期预告，固定步长维护 route_warnings 快照并发出 route_warning 事件；完整结束后才 spawn，不由渲染回调修改规则。
- route_guide feature 从 Path2D 导出的真实格心路线及地表高度生成连续透明高亮窄带，UV 按累计路程排列，一束连续流光从出生点向基地扫过一次，随后淡出。进度完全取模拟时间，没有 TIME 或独立计时器；暂停、单步、1×／2×／4×沿用正常战斗时钟。终局、重开、重载、退出清理视图。
- Art Test 以两条模拟预告快照使用同一显示实现，前 2 秒隐藏敌人，完成后显示三类敌人并播放模拟攻击。
- 实际 Godot Compatibility 渲染专项 route_warning_test 42 项通过，检查完整 2 秒无敌人、准时生成、组内间隔、双路线、单步暂停、倍速、重开重载及 1280×800／960×600／1600×900 的实际像素流向（亮带位置从出生侧向基地侧移动）。战斗规则 158 项、战斗集成 106 项、完整游戏图形 461 项、干员操作 26 项、Art/Game 显示一致性 84 项、Logic Test 18 cases／98 checks 全通过，Art Battle 与工作区导航均 0 failures。原始字典配置缺省时长为 0，保留现有纯规则样例的时刻；正式关卡明确启用 2 秒。
- 日志 temp/route_warning.log、temp/game_integration.log、temp/game_visual.log、temp/operator_actions.log、temp/presentation_parity.log、temp/art_shared.log、temp/game_regression_battle.log、temp/game_regression_logic.log、temp/game_regression_workspaces.log。截图 temp/verification/route_early_*.png、route_late_*.png。接口说明 features/battlefield_view/route_guide.md 与 features/battle/README.md。
