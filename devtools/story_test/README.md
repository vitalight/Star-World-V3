# Story Test

从 Developer Hub 的 Story Test 进入，或运行 story_workspace.tscn。默认打开正式 1-1 剧情，下拉框只提供第一章五个独立剧情关。

背景、角色与文本统一读取正式 content，通过 game/content/content_catalog.gd 加载，复用 features/story 的 Session 和 View；不再保留开发样例或直接引用 Human 初始素材。

- 点击“继续”、画面空白处或 Enter/Space 推进；1-1 从家中近景切换至空洞全景，再按文本切换大星与小黄。
- “回退”返回上一段并移除后续记录；起始段不可回退，回退会停止自动播放。
- 两人交谈时同时出场，说话者高亮；旁白不显示姓名。
- “重播剧情”回到当前剧情开头并清空记录；“重新加载”读取已保存的正式资源、表格和 Markdown，并从原对话序号继续，记录按新内容重建。若剧情缩短到不足该序号，则停在最后一段对话；切换剧情仍从开头开始。
- “记录”显示可滚动对话记录；“调试”额外显示节点、背景、出场角色与已读段数。
- “自动”按阅读时长推进，结束时停止；打开记录或调试时暂停计时。“跳过”推进到结束，并保留循环保护。
- 通过 Developer Hub 面包屑返回首页；窄窗口顶栏换行，长对白可滚动阅读。

验证入口：features/story/tests/story_test.gd、devtools/story_test/workspace_test.gd、devtools/story_test/visual_test.gd、game/tests/content_tools_test.gd。通过 GODOT_PATH 从命令行运行；visual_test.gd 使用真实鼠标事件，需启用渲染，截图写入 temp/verification/。
