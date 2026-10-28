# Blocked high terrain v2

Source: built-in imagegen, editing `blocked_high_v1.png` with `content/terrains/terrain_002/atlas.png` as an additional material reference. The generated image is `blocked_high_v2.png`.

Prompt: Use case: precise-object-edit. Create a square top-down tactical game tile for a non-deployable elevated concrete platform. First reference is the edit target: keep its clean complete black-and-yellow diagonal hazard border around all four edges and its square flat overhead framing. Replace the dark center entirely with light beige-gray concrete paving, matching the light high-platform tiles in the top row of the second reference. Center should be predominantly pale concrete, visibly much lighter than the border, simple paving seams and subtle wear; no dark steel panels, grates or holes. Integrate the warning border naturally. Same hand-painted urban strategy game material, diffuse light, no perspective, no shadows, no characters, no text or logos.

Packing: resized to 256×256 and placed in row 4, column 4 of `content/terrains/terrain_002/atlas_blocked_v2.png`, and to 64×64 in editor palette coordinate (1,3). The earlier dark texture is retained in row 3, column 4 and palette coordinate (2,3) for blocked ground.
