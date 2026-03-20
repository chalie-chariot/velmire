extends Node
class_name SynergyEngine

var _popup_bg: ColorRect = null
var _popup_label1: Label = null
var _popup_label2: Label = null
var _popup_tween: Tween = null

func _ready() -> void:
	add_to_group("synergy_engine")

func check_synergies(connection_manager: Node) -> void:
	# 참고: 관(coffin)-노드 연결(try_connect_to_coffin) 시에는 이 함수가 호출되지 않음.
	# finish_connect(노드-노드) → _notify_synergy_engine → check_synergies 경로만 사용됨.
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

	# 기존 팝업 있으면 텍스트만 업데이트 + 타이머 리셋
	if is_instance_valid(_popup_bg) and is_instance_valid(_popup_label1) and is_instance_valid(_popup_label2):
		_popup_bg.modulate = Color(1, 1, 1, 1)  # 투명도 초기화
		var lines: PackedStringArray = text.split("\n", false)
		_popup_label1.text = "⚡ SYNERGY  " + (lines[0] if lines.size() > 0 else "")
		_popup_label2.text = lines[1] if lines.size() > 1 else ""
		if _popup_tween:
			_popup_tween.kill()
		_popup_tween = _popup_bg.create_tween()
		_popup_tween.tween_interval(1.5)
		_popup_tween.tween_property(_popup_bg, "modulate:a", 0.0, 0.4)
		_popup_tween.tween_callback(_popup_cleanup)
		return

	# 새 팝업 생성
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.0, 0.0, 0.0)
	bg.size = Vector2(400, 110)
	bg.position = Vector2(760, 75)
	main.get_node("CanvasLayer").add_child(bg)
	_popup_bg = bg

	var border: ColorRect = ColorRect.new()
	border.color = Color(1.0, 0.8, 0.1, 0.9)
	border.size = Vector2(400, 2)
	border.position = Vector2(0, 0)
	bg.add_child(border)

	var border2: ColorRect = ColorRect.new()
	border2.color = Color(1.0, 0.8, 0.1, 0.9)
	border2.size = Vector2(400, 2)
	border2.position = Vector2(0, 108)
	bg.add_child(border2)

	var lines: PackedStringArray = text.split("\n", false)
	var line1: String = "⚡ SYNERGY  " + (lines[0] if lines.size() > 0 else "")
	var line2: String = lines[1] if lines.size() > 1 else ""

	var label1: Label = Label.new()
	label1.text = line1
	label1.add_theme_font_size_override("font_size", 24)
	label1.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label1.size = Vector2(400, 32)
	label1.position = Vector2(0, 20)
	bg.add_child(label1)
	_popup_label1 = label1

	var label2: Label = Label.new()
	label2.text = line2
	label2.add_theme_font_size_override("font_size", 22)
	label2.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15, 1.0))
	label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label2.size = Vector2(400, 32)
	label2.position = Vector2(0, 54)
	bg.add_child(label2)
	_popup_label2 = label2

	bg.modulate.a = 0.0
	bg.position.y = 110.0

	_popup_tween = bg.create_tween()
	_popup_tween.tween_property(bg, "modulate:a", 1.0, 0.2)
	_popup_tween.parallel().tween_property(bg, "position:y", 75.0, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_popup_tween.tween_interval(1.5)
	_popup_tween.tween_property(bg, "modulate:a", 0.0, 0.4)
	_popup_tween.tween_callback(_popup_cleanup)


func _popup_cleanup() -> void:
	if is_instance_valid(_popup_bg):
		_popup_bg.queue_free()
	_popup_bg = null
	_popup_label1 = null
	_popup_label2 = null
	_popup_tween = null
