# 战斗数值编辑器

在 Godot 编辑器顶部选择“战斗数值”。四个分类分别编辑关卡及波次、角色、技能和怪物；选择具体对象后修改字段。关卡页面可以新增、删除和编辑出怪组，敌人与路线从当前注册资源和地图中选择；显示波次序号不在此编辑，已有序号保留。角色和怪物页面显示头像，技能页面显示图标；头像和图标本身在资源 Inspector 中编辑。

关卡页面使用与选关界面相同的地图预览图。修改地图或新增战斗关后，在图形环境运行 `& $env:GODOT_PATH --path . --script res://scripts/update_level_previews.gd`，并等待编辑器导入生成的图片。

“保存所有修改”校验全部关卡、路线、编队、单位和技能，然后写回正式 CSV 和资源文件。切换对象会保留未保存草稿；退出前留意 Godot 的未保存提示。校验失败或源文件被外部修改时不会覆盖冲突文件；界面保留草稿并显示错误。若发生多文件写入失败，编辑器尝试恢复已经写入的文件，恢复失败的文件会在错误中列出。

资源是共用的：修改角色、怪物或技能会影响所有引用它的关卡或角色。技能说明不会自动随数值变化，调整技能时请同时检查说明。角色攻击范围以朝右为基准，点击格子增删范围，箭头移动格子视野；也可以直接输入分号分隔的坐标，例如 `0,0;1,0;2,0`。范围不能为空。

先在关卡强度中选择关卡，点击“保存并试玩关卡”会保存修改并运行该关卡的 Game Test。停止运行后回到编辑器。地图和路线本身仍通过 Godot 地图场景编辑；新增单位和技能沿用正式内容编辑流程。

测试使用项目根目录和 `GODOT_PATH`，临时数据位于 `temp/`：

```powershell
& $env:GODOT_PATH --headless --path . --script res://devtools/balance_editor/csv_document_test.gd
& $env:GODOT_PATH --headless --path . --script res://devtools/balance_editor/model_test.gd
& $env:GODOT_PATH --path . --script res://devtools/balance_editor/editor_ui_test.gd
& $env:GODOT_PATH --path . --script res://devtools/balance_editor/play_test.gd
```
