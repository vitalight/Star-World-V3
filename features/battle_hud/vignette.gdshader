shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = smoothstep(0.30, 1.25, length(p * vec2(0.8, 0.85)));
	COLOR = vec4(0.015, 0.02, 0.025, edge * 0.45);
}
