# 第一章敌人图集 v2

使用内置 imagegen，透明背景。参考：用户提供的敌人描述及画风要求、`Human/ArtReference.jpg`、现有 `enemy-atlas-101.png`（布局和用途）。以下为实际发送的完整提示词，两张图分别由共同段落与对应段落拼接而成。

## 共同段落

Use case: stylized-concept. Asset: 4x4 transparent sprite atlas for a 2D tactical RPG, 4 rows of distinct monsters, 4 poses per monster. STRICT FACING DIRECTION: Every single one of the sixteen sprites MUST FACE SCREEN LEFT, toward the LEFT edge of the image. The creature's nose, face direction, movement and attacking direction all point left, NEVER right. For the rear three-quarter views show the actual back while the head and body still orient toward screen left. Do not mirror alternating columns. Each row contains the same creature in four compact poses: column 1 walking front-left 3/4, column 2 walking back-left 3/4, column 3 attacking front-left 3/4, column 4 attacking back-left 3/4. Separate sprites centered in equal cells, ample empty transparent space around all sides of each sprite, no touching or crossing cells, no cropping; consistent size and foot baseline per row. Style: polished hand-drawn chibi tactical RPG game sprites, industrial unease and restrained design blended with cute silhouettes, bold clear color blocks and light fantasy. Simplify contours and linework; broad quiet untextured areas and selective fine details at focal points, clean deliberate shapes, avoid fussy uniform detail and generic over-rendered AI look. Distinct recognizable palettes per monster, shared subtle contamination crystals. Transparent background; no shadows, floor, text, borders, grid, UI, watermark.

## 图集 01

Rows top to bottom: 1 small low black-gray sludge slime with glowing acid-green crystal inside, rounded soft body; 2 slender small biped rift beast, dusty rust-red body with amber node fissures; 3 large slow four-legged heavy claw beast, deep slate-blue body, massive forelegs and pale ice-blue crystal armor; 4 humanoid shield guard in muted ochre and dark iron, carrying a large shield made of teal crystal and fragments. Each row must visibly differ in its dominant colors and silhouette. All sprites face screen LEFT.

## 图集 02

Rows top to bottom: 1 polluted giant flying insect, muted olive and yellow-green abdomen glow, translucent wings, hovering; 2 fast black wolf with electric cyan glowing limb markings; 3 huge berserk mutant beast, dark maroon and violet with restrained violet electricity and node energy; 4 gigantic humanoid dark-light colossus, weathered charcoal and ivory with warm gold node core in chest. Each row must visibly differ in its dominant colors and silhouette. All sprites face screen LEFT.

## 检查记录

- `enemy-chapter1-atlas-01-v2.png`：污泥怪、裂口兽、重爪兽、盾卫。
- `enemy-chapter1-atlas-02-v2.png`：毒飞虫、疾狼、暴走兽、黯光巨像。
- 原始输出，未后处理。两张均为 1536×1024 RGBA，角落透明，不符合 1024×1024、256×256 单元的正式规格。
- 整图目视检查：色系已区分，多数姿态呈向左的运动方向；人形单位部分姿态朝向不够明确，部分背面与正面区分不足。存在光晕、攻击特效和部分主体靠近网格边界，尚未逐格检查透明边距及完整性，不能直接按项目图集接入。
