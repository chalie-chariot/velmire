extends Node
class_name SynergyEngine

func _ready() -> void:
	add_to_group("synergy_engine")

func check_synergies(connection_manager: Node) -> void:
	_clear_all_synergies()

	var connections = connection_manager._connections

	for conn in connections:
		var a = conn.from
		var b = conn.to

		if not is_instance_valid(a) or not is_instance_valid(b):
			continue

		_apply_synergy(a, b)

	var cm = get_tree().get_first_node_in_group("connection_manager")
	if cm:
		cm.trigger_synergy_flash()

func _clear_all_synergies() -> void:
	for n in get_tree().get_nodes_in_group("game_nodes"):
		n.synergy_double_damage = false
		n.synergy_fast_cooldown = false
		n.attack_cooldown = 3.0 if n.node_type != "흡혈" else 2.0
		n.synergy_wide_slow = false
		n.synergy_active = false

func _apply_synergy(a: Node, b: Node) -> void:
	var types: Array = [a.node_type, b.node_type]

	if types.has("흡혈") and types.has("결계"):
		var absorb = a if a.node_type == "흡혈" else b
		var freeze = a if a.node_type == "결계" else b
		absorb.synergy_double_damage = true
		freeze.synergy_active = true  # 결계도 시너지 활성 표시
		_show_synergy_popup(absorb, "흡혈+결계\n데미지 2배!")

	if types.has("흡혈") and types.has("증폭"):
		var absorb = a if a.node_type == "흡혈" else b
		if not absorb.synergy_fast_cooldown:
			absorb.synergy_fast_cooldown = true
			absorb.attack_cooldown = 1.5  # 흡혈 기본 2초의 50%↓
		_show_synergy_popup(absorb, "흡혈+증폭\n쿨다운 50%↓")

	if types.has("결계") and types.has("증폭"):
		var freeze = a if a.node_type == "결계" else b
		freeze.synergy_wide_slow = true
		_show_synergy_popup(freeze, "결계+증폭\n범위 2배!")


func _show_synergy_popup(node: Node, text: String) -> void:
	var main = node.get_tree().get_first_node_in_group("main")
	if not main:
		return
	if main.has_method("_get_chat_manager"):
		var cm = main._get_chat_manager()
		if cm:
			cm.send_chat("synergy")
	# 화면 상단 중앙에 박스형 팝업

	# 배경 박스 (텍스트 상하 여백 확보, 전체적으로 아래로)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.0, 0.0, 0.0)
	bg.size = Vector2(400, 96)
	bg.position = Vector2(760, 75)  # TopBar 아래, 여유 있게
	main.get_node("CanvasLayer").add_child(bg)

	# 테두리 (상하 여백)
	var border: ColorRect = ColorRect.new()
	border.color = Color(1.0, 0.8, 0.1, 0.9)
	border.size = Vector2(400, 2)
	border.position = Vector2(0, 0)
	bg.add_child(border)

	var border2: ColorRect = ColorRect.new()
	border2.color = Color(1.0, 0.8, 0.1, 0.9)
	border2.size = Vector2(400, 2)
	border2.position = Vector2(0, 94)
	bg.add_child(border2)

	# 텍스트 (위 18px, 아래 28px 여백)
	var label: Label = Label.new()
	label.text = "⚡ SYNERGY  " + text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color",
		Color(1.0, 0.9, 0.2, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(400, 50)
	label.position = Vector2(0, 18)
	bg.add_child(label)

	# 아래에서 위로 슬라이드 + 페이드인 → 유지 → 페이드아웃
	bg.modulate.a = 0.0
	bg.position.y = 110.0

	var tween: Tween = bg.create_tween()
	tween.tween_property(bg, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(bg, "position:y", 75.0, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_interval(1.5)
	tween.tween_property(bg, "modulate:a", 0.0, 0.4)
	tween.tween_callback(bg.queue_free)
