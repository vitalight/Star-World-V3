# Effects

`effect_view_3d.gd` 接受外部贴图和外部展示时钟，不计算伤害，不加载具体 content。原有 `show_phase(time)` 循环预览保持可用。

- `play_once(color, seconds)`：单次缩放淡出，用于受击、治疗、技能启动。
- `play_projectile(from, to, seconds, color)`：沿世界坐标飞行的子弹，贴图默认朝左，按照镜头平面朝向目标；`destination` 可由适配器更新以跟随移动目标。
- `play_slash(from, to, color)`：在攻击者前方播放朝向目标的刀光。
- `advance_visual(delta)`：只由外部模拟时钟推进；不自行使用真实时间。到期释放节点，`kind` 区分 projectile、slash、impact、heal、skill。

战斗单次特效作为小幅叠加提示，使用 render_priority 10 与 no_depth_test，保证在角色立片上可读；不会影响地块、角色或战斗拾取。循环预览保持原深度行为。

`game/adapters/battle_presentation.gd` 将真实／模拟 attack_start 映射为子弹或刀光；damage 映射为命中闪光与角色闪烁，heal 使用绿色治疗图，skill_start 使用强化图。命中或 miss 关闭对应飞行子弹，伤害时机始终由 battle 决定。重开、退出和终局清理效果。

具体素材来自 content/effects/effect_001 中的 AtlasTexture 配置：texture.tres（刀光）、projectile.tres（子弹）、impact.tres（受击）、healing.tres（治疗）、boost.tres（强化）。全部复用原有 atlas.png，未生成新图片。
