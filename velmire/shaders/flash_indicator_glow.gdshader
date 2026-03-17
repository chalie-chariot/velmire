shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(1.0, 0.88, 0.1, 0.2);
// 은은한 노란빛 산란

void fragment() {
	vec2 uv = UV - vec2(0.5);
	// 중앙에서 바깥으로 넓게 퍼지는 부드러운 감쇠 (블러/산란된 빛)
	float r = length(uv) * 2.0;
	float soft = 1.0 - smoothstep(0.0, 1.4, r);
	// 상단이 더 밝게, 하단으로 부드럽게 스며들듯
	float v_fade = 0.6 + 0.4 * (1.0 - UV.y);
	float alpha = soft * v_fade * base_color.a;
	COLOR = vec4(base_color.rgb, alpha);
}
