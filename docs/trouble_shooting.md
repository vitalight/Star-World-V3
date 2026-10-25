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


### 立片左右朝向相反

当前角色和敌人的 pose 原图默认朝左，不能把 facing=0（右）当作“不翻转”。actor_view_3d 应只在 facing=0 时设置 flip_h=true，facing=2（左）保持原图。不要改战斗的朝向编号或范围旋转来补偿画面，否则会使攻击范围与箭头反向。敌人首次创建时先按其路线当前段初始化朝向并放到逻辑位置，再根据后续实际位移更新；使用新节点默认原点计算首帧位移会误判朝向。回归入口 game/tests/facing_test.gd。
