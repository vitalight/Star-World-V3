shader_type canvas_item;
render_mode unshaded;

uniform vec4 source_edges;
uniform vec4 screen_edges;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

float align_axis(float value, vec2 screen, vec2 source) {
	if (value < screen.x) {
		return mix(0.0, source.x, value / screen.x);
	}
	if (value > screen.y) {
		return mix(source.y, 1.0, (value - screen.y) / (1.0 - screen.y));
	}
	return mix(source.x, source.y, (value - screen.x) / (screen.y - screen.x));
}

void fragment() {
	float depth = clamp((UV.y - screen_edges.y) / (screen_edges.w - screen_edges.y), 0.0, 1.0);
	float left = mix(screen_edges.x, screen_edges.z, depth);
	float source_left = mix(source_edges.x, source_edges.z, depth);
	vec2 sample_uv = vec2(
		align_axis(UV.x, vec2(left, 1.0 - left), vec2(source_left, 1.0 - source_left)),
		align_axis(UV.y, screen_edges.yw, source_edges.yw)
	);
	COLOR = tint * texture(TEXTURE, sample_uv);
}
