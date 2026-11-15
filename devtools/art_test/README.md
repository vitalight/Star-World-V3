# Art Test

Art Test 是资产与表现预览工作区，只展示素材和模拟快照，不运行战斗、伤害、部署或波次。从 Developer Hub 进入；`art_workspace.tscn` 默认打开 Character，各页签的 `*_preview.tscn` 可独立 F6 运行。

## 页签

- Character／Enemy：分别浏览角色和敌人的动作帧与内容 ID；未注册的素材标为“未注册”。
- Effect：浏览游戏使用的战斗特效。
- Animation：循环预览攻击、移动和特效，支持播放、暂停和重播；怪物移动为静态姿态配合程序摆动。
- Battle：使用正式表现适配器和模拟快照展示 3D 战场、角色、HUD 与路线端点，无战斗模拟。
- Skill：浏览技能图标切片。

## 素材与依赖

- 已注册角色、敌人和技能直接通过游戏的内容目录获取；战斗特效直接使用表现适配器引用的资源。更新正式内容后预览自动跟随。
- 尚未注册的角色与敌人读取现有预览素材；注册正式内容时移除对应的预览条目。
- 首次进入只创建当前页签；其他页签在首次打开时创建，并共享本次打开时读取的游戏内容目录。
- Battle 与 Game Test 共用 `scene_001`、表现适配器、HUD 和战场组件；表现模块不依赖具体 content、devtools 或 battle。
- 浏览目录、导航和播放控制属于 devtools。

## 验证

`devtools/hub/tests/workspace_smoke.gd` 检查导航、页签切换、素材切片、播放状态和窗口排版；`devtools/art_test/battle_visual_smoke.gd` 使用真实渲染检查 Battle 页的暂停、倍速、缩放和隐藏停渲染。日志与截图写入 `temp/`，图形验收不能使用 headless。
