
shader_type canvas_item;

uniform vec4 vein_color : source_color = vec4(1.0, 0.251, 0.251, 1.0);
uniform vec4 vignette_color : source_color = vec4(0.65, 0.0, 0.0, 1.0);

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vein_width : hint_range(0.001, 0.1) = 0.01;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float edge_depth : hint_range(0.0, 0.5) = 0.2;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vein_strength : hint_range(0.0, 1.0) = 0.7;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float veins(vec2 uv) {
	vec2 p = uv * 9.0;
	float distortion = noise(p * 0.7) * 0.35;

	float pattern = abs(
		sin(p.x * 3.0 + sin(p.y * 1.7) * 1.5 + distortion * 5.0)
	);

	float branches = abs(
		sin(p.y * 4.0 + sin(p.x * 2.0) * 1.8 + distortion * 4.0)
	);

	return 1.0 - smoothstep(0.0, vein_width, min(pattern, branches));
}

void fragment() {
	vec2 uv = UV;

	float edge = min(
		min(uv.x, 1.0 - uv.x),
		min(uv.y, 1.0 - uv.y)
	);

	float edge_mask = 1.0 - smoothstep(0.0, edge_depth, edge);

	float pulse = 0.85 + sin(TIME * pulse_speed) * 0.15;

	// Normalize existing GDScript intensity range (0.08-0.15)
	float effect = clamp(intensity / 0.15, 0.0, 1.0);

	float vein_pattern = veins(uv);

	float vignette_alpha = edge_mask * effect * vignette_strength * pulse;
	float vein_alpha = vein_pattern * edge_mask * effect * vein_strength * pulse;

	float alpha = vein_alpha + vignette_alpha * (1.0 - vein_alpha);

	vec3 color = (
		vein_color.rgb * vein_alpha
		+ vignette_color.rgb * vignette_alpha * (1.0 - vein_alpha)
	) / max(alpha, 0.0001);

	COLOR = vec4(color, alpha);
}
