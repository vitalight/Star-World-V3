# 第一章敌人图集 v4

使用内置 imagegen，透明背景。01 参考 `enemy-chapter1-atlas-01-v3.png`；02 参考复杂版本 `enemy-chapter1-atlas-02-v2.png`。以下为完整实际提示词。

## 图集 01

Create a SQUARE transparent 4 by 4 game sprite atlas, 16 isolated full-body sprites, four rows and four columns. CRITICAL LAYOUT: reserve a generous empty transparent margin of at least 15% of each cell width on ALL four sides of EVERY sprite. Each sprite occupies at most 70% of its own cell width and height, is centered and completely contained, with no overlapping cells, no cropped limbs, wings or equipment. Do not draw a grid or cell boundaries. All sixteen face screen LEFT, including rear three-quarter views. Columns are walk front-left, walk back-left showing back, attack front-left, attack back-left showing back. Compact attacks, no large effects. Hand-painted chibi tactical RPG style: restrained industrial menace, cute silhouettes, clear color blocks, medium detail density with select detail clusters and quiet surfaces, not overly busy nor overly plain. Moderately desaturated, muted palette, restrained glow, distinct colors per monster. Transparent background; no text, shadow, floor, border, watermark. Reference image is for monster identities and art style. Row 1 black-gray sludge slime with muted green glowing crystal; row 2 slender rust-red biped rift beast with amber cracks; row 3 bulky slate-blue quadruped heavy-claw beast with ice-blue crystal armor; row 4 ochre and iron humanoid shield guard with teal crystal shield.

## 图集 02

Use the supplied earlier complex monster sheet as the design and style reference. Recreate its four monsters faithfully, maintaining its rich detailed illustration, strong dramatic silhouettes, textures, character and distinct color families: row 1 polluted flying insect with translucent wings and glowing abdomen, row 2 dark wolf with glowing markings, row 3 powerful berserk mutant beast with node energy and electricity, row 4 dark-light humanoid colossus with glowing chest core. Create a SQUARE transparent 4 by 4 game sprite atlas, 16 isolated full-body sprites. CRITICAL: reserve at least 15% of each cell width as empty transparent margin on all four sides of every sprite. Each sprite fits entirely within its own cell, occupies at most 70% of cell width and height; wings, limbs, tails, equipment and effects are all complete and cannot cross the cell edge. All monsters face SCREEN LEFT, including rear views. Four columns: front-left walk, back-left walk, front-left attack, back-left attack; show real backs in rear views. Moderately lower saturation than the reference while retaining distinct palette per monster. No grid, text, ground, shadows or watermark. Compact poses and effects.

## 检查

- 01 行：污泥怪、裂口兽、重爪兽、盾卫；02 行：毒飞虫、疾狼、暴走兽、黯光巨像。
- `*-v4-source.png` 为 1254×1254 原始输出；`*-v4.png` 为等比缩放至 1024×1024 的 RGBA PNG。
- 自动检查 256 像素网格线发现非透明像素，两张均未满足透明间距，第二张部分攻击光效跨格。目视整体大致朝左，但部分人形正面姿态方向不明确。未完成逐格完整性验证，不能直接切片接入。
