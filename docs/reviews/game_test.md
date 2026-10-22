# Game Test 集成评审

- 模块名称与路径：`game/battle`、`game/adapters`、`devtools/game_test`；扩展 `features/battle` 的配置资源、`battlefield_view` 的编辑数据桥、`actor_view`、`effects`、`battle_hud`；正式内容位于 scene_001 和已有角色／敌人目录。
- 职责：用同一 battle 模拟与同一表现 feature 完成综合战斗。game 管生命周期和适配，devtools 只增加工具与导航；不增加战斗规则，不让显示状态反写模拟，不包含剧情和连续动作资产制作。
- 输入／输出：TileMapLayer 自定义数据和 Path2D 转为 terrain/routes，Level/Unit/Wave Resource 转为 battle 配置；命令经原 battle 公共接口验证。单一 refresh 消费事件并以 observed(state, events) 发送深拷贝给调试观察者。HUD 只发部署、朝向、开始、暂停、技能、撤退与重开意图。
- 依赖检查：正式模块无 devtools 引用，features 无具体 content 路径；配置资源不含外观依赖；game 按 content_id 装配外观。地图编辑桥使用关卡资源的 errors/configuration 协议，3D 展示只读取 cells/height。移除 scene_001 的手写布局副本；TileMap 是地形唯一来源。game 无 Human/StarterContent 或 temp 运行依赖。
- 接入前提：原 Battle 视觉评审已通过；Human 需求标明 Logic Test 已验收，本轮用户明确授权按计划集成。历史 battle.md 的“待独立评审”记录保留为当时状态；本轮重新检查 battle 公共接口、依赖方向与测试结果，并在本记录确认接入条件。
- 独立入口：`game/battle/battle_scene.tscn`；Game Test 工作区入口维持原路径。2D 编辑为 scene_001/map.tscn，3D 预览为 scene_001/preview.tscn。
- 验证：Godot 4.7.2（GODOT_PATH），OpenGL Compatibility，RTX 3060 Ti。battle 158 项、Logic Test 18 用例／98 项均为零失败；Art Test 专项、工作区导航图形回归均为零失败。Game Test 集成 81 项、真实渲染及输入 461 项为零失败。
- 覆盖：固定方案获胜、空场失败、三波与双路线、五种职业、部署拒绝不扣费、阻挡、伤害、治疗、技能、撤退和再部署；纯逻辑与实际组装状态及事件流一致；暂停／单步／倍速、重开、释放与重复进入；保存编辑地图和资源后的重载、空格与水域、断路／越界／错误波次阻止启动；三种窗口尺寸拾取与 UI；调试窗拖动、缩放、输入隔离及 F3 开关。
- 证据：`temp/game_integration.log`、`temp/game_visual.log`、`temp/game_regression_*.log`；`temp/verification/game_fighting.png`、`game_debug.png`、`game_1280x800.png`、`game_960x600.png`、`game_1600x900.png`、`game_editable_map.png`、`game_map_preview.png`、`game_victory.png`、`game_defeat.png`。已检查真实渲染截图；程序化输入不表述为人工操作桌面。
- 限制：角色使用现有正／背面待机／攻击姿态与水平翻转，飞行敌人用抬高立片表示；地图路线为显式轴向折线，无自动寻路；重载只读取已保存内容且重置战斗。编辑器导入曾出现受限环境 Safe save failed，资源导入、场景运行与测试成功，未改动用户编辑器安全保存设置。
- 评审结论：实现检查与自动集成验证通过，可接入 Game Test；本记录不声称用户已人工验收本轮新画面。
- 评审人和日期：Codex，2026-10-21。
- 集成位置：Developer Hub → Game Test → 实际 game/battle 组装场景。


## 参考图改造复核（2026-10-21）

