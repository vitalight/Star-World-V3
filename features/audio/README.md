# Audio

通用音频能力：cue 资源类型、cue 库校验、音量设置持久化，以及一个持有 `Music`／`SFX` 总线的播放节点。模块不读取任何 content 路径，库由调用方注入；缺少 cue 或 cue 的 stream 为空时静默返回 `false`，不报错，便于素材后补。

## 公共接口

| 文件 | 类型 | 职责 |
| --- | --- | --- |
| `audio_cue.gd` | `@tool AudioCue extends Resource` | 一条声音：`id`、`bus`、`stream`、`volume_db`、`pitch_variance`、音效起始偏移 `start_offset`（秒） |
| `audio_library.gd` | `@tool AudioLibrary extends Resource` | `cues` 显式引用、`find(id)`、`ids()`、`errors()` |
| `audio_settings.gd` | `RefCounted` | `music_volume`／`sfx_volume` 的 `ConfigFile` 读写，缺失或损坏时回落默认值 |
| `audio_director.gd` | `Node` | 幂等创建 `Music`／`SFX` 总线，双播放器交叉淡入淡出，12 路音效池 |

`AudioDirector` 由产品流程显式 `.new()` 并 `add_child`，不是 autoload：

```gdscript
audio = AudioDirector.new()
audio.set_library(Cues)          # content/audio/cues.tres
audio.apply_settings(settings)
add_child(audio)
audio.play_music("music_main")   # 切换时淡入淡出；相同 id 不重启
audio.play_sfx("sfx_ui_click")   # 未配置或流为空返回 false
```

- 相同的音乐 id 重复请求不会重启；`fade = 0` 立即切换，便于无界面测试。
- 音效池优先使用空闲播放器，满载时轮转覆盖最旧的一路；同一批事件由调用方去重。
- 音效从 cue 的 `start_offset` 开始播放；默认为 0，且必须小于音频时长。音乐不使用此偏移。
- 循环由素材导入设置决定（MP3 为 `.import` 的 `loop=true`），cue 不保存循环开关。
- 音量作用在总线上：0 静音该总线，其余值按 `linear_to_db` 设置。

## 接入约定

- 具体 cue 与音频文件属于 `content/audio`；features 不硬编码内容路径。
- 战斗事件到音效的映射位于 `game/adapters/battle_audio.gd`，不是本模块。
- HUD 与剧情只发出 `ui_sound_requested(id)` 意图信号，由 game 决定是否播放。
- 需要同时被测试和产品使用：测试可用内存 `AudioStreamWAV` 与内存库，不依赖正式素材。

## 测试

见 [tests/README.md](tests/README.md)。
