# Story Test

从 Developer Hub 的 Story Test 进入，或 F6 运行 `story_workspace.tscn`。满屏显示背景和前景角色，以底部黑色渐变承载说话人和对白；顶部保留返回首页的共享面包屑与轻量控制。

基础验收：

1. 开场一人居中；点击“继续”、画面空白处或 Enter/Space 推进，随后两人左右出场，说话者高亮。继续后出现两条路线选项；选择期间隐藏“继续”。
2. 选择高地或水渠，背景从雪村切换为花园，另一角色退场；再继续到对应结局，所有角色退出。
3. “重播剧情”随时回到开场并清空记录，可以再体验另一分支。
4. 顶部“记录”打开可滚动对话记录，包含选择文字；“调试”额外显示节点、背景、出场角色与已读段数。
5. “自动”按阅读时长推进，分支和结束时停止；打开记录或调试时暂停计时。“跳过”仅推进对话，遇选择/结束停下，并以已访问节点和 128 步上限防止循环。
6. 通过 Developer Hub 面包屑返回首页；窄窗口顶栏换行，长对白可在底部区域滚动阅读。

`sample_story.tres` 是工作区专属假数据，不属于正式内容；新增样例可在此处编辑图数据。推进与演出复用 `features/story`，工作区传入素材并组装开发控制；尚未接入 Game Test。

背景直接使用用户指定的 `Human/StarterContent/story/story-01.png` / `story-02.png`。角色复用 Game Test 使用的 `content/data/character_001.tres` 和 `content/data/character_003.tres` 的 `appearance.poses[0]`；没有重画、复制角色素材或改变战斗外观映射。当前原素材是约 300px 的战斗立片，放大显示会偏柔和。

自动验证：

```powershell
& $env:GODOT_PATH --headless --path . --script res://features/story/tests/story_test.gd
& $env:GODOT_PATH --headless --path . --script res://devtools/story_test/workspace_test.gd
& $env:GODOT_PATH --path . --script res://devtools/story_test/visual_test.gd
& $env:GODOT_PATH --path . --script res://devtools/hub/tests/workspace_smoke.gd
```

渲染测试使用真实鼠标事件，截图写入 `temp/verification/`。Story 专项保存 `story_single`、`story_dual`、`story_garden`、`story_end`、`story_branch` 及窄屏版本，覆盖出入场、高亮、背景变化、选择、重播与记录弹层；Hub 测试覆盖入口、两条分支和退出。
# 正式章节预览补充

工具栏的内容下拉框提供原开发样例与第一章六段剧情。“重新加载”读取已保存的角色／技能／外观资源、背景表及 Markdown；“重播剧情”从当前已加载脚本开头播放。角色名、背景与外观映射使用正式 catalog；编辑说明见 `content/campaign/README.md`。
