shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform float segments = 8.0;
uniform float progress = 0.0;

float bolt_height(float x, float seed) {
	float step_x = x * segments;
	float tooth = mod(floor(step_x), 2.0) * 2.0 - 1.0;
	float amplitude = 0.11 + 0.08 * fract(sin(floor(step_x) * 23.7 + seed) * 4375.9);
	float next_amplitude = 0.11 + 0.08 * fract(sin((floor(step_x) + 1.0) * 23.7 + seed) * 4375.9);
	float envelope = smoothstep(0.0, 0.11, x) * (1.0 - smoothstep(0.89, 1.0, x));
	return mix(tooth * amplitude, -tooth * next_amplitude, fract(step_x)) * envelope;
}

void fragment() {
	float seed = floor(progress * 3.0);
	float x = UV.x;
	float y = UV.y - 0.5;
	float arc = abs(y - bolt_height(x, seed));
	float branch_x = clamp((x - 0.31) / 0.42, 0.0, 1.0);
	float branch = abs(y - bolt_height(x, seed) - sin(branch_x * PI) * 0.29);
	float core = 1.0 - smoothstep(0.016, 0.052, arc);
	float halo = (1.0 - smoothstep(0.02, 0.19, arc)) * 0.78;
	float fork = (1.0 - smoothstep(0.014, 0.047, branch)) * sin(branch_x * PI) * 0.75;
	ALBEDO = mix(vec3(0.29, 0.46, 1.0), vec3(0.93, 0.99, 1.0), max(core, fork * 0.7));
	ALPHA = max(max(halo, core), fork) * (1.0 - smoothstep(0.25, 1.0, progress));
}
