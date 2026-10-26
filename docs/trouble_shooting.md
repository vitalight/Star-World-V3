# 常见问题 / 踩坑记录

## 导出 PCK 时无法写入 tmpproject.binary

- 问题：受限环境中导出出现系统临时目录下 `tmpproject.binary` 无法读取，虽然生成 PCK，包内 project.binary 可能不完整。
- 原因：当前进程使用的系统临时目录不可完成该导出写入。
- 结论：创建项目 `temp/chapter_one/export_tmp`，仅在导出命令进程中将 TEMP／TMP 指向该目录；使用 GODOT_PATH 重新导出，并在独立空目录加载 PCK 验证。2026-10-25已通过三关战斗及六段剧情加载；编辑器设置 Safe save 警告需与实际运行包验证分开判断。

## `.NET assemblies not found`
- 原因：此前使用 Mono 版，程序集文件实际存在，推断为沙箱内目录访问问题，未定位唯一根因。
- 结论：已改用 `GODOT_PATH` 指向的标准版 Godot 4.7.2；2026-10-21 命令行验证导入、首页启动和战斗测试通过，未再出现该错误。

## `.NET Sdk not found`
- 原因：Mono 编辑器未找到兼容的 .NET SDK，与程序集目录错误不同。
- 结论：当前项目仅用 GDScript，切换标准版后该提示已消失，无需为本项目安装 SDK。

## `Could not create editor data/config directory`
- 原因：受限环境无法写入默认 Godot 用户目录。
- 结论：启动 BAT 在局部环境中将 APPDATA 指向 `temp/devtools/user/`，不修改系统设置。


## 俯视镜头下草丛／高台切掉干员头部

- 现象：道路干员靠近后排高台草丛时，头部出现水平裁切；移除草叶仍有部分头部消失。
- 原因：全 billboard 的可见平面会伸入后方地形，其几何深度不适合作为角色站立位置的遮挡判定。
- 最终处理（2026-10-22）：保持完整 billboard 与原始比例，通过 actor_view/billboard_depth.gdshader 计算经过脚底的竖直平面深度。可见顶点不倾斜、不拉伸，保留实际前景遮挡。此前 Y 轴 billboard 加纵向补偿的尝试会导致视觉变形，已撤销。
- 验证：使用 GODOT_PATH 执行 `--path . --script res://game/tests/actor_occlusion_test.gd --log-file temp/actor_occlusion.log`。比较三个窗口尺寸的原生 billboard 轮廓与地形显示／隐藏时的头部像素，并验证前景墙、受击闪烁和离场淡出。头部九个用例均 100% 可见，专项共 21 项零失败。


### MP3 背景音乐循环

- 现象：`AudioStreamMP3.loop` 为 false，BGM 播放一遍就停。
- 处理：编辑对应 `.mp3.import` 的 `[params]`，设置 `loop=true` 后重新导入；只改参数区，不要手写 `[remap]` 里的 `uid` 或 `dest_files`（含生成哈希，写错会破坏导入）。若修改后未触发重新导入，删除 `.godot/imported/` 下对应的 `*.mp3str` 再跑 `--headless --import`。
- 已知限制：MP3 循环在接缝处可能有编码器延迟间隙；需要无缝循环时改用 OGG／WAV 并配置循环点。

### 音频无界面测试

- `--headless` 使用 Dummy 音频驱动，`AudioStreamPlayer.playing` 与听感不可靠。测试只断言总线索引、接口返回值、`current_music_id` 与 `stream.loop`。
- 当前部分音效 cue 的 `stream` 为空，`play_sfx` 返回 `false` 属预期，不是失败；补上素材后即会播放。
- 设置文件写入 `user://audio_settings.cfg`；隔离测试时把 `APPDATA` 指向 `temp/` 下的目录，避免污染真实用户数据。

### 无界面运行渲染测试会永久挂起

- 现象：`--headless` 运行 `game/tests/route_warning_test.gd` 等测试时进程一直不退出，看起来像测试超时。
- 原因：测试内部无条件 `await RenderingServer.frame_post_draw`；`--headless` 没有渲染帧，该信号不会发出，协程永远停在等待处。
- 结论：这类测试必须用真实窗口运行。逻辑回归选不依赖渲染的测试；需要截图的测试把等待放在 `--capture` 分支里，例如 `chapter_flow_test.gd` 和 `audio_integration_test.gd`。

### 立片左右朝向相反

当前角色和敌人的 pose 原图默认朝左，不能把 facing=0（右）当作“不翻转”。actor_view_3d 应只在 facing=0 时设置 flip_h=true，facing=2（左）保持原图。不要改战斗的朝向编号或范围旋转来补偿画面，否则会使攻击范围与箭头反向。敌人首次创建时先按其路线当前段初始化朝向并放到逻辑位置，再根据后续实际位移更新；使用新节点默认原点计算首帧位移会误判朝向。回归入口 game/tests/facing_test.gd。
