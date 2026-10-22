shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform sampler2D sprite_texture : source_color, filter_linear, repeat_disable;
uniform float readiness = 0.0;
varying vec3 billboard_world;
varying flat vec3 foot_world;

void vertex() {
	// Keep the visible quad exactly parallel to the camera, with no Y stretch.
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	billboard_world = (billboard * vec4(VERTEX, 1.0)).xyz;
	foot_world = MODEL_MATRIX[3].xyz;
}

void fragment() {
	vec4 texel = texture(sprite_texture, UV);
	if (texel.a < 0.32) { discard; }
	ALBEDO = texel.rgb * COLOR.rgb;
	if (readiness > 0.0) {
		vec2 step_uv = 2.5 / vec2(textureSize(sprite_texture, 0));
		float neighbor = min(min(texture(sprite_texture, UV + vec2(step_uv.x, 0.0)).a,
			texture(sprite_texture, UV - vec2(step_uv.x, 0.0)).a),
			min(texture(sprite_texture, UV + vec2(0.0, step_uv.y)).a,
			texture(sprite_texture, UV - vec2(0.0, step_uv.y)).a));
		float rim = clamp(texel.a - neighbor, 0.0, 1.0);
		ALBEDO = mix(ALBEDO, vec3(1.0, 0.76, 0.22), readiness * (rim * 0.85 + 0.06));
	}
	ALPHA = texel.a * COLOR.a;
	// Use an upright depth plane through the feet. The visible quad remains a
	// billboard, but its head no longer inherits the depth of the terrain behind.
	vec3 horizontal = vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z);
	vec3 normal = length(horizontal) > 0.0001 ? normalize(horizontal) : vec3(0.0, 0.0, 1.0);
	vec3 origin = INV_VIEW_MATRIX[3].xyz;
	vec3 ray = billboard_world - origin;
	if (PROJECTION_MATRIX[3][3] > 0.5) {
		origin = billboard_world;
		ray = -INV_VIEW_MATRIX[2].xyz;
	}
	float denominator = dot(ray, normal);
	vec3 upright = billboard_world;
	if (abs(denominator) > 0.0001) {
		float along = dot(foot_world - origin, normal) / denominator;
		upright = origin + ray * along;
	}
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(upright, 1.0);
	float ndc_depth = clip.z / clip.w;
	DEPTH = CLIP_SPACE_FAR == -1.0 ? ndc_depth * 0.5 + 0.5 : ndc_depth;
}
