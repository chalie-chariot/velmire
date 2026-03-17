shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int effect_type : hint_range(0, 1) = 0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv);
	vec3 col = vec3(1.0, 0.15, 0.25);
	float alpha = 0.0;

	if (effect_type == 0) {
		// 도넛 링 — 안쪽 완전 비움
		float ring_r = 0.08 + progress * 0.42;
		float thickness = 0.018 - progress * 0.01;
		float ring = smoothstep(thickness, 0.0,
			abs(r - ring_r));
		float fade = pow(1.0 - progress, 0.8);
		alpha = ring * fade * 2.0;
		col = mix(
			vec3(1.0, 0.6, 0.65),
			vec3(0.9, 0.05, 0.15),
			progress
		);

	} else {
		// 빛줄기 — 중심 제외하고 방사만
		float angle = atan(uv.y, uv.x);
		float rays = pow(
			max(0.0, sin(angle * 8.0)), 5.0
		);
		// 중심 마스크 (안쪽 비움)
		float center_mask = smoothstep(0.08, 0.18, r);
		float outer_mask = smoothstep(0.5, 0.35, r);
		float streak = rays * center_mask * outer_mask;
		float fade = pow(1.0 - progress, 1.2);
		// 줄기가 바깥으로 밀려나가는 느낌
		float push = smoothstep(0.0, 0.5, r - progress * 0.2);
		alpha = streak * fade * push * 1.5;
		col = vec3(1.0, 0.3, 0.4);
	}

	COLOR = vec4(col, clamp(alpha, 0.0, 1.0));
}
