# Story

独立的同步对话图模块，负责节点推进、分支选择、本次播放记录和可复用演出视图。没有 devtools、具体内容或 battle 依赖。game/player 已组装第一章的战前／战后线性剧情；Markdown 解析位于 game/content，存档与解锁由 game/player 负责。

`story_script.gd` 定义 Resource：`title`、`start` 和以字符串 ID 为键的 `nodes`。节点均包含 `type`、`text` 和可选 `speaker`：

- `line`：包含 `next`，调用 `advance()` 推进。
- `choice`：包含非空 `choices` 数组，每项包含 `text` / `next`，调用 `choose(index)` 推进。
- `end`：终点，拒绝继续或选择。结束文字仍可读取。

`errors()` 检查起点、字段类型、选项和跳转目标。允许循环图，推进完全由调用方操作，没有自动执行循环。

可选演出字段：`background` 为背景 ID；`actors` 为最多两个不重复的角色 ID 数组；`speaker_actor` 为其中正在说话的角色 ID。不提供这些字段仍可只运行文本；每个节点提供完整场景状态，不继承上个节点。`actors: []` 表示角色退场。

`story_session.gd` 公共接口：

- `load_story(resource) -> PackedStringArray`：校验后复制图并开始；失败返回错误，保留之前的会话。
- `advance() / choose(index) -> bool`：拒绝错误时机和非法索引；成功后到达下个节点。
- `restart()`：清空记录，回到本次加载的起点。
- `snapshot() -> Dictionary`：当前节点、`id`、`title`、`finished`、`history` 的深拷贝。未加载时为空。历史中选择节点的 `selected` 保存选择文字。

验证：`& $env:GODOT_PATH --headless --path . --script res://features/story/tests/story_test.gd`

`story_view.gd` 是独立 Control，不创建会话。调用方用 `configure(backgrounds, actors)` 传入 ID → Texture2D 映射，再调用 `show_snapshot(snapshot)`。它按比例铺满背景、显示单人居中/双人左右的透明角色、降低非说话角色亮度，并绘制底部黑色渐变、说话人、可滚动对白和选择按钮。`advance_requested` / `choice_requested(index)` 只表达输入意图，由调用方决定能否推进。贴图不会拉伸，不读取任何固定 content 路径。

暂不支持条件分支、变量、存档、脚本事件、打字机、音频或转场动画。自动播放、跳过和记录弹层属于 Story Test 控制，不是会话隐含行为。
