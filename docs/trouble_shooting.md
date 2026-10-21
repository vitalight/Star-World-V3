# 常见问题 / 踩坑记录

## `.NET assemblies not found`
- 原因：此前使用 Mono 版，程序集文件实际存在，推断为沙箱内目录访问问题，未定位唯一根因。
- 结论：已改用 `GODOT_PATH` 指向的标准版 Godot 4.7.2；2026-10-21 命令行验证导入、首页启动和战斗测试通过，未再出现该错误。

## `.NET Sdk not found`
- 原因：Mono 编辑器未找到兼容的 .NET SDK，与程序集目录错误不同。
- 结论：当前项目仅用 GDScript，切换标准版后该提示已消失，无需为本项目安装 SDK。

## `Could not create editor data/config directory`
- 原因：受限环境无法写入默认 Godot 用户目录。
- 结论：启动 BAT 在局部环境中将 APPDATA 指向 `temp/devtools/user/`，不修改系统设置。
