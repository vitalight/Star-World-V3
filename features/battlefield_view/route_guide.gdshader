shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float route_length = 9.0;
void fragment() {
	float across = abs(UV.y - 0.5) * 2.0;
	float core = 1.0 - smoothstep(0.20, 0.62, across);
	float glow = 1.0 - smoothstep(0.40, 1.0, across);
	// A single illuminated packet traverses the entire route, birth -> base.
	float head = progress * 1.25 - 0.10;
	float packet = smoothstep(head - 0.30, head - 0.12, UV.x) * (1.0 - smoothstep(head, head + 0.07, UV.x));
	float streak = 0.55 + 0.45 * pow(0.5 + 0.5 * cos((UV.x - head) * route_length * 15.0), 3.0);
	float fade = smoothstep(0.0, 0.07, progress) * (1.0 - smoothstep(0.90, 1.0, progress));
	ALBEDO = mix(vec3(1.0, 0.22, 0.10), vec3(1.0, 0.92, 0.67), packet * core);
	ALPHA = fade * (glow * 0.22 + core * (0.20 + packet * streak * 0.58));
}
