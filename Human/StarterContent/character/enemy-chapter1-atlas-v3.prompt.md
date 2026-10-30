# 第一章敌人图集 v3

内置 imagegen；参考和第一张编辑目标：`enemy-chapter1-atlas-01-v2.png`。每张分别使用以下完整提示词，透明背景选项开启。

## 图集 01

Use the supplied image as the design reference and edit target. Recreate its four rows of monsters, preserving the distinctive designs, palettes, clean selective detail, and four left-facing poses, but recompose as a SQUARE 1024×1024 transparent 4×4 sprite atlas: 16 independent full-body sprites, 256×256 cells. Each sprite fits entirely inside its cell with at least 10 pixels clear transparent margin on each side. Scale each intact sprite down to fit, retain its natural proportions, don't stretch. All face screen left; columns walk front-left, walk back-left (actual back), attack front-left, attack back-left (actual back), actions compact and within cell. Transparent background, no floor, glow backgrounds, grids, labels, shadows, watermarks or large effects.

## 图集 02

Use the supplied image ONLY as a style and restraint reference, not as the monsters to reproduce. Generate a SQUARE 1024×1024 transparent 4×4 sprite atlas, exactly 16 isolated sprites, 256×256 cells, one monster per row, four poses each. Match reference's clean hand-drawn chibi tactical RPG illustration, bold color blocks and simple contours, and its generous quiet untextured areas. This is crucial: SIMPLIFY these monsters strongly. Use broad smooth surfaces with only a few deliberate detail clusters at face, core or joints; minimal crystal accents, very few large tufts, plates or cracks. No repetitive scales, spikes, fur strands, tiny facets, dense textures, intricate armor or all-over busy patterns. Row 1: cute polluted flying insect, olive body, a few translucent wings and luminous yellow-green abdomen. Row 2: black wolf, simple large fur shapes, sparse cyan glowing lines on legs. Row 3: bulky berserk beast, dark maroon body, a few violet crystals and modest electrical accents. Row 4: humanoid colossus, charcoal and ivory broad simple armor shapes and gold glowing chest core. Distinct palettes per row. ALL sixteen monsters face toward screen LEFT, including rear views, with heads, movement and attacks oriented left. Columns walking front-left 3/4, walking back-left 3/4 showing back, attacking front-left, attacking back-left showing back. Compact poses, no large effects, each sprite entirely within its cell with at least 10 pixels transparent on every edge, no overlap or clipping. Transparent background, no glow backgrounds, no floor, shadows, grid, text, border or watermark.

## 清单和检查

- 01 行：污泥怪、裂口兽、重爪兽、盾卫；02 行：毒飞虫、疾狼、暴走兽、黯光巨像。
- `*-v3-source.png` 为 1254×1254 原始输出；`*-v3.png` 为等比缩放至 1024×1024 的 RGBA PNG。
- 整图目视：第二张细节较上一版明显简化；怪物大致向左，部分背面姿态方向不明显。未逐格检查姿态和主体完整性。
- 自动检查 256 像素网格线发现非透明像素，未满足各格透明间隔要求；尚未按主体边界重新排版，不能直接接入游戏。
