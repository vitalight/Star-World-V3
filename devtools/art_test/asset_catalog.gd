extends RefCounted
## Source order is explicit; raw inputs are previewed without creating content IDs.
const CHARACTER_ATLASES = [
	"hero-atlas-01.png", "hero-atlas-02.png",
	"enemy-atlas-01.png", "enemy-atlas-02.png",
]
const EFFECT_ATLASES = ["effect-atlas-01.png", "effect-atlas-02.png"]
const POSES = ["正面待机", "背面待机", "正面攻击", "背面攻击"]

static func slice(atlas: Texture2D, row: int, column: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	var cell := atlas.get_size() / 4.0
	texture.region = Rect2(Vector2(column, row) * cell, cell)
	return texture

static func characters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for filename in CHARACTER_ATLASES:
		var atlas := load("res://Human/StarterContent/character/" + filename) as Texture2D
		for row in 4:
			var poses: Array[Texture2D] = []
			for column in 4:
				poses.append(slice(atlas, row, column))
			result.append({"source": filename, "row": row, "poses": poses})
	return result

static func effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for filename in EFFECT_ATLASES:
		var atlas := load("res://Human/StarterContent/effects/" + filename) as Texture2D
		for row in 4:
			for column in 4:
				result.append({"source": filename, "row": row, "column": column,
					"texture": slice(atlas, row, column)})
	return result

static func frames(poses: Array, back: bool) -> SpriteFrames:
	var result := SpriteFrames.new()
	result.set_animation_speed(&"default", 2.0)
	var first := 1 if back else 0
	result.add_frame(&"default", poses[first])
	result.add_frame(&"default", poses[first + 2])
	return result

## Formal icon slices shared with character appearances in Game Test.
static func skills() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in 16:
		result.append({"name": "图标 %02d" % (index + 1), "row": index / 4, "column": index % 4,
			"texture": load("res://content/ui/skill_icons/icon_%02d.tres" % (index + 1))})
	return result
