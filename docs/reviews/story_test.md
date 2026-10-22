# Story / Story Test 初版

- 模块名称与路径：`features/story`；开发工作区 `devtools/story_test`。
- 职责与明确不负责的内容：同步推进对话图、分支选择、结束与重播及本次历史；可复用视图显示背景、单人/双人立片、说话者高亮、底部渐变对白。不计算战斗，不承担正式游戏流程。
- 输入、输出、信号及资源依赖：调用方传入 `story_script.gd` Resource；`load_story` 返回配置错误，操作返回是否成功，`snapshot` 返回深拷贝。StoryView 接收外部纹理映射与快照，发出继续/选择输入信号；feature 不引用具体内容。Story Test 传入用户指定的两张背景、正式战斗 character_001/003 appearance 的 poses[0]。无全局信号或自动加载，feature 不依赖 devtools。
- 独立运行场景 / 所属开发工作区：`devtools/story_test/story_workspace.tscn`；Developer Hub 第五个入口。
- 验证步骤与结果：Godot 4.7.2 / OpenGL Compatibility；规则测试 27 项零失败，覆盖两条分支、错误操作、结束、重播、图/快照隔离、错误配置与演出字段；工作区测试零失败，额外覆盖素材复用、高亮、出入场、背景切换、自动在分支停止、记录暂停、跳过及循环保护；Story 专项原生鼠标/渲染测试零失败，覆盖默认/800×650 窄屏和记录弹层。初版完整渲染导航 smoke 零失败，本轮回归结果见交付说明。
- 参考图、截图或测试输出：`temp/story_test/` 日志；`temp/verification/story_single.png`、`story_dual.png`、`story_garden.png`、`story_end.png` 和相应窄屏截图。
- 已知限制：复用现有战斗立片，原图约 300px，放大后偏柔和；无音频、打字机、条件变量、事件指令、存档或转场动画。图允许循环，跳过有循环保护；暂不诊断不可达节点。表现映射由调用方保证资源 ID 存在。
- 评审结论：待评审。
- 评审人和日期：待指定；2026-10-22 提交开发工作区验证。
- 通过后集成位置：由 game 持有会话并连接游戏流程；当前没有接入正式 game。
