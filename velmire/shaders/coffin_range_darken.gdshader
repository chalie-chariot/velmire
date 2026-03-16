shader_type canvas_item;

uniform vec2 coffin_center;
uniform float coffin_radius;
uniform vec2 viewport_size;
uniform float darken_strength : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 pixel_pos = UV * viewport_size;
	float dist = distance(pixel_pos, coffin_center);
	// 화면 가장자리(어두움) → 관 범위(밝음)까지 서서히 그라데이션 (약 700px 구간)
	float max_dist = length(vec2(viewport_size.x * 0.5, viewport_size.y * 0.5));
	float darken = smoothstep(coffin_radius, max_dist, dist) * darken_strength;
	COLOR = vec4(0.0, 0.0, 0.0, darken);
}
