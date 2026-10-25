# 第一章「上海」集成评审

- 模块与职责：`game/content` 读取和校验正式 CSV／Markdown；`game/player` 管理章节流程、剧情会话和存档；`features/battle` 只扩展回费与计时防守；`features/battlefield_view` 接收外部地图、图集和配色。三关与五名角色均为 content 实例。
- 接口与依赖：CSV → Battle 既有配置字典；Markdown → StoryScript；game 连接 StorySession／StoryView。battle 不加载内容、不依赖 UI；正式 game/features 不依赖 devtools。通用 editable_field 从 scene_001 的显示代码提取，旧场景保留资源入口并继承相同实现。
- 工作区：Game Test 保留原样例，并增加三关切换／重载；Story Test 保留分支样例，并增加六段正式剧情。Player Mode 直接组装共享模块。
- 版本与环境：2026-10-25，GODOT_PATH 指向 Godot 4.7.2，真实窗口为 OpenGL Compatibility／RTX 3060 Ti。用户已有 Human/Human.md 改动未编辑。

## 验证结果

| 检查 | 结果 |
| --- | --- |
| 第一章内容、引用、CSV／MD、重载、三关回放／空场失败 | 35项，0失败 |
| 回费与修复目标、暂停／单步／重置／时间切片 | 12项，0失败 |
| 玩家原生鼠标流程，三种窗口尺寸、读完／跳过、续接／迁移／破损存档 | 100项，0失败 |
| Game Test／Story Test 内容切换与重载、配置错误显示与恢复 | 20项，0失败；真实渲染也通过 |
| 原战斗规则 | 172项，0失败 |
| 原固定战斗场景回放 | 18场景、86项，0失败 |
| 原战斗集成 | 116项，0失败 |
| 原战斗视觉／操作 | 448项，0失败 |
| 原技能集成／表现一致／路线预告 | 54／84／42项，0失败 |
| 原剧情规则／工作区／原生视觉输入 | 27项及两套验证，0失败 |
| 独立空目录加载导出 PCK | 三场实际战斗及六段剧情，0失败 |

三关命令回放全部基地生命5、无人阵亡，分别约190.67／202.55／210秒获胜；场内操作通过公共部署、撤退与技能命令进行。第二关没有月月，第二、三关没有小黄。第三关修复完成仍要求清完所有敌人。失败不授予进度；胜利先保存 pending_after，读完／跳过战后剧情后才解锁。

## 证据与结论

日志及截图位于 `temp/chapter_one/`：`chapter_content_test_final.log`、`campaign_rules_test_final.log`、`render_flow.log`、`tools_render.log`、`battle_visual.log`、`packed.log`；截图 `levels_1280x800.png`、`levels_960x600.png`、`levels_1600x900.png`、`story_cat.png`、`repair.png`、`chapter_complete.png`、`game_test_chapter.png`、`story_test_chapter.png`。集成代理已逐张查看选关、剧情、小黄、修复战斗、章节完成和工具预览图。没有把截图或测试存档作为正式运行依赖。

导出预设显式包含 CSV／MD，并对 CSV 使用 keep 导入。受限环境的默认系统临时目录曾导致 project.binary 写入失败；设置进程 TEMP／TMP 到项目 temp 后，导出 PCK 可在空目录实际组装三关。编辑器设置持久化仍可能输出 Safe save 警告，不影响已验证的运行包读取。

已知限制：角色以既有素材映射为主，小黄、地点背景、先锋／特种图标为矢量占位；尚未进行最终美术统一。目标总体验15—25分钟，实际阅读时长尚需人工试玩。固定编队，无养成、音频、战斗中间存档或后续章节；这些均在本轮确认范围之外。

- 评审结论：通过技术自评与集成回归，接入 Player Mode；最终美术与难度体验仍可继续迭代。
- 评审人及日期：本次实现／集成代理，2026-10-25。
