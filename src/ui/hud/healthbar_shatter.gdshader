shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float crack_scale : hint_range(1.0, 50.0) = 14.0;
uniform vec4 crack_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float voronoi_edge(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = hash2(cell + neighbor);
			float dist = length(neighbor + point - f);
			if (dist < d1) {
				d2 = d1;
				d1 = dist;
			} else if (dist < d2) {
				d2 = dist;
			}
		}
	}
	return d2 - d1;
}

void fragment() {
	vec4 base = texture(screen_texture, SCREEN_UV);
	float edge = voronoi_edge(UV * crack_scale);
	float crack_mask = smoothstep(0.0, 0.03, edge);
	vec4 cracked = mix(crack_color, base, crack_mask);
	vec4 result = mix(base, cracked, clamp(progress * 1.5, 0.0, 1.0));
	result.a = base.a * (1.0 - progress);
	COLOR = result;
}
