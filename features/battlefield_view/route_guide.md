# 路线引导线

`route_guide.gd` 是纯表现 Node3D。`configure(route, surface_height)` 接受沿敌人移动方向排列的格心路线与地表高度回调；用连续的窄带网格贴合地表，UV.x 按沿线累计距离归一化，支持折线路径。不会生成敌人、判断路线可通行性或参与拾取。

`set_progress(0..1)` 控制一次从出生点到目标点的流动高亮与淡入淡出。shader 不读取 TIME，也没有内部 process，因此暂停和倍速由调用方的模拟时间决定。完整底线保持半透明。

正式组装由 BattlePresentation 读取 route_warnings 快照维护视图：把预告进度映射为两轮扫光，高亮沿全路线扫过两次后随预告结束消失；不依靠动画播放回调控制 battle。预告结束、终局、重开、重载和退出清理节点。Art Test 以模拟预告快照使用相同路径。
