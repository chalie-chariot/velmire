shader_type canvas_item;

uniform float time_val : hint_range(0.0, 100.0) = 0.0;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;

// 세로 긴 6각형 마스크
float hex_mask(vec2 uv) {
	vec2 p = (uv - vec2(0.5)) * 2.0;
	p.x *= 0.75; // 가로를 좁혀서 세로로 긴 비율
	float a = abs(p.x);
	float b = abs(p.y);
	float c = abs(p.x * 0.5 + p.y * 0.866);
	float d = abs(p.x * 0.5 - p.y * 0.866);
	float dist = max(max(a, b * 0.577), max(c, d) * 0.577);
	return smoothstep(0.58, 0.54, dist);
}

void fragment() {
	vec2 uv = UV;
	float mask = hex_mask(uv);

	vec2 p = uv - vec2(0.5);

	// 6면 각도 분할
	float angle = atan(p.y * 1.3, p.x); // 세로 보정
	float sector = (angle + 3.14159) / (3.14159 / 3.0);
	int fi = int(floor(sector)) % 6;

	// 면별 밝기 (fi로 직접 분기)
	float brightness;
	if      (fi == 0) { brightness = 0.75; }
	else if (fi == 1) { brightness = 1.0;  }
	else if (fi == 2) { brightness = 0.55; }
	else if (fi == 3) { brightness = 0.85; }
	else if (fi == 4) { brightness = 0.45; }
	else              { brightness = 0.9;  }

	// 루비 색상
	vec3 ruby_dark  = vec3(0.35, 0.0,  0.04);
	vec3 ruby_mid   = vec3(0.82, 0.04, 0.10);
	vec3 ruby_light = vec3(1.0,  0.35, 0.40);

	vec3 col = mix(ruby_dark, ruby_mid, brightness);

	// 면 경계 커팅 라인
	float edge = abs(fract(sector) - 0.5);
	float cut = smoothstep(0.03, 0.06, edge);
	col = mix(vec3(0.08, 0.0, 0.01), col, cut);

	// 중심 깊이감
	float dist_center = length(p * vec2(0.75, 1.0));
	float depth = clamp(1.0 - dist_center * 1.9, 0.0, 1.0);
	col = mix(col, ruby_light, depth * 0.35);

	// 면별 순차 반짝임
	float sparkle = pow(
		max(0.0, sin(time_val * 1.5 + float(fi) * 1.047)),
		10.0
	);
	col += vec3(1.0, 0.55, 0.6) * sparkle * 0.55;

	// 상단 좌측 고정 하이라이트
	float hl = smoothstep(0.15, 0.0,
		length(p - vec2(-0.12, -0.22)));
	col = mix(col, vec3(1.0, 0.88, 0.92), hl * 0.75);

	// 외곽 rim
	float rim = 1.0 - smoothstep(0.3, 0.55,
		length(p * vec2(0.75, 1.0)));
	col += vec3(0.85, 0.05, 0.15) * rim * 0.2;

	// 만충 펄스
	float pulse = sin(time_val * 3.5) * 0.5 + 0.5;
	col += vec3(1.0, 0.2, 0.3) * glow_intensity * pulse * 0.35;

	COLOR = vec4(col, mask);
}
