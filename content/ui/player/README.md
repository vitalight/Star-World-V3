# 玩家界面素材

`background.png`、`atlas.png` 分别从 `Human/StarterContent/ui/ui-main-background.png` 与 `ui-atlas-01.png` 整理而来，原件保持不动。正式 Player Mode 只依赖本目录。

图集为 1254 × 1254；`game/player/player_mode.gd` 使用 AtlasTexture 区域引用按钮、月徽与分隔装饰，文字由原生控件显示。两张 blueprint 仅作为人工参考，不作为可点击界面贴图。

主界面使用 `main_background_v2.png`（来自 `ui-main-background-v2.png`）以及从 `ui-main-element-v2.png` 提取的 `main_emblem_v2.png`、`main_button_light_v2.png`、`main_button_dark_v2.png` 和 `main_settings_v2.png`。星徽做亮度透明处理，按钮裁切为独立图片；标题和按钮文字由原生控件显示。参考图 `ui-main-v2.png` 仅用于布局参考。旧素材仍供设置和选关页面使用。
