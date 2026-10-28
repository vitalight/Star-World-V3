# 音频内容

`cues.tres` 是唯一的音频清单，`game/player/player_mode.gd` 加载后交给 `features/audio/audio_director.gd`。cue 使用语义键而不是实体编号：音乐为 `music_*`，音效为 `sfx_*`。

## 目录

```text
content/audio/
├── cues.tres
├── music/             # 背景音乐（循环）
└── sfx/               # 战斗与 UI 音效（单次）
```

文件名与 cue id 保持一致，便于对照，但程序只认 `cues.tres` 中的显式引用；改名需要同步更新对应 `[ext_resource]`。

## 新增或替换音频

1. 把文件放入 `music/` 或 `sfx/`，使用 snake_case 文件名。
2. 首次导入后设置循环（仅音乐）：编辑 `<file>.mp3.import` 的 `[params]`，把 `loop=true`；不要手写 `[remap]` 中的 `uid` 或 `dest_files`。
3. 用 Godot 重新导入，然后在 `cues.tres` 给对应 cue 的 `stream` 指到新资源；没有现成 cue 时新增一条 `AudioCue` 子资源。
4. 运行 `game/tests/audio_integration_test.gd` 确认清单有效。

尚未有素材的音效保留 cue 但留空 `stream`：播放时静默返回 `false`，属预期状态。

## 当前条目

- 音乐：`music_main`（主菜单／关卡／剧情／设置）、`music_battle`（战斗）
- 已有音效：`sfx_ui_click`、`sfx_attack`、`sfx_hit`、`sfx_heal`、`sfx_notify`（路线预警）
- 攻击音效在攻击起手事件播放，从素材 0.06 秒处开始，以减少前段低音量造成的听感延迟。
- 占位音效：部署、撤退、生成、费用、技能起止、受击、落空、阻挡、死亡、逃脱、胜负

## 署名

`music_main`：Danyvin — Chill R&B（原文件名 `background-peace-danyvin-chill-rnb.mp3`）
`music_battle`：Miromax Music — Stylish Funk（原文件名 `background-battle-miromaxmusic-stylish-funk.mp3`）
音效：freesound.org、Dragon Studio、Universfield、Kauasilbershlach Parodes、universfield（原始文件名见提交历史）

使用前请确认各素材的授权范围。
