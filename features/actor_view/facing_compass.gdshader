shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;

void fragment() {
	// Tactical ground overlay stays readable beside raised tiles; actors draw above it.
	// Ground-plane UVs: the pointer faces local +X; the mesh rotates with facing.
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float radius = length(p);
	float aa = max(fwidth(radius), 0.008);
	float disk = 1.0 - smoothstep(0.58 - aa, 0.58 + aa, radius);
	float ring = (1.0 - smoothstep(0.64 - aa, 0.64 + aa, radius))
		* smoothstep(0.56 - aa, 0.56 + aa, radius);
	float triangle_edge = min(p.x - 0.49, (0.97 - p.x) * 0.58 - abs(p.y));
	float arrow = smoothstep(-aa, aa, triangle_edge);
	ALBEDO = mix(vec3(0.26, 0.88, 0.76), vec3(0.83, 1.0, 0.92), arrow);
	ALPHA = max(max(disk * 0.12, ring * 0.70), arrow * 0.82);
}
