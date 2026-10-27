# 第一章素材任务

依据：Human/Story_01.md（本次正式剧情输入）；agents/artist.md。
使用 imagegen；每张 1600×900 PNG、16:9、无边框。只画环境，无人物、猫、怪物、UI、文字；干燥哑光地面、克制光效、安静区域、统一手绘动漫风格。原始生成图保留，精确 prompt 写同名 .prompt.txt；正式图放 content，不能依赖 temp 或 Human。

| 状态 | 剧情用途 | 原件与正式目标 |
| --- | --- | --- |
| 已生成并验收 | 1-2 空洞闭合后的家中，延续现有家中构图，窗外仍停电，右侧空洞完全关闭 | Human/StarterContent/story/chapter01/chapter01_02_home_closed_v1.png → content/scenes/scene_0102A/background.png |
| 已生成并验收 | 1-3 驱车途中，从车内望向停电的上海街道，少量仪表光，无人无字 | Human/StarterContent/story/chapter01/chapter01_03_city_drive_v1.png → content/scenes/scene_0103A/city_drive.png |
| 已生成并验收 | 1-5 灯火归来，保持现有东方明珠视角，节点彻底闭合，塔与城市重新亮起，地面无大片反光 | Human/StarterContent/story/chapter01/chapter01_05_city_restored_v1.png → content/scenes/scene_0104A/city_restored.png |

现有家中空洞、路边救援、东方明珠异常背景及五名角色外观复用。暂时未实现的连续动画（扑击、跌入空洞、节点收缩）用短动作叙述承接，不将角色烘焙进环境图。

## 交付验收

- 三张均使用内置 imagegen 生成，原始图 1672×941 保留于 Codex generated_images；仅使用 Lanczos 纯缩放得到 1600×900 正式 PNG，未程序重画。
- 三张同名 .prompt.txt 保存实际传入工具的完整 prompt；原件目录与正式目标 PNG 尺寸一致。
- 视觉检查：家中保持家具与镜头，右侧空洞及异常粒子已去除；车辆图为无人车内望向停电上海街道；东方明珠图去除节点晶体和光环，塔与城市恢复温暖灯火。三图均无人物、动物、怪物、文字、水印和边框。
- 地面高光较原异常场景克制，东方明珠远景河面保留少量局部灯影。生成图只提供静态背景，连续动作仍由剧情承接。