- 依据 Human/ArtReference.jpg 放大战场投影、提高俯视角，并将地图投影中心移至 HUD 安全区中心；1280×800、960×600、1600×900 的全部 60 格均保持可见且拾取一致。外围废墟允许裁切，环境平面覆盖背景，避免底座式构图。
- TileMap 中草丛由重复条带改为六块零散分布；减少草叶密度、高度和亮度，改用断续外围废墟、暖主光及冷环境光。高台／道路的部署属性、高度、双路线、原防守位置和所有战斗数值保持一致。
- 顶部只集中显示敌人进度与基地生命，费用／部署数量移至右下。卡组使用已有肖像裁切、顶部费用与冷却遮罩；部署成功由快照驱动隐藏，撤退／阵亡后恢复，Container 自动收拢，节点顺序保持原编队顺序。角色仅常驻血条，详情选中查看。
- F3 保留小按钮与快捷键；返回 Hub 移入游戏菜单。工作区导航验证经真实菜单点击完成。
- 新增验证：非法部署保留卡片、成功部署隐藏、撤退恢复、真实死亡事件恢复、冷却结束、费用不足、编队顺序、重开清除遮罩；图形输入检查覆盖无空位收拢、卡组右对齐、撤退冷却与无常驻生命数字。
- 最终验证：集成 81 项、真实图形／输入 461 项、battle 158 项、Logic Test 18 用例／98 项均零失败；Art Test 专项与工作区导航均零失败。真实渲染使用 GODOT_PATH 引擎的 Compatibility 后端，未用 headless 代替画面验收。
- 已检查截图：temp/verification/game_1280x800.png、game_960x600.png、game_1600x900.png、game_fighting.png、game_partial_roster.png、game_redeploy.png。检查了战斗遮挡、部分部署收拢及撤退冷却后的实际画面。日志沿用 temp/game_integration.log、game_visual.log、game_regression_*.log。
- 依赖复核：HUD 只消费快照、发送意图；没有新增 battle 规则或状态副本；正式表现复用原资源，无新增图像资产。Human/Human.md 的用户修改保持原样。本记录为实现及验证结果，不代表用户已人工验收新画面。


## 头部被草丛／高台遮挡早期修复（已由后续方案替代）

- 已复现用户报告：完全相机朝向的立片在俯视角下倾斜，与后排高台及草丛交叉；只隐藏草叶无法消除高台裁切。
- 角色改为竖直的 Y 轴朝向，并做垂直投影补偿，保留正常深度检测与脚底锚点；血条对齐贴图实际不透明区域顶部，角色点击范围同步更新。
- 新增 game/tests/actor_occlusion_test.gd：在三个实际窗口尺寸下比较角色独立渲染与完整地形渲染的头部像素，覆盖道路近卫、草丛下重装攻击背面姿态和草丛上术师。修复前明确失败，修复后九个用例头部均 100% 可见。
- 最终复跑：遮挡回归 9 项、图形／输入 461 项、战斗集成 81 项及 Art Test 专项均零失败。证据为 temp/actor_occlusion.log、temp/verification/head_*.png 和更新的 game_fighting.png。未更改战斗规则、草丛数据或用户 Human/Human.md 修改。


## 完整 Billboard、拖动部署与脚下状态条（2026-10-22）

- 根据用户反馈撤销 Y 轴 billboard 和纵向补偿，恢复永远平行于镜头的完整 billboard。可见几何与原始比例保持一致；新增 feature 内的 billboard_depth 着色器，将遮挡深度映射到脚底竖直平面，解决草丛切头，同时保留前景墙遮挡、受击闪烁及淡出。
- 干员卡支持按住拖动：角色预览、候选格高亮、松开后四向确认，确认前不扣费。地图外、调试窗、Esc、右键、重置及失焦取消拖动；仍保留点击卡片再点击地块的原操作。非法地形／占位由 battle 原命令拒绝，失败不扣费、不隐藏卡片。
- 按用户确认，干员脚下常驻生命绿条和技力蓝条，技能开启期间增加金色持续时间条。值直接来自快照 HP/SP/skill_left；暂停和倍速沿用模拟时钟。敌人只显示生命条，不再将干员状态条置于头顶。
- 专项验证：actor_occlusion_test 共 21 项，覆盖三个窗口尺寸下原生 billboard 轮廓一致、头部 100% 可见、真正前景遮挡及闪烁／淡出；deployment_view_test 共 24 项，覆盖真实指针拖动、朝向确认、非法地形／占位、卡片隐藏、取消、重置、调试窗隔离、状态条颜色／位置／技能期限／暂停。均零失败。
- 证据：temp/actor_occlusion.log、temp/deployment_view.log、temp/verification/head_*.png、game_dragging.png、game_foot_bars.png、更新的 game_fighting.png。未改动 battle 规则、地形数据和用户 Human/Human.md 修改。

