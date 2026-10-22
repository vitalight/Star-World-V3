# 架构约定

## 目标

支持模块独立开发、独立验证、评审后集成。目录表达稳定职责，评审通过只改变组装引用，不移动或复制模块。

当前阶段只确定顶层职责、依赖方向、开发工作区和内容标识。下文的模块内部组织作为初步方向，具体接口、配置实现、时间推进和坐标等细节在对应模块开发时确定。

## 五层职责与依赖

| 目录 | 职责 | 允许的项目依赖 |
| --- | --- | --- |
| core | 与塔防无关且已被实际复用的基础设施 | 不依赖其余四层 |
| features | 可复用的玩法和表现能力 | core；必要且明确记录的其他 feature 公共接口，禁止循环依赖 |
| content | 具体角色、敌人、关卡和专属资源 | features 定义的资源类型及可复用场景、core |
| game | 加载内容、连接模块、管理最终游戏流程 | features、content、core |
| devtools | 调试、预览和验证工具 | game、features、content、core |

正式模块不能引用 devtools。features 不通过硬编码路径加载具体 content，也不依赖 game。
Human/StarterContent 专门存放外部输入的初始素材。开发预览可以引用它；正式内容使用经过整理的 content 资源，features 不绑定具体角色或地图图集，由外部传入资源。
core 初期留空，不预先增加全局事件总线、万能 Manager 或只有一个调用者的工具抽象。

## 临时数据

任务产生的临时数据统一写入项目根目录 `temp/`，可按任务建立子目录。包括中间生成文件、临时脚本、调试日志、检查截图和一次性验证输出。
`temp/` 不纳入 Git，目录内保留 `.gdignore` 以避免 Godot 导入临时资源；目录不存在时先创建。
正式产物应整理至对应模块或内容目录，项目运行不得依赖 `temp/`。需要长期保留的测试样例和评审记录属于正式产物。
Godot 自动管理的 `.godot/` 缓存维持引擎默认位置。

## Feature 的组织

battle 是一个对外统一的战斗模块，units、deployment、targeting、navigation、waves 是它的内部实现目录，不是分别对外暴露的顶层模块。
由 battle.gd 提供战斗创建、命令提交、模拟推进和状态/事件读取等必要接口，当前公共接口见 features/battle/README.md。

actor_view、effects、battlefield_view、battle_hud 可以独立展示；它们不计算伤害、波次、部署合法性和胜负，也不直接查找战斗内部节点。
game/adapters 将战斗事件与状态转成表现更新，并将用户操作意图交给战斗模块验证。
战斗状态由 battle 持有，显示状态不能成为玩法真相的第二份来源。

每个模块就近保存自己的场景、脚本、资源及专属测试。不创建全局 scripts、scenes、resources 分类来拆散同一模块。

根目录 `scripts/` 仅存放项目级命令行任务入口（例如启动开发者场景的 BAT），不承载游戏模块脚本。常见问题与环境排查单独记录在 `docs/troubleshooting.md`。
模块增大后再按真实变化原因拆分，不能为了目录对称而增加转发层。

## 数据与资源归属

features 定义可复用的数据结构和行为；content 提供具体实例。例如，未来的单位配置类型位于 features/battle/units/，角色实例位于 content/characters/character_001/。

### 内容 ID

场景、角色、地形统一使用 `type_001` 格式：小写英文类型前缀、下划线、从 `001` 开始的编号，编号至少三位。

| 内容类型 | ID 示例 |
| --- | --- |
| 场景 | `scene_001` |
| 角色 | `character_001` |
| 地形 | `terrain_001` |

同一类型内编号唯一，按类型独立编号。ID 分配后保持稳定，显示名称可以单独修改；删除的 ID 不分配给其他内容。
具体内容目录使用对应 ID 命名。此规则用于内容实体，不要求开发工具场景、通用模块场景或每个资源文件都分配内容 ID。
Human/StarterContent 中的外部输入保留原始名称，整理为正式内容时分配 ID。

### 资源归属

