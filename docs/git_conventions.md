# Git 提交约定

## 标题格式

```text
type(scope): description
```

scope 必填，使用受影响的模块或职责名称；冒号后留一个空格。
type 和 scope 使用小写英文。description 默认使用简洁英文动词短语，说明实际变化，末尾不加句号。

## 类型

| type | 用途 |
| --- | --- |
| feat | 新增功能 |
| fix | 修复错误 |
| refactor | 调整实现或结构，保持既有行为 |
| docs | 文档变更 |
| test | 测试变更 |
| perf | 性能优化 |
| style | 格式调整，不改变行为 |
| build | 构建、依赖或导出配置 |
| ci | 持续集成配置 |
| chore | 其他维护工作 |
| revert | 撤销已有提交，正文注明被撤销的提交 |

## Scope 与示例

优先使用具体模块名，如 `battle`、`actor_view`、`effects`、`battle_hud`。
内容、工具和项目级修改可使用 `content`、`devtools`、`game`、`core`、`architecture`、`repo`。
这些名称是示例，不是封闭名单；新增模块时使用它的稳定名称。

```text
feat(battle): add unit deployment validation
fix(actor_view): reset animation when reusing a view
refactor(architecture): organize project by feature
chore(content): move starter assets into human inputs
docs(repo): define commit conventions
test(battle): cover deployment outside the map
```

## 提交范围与正文

一次提交表达一个可解释的改动目的；实现该目的所需的代码、测试和文档可以一起提交。
独立的功能与无关格式整理分开提交。涉及多个目录时，scope 按改动目的选择，不罗列全部路径。
避免 `update stuff`、`fix bug` 等无法表达具体变化的标题。

需要说明原因、兼容性或验证结果时，在标题后空一行添加正文。
破坏已有公共接口或内容格式时使用 `type(scope)!: description`，正文以 `BREAKING CHANGE:` 说明影响与迁移方式。

本约定规定提交消息格式，不要求每次修改后自动提交或推送。
