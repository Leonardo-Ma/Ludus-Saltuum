shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

void vertex() {
	// Trail3D packs local tangent and signed half width in CUSTOM0
	vec3 local_camera = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	vec3 side = cross(VERTEX - local_camera, CUSTOM0.xyz);
	VERTEX += side * (CUSTOM0.w * inversesqrt(max(dot(side, side), 1e-8)));
}

void fragment() {
	float edge = abs(UV.y * 2.0 - 1.0);
	float soft_edge = 1.0 - smoothstep(0.1, 1.0, edge);
	float wake = smoothstep(0.12, 0.36, UV.x);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * soft_edge * wake;
}
