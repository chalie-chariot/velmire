shader_type canvas_item;

uniform float fill_ratio : hint_range(0.0, 1.0) = 0.5;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform int level : hint_range(1, 3) = 1;
uniform float time_val : hint_range(0.0, 100.0) = 0.0;

// 심장형 마스크 함수 (거꾸로)
float heart_mask(vec2 uv) {
	vec2 p = uv - vec2(0.5, 0.45);
	p.y = -p.y; // 거꾸로
	float a = atan(p.x, p.y) / 3.141593;
	float r = length(p);
	float h = (sqrt(1.0 - a * a) * 0.55);
	return smoothstep(h + 0.02, h - 0.02, r);
}

// 균열 패턴 (Lv.1)
float crack_pattern(vec2 uv) {
	float c = 0.0;
	c += step(0.97, sin(uv.x * 18.0 + uv.y * 7.0));
	c += step(0.97, sin(uv.x * 9.0 - uv.y * 14.0));
	return clamp(c, 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV;
	float mask = heart_mask(uv);

	// 액체 채움 (하단부터)
	float liquid_line = 1.0 - fill_ratio;
	// 출렁임
	float wave = sin(uv.x * 12.0 + time_val * 3.0) * 0.025 * fill_ratio;
	float liquid = step(liquid_line + wave, uv.y);

	// 레벨별 액체 색상
	vec4 liquid_color;
	if (level == 1) {
		// 탁한 루비
		liquid_color = mix(
			vec4(0.45, 0.05, 0.08, 0.85),
			vec4(0.65, 0.08, 0.12, 0.9),
			uv.y
		);
	} else if (level == 2) {
		// 맑은 루비
		liquid_color = mix(
			vec4(0.7, 0.05, 0.15, 0.85),
			vec4(0.95, 0.1, 0.2, 0.9),
			uv.y
		);
	} else {
		// 발광 루비
		liquid_color = mix(
			vec4(0.9, 0.05, 0.2, 0.9),
			vec4(1.0, 0.3, 0.4, 1.0),
			uv.y
		);
	}

	// 유리 본체 색상
	vec4 glass_color = vec4(0.06, 0.0, 0.01, 0.75);

	// 액체/유리 혼합
	vec4 base = mix(glass_color, liquid_color, liquid);

	// 테두리 (금속 느낌)
	float border = heart_mask(uv) - heart_mask(uv * 0.88 + 0.06);
	vec4 border_color;
	if (level == 1) {
		border_color = vec4(0.25, 0.25, 0.25, 1.0); // 낡은 회색
	} else if (level == 2) {
		border_color = vec4(0.55, 0.35, 0.1, 1.0);  // 금속 골드
	} else {
		border_color = vec4(0.85, 0.6, 0.15, 1.0);  // 빛나는 골드
	}
	base = mix(base, border_color, border);

	// Lv.1 균열
	if (level == 1) {
		float crack = crack_pattern(uv) * mask;
		base = mix(base, vec4(0.8, 0.8, 0.8, 1.0), crack * 0.4);
	}

	// Lv.3 내부 심장 코어
	if (level == 3) {
		float core_pulse = 0.5 + 0.5 * sin(time_val * 2.5);
		float core = heart_mask(uv * 1.6 - vec2(0.3, 0.25));
		base = mix(base, vec4(1.0, 0.5, 0.6, 1.0), core * core_pulse * 0.6);
	}

	// 만충 발광 오버레이
	base.rgb += vec3(0.8, 0.0, 0.1) * glow_intensity * mask;

	// 하이라이트 (유리 광택)
	float highlight = smoothstep(0.85, 1.0,
		heart_mask((uv - vec2(0.08, 0.08)) * 1.1));
	base = mix(base, vec4(1.0, 0.8, 0.85, 0.6), highlight * 0.35);

	COLOR = vec4(base.rgb, base.a * mask);
}
