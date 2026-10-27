# Story

独立的同步对话图模块，负责节点推进、分支选择、本次播放记录和可复用演出视图。没有 devtools、具体内容或 battle 依赖。game/player 已组装第一章的关卡线性剧情与章末尾声；Markdown 解析位于 game/content，存档与解锁由 game/player 负责。

`story_script.gd` 定义 Resource：`title`、`start` 和以字符串 ID 为键的 `nodes`。节点均包含 `type`、`text` 和可选 `speaker`：

- `line`：包含 `next`，调用 `advance()` 推进。
- `choice`：包含非空 `choices` 数组，每项包含 `text` / `next`，调用 `choose(index)` 推进。
- `end`：终点，拒绝继续或选择。结束文字仍可读取。

`errors()` 检查起点、字段类型、选项和跳转目标。允许循环图，推进完全由调用方操作，没有自动执行循环。

可选演出字段：`background` 为背景 ID；`actors` 为最多两个不重复的角色 ID 数组；`speaker_actor` 为其中正在说话的角色 ID。不提供这些字段仍可只运行文本；每个节点提供完整场景状态，不继承上个节点。`actors: []` 表示角色退场。`framing` 可选 wide（默认全景）或 left_close（裁取背景左侧 60% 后放大填满画面），每段独立设置，不继承。

`story_session.gd` 公共接口：

- `load_story(resource) -> PackedStringArray`：校验后复制图并开始；失败返回错误，保留之前的会话。
- `advance() / choose(index) -> bool`：拒绝错误时机和非法索引；成功后到达下个节点。
- `back() -> bool`：回到实际历史中的上一节点并删除后续记录；回到选择节点时清除原选项。起点或空会话返回 false。
- `restart()`：清空记录，回到本次加载的起点。
- `snapshot() -> Dictionary`：当前节点、`id`、`title`、`finished`、`history` 的深拷贝。未加载时为空。历史中选择节点的 `selected` 保存选择文字。

验证：`& $env:GODOT_PATH --headless --path . --script res://features/story/tests/story_test.gd`

`story_view.gd` 是独立 Control，不创建会话。调用方用 `configure(backgrounds, actors)` 传入 ID → Texture2D 映射，再调用 `show_snapshot(snapshot)`。它按比例铺满背景、显示单人居中/双人左右的透明角色、降低非说话角色亮度，并绘制底部黑色渐变、说话人、可滚动对白和选择按钮。`advance_requested` / `choice_requested(index)` 只表达输入意图，由调用方决定能否推进。`ui_sound_requested(id)` 在按钮按下和点击推进时发出，由调用方决定是否播放，视图自身不持有音频节点。贴图不会拉伸，不读取任何固定 content 路径。

暂不支持条件分支、变量、存档、脚本事件、或打字机。音频播放由调用方接入，模块只发出 UI 音效意图。自动播放、跳过和记录弹层属于 Story Test 控制，不是会话隐含行为。

同一背景图切换取景时，画面在约 0.35 秒内平滑过渡；切换到另一张背景图时在同样时间内交叉渐变。首次显示和剧情结束直接切换；连续推进、震动和窗口缩放不阻塞播放。验证：`res://features/story/tests/story_background_transition_test.gd`。

震动演出字段：节点可设置 `anim_screen_shake: bool` 与 `anim_actor_shake: Array[String]`。anim_actor_shake 只能包含本段 actors 中的唯一 ID。视图每次 show_snapshot 都从静止布局开始播放本段的衰减震动，重播会重新触发；调用方应只在进入／重播节点时显示快照。画面震动移动背景与所有角色，单独角色震动只移动目标；UI 保持静止。效果不阻塞推进，下一段、结束或空快照立即清除，resize 不重播。验证：`res://features/story/tests/story_shake_test.gd`。

连续剧情中仍然出场的角色按 ID 匹配；当单人、双人或左右顺序改变时，角色在约 0.3 秒内平滑移动到新布局，新出现的角色直接显示。移动时若朝向改变，会自动播放与 `anim_actor_flip` 相同的转身动画；显式配置翻转时不会重复播放。快速切段从当前显示位置继续移动；震动、离场和窗口缩放与布局移动可同时工作。结束或角色退场后不保留旧位置。验证：`res://features/story/tests/story_transition_test.gd`。

角色运动字段：`anim_actor_flip`、`actor_mirror`、`anim_actor_exit_left`、`anim_actor_exit_right` 都是本段已出场且唯一的角色 ID 数组，默认为空。未指定 actor_mirror 时，双角色镜头默认左侧镜像、右侧原图朝向，单角色居中默认镜像朝右；actor_mirror 令指定角色镜像，未列出的角色保留默认朝向（空列表不改变默认朝向）。actor_mirror 定义完整的最终朝向；anim_actor_flip 从其相反朝向经过横向收窄转到最终朝向，约0.24秒。anim_actor_exit_left／anim_actor_exit_right 先停顿0.3秒，再分别让目标用约0.45秒向左／向右移出并淡出，完成后隐藏，同一角色不能同时配置左右离场。每次 show_snapshot 从本段显式状态重新播放，不继承前段的缩放、朝向、透明度和离场状态；可与震动叠加。验证：`res://features/story/tests/story_actor_motion_test.gd`。