一个角色目录可以包含 stats.tres、view.tscn、textures/。stats.tres 只描述战斗所需数据，不引用外观场景、贴图和动画。
game 负责根据内容标识关联数值和外观，使 Logic Test 可以只加载战斗数据。
通用展示行为放在 features/actor_view，具体角色的外观配置和专属资源放在 content。

已有原始图集存放于 Human/StarterContent，保留其 character、effects、texture 子目录。外部输入与正式内容分开管理：原件留在此处，经过切片、配置或其他加工后用于游戏的资源归入 content 对应目录。
原始需求和参考图留在 Human；生成的评审概念图放在 devtools/blueprint/images。
数据驱动主要用于属性、单位、关卡和波次，复杂行为仍用代码实现。

## 五个开发工作区

| 工作区 | 组装方式 | 验证目标 |
| --- | --- | --- |
| Blueprint | 参考图与概念图 | 视觉方向 |
| Art Test | 表现 feature + 模拟数据或具体外观 | 动画、特效、地图和 UI |
| Logic Test | battle + 极简显示 + 测试配置 | 战斗规则 |
| Game Test | 加载 game/battle 的实际组装场景 | 完整集成 |
| Story Test | story 会话与演出 + 工作区专属剧情样例/外部素材 | 对话、分支、出入场、背景与重播 |

Logic Test 与 Game Test 必须复用同一战斗实现；Art Test 与 Game Test 必须复用同一表现实现。
Story Test 通过 `features/story` 的公共接口运行样例；正式剧情接入 game 前仍需模块评审，样例不作为正式 content。
临时测试数据、占位图形和调试控制放在所属 devtools 工作区，正式配置放在 content。
战斗模块支持不加载角色场景、动画和 UI 的模拟推进。Game Test 已通过 game/battle 加载实际组装，编辑方式和接口见 devtools/game_test/README.md。

scene_001 的 TileMapLayer 是地形唯一数据源。features/battlefield_view/editable_map.gd 通过关卡资源的 configuration / errors 协议导出战斗配置及编辑器诊断；关卡、单位与波次资源类型由 features/battle 定义。3D 地形生成器只消费格子外观和高度，不计算部署合法性。角色外观由 features/actor_view 定义资源类型，game 按内容 ID 将数值与外观关联。

## 验证与评审

模块专属自动测试放在 features/<module>/tests/；跨模块集成测试放在 game/tests/；devtools 负责人工验证，不能代替自动测试。
测试从模块公共接口验证可观察行为，避免绑定内部节点结构。

流程：独立开发 → 对应工作区验证 → 记录 review → 在 game 连接模块 → Game Test 回归。
使用 docs/module_review.md 模板，将具体记录保存在 docs/reviews/。未评审或未通过的模块不接入正式游戏组装。
评审后保留模块路径，避免维护实验版和正式版两份实现。


Art Test 的 Battle 页使用模拟快照调用 game/adapters/battle_presentation.gd 和同一 playable_hud，不创建战斗模拟器；Game Test 使用真实 battle 快照。镜头、光照及路线端点标记由 features/battlefield_view/battlefield_stage.gd 提供，具体地图与 appearance 由调用方传入；共享显示不得反向引用 devtools。


路线预告时序由 battle 维护，并通过 route_warnings 快照与 route_warning 事件输出；features/battlefield_view/route_guide.gd 只接收路线、地表高度回调及进度，使用 shader 播放单次流动引导线。game/adapters 管理其生命周期，Art Test 以模拟快照复用，不由表现层阻塞或生成敌人。

## 产品界面文案

Game Test 与正式游戏按游戏产品设计：常规界面只显示必要的状态、数值、技能功能与操作结果，不加入注释式操作说明或调试描述，例如“技能就绪，点击图标释放”“点击或拖动干员卡部署”“美术展示·模拟快照”。技能是否可用通过图标亮光、禁用态及状态条表达；失败原因简短明确。操作文档写入 README，开发信息只放调试窗。Art Test 只承担美术预览，不展示技能效果、数值或其他玩法说明。
