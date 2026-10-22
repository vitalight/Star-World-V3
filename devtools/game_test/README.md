# Game Test

从 Developer Hub 进入 Game Test，或在 Godot 中 F6 运行 `game/battle/battle_scene.tscn`。默认项目入口仍是 Developer Hub。Game Test 使用主视口完整显示战场，没有固定宽高比留边和工作区滚动外壳。

## 操作

1. 准备态可先部署。点击底部干员卡再点击地块，或按住卡片拖到地块松开，角色会站在候选地块进入待部署状态并显示攻击范围；随后从地块中心向右／下／左／上移动鼠标选择朝向，立片、箭头与范围同步更新，再按左键确认部署。中心 24 像素内不选择新朝向，未选择朝向时点击战场不会部署；也保留朝向按钮与确认按钮。拖动时显示立片预览和候选格；右键或 Esc 可取消，松开在地图外或调试窗中也会取消。确认前不扣费，确认后仍由 battle 判定合法性。绿色高亮只表示当前 battle 规则允许部署的空格；拖到合法格才显示橙色攻击范围，部署成功后两种高亮立即清除。最终提交仍由 battle 验证，失败不扣费。
2. 点击“开始战斗”推进波次。右上角控制暂停与 1×／2×。暂停时允许明确的部署、撤退和技能命令，模拟与表现时钟冻结。
3. 干员脚下常驻生命绿条和技力蓝条，技能开启时增加金色持续时间条，结束后隐藏；敌人只显示生命条。点击在场干员的立片或地块，左侧查看生命、阻挡、技力和技能剩余时间，执行撤退或释放技能。已部署干员立即从右下卡组隐藏，其余卡片靠右收拢；撤退或阵亡后按原编队顺序恢复，冷却遮罩显示倒计时，冷却结束后仍需满足费用才能选择。
4. 终局显示防守成功／基地失守，点击“重新挑战”恢复准备态。左上菜单也可重开，或选择“Developer Hub”返回；独立运行游戏场景时该操作结束运行。
5. Game Test 左上菜单内的“Developer Hub”返回首页。离开工作区释放战斗、角色、特效与观察连接。

F3 或左上角小按钮“F3”打开内嵌小窗：拖标题移动，拖右下角 ◢ 缩放，× 关闭；窗口限制在游戏区域内。工具提供开始、暂停、单步、1×／2×／4×、重置、重新加载关卡、网格／路线／范围、选中单位快照及最近 12 条事件。单步要求运行态且暂停。小窗的鼠标与键盘输入不传给战场，不直接改写模拟内部状态。

## 在编辑器制作关卡

- 打开 `content/scenes/scene_001/map.tscn`，选择 **Terrain / TileMapLayer** 在 2D 编辑器刷图。四种地块为道路地面、高台、高台草丛、水域；橡皮擦删除的格子没有 3D 地块且不可部署。
- 图集 `content/terrains/terrain_001/tileset.tres` 的自定义数据：`appearance` 为 R/H/G/W，`height` 是 3D 顶面高度，`deployment` 为 ground/high/none，`walkable` 表示路线可通行。编辑图集为单格 64×64；实际 3D 渲染仍使用原有高分辨率 atlas。
- 默认地图 bounds 为 `(0,0,10,6)`。地图从零坐标开始，改变大小时同步编辑 bounds。3D 地块、围墙、底座和游戏镜头据此适配；不要将路线穿过水或空格。
- 在 **Routes** 下选择 upper / lower 的 Path2D 编辑折线路径。2D 格心为 `(32+64*x, 32+64*y)`；建议吸附步长 64、偏移 32。控制点必须对齐格心，线段沿横／纵轴，曲线的入／出手柄保持零。路径节点名称即路线 ID，首点是出生点，末点是基地入口；编辑器用红／蓝点标记两端。
- 选根节点的 **Level** 资源，或直接打开同目录 `level.tres`：修改基地生命、费用、上限、编队、敌人和波次。编队／敌人的数值使用各自目录 `stats.tres`；波次的 time 为绝对战斗时间，enemy 和 route 必须匹配字典键与 Path2D 名称，number 用于显示波次编号。
- 地图根节点的配置警告显示越界、断路、水域、不对齐、非法资源与波次引用。运行时出现配置错误会显示原因并阻止开始，修复后可再次重新加载。
- 保存后打开 `content/scenes/scene_001/preview.tscn` 的 3D 视图。选中 Field，点击 Inspector 的 **刷新 TileMap 的 3D 预览**；该预览也可 F6 运行。它与正式游戏及 Art Test 复用相同地形生成器。
- 在正在运行的 Game Test 中用“重新加载关卡”读取已保存资源，包括外部数值与 TileSet。该操作重置战斗；仅修改尚未保存的编辑器内容不会影响运行中的关卡。

