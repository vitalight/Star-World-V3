shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
	ALBEDO = vec3(0.065, 0.05, 0.035);
	ALPHA = (1.0 - smoothstep(0.08, 0.50, length(UV - vec2(0.5)))) * 0.38;
}
