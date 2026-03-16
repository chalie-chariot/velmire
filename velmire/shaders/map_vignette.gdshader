shader_type canvas_item;

uniform vec2 viewport_size;
uniform float darken_strength : hint_range(0.0, 1.0) = 0.45;

// 아이템으로 밝힐 수 있는 영역 (최대 2개)
uniform vec2 bright_center_0 = vec2(-9999.0, -9999.0);  // 오프시 화면 밖
uniform float bright_radius_0 = 0.0;
uniform float bright_strength_0 : hint_range(0.0, 2.0) = 1.0;

uniform vec2 bright_center_1 = vec2(-9999.0, -9999.0);
uniform float bright_radius_1 = 0.0;
uniform float bright_strength_1 : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 pixel_pos = UV * viewport_size;
	vec2 center = viewport_size * 0.5;
	float dist = distance(pixel_pos, center);
	float max_dist = length(viewport_size * 0.5);
	float darken = smoothstep(0.0, max_dist, dist) * darken_strength;

	// 밝은 영역: 해당 반경 안에서는 암전 감소
	float bright_reduce = 0.0;
	float d0 = distance(pixel_pos, bright_center_0);
	if (bright_radius_0 > 0.0) {
		float mask0 = 1.0 - smoothstep(0.0, bright_radius_0, d0);
		bright_reduce = max(bright_reduce, mask0 * bright_strength_0);
	}
	float d1 = distance(pixel_pos, bright_center_1);
	if (bright_radius_1 > 0.0) {
		float mask1 = 1.0 - smoothstep(0.0, bright_radius_1, d1);
		bright_reduce = max(bright_reduce, mask1 * bright_strength_1);
	}

	darken = max(0.0, darken - darken * bright_reduce);
	COLOR = vec4(0.0, 0.0, 0.0, darken);
}