新增单位时，在对应 content 目录配置 `stats.tres` 与 `appearance.tres`，并将数值资源加入 Level。数值中的稳定 content_id 用于 game 查找外观；外观资源包含正／背面待机与攻击四种姿态、头像和显示高度。数值不引用贴图，正式模块不加载 Human 原图。

## 可重复防守方案

坐标从零开始，朝向编号为右0、下1、左2、上3。准备态部署以下干员，全部朝左：

| 干员 | 格子 |
| --- | --- |
| 近卫 guard | (3,1) |
| 重装 tank | (3,4) |
| 射手 sniper | (5,2) |
| 术师 caster | (4,3) |
| 医疗 medic | (4,2) |

开始后第 3 秒释放近卫技能，第 12 秒撤退术师，第 18 秒将术师部署回原格；等待三波共 13 名敌人处理完成，可稳定获胜。完整命令表在 `game/tests/defense_fixture.gd`。空场直接开始会基地归零失败。

## 验证

在项目根目录使用 `GODOT_PATH`，临时用户目录和全部输出留在 temp：

```powershell
New-Item -ItemType Directory -Force temp/game_test | Out-Null
if (-not (Test-Path temp/.gdignore)) { New-Item -ItemType File temp/.gdignore | Out-Null }
$env:APPDATA = (Resolve-Path temp/game_test).Path
& $env:GODOT_PATH --headless --path . --script res://game/tests/battle_integration_test.gd --log-file temp/game_integration.log
& $env:GODOT_PATH --path . --script res://game/tests/battle_visual_test.gd --log-file temp/game_visual.log
```

第一项比较纯逻辑与组装场景的状态／事件，验证关卡编辑、重载、非法配置、胜负和生命周期；第二项使用真实 Compatibility 渲染器与 Godot 鼠标／键盘事件，验证 1280×800、960×600、1600×900、部署、选择、技能、暂停、调试窗与场景退出。截图在 `temp/verification/game_*.png`。图形验收不可使用 headless 替代。

现有素材仅含四种姿态，移动依赖位置更新，受击闪烁、死亡淡出和事件特效使用程序表现；没有补造连续动作帧。Art Test 保持展示预览，Logic Test 保持纯逻辑验证。

## 参考图画面调整

按 Human/ArtReference.jpg 调整战术视角：镜头提高俯视角并放大地图，依据窗口比例和上下 HUD 安全区适配，外围废墟允许裁出画面。敌人进度与基地生命位于顶部中央，费用／部署数量和裁切肖像卡组位于右下；脚下显示生命绿条与技力蓝条，技能开启时增加持续时间条，详细数值选中查看。

TileMap 中减少高台草丛并改为零散分布，保留两条道路、地形高度及原防守位置；草丛降低高度、密度和颜色亮度，外围改为断续废墟，底部环境平面延伸至镜头外。继续复用原素材与战斗规则。


## Billboard 与交互回归

角色始终按镜头完整 billboard 渲染，保留原贴图比例；不再使用 Y 轴 billboard 或额外纵向拉伸。表现着色器将深度映射至经过脚底的竖直判定平面，避免后排草丛／高台切头，同时保留真正前景物体的遮挡。参考 [Godot spatial shader 的自定义深度接口](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)。

新增真实渲染回归入口：

```powershell
& $env:GODOT_PATH --path . --script res://game/tests/actor_occlusion_test.gd --log-file temp/actor_occlusion.log
& $env:GODOT_PATH --path . --script res://game/tests/deployment_view_test.gd --log-file temp/deployment_view.log
```

前者比较原生 billboard 轮廓、完整地形下的头部像素、前景遮挡、闪烁与淡出；后者用 Godot 鼠标和键盘事件验证拖动／朝向确认／非法落点／取消／调试窗隔离／三种窗口尺寸，以及生命、技力、技能持续时间和暂停同步。截图留在 temp/verification/game_dragging.png、game_foot_bars.png 和 head_*.png。


## Art / Game 显示一致性

Art Test 的 Battle 页以模拟快照使用同一表现适配器、角色资源和 HUD。两边共用 battlefield_stage 的构图／光照与原 Art Test 红色敌方入口、蓝色基地线框样式；端点均从 TileMap 编辑场景的路线生成。`game/tests/presentation_parity_test.gd` 使用相同快照检查角色姿态、敌人高度、状态条、卡片显隐、HUD 读数和端点几何一致。工作区外壳不同：Art Test 保留导航与等比预览，Game Test 仍铺满窗口。