- 最终完整回归：Game Test 集成 81 项、整关真实图形／输入 461 项、battle 158 项、Logic Test 18 用例／98 项均零失败；Art Test 专项与工作区导航复跑均零失败。图形点击助手补充点击前的指针移动，使注入事件顺序符合实际操作。三种窗口尺寸均使用 GODOT_PATH 的真实 Compatibility 渲染。


## 2026-10-22 待部署与鼠标朝向

拖放松开后在候选地块保留独立表现立片并显示攻击范围，不生成战斗单位、不扣费。鼠标从地块中心移出 24 像素后，依据相机投影选择四向，保持候选格不变，同步更新姿态、地面箭头和攻击范围；左键确认后由 battle 验证部署。右键、Esc、重开、终局及重载清理预览。原朝向按钮继续可用。待部署时始终显示攻击范围，不受调试范围开关影响。

验证：真实渲染部署交互 38 项检查、战斗集成 81 项检查及完整图形回归 461 项检查全部通过。覆盖四向移动、原地预览、未定向点击、确认前费用与单位数、成功后卡片隐藏、取消清理及三种窗口比例。图形测试按钮定位前等待容器完成布局，消除信息面板刚显示时按钮坐标未更新造成的偶发误点。输出位于 temp/deployment_view.log、temp/game_integration.log、temp/game_visual.log，待部署截图 temp/verification/game_pending_deployment.png。


## 2026-10-22 Art / Game Battle 显示统一

- Art Test Battle 移除预览专用的手写生命条、HUD、镜头／光照与入口绘制，改用模拟快照接入同一个 BattlePresentation 和 playable_hud。样例与正式编队对齐为五类干员、三类敌人；不创建 battle 模拟器，也不计算战斗规则。
- battlefield_stage 统一相机创建／适配、环境与路线端点标记。Game Test 敌方入口和基地采用原 Art Test 红色 ec5743／蓝色 63c6f5、0.85 格十二边线框样式；两边端点由当前地图路线生成。敌人共用同一 appearance、朝向、飞行高度和状态条显示。
- 保留 Art Test 的页签导航、16:9 预览、暂停／倍速、重播、隐藏停渲染和释放；Game Test 保留全窗口、部署鼠标定向、技能、撤退与内嵌调试。
- 实际 Godot 4.7.2 Compatibility / RTX 3060 Ti 渲染验证：显示一致性 90 项、完整游戏图形 461 项、部署交互 38 项、角色遮挡 21 项检查全通过；headless 战斗集成 81 项通过；Art Battle 与工作区导航均 0 failures。图形回归覆盖 1280×800、960×600、1600×900；Art 页缩放与输入由其专项检查覆盖。
- 输出：temp/presentation_parity.log、temp/art_shared.log、temp/game_visual.log、temp/deployment_view.log、temp/actor_occlusion.log、temp/game_integration.log、temp/game_regression_workspaces.log。相同快照截图：temp/verification/art_shared_battle.png、temp/verification/game_shared_battle.png。
- 检查结论：两边消费同一快照时角色、HUD、构图、状态条和入口标记一致；生产代码未引入对 devtools 或 temp 的依赖；未修改 Human/Human.md。


## 2026-10-22 部署职业与地形限制

规则层原有近战仅限 ground、远程／医疗仅限 high 的校验保持不变；交互层提前检查选格与拖放，错误地形不进入待部署、不创建预览角色，显示“近战干员只能部署在地面”或“远程／医疗干员只能部署在高台”，保留卡片与费用。卡片悬停标注地形要求，允许继续选择正确地块。地图判断仍来自 TileMap 导出的 terrain。

验证：跨模块集成 106 项检查通过，逐一覆盖五类干员的错误地形拒绝、费用和卡片不变、正确地形待部署及最终部署；真实渲染拖放／朝向专项 48 项检查通过，包括射手、术师和医疗落地拒绝及高台允许。Art Test HUD 回归与原 battle 部署规则检查同时验证。输出为 temp/game_integration.log、temp/deployment_view.log、temp/art_shared.log、temp/game_regression_battle.log。


## 2026-10-22 攻击、受击特效

远程干员及远程敌人的 attack_start 创建朝目标飞行的子弹；近战单位的 attack_start 创建攻击者前方刀光。damage 在目标处播放受击闪光并保留原有角色闪烁，heal 使用绿色治疗图，skill_start 使用强化图。全部复用 effect_001 原图集的 AtlasTexture，不生成或修改原图片。

