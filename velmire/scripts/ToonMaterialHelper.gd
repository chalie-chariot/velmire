extends Node

# 오브젝트 이름 기준 색상 매핑
const COLOR_MAP = {
	# 바닥 / 벽
	"Floor": Color(0.08, 0.05, 0.05),
	"WallBack": Color(0.06, 0.04, 0.04),
	"WallLeft": Color(0.06, 0.04, 0.04),
	"WallRight": Color(0.06, 0.04, 0.04),
	"Ceiling": Color(0.04, 0.03, 0.03),

	# 책상 — 검붉은
	"Desk": Color(0.12, 0.06, 0.07),

	# 의자
	"Chair_Back": Color(0.08, 0.06, 0.06),
	"Chair_Seat": Color(0.08, 0.06, 0.06),
	"Chair_Head": Color(0.08, 0.06, 0.06),
	"Chair_Wing": Color(0.07, 0.05, 0.05),
	"Chair_Base": Color(0.10, 0.08, 0.08),
	"Chair_Arm": Color(0.12, 0.10, 0.10),
	"Chair_Metal": Color(0.14, 0.12, 0.12),
	"Chair_Chrome": Color(0.25, 0.22, 0.22),
	"Chair_Wheel": Color(0.07, 0.05, 0.05),
	"Chair_Gas": Color(0.20, 0.17, 0.17),
	"Chair_Mech": Color(0.10, 0.08, 0.08),
	"Chair_Frame": Color(0.10, 0.08, 0.08),
	"Chair_NeckPad": Color(0.08, 0.06, 0.06),
	"Chair_ArmPad": Color(0.10, 0.08, 0.08),
	"Chair_ArmPole": Color(0.12, 0.10, 0.10),
	"Chair_Stitch": Color(0.30, 0.05, 0.08),

	# 모니터 — 검붉은 베젤
	"Mon_Body": Color(0.10, 0.06, 0.07),
	"Mon_Neck": Color(0.10, 0.06, 0.07),
	"Mon_Arm": Color(0.10, 0.06, 0.07),
	"Mon_Base": Color(0.10, 0.06, 0.07),
	"Mon_Scr": Color(0.05, 0.03, 0.08),
	"Mon_CurveCen": Color(0.05, 0.03, 0.08),

	# 키보드/마우스 — 짙은 회색
	"KB_Body": Color(0.10, 0.08, 0.10),
	"MousePad": Color(0.08, 0.06, 0.09),
	"Mouse": Color(0.10, 0.08, 0.11),

	# 마이크/암 — 검정
	"Mic2": Color(0.08, 0.06, 0.08),
	"MicArm": Color(0.07, 0.05, 0.07),
	"PopFilter": Color(0.12, 0.10, 0.13),

	# 혈액팩 — 검붉은
	"Bag_Body": Color(0.35, 0.04, 0.05),
	"Bag_Liquid": Color(0.28, 0.03, 0.04),
	"Bag_Stand": Color(0.18, 0.16, 0.20),
	"Bag_Pole": Color(0.18, 0.16, 0.20),
	"Bag_Arm": Color(0.18, 0.16, 0.20),
	"Bag_Port": Color(0.15, 0.13, 0.16),

	# 보틀 — 짙은 회색
	"Bottle_Body": Color(0.20, 0.18, 0.22),
	"Bottle_Cap": Color(0.22, 0.10, 0.30),

	# 게임패드 — 검정
	"GP_Body": Color(0.08, 0.06, 0.09),
	"GP_Grip": Color(0.07, 0.05, 0.08),
	"GP_Stick": Color(0.09, 0.07, 0.10),
	"GP_Dpad": Color(0.10, 0.08, 0.11),
	"GP_Bumper": Color(0.09, 0.07, 0.10),
	"GP_Trigger": Color(0.08, 0.06, 0.09),

	# 방음패널
	"Foam_": Color(0.08, 0.06, 0.06),
	"FoamTip_": Color(0.10, 0.07, 0.07),

	# 포스터/액자
	"Poster_Frame": Color(0.10, 0.07, 0.07),
	"Poster_Art1": Color(0.12, 0.05, 0.06),
	"Poster_Art2": Color(0.08, 0.04, 0.05),

	# 선반/소품
	"Shelf": Color(0.10, 0.07, 0.07),
	"Skull": Color(0.55, 0.52, 0.55),
	"Candle_Body": Color(0.45, 0.42, 0.40),
	"Candle_Base": Color(0.15, 0.13, 0.16),

	# 링라이트
	"RL_Ring": Color(1.00, 1.00, 1.00),
	"RL_LED": Color(1.00, 1.00, 1.00),
	"RL_Pole": Color(0.10, 0.08, 0.10),
	"RL_Base": Color(0.10, 0.08, 0.10),
	"RL_Leg": Color(0.10, 0.08, 0.10),

	# 발광 — 네온 컬러 유지
	"LED_Strip": Color(0.00, 1.00, 0.80),
	"BiasLight": Color(1.00, 0.20, 0.60),
	"Neon_": Color(0.80, 0.00, 1.00),
	"CeilLED": Color(0.15, 0.05, 0.08),
	"Key_0_": Color(0.00, 1.00, 0.80),
	"Key_1_": Color(1.00, 0.20, 0.80),
	"Key_2_": Color(0.20, 0.60, 1.00),
	"KB_Space": Color(0.80, 0.00, 1.00),
	"KB_accent": Color(1.00, 0.80, 0.00),
	"GP_BtnA": Color(1.00, 0.15, 0.15),
	"GP_BtnB": Color(0.00, 1.00, 0.30),
	"GP_BtnX": Color(0.10, 0.40, 1.00),
	"GP_BtnY": Color(1.00, 0.85, 0.00),
	"GP_BtnHome": Color(0.80, 0.00, 1.00),
	"Mouse_LED": Color(0.00, 1.00, 0.80),
	"Candle_Flame": Color(1.00, 0.60, 0.05),
	"PS_LED": Color(0.00, 1.00, 0.50),
	"Phone_Scr": Color(0.55, 0.30, 0.95),
}