部署地形限制：近卫／重装只能部署在地面；射手／术师／医疗只能部署在高台（包括高台草丛）。点击或拖放到错误地形时不会进入待部署状态，并显示地形要求；保留角色卡、不扣费，可继续选择合适地块。卡片悬停提示也显示“仅限地面／高台”。最终部署仍由 battle 校验。


攻击表现：远程干员与远程敌人在 attack_start 发射朝目标飞行的子弹，近战单位播放刀光；damage 到来时目标播放受击闪光并短暂变色，命中／miss 清除对应子弹。医疗使用独立绿色治疗特效，技能启动使用强化特效。特效跟随战斗时钟暂停和倍速，重开与退出清理；Art Test Battle 通过同一适配器预览这些事件。真实渲染专项入口 `game/tests/combat_effects_test.gd`，日志 temp/combat_effects.log，截图 temp/verification/combat_projectile.png、combat_slash.png、combat_impact.png。


攻击范围预览使用贴合各地块高度的橙色半透明覆盖层及亮橙边框；仅合法拖动候选与待部署定向显示范围；无效格、地图外、部署完成后，以及点击在场干员查看详情时均不显示范围。覆盖层保留地形纹理和角色可读性，不参与地块拾取。


## 技能与撤退

主动技能技力充满（包括自动回复达标）时，在场干员显示金色轮廓亮光与菱形提示。点击干员打开详情，点击高亮的技能图标按钮释放；技力不足、技能持续中或尚未开始战斗时按钮禁用，并显示原因。释放后就绪亮光消失，技能持续时间沿用脚下金色条；无主动技能的单位不显示就绪亮光。提示与动画使用战斗时钟，暂停冻结；待部署预览、离场与终局不显示提示。

详情中的“撤退”回收干员，返还部署费用的一半（向下取整，受费用上限限制）。卡片按原编队顺序恢复并显示再部署冷却，冷却期间禁止选择和重新部署；冷却结束后还需满足费用要求。详情显示返费与冷却信息。

技能图标由 appearance 的可选 skill_icon 字段提供，未配置时回退为角色头像；当前近卫复用现有强化特效作为图标，没有新增图片。完整鼠标操作验证入口为 game/tests/operator_actions_test.gd，截图 temp/verification/operator_skill_ready.png，日志 temp/operator_actions.log。


## 出怪前路线预告

每组出怪前播放一次 2 秒路线预告：半透明红橙色引导线贴在地面，连通该组出生点与基地，连续高亮光束从出生点流向目标，扫过一次后淡出；预告完成才开始出怪。同组后续敌人保留原间隔，不逐个重复预告。不同路线可同时预告。

路线仍取 TileMap 编辑场景中的 Path2D，跟随地表高度。时序由 battle 产生 route_warnings 快照与 route_warning 事件，表现只按模拟时间显示，支持暂停、单步和倍速；重开、重载、终局和离开时清理。Level 的 route_warning_duration 当前为 2 秒；Wave.time 是期望的最早首怪时刻，若不足 2 秒则顺延至第 2 秒，后续组的时间保持不变。Art Test 使用同一引导线实现，模拟预告完成后再显示敌人。

验证入口 game/tests/route_warning_test.gd；日志 temp/route_warning.log，三种窗口截图 temp/verification/route_early_*.png、route_late_*.png。


顶部敌人进度／基地生命沿用原 Art Test 的图标样式：旗帜 ⚑＋进度、城堡 ♜＋剩余生命，Art Test 与 Game Test 共用格式，不以“敌人／基地”文字替代图标。


部署高亮使用 battle.deployment_check 的只读结果：绿色半透明覆盖层表示当前可部署格（同时检查地形、占用、费用、冷却与上限），橙色覆盖层仅在合法候选格显示攻击范围。取消或成功部署清除绿色和橙色覆盖层；在场干员的详情、技能和撤退操作继续正常使用。


当前攻击范围（含干员所在格，随四向朝向旋转）：射手横向 3 格、朝向纵深 4 格；术师 3×3；近卫横向 1 格、朝向纵深 2 格。预览与实际判定均读取各自 stats.tres 的 range_cells。


角色朝向：当前立片原图默认朝左，所以部署朝右（0）时水平翻转、朝左（2）时保持原图；上／下沿用正背面姿态。待部署预览、在场待机／攻击和敌人共用同一映射。敌人出生首帧按所在路线段初始化朝向，后续按实际移动方向更新，不从世界原点推算。
