# Audio 自动化测试

无正式素材依赖：使用内存 `AudioStreamWAV` 与内存 `AudioLibrary`，可在 `--headless` 下运行。Dummy 音频驱动只能验证总线、返回值和资源状态，不能验证听感。

- `audio_test.gd`：库查找与结构校验（重复 id、前缀与总线不匹配、空 stream 合法）；设置读写、越界 clamp、损坏文件回落；总线创建、音乐切换与重复请求、空流静默、音效池轮转。
- 游戏层 `game/tests/audio_integration_test.gd` 加载真实 `content/audio/cues.tres`，核对音乐流类型与循环、战斗 cue 是否齐全、事件映射与同批去重，并实例化 Player Mode 验证页面音乐、设置页滑块、总线音量与重启后持久化。

```powershell
& $env:GODOT_PATH --headless --path . --audio-driver Dummy --script res://features/audio/tests/audio_test.gd
& $env:GODOT_PATH --headless --path . --audio-driver Dummy --script res://game/tests/audio_integration_test.gd
```

设置文件写入 `res://temp/audio/`；真实运行时写入 `user://audio_settings.cfg`。