效果通过 BattlePresentation 单一事件入口创建，位置考虑地形、飞行高度与 billboard 身体锚点；子弹跟踪目标，damage／miss 清除对应子弹。effects 使用外部模拟时钟，暂停冻结、倍速与固定步长一致，重开／退出清理；不增加伤害计算，也不改变结算时机。命中闪光采用较高渲染优先级确保立片上可读。Art Test Battle 改用模拟攻击与伤害事件进入同一适配器，并在重播时清理效果和攻击姿态。

验证：combat_effects_test 使用真实 Godot Compatibility 渲染，185 项检查通过，覆盖敌我双方远程／近战、伤害／治疗、命中／落空、暂停／2×、重开及实际像素可见性；普通获胜编队之外，用单重装对单近战敌人的实际战斗确认阻挡后刀光。显示一致性 90 项、战斗集成 106 项、完整游戏图形 461 项通过，Art Battle 专项 0 failures。原 battle 规则代码未修改。

日志：temp/combat_effects.log、temp/presentation_parity.log、temp/game_integration.log、temp/game_visual.log、temp/art_shared.log。实际渲染截图：temp/verification/combat_projectile.png、combat_slash.png、combat_impact.png。新增接口见 features/effects/README.md。


## 2026-10-22 橙色攻击范围覆盖层

将原攻击范围细黄线框改为橙色半透明地块覆盖层与亮橙边框，按各格 surface_height 贴合地面／高台；拖动、待部署朝向和选中在场单位共用样式，保留候选格、朝向箭头及地形纹理，覆盖层不参与拾取。规则范围仍直接使用 battle/combat.range_cells。

真实 Compatibility 渲染下 deployment_view_test 48 项检查通过，覆盖拖放、四向选择、取消、部署限制与三种窗口尺寸。已检查 temp/verification/game_pending_deployment.png 的橙色填充与角色可读性；日志 temp/deployment_view.log。


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


## 2026-10-22 更正顶部敌人／基地样式

用户所指的是顶部 HUD 的敌人进度与基地生命图标。此前误解成地图入口标记，且把原 Art Test 的图标改成文字。现已恢复原 Art Test 的旗帜 ⚑／城堡 ♜ 图标与数字，两边共用 battle_hud_overlay.status_readout 格式；保持已统一的显示逻辑。地图入口标记与战斗规则未在本次更正中改动。

真实渲染已检查 temp/verification/game_1280x800.png，顶部图标正常；Art Battle 专项 0 failures，完整游戏图形 461 项检查通过，覆盖三种窗口尺寸。日志 temp/art_shared.log、temp/game_visual.log。


## 2026-10-22 部署高亮阶段调整

拖动／选择干员后，以绿色半透明地块覆盖层显示所有当前可部署位置；仅悬停在合法候选格时显示橙色攻击范围，待部署定向继续显示。错误地形、已占用格和地图外不显示橙色；提交成功／取消清除全部部署高亮，点击在场干员也不再显示攻击范围。绿色和橙色使用不同高度及绘制优先级，重叠时橙色清晰可见。

新增 battle.deployment_check 只读公共接口，并让 deploy 复用完全相同的校验；绿色候选同时尊重占位、费用、职业地形、冷却和部署上限，不在游戏层复制规则。候选集纳入覆盖层刷新签名，使战况变化能够更新高亮。错误候选不进入待部署状态。

实际 Compatibility 渲染：deployment_view_test 54 项、完整游戏图形 461 项通过；battle 159 项与战斗集成 106 项通过。检查了拖动无效格时只有绿色、合法格绿色与橙色并存、确认后清除、占用格排除，以及远程／医疗合法高台提示。输出 temp/deployment_view.log、temp/game_visual.log、temp/game_regression_battle.log、temp/game_integration.log；截图 temp/verification/game_dragging_invalid.png、game_dragging.png、game_pending_deployment.png。


## 2026-10-22 射手／术师／近卫范围

正式 stats.tres 调整射手为横向 3、朝向纵深 4（12 格），术师为 3×3（9 格），近卫显式配置横向 1、纵深 2（2 格，原默认值相同）。均从自身所在格起算，横向以干员为中心；使用既有 combat.range_cells 四向旋转，无表现层范围副本。

临时引擎校验三类单位共 12 个朝向，范围面积与尺寸均正确；真实渲染检查 temp/verification/range_sniper.png、range_caster.png、range_guard.png；部署交互 54 项、战斗集成 107 项通过，固定命令序列仍可获胜。日志 temp/operator_ranges.log、temp/deployment_view.log、temp/game_integration.log。


