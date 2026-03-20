extends Node

# 오브젝트 이름 기준 색상 매핑
const COLOR_MAP = {
	# 벽/바닥
	"Floor": Color(0.140, 0.120, 0.200),
	"WallBack": Color(0.070, 0.060, 0.110),
	"WallLeft": Color(0.070, 0.060, 0.110),
	"WallRight": Color(0.070, 0.060, 0.110),
	"Ceiling": Color(0.055, 0.048, 0.090),

	# 책상
	"Desk": Color(0.075, 0.055, 0.120),

	# 의자
	"Chair_Back": Color(0.06, 0.05, 0.09),
	"Chair_Seat": Color(0.06, 0.05, 0.09),
	"Chair_Head": Color(0.06, 0.05, 0.09),
	"Chair_Arm": Color(0.50, 0.22, 0.85),
	"Chair_Accent": Color(0.50, 0.22, 0.85),
	"Chair_Metal": Color(0.22, 0.20, 0.25),
	"Chair_Chrome": Color(0.70, 0.68, 0.72),
	"Chair_Wheel": Color(0.07, 0.06, 0.09),

	# 모니터
	"Mon_Body": Color(0.05, 0.04, 0.09),
	# 모니터 스크린 (꺼짐 — 어두운 패널)
	"Mon_Scr": Color(0.06, 0.05, 0.10),
	"Mon_CurveCenter": Color(0.06, 0.05, 0.10),

	# LED 스트립
	"LED_Strip": Color(0.00, 1.00, 0.80),
	# 모니터 Bias LED (GLB 메시 이름에 BiasLight 포함) → 핑크
	"BiasLight": Color(1.00, 0.20, 0.60),

	# 키보드/마우스
	"KB_Body": Color(0.10, 0.08, 0.16),
	# 키보드 행별 네온
	"Key_0_": Color(0.00, 1.00, 0.80),
	"Key_1_": Color(1.00, 0.20, 0.80),
	"Key_2_": Color(0.20, 0.60, 1.00),
	"KB_Space": Color(0.80, 0.00, 1.00),
	"KB_accent": Color(1.00, 0.80, 0.00),
	# 네온사인
	"Neon_": Color(0.80, 0.00, 1.00),
	"MousePad": Color(0.08, 0.06, 0.14),
	"Mouse_LED": Color(0.00, 1.00, 0.80),
	"Mouse": Color(0.14, 0.11, 0.20),

	# 혈액팩
	"Bag_Body": Color(0.75, 0.05, 0.08),
	"Bag_Liquid": Color(0.50, 0.02, 0.04),

	# 보틀
	"Bottle": Color(0.70, 0.70, 0.75),

	# 게임패드
	"GP_Body": Color(0.06, 0.05, 0.10),
	"GP_Grip": Color(0.08, 0.06, 0.12),
	# 게임패드 버튼 (네온)
	"GP_BtnA": Color(1.00, 0.15, 0.15),
	"GP_BtnB": Color(0.00, 1.00, 0.30),
	"GP_BtnX": Color(0.10, 0.40, 1.00),
	"GP_BtnY": Color(1.00, 0.85, 0.00),
	"GP_BtnHome": Color(0.80, 0.00, 1.00),
	"GP_Stick": Color(0.10, 0.08, 0.14),
	"GP_Dpad": Color(0.12, 0.10, 0.18),
	"GP_Bumper": Color(0.10, 0.08, 0.16),
	"GP_Trigger": Color(0.10, 0.08, 0.14),

	# 스마트폰
	# 스마트폰 화면 발광
	"Phone_Scr": Color(0.55, 0.30, 0.95),
	"Phone_Body": Color(0.10, 0.08, 0.14),
	"Phone_Cam": Color(0.06, 0.05, 0.09),
	"PhCam_": Color(0.30, 0.20, 0.60),

	# 링라이트
	"RL_Ring": Color(1.00, 1.00, 1.00),
	"RL_LED": Color(1.00, 1.00, 1.00),
	"RL_Pole": Color(0.08, 0.06, 0.10),

	# 촛불
	"Candle_Flame": Color(1.00, 0.60, 0.05),

	# 마이크
	"Mic2_Body": Color(0.10, 0.08, 0.14),
	"MicArm": Color(0.08, 0.06, 0.10),
}

# 기본 색상 (매핑 없는 오브젝트)
const DEFAULT_COLOR = Color(0.15, 0.12, 0.22)
const SHADOW_MULT = 0.22
const HIGHLIGHT_MULT = 1.28

var toon_shader: Shader

func _ready() -> void:
	toon_shader = load("res://assets/shaders/toon_shader.gdshader") as Shader
	var room = get_parent().get_node_or_null("room")
	if room:
		apply_toon_recursive(room)
		print("툰셰이더 적용 완료")
	else:
		print("[ERROR] room 노드를 찾을 수 없음")

	_create_bias_lights()


