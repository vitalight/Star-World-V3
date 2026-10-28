# Art Test

Art Test 是资产与表现预览工作区，只展示素材和模拟快照，不运行战斗、伤害、部署或波次。从 Developer Hub 进入；`art_workspace.tscn` 默认打开 Character，各页签的 `*_preview.tscn` 可独立 F6 运行。

## 页签

- Character：按图集行浏览角色四姿态。
- Effect：浏览特效图集切片。
- Animation：循环预览角色与特效素材，支持播放、暂停和重播。
- Battle：使用正式表现适配器和模拟快照展示 3D 战场、角色、HUD 与路线端点，无战斗模拟。
- Skill：浏览技能图标切片。

## 素材与依赖

- 开发预览直接读取 `Human/StarterContent/` 的原始图集；正式内容使用 `content/` 下的副本。
- 图集按 4×4 网格读取，不重新采样或覆盖原图。素材不含连续行走、受击或死亡帧，动态预览使用程序缩放、淡出等表现。
- Battle 与 Game Test 共用 `scene_001`、表现适配器、HUD 和战场组件；表现模块不依赖具体 content、devtools 或 battle。
- 浏览目录、导航和播放控制属于 devtools。

## 验证

`devtools/hub/tests/workspace_smoke.gd` 检查导航、页签切换、素材切片、播放状态和窗口排版；`devtools/art_test/battle_visual_smoke.gd` 使用真实渲染检查 Battle 页的暂停、倍速、缩放和隐藏停渲染。日志与截图写入 `temp/`，图形验收不能使用 headless。
