# Audio / 音乐与音效

- 模块名称与路径：`features/audio`；内容位于 `content/audio`；集成于 `game/player`、`game/battle` 与 `game/adapters/battle_audio.gd`。
- 职责与明确不负责的内容：cue 资源类型与清单校验、`Music`／`SFX` 总线与播放器、音乐交叉淡入淡出、音效池、音量设置读写。不读取具体内容路径，不承担战斗事件语义（映射属于 game/adapters），不实现设置界面（属于 game/player），不生成或处理素材。
- 输入、输出、信号及资源依赖：调用方注入 `AudioLibrary`（`content/audio/cues.tres`）与 `audio_settings.gd`；`play_music(id, fade)` / `play_sfx(id)` 返回是否真正开始播放，`current_music_id` 可观察。`AudioSettings` 以 `ConfigFile` 读写线性音量。`battle_hud`／`story` 只发 `ui_sound_requested(id)` 意图。无 autoload、无全局信号；总线在运行期幂等创建。
- 独立运行场景 / 所属开发工作区：无独立工作区；以规则测试与 Player Mode 实际流程验证。素材试听使用 Player Mode。
- 验证步骤与结果：Godot 4.7.2 / Compatibility。
  - `features/audio/tests/audio_test.gd`：44 项检查零失败，覆盖库查找与 7 类结构错误、空 stream 合法、设置往返／越界 clamp／损坏文件回落、总线创建、音乐切换与重复请求、空流静默、音效池轮转、总线静音。
  - `game/tests/audio_integration_test.gd`：52 项检查零失败，覆盖真实清单校验、两首 MP3 已导入且 `loop == true`、全部战斗 cue 存在、事件映射（含 `damage.friendly`、`death.side`、`finished.phase` 分支）与同批去重、Player Mode 页面音乐、设置页双滑块、总线音量与静音、重启后音量持久化。
  - 回归：`battle_test` 172 项、`scenario_test` 86 项、`battle_integration_test` 116 项、`chapter_flow_test` 103 项、`chapter_content_test` 73 项、`story_test` 27 项，均零失败。
  - 无界面使用 Dummy 音频驱动，只验证总线、返回值与资源状态，未验证听感。
- 参考图、截图或测试输出：命令见 `features/audio/tests/README.md`；设置文件与流程存档输出到 `temp/audio/`。
- 已知限制：部分音效 cue 仍为空（部署、撤退、生成、费用、技能起止、受击、落空、阻挡、死亡、逃脱、胜负），播放时静默返回 `false`；MP3 循环接缝可能有编码器间隙，需要无缝时改用 OGG／WAV；战斗音效为非定位播放，未做 3D 空间化。
- 评审结论：通过（规则、集成与既有流程回归零失败；人工听感检查待在有声环境执行）。
- 评审人和日期：本次实现代理；2026-10-26。
- 通过后集成位置：`game/player/player_mode.gd` 持有常驻 `AudioDirector` 并切换页面音乐；`game/battle/battle_scene.gd` 将事件交给 `game/adapters/battle_audio.gd`；`features/battle_hud` 与 `features/story` 仅发 UI 音效意图。