func _create_bias_lights() -> void:
	var parent = get_parent()

	var configs = [
		{
			"pos": Vector3(-0.72, -2.62, 1.35),
			"color": Color(1.0, 0.2, 0.6),
			"energy": 1.2,
		},
		{
			"pos": Vector3(0.72, -2.62, 1.35),
			"color": Color(0.0, 0.9, 0.8),
			"energy": 1.2,
		},
	]

	for i in range(configs.size()):
		var cfg = configs[i]
		var mp = cfg["pos"] as Vector3
		var bcol = cfg["color"] as Color
		var w = 0.52
		var h = 0.32
		var d = -0.08

		var emit_mat = StandardMaterial3D.new()
		emit_mat.emission_enabled = true
		emit_mat.emission = bcol
		emit_mat.emission_energy_multiplier = 4.0
		emit_mat.albedo_color = bcol
		emit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		var bars = [
			[Vector3(mp.x, mp.y + d, mp.z + h * 0.5 + 0.01), Vector3(w, 0.008, 0.008)],
			[Vector3(mp.x, mp.y + d, mp.z - h * 0.5 - 0.01), Vector3(w, 0.008, 0.008)],
			[Vector3(mp.x - w * 0.5 - 0.01, mp.y + d, mp.z), Vector3(0.008, 0.008, h)],
			[Vector3(mp.x + w * 0.5 + 0.01, mp.y + d, mp.z), Vector3(0.008, 0.008, h)],
		]

		for j in range(bars.size()):
			var mesh_inst = MeshInstance3D.new()
			mesh_inst.name = "BiasBar_%d_%d" % [i, j]
			var box_mesh = BoxMesh.new()
			box_mesh.size = bars[j][1]
			mesh_inst.mesh = box_mesh
			mesh_inst.material_override = emit_mat
			mesh_inst.position = bars[j][0]
			parent.add_child(mesh_inst)

		var omni = OmniLight3D.new()
		omni.name = "BiasOmni_%d" % i
		omni.position = Vector3(mp.x, mp.y - 0.12, mp.z)
		omni.light_color = bcol
		omni.light_energy = cfg["energy"] as float
		omni.omni_range = 1.2
		parent.add_child(omni)

	var desk_omni = OmniLight3D.new()
	desk_omni.name = "DeskLED_Omni"
	desk_omni.position = Vector3(0.0, -2.2, 0.78)
	desk_omni.light_color = Color(0.0, 1.0, 0.8)
	desk_omni.light_energy = 0.6
	desk_omni.omni_range = 1.2
	parent.add_child(desk_omni)

	var ceil_omni = OmniLight3D.new()
	ceil_omni.name = "CeilLED_Omni"
	ceil_omni.position = Vector3(0.0, -1.8, 4.5)
	ceil_omni.light_color = Color(0.6, 0.0, 1.0)
	ceil_omni.light_energy = 0.5
	ceil_omni.omni_range = 3.0
	parent.add_child(ceil_omni)


func apply_toon_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		apply_toon_to_mesh(node)
	for child in node.get_children():
		apply_toon_recursive(child)


func apply_toon_to_mesh(mesh_instance: MeshInstance3D) -> void:
	var base_col = get_color_for_node(mesh_instance.name)

	# 발광 오브젝트 목록
	var emit_keywords = [
		"RL_Ring", "RL_LED",
		"GP_BtnHome", "GP_BtnA", "GP_BtnB", "GP_BtnX", "GP_BtnY",
		"Mouse_LED",
		"NeonLight", "Neon_", "LED_Strip",
		"PhCam_L",
		"Key_0_",
		"Key_1_",
		"Key_2_",
		"KB_Space",
		"KB_accent",
		"Phone_Scr",
		"BiasLight_Top",
		"BiasLight_Bot",
		"BiasLight_L",
		"BiasLight_R",
		"Candle_Flame",
	]

	var is_emit = false
	for kw in emit_keywords:
		if mesh_instance.name.contains(kw):
			is_emit = true
			break

	if is_emit:
		var emit_col = base_col

		# 키캡은 행별로 살짝 랜덤 밝기 변화
		var key_keywords = ["Key_0_", "Key_1_", "Key_2_", "KB_Space", "KB_accent"]
		var is_key = false
		for kk in key_keywords:
			if mesh_instance.name.contains(kk):
				is_key = true
				break

		var highlight_boost = 1.55 if is_key else 1.32

		var mat = ShaderMaterial.new()
		mat.shader = toon_shader
		mat.set_shader_parameter("base_color", emit_col)
		mat.set_shader_parameter(
			"shadow_color",
			Color(
				emit_col.r * 0.6,
				emit_col.g * 0.6,
				emit_col.b * 0.6
			)
		)
		mat.set_shader_parameter(
			"highlight_color",
			Color(
				min(emit_col.r * highlight_boost, 1.0),
				min(emit_col.g * highlight_boost, 1.0),
				min(emit_col.b * highlight_boost, 1.0)
			)
		)
		mat.set_shader_parameter("shadow_threshold", 0.0)
		mat.set_shader_parameter("highlight_threshold", 0.0)
		mat.set_shader_parameter("outline_thickness", 0.001)
		mat.set_shader_parameter("outline_color", Color(0.04, 0.03, 0.08, 1.0))
		mesh_instance.material_override = mat
		return

	# 일반 툰셰이더
	var shadow_col = Color(
		base_col.r * SHADOW_MULT,
		base_col.g * SHADOW_MULT,
		base_col.b * SHADOW_MULT
	)
	var highlight_col = Color(
		min(base_col.r * HIGHLIGHT_MULT + 0.1, 1.0),
		min(base_col.g * HIGHLIGHT_MULT + 0.05, 1.0),
		min(base_col.b * HIGHLIGHT_MULT + 0.15, 1.0)
	)

	var mat = ShaderMaterial.new()
	mat.shader = toon_shader
	mat.set_shader_parameter("base_color", base_col)
	mat.set_shader_parameter("shadow_color", shadow_col)
	mat.set_shader_parameter("highlight_color", highlight_col)
	mat.set_shader_parameter("shadow_threshold", 0.42)
	mat.set_shader_parameter("highlight_threshold", 0.78)
	mat.set_shader_parameter("outline_thickness", 0.0025)
	mat.set_shader_parameter("outline_color", Color(0.04, 0.03, 0.08, 1.0))
	mesh_instance.material_override = mat


func get_color_for_node(node_name: String) -> Color:
	for key in COLOR_MAP.keys():
		if node_name.begins_with(key) or node_name.contains(key):
			return COLOR_MAP[key]
	return DEFAULT_COLOR