## 2026-10-22 修正干员及敌人朝向

确认 pose 原图默认向左，原共享表现却在 facing=2 时翻转，导致左右相反；现改为 facing=0（右）才水平翻转。部署预览、五类在场干员的待机／攻击、敌人及 Art Test 同步修正；逻辑朝向编号、范围和箭头保持原定义。

同时修正敌人出生首帧：新立片先放到逻辑位置，再按距离对应的路线段初始化朝向；后续根据实际位移更新，避免从默认世界原点推断首帧方向。无路线的 Art 模拟快照沿用传入 facing。

复现脚本初始 16 项中 13 项失败；修复后永久回归 facing_test 52 项通过，覆盖五名干员四向待机／攻击、三类敌人左右路线的出生首帧与后续移动。真实渲染已核对 facing_0.png（朝右）与 facing_2.png（朝左），部署交互 54 项、显示一致性 84 项、战斗集成 107 项及 Art Battle 专项通过。日志 temp/facing.log、temp/deployment_view.log、temp/presentation_parity.log、temp/game_integration.log、temp/art_shared.log；截图 temp/verification/facing_*.png。

### 选中在场干员显示范围

点击已部署干员时，按战斗快照中的位置、朝向与范围配置显示橙色覆盖层；取消选择、撤退或离场时清除。部署成功后不自动选中，继续保持部署完成即清除预览。覆盖层缓存纳入选中单位信息，切换干员时正确刷新。

真实图形验证：deployment_view_test 58 项、operator_actions_test 26 项均通过；截图 `temp/verification/game_selected_range.png`，日志 `temp/verification/selected_range.log`、`selected_range_actions.log`。

### 选中干员的就近操作与信息展示

撤退改为干员附近左上角的图标按钮，技能改为右下角的技能图标按钮。游戏层投影干员位置并调用 HUD 的 set_operator_anchor，HUD 负责窗口内布局及避免与左侧详情重叠；窗口变化后重新定位。按钮继续只发正常撤退／技能意图，快照控制技能就绪、持续中与无主动技能的禁用状态，离场、取消选择及终局时隐藏。

左侧展示所选干员立绘、生命与技力、技能图标及功能说明；描述从实际技能倍率、持续时间与回复方式生成，不另存规则。复用原有立绘与技能纹理。

真实渲染检查 1280×800、960×600、1600×900；operator_actions_test 48 项、battle_visual_test 459 项、deployment_view_test 58 项通过，Art Battle smoke 通过。验证包含图标相对位置与边界、切换干员、技能释放及禁用、撤退返费与冷却、取消选择隐藏、地图边缘避让、调试窗输入隔离。截图 temp/verification/operator_actions_*.png，日志 temp/verification/nearby_*.log。

### 顶部 HUD 比例与调试入口位置

移除部署卡片的 tooltip_text，悬浮不再弹出名称／部署地形字样。顶部菜单、倍速、暂停按钮与图标放大 1.5 倍，中央进度图标和数字字号放大 1.2 倍并扩展容器。开发者 F3 按钮改为左下角锚定，提示／开始区域右移留出空间。

真实图形回归 battle_visual_test 459 项通过，覆盖 1280×800、960×600、1600×900、菜单、暂停倍速、F3 调试窗输入隔离及导航。已核对 temp/verification/game_960x600.png；对应三种尺寸截图 game_*.png，日志 temp/verification/top_hud_scaling.log。

### 角色表现下移与方形操作按钮

共享 actor_view 根据相机投影，将角色视觉锚点沿原高度平面移动至屏幕向下 20px 处，逻辑位置保留。干员、敌人、飞行单位及待部署预览统一生效；拾取、附近操作按钮、状态条、阴影与攻击／受击特效同步使用视觉位置。撤退与技能图标的全部按钮状态改为正方形，技能就绪边框也不再倾斜。

真实渲染验证：三种窗口尺寸的五名干员与三类敌人均下移 20px，拾取同步；facing_test 115 项、actor_occlusion_test 21 项、operator_actions_test 48 项、deployment_view_test 58 项、combat_effects_test 215 项、presentation_parity_test 84 项、battle_visual_test 459 项全部通过。截图 temp/verification/actor_lowered_*.png，日志 temp/verification/actor_lower_*.log。

### 干员脚下罗盘方向标识

