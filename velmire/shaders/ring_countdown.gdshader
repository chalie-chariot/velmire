shader_type canvas_item;

uniform float arc_ratio : hint_range(0.0, 1.0) = 1.0;
// 1.0 = 360도 / 0.0 = 0도

uniform float warning : hint_range(0.0, 1.0) = 0.0;
// 0 = 청록 / 1 = 빨강

uniform float fade : hint_range(0.0, 1.0) = 1.0;
// 페이드아웃용

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv);

	// 링 두께 (600x600 기준 미세 조정)
	float ring = smoothstep(0.504, 0.500, r)
		   - smoothstep(0.490, 0.486, r);

	// 시계방향 호 계산
	// atan2 기준: 12시 방향이 0, 시계방향 증가
	float angle = atan(uv.x, -uv.y); // -PI ~ PI
	angle = angle / (2.0 * 3.14159) + 0.5; // 0 ~ 1
	// arc_ratio 만큼만 표시
	float arc = step(angle, arc_ratio);

	// 색상 (청록 → 빨강)
	vec3 cyan  = vec3(0.0, 0.9, 0.85);
	vec3 red   = vec3(1.0, 0.15, 0.2);
	vec3 col   = mix(cyan, red, warning);

	// 빨강일 때 깜빡임
	float blink = mix(1.0,
		step(0.5, fract(TIME * 2.5)),
		warning);

	float alpha = ring * arc * fade * blink;
	COLOR = vec4(col, clamp(alpha, 0.0, 1.0));
}
