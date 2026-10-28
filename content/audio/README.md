# 音频内容

`cues.tres` 是唯一音频清单，由 `game/player/player_mode.gd` 加载后交给 `features/audio/audio_director.gd`。cue 使用语义键：音乐为 `music_*`，音效为 `sfx_*`。

音乐放在 `music/`（循环），音效放在 `sfx/`（单次）；文件名使用 snake_case。程序只认 `cues.tres` 中的显式引用，改名需要同步更新对应 `[ext_resource]`。

## 新增或替换音频

1. 将文件放入对应目录。
2. 音乐在 `<file>.import` 的 `[params]` 中设置 `loop=true`；不要手写 `[remap]` 的 `uid` 或 `dest_files`。
3. 重新导入后，在 `cues.tres` 中把对应 cue 的 `stream` 指向新资源；没有现成 cue 时新增 `AudioCue` 子资源。
4. 运行 `game/tests/audio_integration_test.gd` 验证清单。
5. 尚未有素材的音效保留 cue 并留空 `stream`；播放时静默返回 `false`，属预期状态。

## 署名

- `music_main`：Danyvin — Chill R&B（原文件名 `background-peace-danyvin-chill-rnb.mp3`）
- `music_battle`：Miromax Music — Stylish Funk（原文件名 `background-battle-miromaxmusic-stylish-funk.mp3`）
- 音效：freesound.org、Dragon Studio、Universfield、Kauasilbershlach Parodes、universfield（原始文件名见提交历史）

使用前请确认各素材的授权范围。