共享 actor_view 新增纯 shader 绘制的半透明圆面／圆环及三角方向箭头，无新增图片。水平 PlaneMesh 跟随视觉脚点，方向读取同一快照 facing，覆盖四向待机与攻击，待部署时同步鼠标选向。使用较低绘制优先级的地面覆盖层，避免在高台边缘被截掉，角色和脚下状态条保持可读；敌人不显示此标识，撤退／离场立即移除，重开随角色清理。删除游戏层旧的待部署点状箭头。

真实渲染验证 facing_test 185 项、deployment_view_test 62 项、operator_actions_test 49 项、presentation_parity_test 84 项、actor_occlusion_test 21 项全部通过。包含五类干员四向姿态、三种窗口尺寸下的脚点对齐、待部署朝向、敌人排除和撤退清理。四向对照图 temp/verification/compass_four_directions.png，原图 facing_0.png 至 facing_3.png；日志 temp/verification/compass_*.log。

### 五名干员技能与正式图集图标

采用用户提供的 Human/StarterContent/icon/skill-atlas-01.png，原件保留；正式副本与16张 AtlasTexture 位于 content/ui/skill_icons。近卫锋刃（攻击200%／5秒）、重装坚城（防御250%／8秒）、射手疾风连射（间隔50%／6秒）、术师聚能爆破（法术攻击220%／6秒）、医疗急救增幅（治疗200%／8秒），五项手动释放，分别配置自动／受击／攻击回复。具体数值保持在 stats.tres，外观资源引用对应图标，不由HUD计算效果。

Art Test 新增第五页 Skill 和独立 skill_preview.tscn 入口，仅完整展示16张美术素材及其编号、来源行列；Game Test 左侧详情和附近按钮引用同一纹理，技能功能文案仅在 Game Test 显示。描述含技能名称与配置文案。额外处理场景组装期间镜头尚未拟合的投影零深度，消除 headless 集成检查的投影报错。

验证：规则172项、五技能集成53项、原关卡107项、技能／撤退交互49项、显示一致性84项、全图形459项通过；Logic Test 18 cases / 98 checks 和 Art Battle smoke 通过。五技能集成用真实战斗充能并释放全部技能，比对纯逻辑与游戏最终快照一致且胜利；在1280×800、960×600、1600×900渲染 Skill 页，图标切片与操作面板已核对。截图 temp/verification/skill_art_*.png、skill_atlas_*.png、skill_game_*.png；日志 temp/verification/skill_*.log。

导航补充：workspace_smoke 已覆盖第五个 Skill 页签与 skill_preview 独立入口，最终 Visual/navigation verification 为0失败。首轮合成鼠标导航在退出 Animation 时出现一次离场释放断言失败，单独完整复跑通过；本次未更改导航点击辅助实现。

### 移除 Logic Test 界面

Game Test 接管手动战斗验证，删除旧 Logic Test 工作区及绘制脚本，首页保留 Blueprint、Art Test、Game Test、Story Test 四个入口。18个有价值的固定命令场景和观察器迁入 features/battle/tests，无界面回放仍验证全部原场景及不同时间分片下的状态一致性；旧界面相关12项检查随界面退役，等价能力由现有Game Test与battle测试覆盖。测试迁移详情和运行命令见 features/battle/tests/README.md。

验证：场景回归18 cases／86 checks、基础规则172项、游戏集成107项、真实游戏图形459项全部通过，首页／工作区导航0失败。已核对首页四入口截图 temp/verification/hub.png，当前代码与运行配置不再引用删除的工作区路径。日志 temp/verification/scenario_migration.log、logic_removed_*.log。历史Logic Test评审保留为当时状态，并标注迁移路径。

### 清理产品界面的注释式文案

移除“技能就绪·点击图标释放”、充能／操作教学、部署鼠标说明、常驻成功提示及技能按钮指导性tooltip。技能可用性由图标亮光、禁用态和技力条表达，仅持续期间保留剩余时间；详情保留干员数值、技能名称和功能。notice 只承载简短失败原因，正常选择与操作清除并隐藏空提示，Art Battle 同步移除模拟快照提示。产品文案边界已写入 docs/architecture.md。

真实渲染与交互检查 operator_actions_test 49项、deployment_view_test 62项通过，覆盖三种窗口尺寸、技能就绪／充能／持续、撤退及非法部署反馈。截图 temp/verification/operator_actions_*.png，日志 temp/verification/product_copy_*.log。
