# Story

同步对话图模块：节点推进、选择、本次播放记录和可复用演出视图。不依赖 devtools、具体内容或 battle；Markdown 解析位于 game/content，存档与解锁由 game/player 负责。

## 资源

`story_script.gd` 定义 `title`、`start` 和以字符串 ID 为键的 `nodes`：

- `line`：包含 `next`，调用 `advance()` 推进。
- `choice`：包含非空 `choices`（`text`／`next`），调用 `choose(index)` 推进。
- `end`：终点，拒绝继续或选择。

`errors()` 校验起点、字段类型、选项和跳转目标。允许循环图，推进完全由调用方控制。

## 会话

`story_session.gd` 公共接口：

- `load_story(resource) -> PackedStringArray`：校验后复制图并开始；失败返回错误并保留之前的会话。
- `advance()`／`choose(index) -> bool`：拒绝错误时机和非法索引。
- `back() -> bool`：回到实际历史中的上一节点并删除后续记录。
- `restart()`：清空记录，回到本次加载的起点。
- `snapshot() -> Dictionary`：返回当前节点、`id`、`title`、`finished`、`history` 的深拷贝。

## 视图

`story_view.gd` 是独立 Control，不创建会话。调用方用 `configure(backgrounds, actors)` 注入 ID → Texture2D 映射，再调用 `show_snapshot(snapshot)`。视图通过 `advance_requested`、`choice_requested(index)`、`ui_sound_requested(id)` 只发出意图，是否推进或播放音频由调用方决定；视图不读取固定 content 路径。

节点可选字段：`background`、`actors`（最多两个不重复 ID）、`speaker_actor`、`framing`（`wide`／`left_close`）、`anim_screen_shake`、`anim_actor_shake`、`anim_actor_flip`、`actor_mirror`、`anim_actor_exit_left`／`anim_actor_exit_right`。每个节点提供完整场景状态，不继承上一节点；`actors: []` 表示全部退场。

对白逐字显示，文本中的换行后停顿 0.6 秒；调用方可用 `is_typing()` 查询状态，并用 `reveal_dialogue()` 立即显示全文（返回是否跳过了动画）。点击或按确认键先显示全文，再推进。暂不支持条件分支、变量、存档或脚本事件。演出过渡与动画细节由视图实现，验证见 `features/story/tests/`。
