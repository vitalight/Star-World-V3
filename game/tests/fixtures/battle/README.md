# 固定战斗测试夹具

这里的地图、TileSet、编队、敌人、技能和展示素材是测试专属快照，不引用 `content/`。`sample_battle_fixture.tscn` 和 `game_workspace_fixture.tscn` 显式注入这些资源；正式 Game Test 仍使用自己的开发样例和正式资源。

规则、交互或回归测试需要稳定输入时修改此目录，而不是修改正式角色或关卡。素材仅用于测试显示和输入，不作为正式美术来源。`battle_integration_test.gd` 检查此目录中的场景和资源不得引用 `res://content/`。