const DEFAULT_COLOR = Color(0.07, 0.05, 0.05)
const SHADOW_MULT = 0.15
const HIGHLIGHT_MULT = 1.50

var toon_shader: Shader

func _ready() -> void:
	toon_shader = load("res://assets/shaders/toon_shader.gdshader") as Shader
	var room = get_parent().get_node_or_null("room")
	if room:
		apply_toon_recursive(room)
		print("툰셰이더 적용 완료")
	else:
		print("[ERROR] room 노드를 찾을 수 없음")

	var main_title = get_parent()
	if main_title:
		_disable_omni_lights_by_prefix(main_title, "CeilLight_")

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

	# 책상 아래 LED만 약하게 (다른 조명은 건드리지 않음)
	var desk_omni = OmniLight3D.new()
	desk_omni.name = "DeskLED_Omni"
	desk_omni.position = Vector3(0.0, -2.2, 0.78)
	desk_omni.light_color = Color(0.0, 1.0, 0.8)
	desk_omni.light_energy = 0.25
	desk_omni.omni_range = 0.7
	parent.add_child(desk_omni)

	var ceil_omni = OmniLight3D.new()
	ceil_omni.name = "CeilLED_Omni"
	ceil_omni.position = Vector3(0.0, -1.8, 4.5)
	ceil_omni.light_color = Color(0.15, 0.05, 0.08)
	ceil_omni.light_energy = 0.3
	ceil_omni.omni_range = 3.0
	parent.add_child(ceil_omni)


func _disable_omni_lights_by_prefix(root: Node, prefix: String) -> void:
	for child in root.get_children():
		if child is OmniLight3D and child.name.begins_with(prefix):
			(child as OmniLight3D).light_energy = 0.0
		_disable_omni_lights_by_prefix(child, prefix)


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
		"CeilLED", "PS_LED",
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
