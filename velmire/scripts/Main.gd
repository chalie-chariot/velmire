extends Node2D

@onready var blood_entity_scene = preload("res://scenes/BloodEntity.tscn")
@onready var _coffin_rect: ColorRect = $CanvasLayer/Coffin
@onready var _vignette: ColorRect = $CanvasLayer/VignetteOverlay
@onready var _live_dot: Label = $CanvasLayer/TopBar/LiveDot
@onready var _blood_label: Label = $CanvasLayer/TopBar/BloodLabel
@onready var _timer_label: Label = $CanvasLayer/TopBar/TimerLabel
@onready var _tooltip: ColorRect = $CanvasLayer/TooltipBar
@onready var _tip_name: Label = $CanvasLayer/TooltipBar/NodeName
@onready var _tip_desc: Label = $CanvasLayer/TooltipBar/NodeDesc
@onready var _tip_syn1: Label = $CanvasLayer/TooltipBar/Synergy1
@onready var _tip_syn2: Label = $CanvasLayer/TooltipBar/Synergy2
@onready var _stat_atk: Label = $CanvasLayer/TooltipBar/StatATK
@onready var _stat_cd: Label = $CanvasLayer/TooltipBar/StatCooldown
@onready var _hint_popup: PanelContainer = $CanvasLayer/HintPopup
@onready var _hint_label: Label = $CanvasLayer/HintPopup/HintLabel
@onready var _hint_area: Control = $CanvasLayer/HintArea
@onready var _dots_container: Control = $CanvasLayer/HintArea/DotsContainer
@onready var _viewer_label: Label = $CanvasLayer/RightPanel/ViewerBar/ViewerLabel
@onready var _like_label: Label = $CanvasLayer/RightPanel/ViewerBar/LikeLabel
@onready var _left_blood_label: Label = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/BloodRow/BloodValue
@onready var _left_ruby_label: Label = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/RubyRow/RubyValue
@onready var _owned_container: VBoxContainer = $CanvasLayer/LeftPanel/OwnedNodesContainer

var _owned_nodes: Array = [
	{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1)},
	{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9)},
	{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2)},
]
var _left_tween: Tween
var _right_tween: Tween
var _hp_tween: Tween
var _damage_tween: Tween
var _coffin_push_tween: Tween
const _coffin_base_pos: Vector2 = Vector2(920.0, 480.0)
var _left_open: bool = false
var _right_open: bool = false
var spawn_timer: float = 0.0
var spawn_interval: float = 3.0
var max_entities: int = 5
var coffin_hp: float = 100.0
var coffin_max_hp: float = 100.0
var _hp_hide_timer: float = 0.0
var _hp_visible: bool = false
var _blink_timer: float = 0.0
var _blink_state: bool = true
var _is_game_over: bool = false
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _vignette_tween: Tween
var _node_slots: Array = [
	{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1), "cost": 10},
	{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9), "cost": 15},
	{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2), "cost": 20},
	{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1), "cost": 12},
	{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9), "cost": 18},
	{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2), "cost": 22},
]
var _unlocked_slots: int = 3  # 초기 3개
var _max_slots: int = 6       # 최대 6개
const _num_node_type_slots: int = 3  # 구매 가능 노드 종류 수 (흡혈/결계/증폭) — 그 외는 빈 슬롯
var _slot_unlock_cost: int = 30  # 슬롯 해금 비용
var _hint_hiding: bool = false
var _hint_hide_tweens: Array = []
var _unlock_animation_playing: bool = false  # 해금 애니 중엔 인디케이터 숨기지 않음
var _pending_spawn_index: int = -1  # 재화 차감됐지만 아직 스폰 안된 슬롯 (중복 방지)
var _slots_in_panel: bool = false  # X키로 슬롯이 Q 패널로 회수된 상태
var _slot_data: Array = [null, null, null, null, null, null]  # 6개 인디케이터 슬롯
var _selected_nodes: Array = []
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_duration: float = 3.0  # 3초 안에 다음 처치 없으면 콤보 리셋
var _hitstop_timer: float = 0.0

# ===== 난이도 단계 (30초마다 증가) =====
# 단계 0~3   혈체(血體)   기본 핏덩어리
# 단계 4~5   기혈(寄血)   기생하는 피 - 핵이 숙주처럼 내부에 자리잡음
# 단계 6~7   숙혈(宿血)   숙주가 된 피 - 줄기가 뻗어 주변을 잠식
# 단계 8~9   침혈(侵血)   침식하는 피 - 완전히 다른 형태로 변이
# 단계 10+   혈왕(血王)   모든 혈체를 지배하는 존재
# ------------------------------------------
# 단계 0 (0~30초):  스폰간격 4.0s / 최대 4개 / HP 60  / 속도 45 / radius 27
# 단계 1 (30~60초): 스폰간격 3.65s / 최대 5개 / HP 80  / 속도 52 / radius 29
# 단계 2 (60~90초): 스폰간격 3.3s  / 최대 6개 / HP 100 / 속도 59 / radius 31
# 단계 3 (90~120s): 스폰간격 2.95s / 최대 7개 / HP 120 / 속도 66 / radius 33
# 단계 4 (120~150s): 기혈 스폰 시작
#                   스폰간격 2.6s  / 최대 8개 / HP 140 / 속도 73 / radius 35
# 단계 5 (150s+):   스폰간격 2.25s / 최대 9개 / HP 160 / 속도 80 / radius 37
# ==========================================
var _elapsed_time: float = 0.0
var _round_time: float = 120.0  # 테스트용 2분
var _remaining_time: float = 120.0
var _viewers: int = 0
var _likes: int = 0
var _viewer_timer: float = 0.0
var _like_timer: float = 0.0
var _prev_difficulty: int = 0
var _danger_chat_sent: bool = false
var _kill_count: int = 0
var _ai_chat_started: bool = false
var _state_timer: float = 0.0
var _no_hit_timer: float = 0.0
var _perfect_defense_notified: bool = false

func _ready() -> void:
	add_to_group("main")
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Main 시작")
	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2
	$EntityLayer/HeartPulse.setup(coffin_center)
	var coffin_particles: Node2D = Node2D.new()
	coffin_particles.set_script(preload("res://scripts/CoffinParticles.gd"))
	coffin_particles.setup(coffin_center)
	$EntityLayer.add_child(coffin_particles)
	$CanvasLayer/LeftPanel.modulate = Color(1, 1, 1, 0)
	$CanvasLayer/RightPanel.modulate = Color(1, 1, 1, 0)
	$CanvasLayer/LeftTab.gui_input.connect(_on_left_tab_gui_input)
	$CanvasLayer/RightTab.gui_input.connect(_on_right_tab_gui_input)
	$CanvasLayer/CoffinHPBar.modulate = Color(1, 1, 1, 0)
	_hint_popup.visible = false
	_spawn_start_nodes()
	var synergy_engine = SynergyEngine.new()
	add_child(synergy_engine)
	var chat_manager = ChatManager.new()
	add_child(chat_manager)
	var chat_log: RichTextLabel = $CanvasLayer/RightPanel/ChatBox/ScrollContainer/ChatLog as RichTextLabel
	chat_manager.setup(chat_log)
	chat_manager.send_chat("start")
	_build_hint_dots()
	_build_owned_nodes()
	$CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow.modulate = Color(1, 1, 1, 0.5)
	ResourceManager.blood_changed.connect(_on_blood_changed)
	ResourceManager.blood_changed.connect(update_blood_ui)
	ResourceManager.special_changed.connect(_on_special_changed)
	_on_blood_changed(ResourceManager.blood)
	update_blood_ui(ResourceManager.blood)
	_on_special_changed(ResourceManager.special)
	_init_viewers()
	update_ruby_ui(ResourceManager.ruby)
	var viewer_bar: Control = $CanvasLayer/RightPanel/ViewerBar
	var right_panel: Control = $CanvasLayer/RightPanel
	viewer_bar.position = Vector2(0, right_panel.size.y - 40)

func show_tooltip(info: Dictionary, node_color: Color) -> void:
	_tip_name.text = info.name
	_tip_desc.text = info.desc
	_tip_syn1.text = "◆ " + info.synergy1
	_tip_syn2.text = "◆ " + info.synergy2
	_stat_atk.text = "⚔ 공격력: " + str(info.atk)
	_stat_cd.text = "⏱ 쿨다운: " + str(info.cooldown) + "s"
	_tip_syn1.add_theme_color_override("font_color", node_color.lightened(0.3))
	_tip_syn2.add_theme_color_override("font_color", node_color.lightened(0.3))
	_tooltip.visible = true

func hide_tooltip() -> void:
	_tooltip.visible = false

func _spawn_start_nodes() -> void:
	var node_scene = preload("res://scenes/GameNode.tscn")
	var grid = $EntityLayer/HeartPulse

	var start_nodes = [
		{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1)},
		{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9)},
	]

	for i in range(start_nodes.size()):
		var data = start_nodes[i]
		var node = node_scene.instantiate()
		node.node_id = data.id
		node.node_type = data.type
		node.node_color = data.color
		node.is_starter_node = true
		# 관 좌우에 배치 (화면 정중앙과 동일한 수직선)
		var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2
		var offset_x: float = -120.0 if i == 0 else 120.0
		var pos: Vector2 = Vector2(coffin_center.x + offset_x, coffin_center.y)
		node.global_position = pos
		node._slot_position = pos
		# 그리드에 등록 + is_placed 설정 (SHIFT 시너지 연결 가능)
		var cell: Vector2i = grid.world_to_grid(pos)
		if grid.is_valid_cell(cell.x, cell.y) and grid.is_cell_empty(cell.x, cell.y):
			grid.place_node(cell.x, cell.y, node.node_id)
			node.is_placed = true
			node.grid_col = cell.x
			node.grid_row = cell.y
		$EntityLayer.add_child(node)

func _build_hint_dots() -> void:
	# 기존 자식 전부 제거
	for child in _dots_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var slot_size: int = 64
	var spacing: int = 88
	var total_width: int = 6 * spacing
	var start_x: int = (1920 - total_width) / 2

	for i in range(6):
		var slot: Panel = Panel.new()
		slot.name = "Slot%d" % i
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.size = Vector2(slot_size, slot_size)
		slot.position = Vector2(start_x + i * spacing, 18)

		# 빈 슬롯 스타일
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.0, 0.0, 0.7)
		style.set_corner_radius_all(32)
		style.border_color = Color(0.4, 0.1, 0.1, 0.6)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		slot.add_theme_stylebox_override("panel", style)
		slot.modulate.a = 0.0

		_dots_container.add_child(slot)

	# BloodCounter 유지
	var blood_counter: Label = Label.new()
	blood_counter.name = "BloodCounter"
	blood_counter.add_theme_font_size_override("font_size", 18)
	blood_counter.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4, 0.85))
	blood_counter.size = Vector2(120, 36)
	blood_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blood_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	blood_counter.position = Vector2(1920 / 2 - 60, -47)
	_dots_container.add_child(blood_counter)

	for i in range(6):
		if i < _slot_data.size() and _slot_data[i] and is_instance_valid(_slot_data[i]):
			_update_slot_visual(i, _slot_data[i])

	_setup_slot_inputs()

func _setup_slot_inputs() -> void:
	var slots = _dots_container.get_children()
	for i in range(min(6, slots.size())):
		var slot = slots[i]
		if not slot is Panel:
			continue
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx: int = i
		slot.gui_input.connect(func(ev): _on_indicator_slot_input(ev, idx))

func _on_indicator_slot_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var node = _slot_data[index] if index < _slot_data.size() else null
	if node and is_instance_valid(node):
		node.visible = true
		node.is_in_indicator = false
		node.global_position = get_viewport().get_mouse_position()
		node._drag_offset = Vector2.ZERO
		node.is_dragging = true
		_slot_data[index] = null
		_update_slot_visual(index, null)

func _highlight_slot(index: int, on: bool) -> void:
	var slots = _dots_container.get_children()
	if index >= slots.size():
		return
	var slot = slots[index]
	if not slot is Panel:
		return
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(32)
	if on:
		style.bg_color = Color(0.3, 0.1, 0.1, 0.9)
		style.border_color = Color(1.0, 0.3, 0.3, 1.0)
	else:
		var node = _slot_data[index] if index < _slot_data.size() else null
		if node and is_instance_valid(node):
			style.bg_color = Color(
				node.node_color.r * 0.2,
				node.node_color.g * 0.2,
				node.node_color.b * 0.2, 0.9)
			style.border_color = Color(
				node.node_color.r,
				node.node_color.g,
				node.node_color.b, 0.8)
		else:
			style.bg_color = Color(0.05, 0.0, 0.0, 0.7)
			style.border_color = Color(0.4, 0.1, 0.1, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	slot.add_theme_stylebox_override("panel", style)

func _get_slot_at(pos: Vector2) -> int:
	var slots = _dots_container.get_children()
	for i in range(min(6, slots.size())):
		var slot = slots[i]
		if not slot is Panel:
			continue
		var slot_rect: Rect2 = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(pos):
			return i
	return -1

func _register_to_slot(index: int, node: Node2D) -> void:
	for i in range(_slot_data.size()):
		if _slot_data[i] == node:
			_slot_data[i] = null
			_update_slot_visual(i, null)

	_slot_data[index] = node
	_update_slot_visual(index, node)

	var slots = _dots_container.get_children()
	if index < slots.size():
		var slot = slots[index]
		if slot is Control:
			node.global_position = slot.global_position + Vector2(32, 32)
			node._slot_position = node.global_position
	node.is_placed = false
	node.is_in_indicator = true
	node.visible = false  # 필드에서 안보이게 숨김
	node.is_selected = false

func _update_slot_visual(index: int, node: Node2D) -> void:
	var slots = _dots_container.get_children()
	if index >= slots.size():
		return
	var slot = slots[index]
	if not slot is Panel:
		return

	for child in slot.get_children():
		child.queue_free()

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(32)

	if node and is_instance_valid(node):
		style.bg_color = Color(
			node.node_color.r * 0.2,
			node.node_color.g * 0.2,
			node.node_color.b * 0.2, 0.9)
		style.border_color = Color(
			node.node_color.r,
			node.node_color.g,
			node.node_color.b, 0.8)

		var label: Label = Label.new()
		label.text = node.node_type
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color",
			Color(1.0, 1.0, 1.0, 0.9))
		label.size = Vector2(64, 64)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(label)
	else:
		style.bg_color = Color(0.05, 0.0, 0.0, 0.7)
		style.border_color = Color(0.4, 0.1, 0.1, 0.6)

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	slot.add_theme_stylebox_override("panel", style)

func _build_owned_nodes() -> void:
	for child in _owned_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	for data in _owned_nodes:
		var row: Button = Button.new()
		row.custom_minimum_size = Vector2(190, 52)
		row.text = ""

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(
			data.color.r * 0.2,
			data.color.g * 0.2,
			data.color.b * 0.2, 0.9)
		style.set_corner_radius_all(8)
		style.border_color = Color(
			data.color.r, data.color.g, data.color.b, 0.6)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		row.add_theme_stylebox_override("normal", style)

		var name_label: Label = Label.new()
		name_label.text = data.type
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color",
			Color(1.0, 1.0, 1.0, 0.9))
		name_label.position = Vector2(12, 8)
		row.add_child(name_label)

		var cost_label: Label = Label.new()
		match data.id:
			"absorb": cost_label.text = "🩸 10"
			"freeze": cost_label.text = "🩸 15"
			"resonate": cost_label.text = "🩸 20"
			_: cost_label.text = "🩸 0"
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color",
			Color(1.0, 0.5, 0.5, 0.8))
		cost_label.position = Vector2(12, 28)
		row.add_child(cost_label)

		row.gui_input.connect(func(ev): _on_owned_node_input(ev, data))
		_owned_container.add_child(row)

func _on_owned_node_input(event: InputEvent, data: Dictionary) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var cost: int = 10
	match data.id:
		"absorb": cost = 10
		"freeze": cost = 15
		"resonate": cost = 20

	if ResourceManager.blood < cost:
		_show_deny_popup("혈액 부족! 🩸%d 필요" % cost)
		return

	var same_count: int = 0
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.node_type == data.type:
			same_count += 1
	if same_count >= 2:
		_show_deny_popup("%s 노드는 최대 2개까지!" % data.type)
		return

	var total_nodes: int = get_tree().get_nodes_in_group("game_nodes").size()
	if total_nodes >= _unlocked_slots:
		_show_deny_popup("슬롯이 꽉 찼어요! 🔓 슬롯 해금 필요")
		return

	if not ResourceManager.spend_blood(cost):
		return

	var node_scene = preload("res://scenes/GameNode.tscn")
	var node = node_scene.instantiate()
	node.node_id = data.id
	node.node_type = data.type
	node.node_color = data.color
	node.global_position = get_viewport().get_mouse_position()
	node._slot_position = get_viewport().get_mouse_position()
	node.is_dragging = true
	node._drag_offset = Vector2.ZERO
	$EntityLayer.add_child(node)

func register_node_select(node: Node2D) -> void:
	if node in _selected_nodes:
		_selected_nodes.erase(node)
		node.is_selected = false
		_sync_connection_manager_selected()
		return

	if _selected_nodes.size() >= 3:
		var oldest = _selected_nodes[0]
		if is_instance_valid(oldest) and oldest.has_method("start_range_fade_out"):
			oldest.start_range_fade_out()
		_selected_nodes.pop_front()

	_selected_nodes.append(node)
	node.is_selected = true
	_sync_connection_manager_selected()

func clear_all_node_selection() -> void:
	for n in _selected_nodes:
		if is_instance_valid(n):
			n.is_selected = false
			if n.has_method("_cancel_range_fade"):
				n._cancel_range_fade()
	_selected_nodes.clear()
	var cm = get_tree().get_first_node_in_group("connection_manager")
	if cm and cm.has_method("clear_selected"):
		cm.clear_selected()

func _sync_connection_manager_selected() -> void:
	var cm = get_tree().get_first_node_in_group("connection_manager")
	if cm and cm.has_method("set_selected"):
		if _selected_nodes.is_empty():
			cm.clear_selected()
		else:
			cm.set_selected(_selected_nodes[-1])

func _on_empty_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_show_deny_popup("상점에서 노드를 구매해 채워넣으세요!")

func _make_slot_input_handler(index: int) -> Callable:
	return func(event: InputEvent): _on_slot_gui_input(event, index)

func _show_deny_popup(text: String) -> void:
	var old = $CanvasLayer.get_node_or_null("DenyPopup")
	if old:
		old.queue_free()

	var label: Label = Label.new()
	label.name = "DenyPopup"
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(400, 50)
	label.position = Vector2(_coffin_base_pos.x - 200, _coffin_base_pos.y - 80)
	$CanvasLayer.add_child(label)

	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", _coffin_base_pos.y - 100, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	tween.tween_property(label, "position:y", _coffin_base_pos.y - 180, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "modulate:a", 0.0, 0.15)
	tween.tween_callback(label.queue_free)

func _shake_slot(index: int) -> void:
	var slot = _dots_container.get_child(index)
	var tween: Tween = create_tween()
	var ox: float = slot.position.x
	tween.tween_property(slot, "position:x", ox + 3, 0.03)
	tween.tween_property(slot, "position:x", ox - 3, 0.03)
	tween.tween_property(slot, "position:x", ox + 3, 0.03)
	tween.tween_property(slot, "position:x", ox - 3, 0.03)
	tween.tween_property(slot, "position:x", ox, 0.03)

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	# 중복 방지: 이미 이 슬롯으로 처리 중이면 무시
	if _pending_spawn_index == index:
		get_viewport().set_input_as_handled()
		return

	if index >= _unlocked_slots:
		return

	var data = _node_slots[index]

	# 재화 부족
	if ResourceManager.blood < data.cost:
		_shake_slot(index)
		_show_deny_popup("혈액 부족! 🩸%d 필요" % data.cost)
		return

	# 종류별 중복 체크
	var same_type_count: int = 0
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.node_type == data.type:
			same_type_count += 1
	if same_type_count >= 2:
		_shake_slot(index)
		_show_deny_popup("%s 노드는 최대 2개까지!" % data.type)
		return

	# 총 노드 수 초과
	var total_nodes: int = get_tree().get_nodes_in_group("game_nodes").size()
	if total_nodes >= _unlocked_slots:
		_shake_slot(index)
		_show_deny_popup("슬롯이 꽉 찼어요! 🔓 슬롯 해금 필요")
		return

	# 재화 차감 (1번만)
	_pending_spawn_index = index
	ResourceManager.spend_blood(data.cost)

	# 노드 스폰 + 드래그 시작
	var node_scene = preload("res://scenes/GameNode.tscn")
	var node = node_scene.instantiate()
	node.node_id = data.id
	node.node_type = data.type
	node.node_color = data.color
	node.global_position = get_viewport().get_mouse_position()
	node._slot_position = get_viewport().get_mouse_position()
	node.is_dragging = true
	node._drag_offset = Vector2.ZERO
	$EntityLayer.add_child(node)

	call_deferred("_clear_pending_spawn")  # 프레임 끝에 초기화 (중복 이벤트 방지)
	get_viewport().set_input_as_handled()

func _clear_pending_spawn() -> void:
	_pending_spawn_index = -1

func _on_unlock_slot_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	get_viewport().set_input_as_handled()
	_unlock_next_slot()

func _unlock_next_slot() -> void:
	if ResourceManager.blood < _slot_unlock_cost:
		var slot = _dots_container.get_child(_unlocked_slots)
		var ox: float = slot.position.x
		var tween: Tween = create_tween()
		tween.tween_property(slot, "position:x", ox + 3, 0.03)
		tween.tween_property(slot, "position:x", ox - 3, 0.03)
		tween.tween_property(slot, "position:x", ox + 3, 0.03)
		tween.tween_property(slot, "position:x", ox - 3, 0.03)
		tween.tween_property(slot, "position:x", ox, 0.03)
		return

	ResourceManager.spend_blood(_slot_unlock_cost)
	_unlocked_slots += 1
	_slot_unlock_cost = int(_slot_unlock_cost * 1.5)

	_hint_hiding = false
	for t in _hint_hide_tweens:
		if t and is_instance_valid(t):
			t.kill()
	_hint_hide_tweens.clear()
	await _build_hint_dots()

	# 해금 애니메이션 동안 인디케이터 숨기지 않음
	_unlock_animation_playing = true

	# 해금 이펙트
	var new_slot = _dots_container.get_child(_unlocked_slots - 1)

	# 1. 시작: 작게 + 투명
	new_slot.scale = Vector2(0.3, 0.3)
	new_slot.modulate.a = 0.0
	new_slot.pivot_offset = Vector2(32, 32)

	# 2. 펑 하고 커졌다가 제자리
	var tween: Tween = create_tween()
	tween.tween_property(new_slot, "scale", Vector2(1.3, 1.3), 0.2
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(new_slot, "modulate:a", 1.0, 0.15)
	tween.tween_property(new_slot, "scale", Vector2(1.0, 1.0), 0.15
		).set_ease(Tween.EASE_IN_OUT)

	# 3. 슬롯 해금 이펙트
	# 스크립트 먼저 설정 후 위치 지정해야 함
	# HintArea가 화면 y:950 근처에 있고
	# DotsContainer 안 슬롯 position 기준으로 계산
	var slot_idx: int = _unlocked_slots - 1
	var slot = _dots_container.get_children()[slot_idx]

	# 슬롯의 실제 화면 좌표 계산
	# DotsContainer는 HintArea 안에 있음
	# HintArea position + slot position + 슬롯 중앙 offset
	var hint_area_y: float = _hint_area.position.y
	var slot_x: float = slot.position.x + slot.size.x / 2
	var slot_y: float = hint_area_y + slot.position.y + slot.size.y / 2

	var ring_effect: Node2D = Node2D.new()
	ring_effect.set_script(preload("res://scripts/SlotUnlockEffect.gd"))
	ring_effect.global_position = Vector2(slot_x, slot_y)
	$EntityLayer.add_child(ring_effect)  # add_child는 마지막에

	# SlotUnlockEffect 페이드아웃(~3초) 끝날 때까지 대기 후 플래그 해제
	await get_tree().create_timer(3.0).timeout
	_unlock_animation_playing = false

func _get_chat_manager() -> Node:
	return get_tree().get_first_node_in_group("chat_manager")

func _has_synergy_connection() -> bool:
	var cm = get_tree().get_first_node_in_group("connection_manager")
	if cm:
		return cm._connections.size() > 0
	return false

func _init_viewers() -> void:
	var base: int = 50 + ResourceManager.total_runs * 30
	_viewers = randi_range(base, base + 50)
	var like_base: int = 10 + ResourceManager.total_runs * 10
	_likes = randi_range(like_base, like_base + 20)
	var cm = _get_chat_manager()
	if cm and cm.has_method("set_idle_interval_range"):
		if _viewers < 100:
			cm.set_idle_interval_range(4.0, 7.0)
		elif _viewers < 300:
			cm.set_idle_interval_range(2.5, 5.0)
		else:
			cm.set_idle_interval_range(1.5, 3.0)
	_update_viewer_ui()

func update_ruby_ui(amount: int) -> void:
	if _left_ruby_label:
		_left_ruby_label.text = str(amount)

func _show_ruby_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(860, 160)
	$CanvasLayer.add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", 140.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)

func _update_viewer_ui() -> void:
	if _viewers > ResourceManager.best_viewers:
		ResourceManager.best_viewers = _viewers
	if _viewer_label:
		_viewer_label.text = "👁 %d" % _viewers
	if _like_label:
		_like_label.text = "❤ %d" % _likes

func on_difficulty_up() -> void:
	_viewers += randi_range(20, 80)
	_likes += randi_range(5, 20)
	_update_viewer_ui()
	var cm = _get_chat_manager()
	if cm:
		cm.send_chat("danger")

func _get_hovered_game_node():
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.is_hovered:
			return n
	return null

func on_entity_killed() -> void:
	_combo_count += 1
	_combo_timer = _combo_duration
	_kill_count += 1

	var cm = _get_chat_manager()
	if cm:
		if _combo_count >= 3:
			cm.send_chat("combo")
		elif _combo_count >= 1:
			cm.send_chat("kill")
	if _combo_count >= 3:
		_likes += randi_range(3, 10)
		_update_viewer_ui()
	if _combo_count == 5:
		ResourceManager.add_ruby(1)
		_show_ruby_popup("5콤보 달성! 🔴+1")

	# 콤보 배수 계산
	var multiplier: float = 1.0
	if _combo_count >= 5:
		multiplier = 2.0
	elif _combo_count >= 3:
		multiplier = 1.5

	# 콤보 텍스트 표시
	if _combo_count >= 3:
		_show_combo_popup(_combo_count, multiplier)

func reset_combo() -> void:
	_combo_count = 0
	_combo_timer = 0.0

func trigger_hitstop(duration: float = 0.06) -> void:
	_hitstop_timer = duration

func _show_combo_popup(count: int, multiplier: float) -> void:
	var label: Label = Label.new()
	if count >= 5:
		label.text = "%d KILL  x%.0f 재화!" % [count, multiplier]
		label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0, 1.0))
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.text = "%d KILL  x%.1f" % [count, multiplier]
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
		label.add_theme_font_size_override("font_size", 22)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(300, 50)
	label.position = Vector2(810, 210)  # 시너지 팝업(50-120) 아래에 배치
	$CanvasLayer.add_child(label)

	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", 190.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)

func _process(delta: float) -> void:
	if _hitstop_timer > 0:
		_hitstop_timer -= delta / Engine.time_scale  # 실제 시간 기준 감소
		Engine.time_scale = 0.05
		return
	else:
		Engine.time_scale = 1.0

	if _is_game_over:
		_apply_shake(delta)
		return
	if _combo_count > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_combo_count = 0
	_elapsed_time += delta
	_remaining_time -= delta
	var difficulty: int = int(_elapsed_time / 30.0)
	spawn_interval = max(1.5, 4.0 - difficulty * 0.35)
	max_entities = min(10, 4 + difficulty)
	if ResourceManager:
		ResourceManager.difficulty = difficulty
	if difficulty != _prev_difficulty:
		_prev_difficulty = difficulty
		on_difficulty_up()

	_viewer_timer += delta
	_like_timer += delta
	if _viewer_timer >= 5.0:
		_viewer_timer = 0.0
		var change: int = randi_range(-5, 15)
		_viewers = max(1, _viewers + change)
		_update_viewer_ui()
	if _like_timer >= 8.0:
		_like_timer = 0.0
		var like_change: int = randi_range(0, 5)
		_likes += like_change
		_update_viewer_ui()

	var hp_ratio: float = coffin_hp / coffin_max_hp
	if hp_ratio <= 0.1 and not _danger_chat_sent:
		_danger_chat_sent = true
		var cm = _get_chat_manager()
		if cm:
			cm.send_chat("danger")
	elif hp_ratio > 0.1:
		_danger_chat_sent = false

	if coffin_hp >= coffin_max_hp:
		_no_hit_timer += delta
		if _no_hit_timer >= 30.0 and not _perfect_defense_notified:
			_perfect_defense_notified = true
			_no_hit_timer = 0.0
			ResourceManager.add_ruby(1)
			_show_ruby_popup("퍼펙트 디펜스! 🔴+1")
	else:
		_no_hit_timer = 0.0
		_perfect_defense_notified = false

	if _elapsed_time >= 20.0 and not _ai_chat_started:
		_ai_chat_started = true
		var cm = _get_chat_manager()
		if cm:
			cm._ai_chat_enabled = true

	_state_timer += delta
	if _state_timer >= 2.0:
		_state_timer = 0.0
		var cm = _get_chat_manager()
		if cm:
			cm.update_game_state({
				"hp_ratio": coffin_hp / coffin_max_hp,
				"difficulty": difficulty,
				"blood": ResourceManager.blood,
				"placed_nodes": get_tree().get_nodes_in_group("game_nodes").size(),
				"connected": _has_synergy_connection(),
				"combo": _combo_count,
				"time_left": _remaining_time
			})

	var minutes: int = int(_remaining_time) / 60
	var seconds: int = int(_remaining_time) % 60
	_timer_label.text = "%02d:%02d" % [minutes, seconds]

	# 30초 이하 빨갛게 깜빡임
	if _remaining_time <= 30.0:
		var blink: float = abs(sin(_elapsed_time * 4.0))
		_timer_label.add_theme_color_override("font_color",
			Color(1.0, blink * 0.3, blink * 0.3, 1.0))
	else:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

	# 시간 종료
	if _remaining_time <= 0.0:
		_remaining_time = 0.0
		_timer_label.text = "00:00"
		_escape_success()

	_blink_timer += delta
	if _blink_timer >= 0.8:
		_blink_timer = 0.0
		_blink_state = !_blink_state
		_live_dot.modulate.a = 1.0 if _blink_state else 0.2
	if coffin_hp >= 45:
		_live_dot.add_theme_color_override("font_color", Color(0, 1, 0.267, 1))
	elif coffin_hp >= 13:
		_live_dot.add_theme_color_override("font_color", Color(1, 1, 0, 1))
	else:
		_live_dot.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if get_tree().get_nodes_in_group("blood_entities").size() < max_entities:
			_spawn_blood_entity()

	_check_coffin_collision()
	_update_coffin_visual()

	if _hp_visible:
		_hp_hide_timer -= delta
		if _hp_hide_timer <= 0.0:
			_hp_visible = false
			_fade_hp_bar(false)

	var my: float = get_viewport().get_mouse_position().y
	if _slots_in_panel:
		pass  # 슬롯이 Q 패널에 있으면 하단 바 표시 안 함
	elif my > 820:
		# 숨기기 진행 중에 마우스 다시 내리면 즉시 취소 후 표시
		if _hint_hiding:
			_hint_hiding = false
			for t in _hint_hide_tweens:
				if t and is_instance_valid(t):
					t.kill()
			_hint_hide_tweens.clear()
			var dots: Array = _dots_container.get_children()
			for dot in dots:
				if dot.name == "BloodBG" or dot.name == "BloodCounter":
					dot.modulate = Color(1, 1, 1, 1)
				else:
					dot.position = Vector2(dot.position.x, 30.0)
					dot.modulate = Color(1, 1, 1, 1)
			_hint_area.position = Vector2(_hint_area.position.x, 950.0)
		elif not _hint_area.visible:
			_hint_area.visible = true
			_hint_area.modulate = Color(1, 1, 1, 1)
			_hint_area.position = Vector2(_hint_area.position.x, 1020.0)

			var area_tween: Tween = _hint_area.create_tween()
			area_tween.tween_property(_hint_area, "position:y", 950.0, 0.35
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

			var dots: Array = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				if dot.name == "BloodBG" or dot.name == "BloodCounter":
					dot.modulate = Color(1, 1, 1, 0)
					var tween: Tween = dot.create_tween()
					tween.tween_interval(0.1)
					tween.tween_property(dot, "modulate", Color(1, 1, 1, 1), 0.2)
					continue
				dot.position = Vector2(dot.position.x, 70.0)
				dot.modulate = Color(1, 1, 1, 0)

				var tween: Tween = dot.create_tween()
				tween.tween_interval(i * 0.07)
				tween.tween_property(dot, "position:y", 30.0, 0.35
				).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				tween.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 1), 0.25)
	else:
		if not _slots_in_panel and _hint_area.visible and not _hint_hiding and not _unlock_animation_playing:
			_hint_hiding = true
			_hint_hide_tweens.clear()
			var area_tween: Tween = _hint_area.create_tween()
			_hint_hide_tweens.append(area_tween)
			area_tween.tween_property(_hint_area, "position:y", 1020.0, 0.25
			).set_ease(Tween.EASE_IN)

			var dots: Array = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				if dot.name == "BloodBG" or dot.name == "BloodCounter":
					var tween: Tween = dot.create_tween()
					_hint_hide_tweens.append(tween)
					tween.tween_interval(0.12)
					tween.tween_property(dot, "modulate", Color(1, 1, 1, 0), 0.22)
					continue
				var tween: Tween = dot.create_tween()
				_hint_hide_tweens.append(tween)
				tween.tween_interval(i * 0.05)
				tween.tween_property(dot, "position:y", 70.0, 0.25
				).set_ease(Tween.EASE_IN)
				tween.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 0), 0.2)

			var hide_delay: float = dots.size() * 0.05 + 0.25
			get_tree().create_timer(hide_delay).timeout.connect(func():
				if _hint_hiding:
					_hint_area.visible = false
					_hint_hiding = false
					_hint_hide_tweens.clear()
			)

	# 재화 표시 업데이트
	var blood_counter = _dots_container.get_node_or_null("BloodCounter")
	if blood_counter and _hint_area.visible:
		blood_counter.text = "🩸 %d" % ResourceManager.blood

	# 드래그 중인 노드가 인디케이터 슬롯 위에 있는지 감지
	var dragging_node: Node2D = null
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.is_dragging:
			dragging_node = n
			break

	if dragging_node and not dragging_node.is_placed:
		var mouse_y: float = get_viewport().get_mouse_position().y
		if mouse_y > 880:
			var slots = _dots_container.get_children()
			for i in range(min(6, slots.size())):
				var slot = slots[i]
				if not slot is Panel:
					continue
				var slot_rect: Rect2 = Rect2(slot.global_position, slot.size)
				if slot_rect.has_point(get_viewport().get_mouse_position()):
					_highlight_slot(i, true)
				else:
					_highlight_slot(i, false)
		else:
			for i in range(6):
				_highlight_slot(i, false)
	else:
		for i in range(6):
			_highlight_slot(i, false)

	# 필드에 배치된 노드만 툴팁 표시
	var hovered_node = _get_hovered_game_node()
	if hovered_node and hovered_node.is_placed:
		show_tooltip(hovered_node._get_node_info(), hovered_node.node_color)
	else:
		hide_tooltip()

	_apply_shake(delta)

func _spawn_blood_entity() -> void:
	var difficulty: int = int(_elapsed_time / 30.0)
	ResourceManager.difficulty = difficulty

	var entity: Node2D
	if difficulty >= 4:
		var stage4_scene = preload("res://scenes/BloodEntityStage4.tscn")
		entity = stage4_scene.instantiate()
		entity._is_evolved = true
		entity._difficulty = difficulty
	else:
		entity = blood_entity_scene.instantiate()

	entity.add_to_group("blood_entities")
	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2

	var side: int = randi() % 4
	var pos: Vector2
	match side:
		0: pos = Vector2(randf_range(0, 1920), -50)
		1: pos = Vector2(randf_range(0, 1920), 1130)
		2: pos = Vector2(-50, randf_range(0, 1080))
		3: pos = Vector2(1970, randf_range(0, 1080))

	entity.global_position = pos
	entity.target = coffin_center
	entity.radius = 27.0 + difficulty * 2.0
	entity.max_hp = 60.0 + difficulty * 20.0
	entity.hp = entity.max_hp
	entity.speed = 45.0 + difficulty * 7.0
	if entity.get("_damage_bar_ratio") != null:
		entity._damage_bar_ratio = 1.0

	if entity.has_method("_generate_points"):
		entity._generate_points()
	elif entity.has_method("_generate_tendrils"):
		entity._generate_tendrils()

	$EntityLayer.add_child(entity)

func _update_coffin_visual() -> void:
	var ratio: float = coffin_hp / coffin_max_hp

	if ratio > 0.7:
		_coffin_rect.color = Color(1.0, 1.0, 1.0, 1.0)
	elif ratio > 0.4:
		_coffin_rect.color = Color(1.0, 0.7, 0.7, 1.0)
	elif ratio > 0.1:
		# 위급 - 빨강 + 점멸
		var pulse: float = (sin(_elapsed_time * 12.0) + 1.0) * 0.5
		var bright: float = lerp(0.4, 1.0, pulse)
		_coffin_rect.color = Color(1.0, 0.3 * bright, 0.3 * bright, 1.0)
	else:
		# 사망 직전 - 강한 빨강 + 빠른 점멸
		var pulse2: float = (sin(_elapsed_time * 20.0) + 1.0) * 0.5
		var bright2: float = lerp(0.3, 1.0, pulse2)
		_coffin_rect.color = Color(1.0, 0.1 * bright2, 0.1 * bright2, 1.0)

func _check_coffin_collision() -> void:
	var coffin_rect: Rect2 = Rect2(_coffin_rect.position, _coffin_rect.size)
	for entity in get_tree().get_nodes_in_group("blood_entities"):
		var r: float = entity.radius if "radius" in entity else 30.0
		var expanded: Rect2 = Rect2(
			coffin_rect.position - Vector2(r, r),
			coffin_rect.size + Vector2(r * 2, r * 2)
		)
		if expanded.has_point(entity.global_position):
			var hit_pos: Vector2 = entity.global_position
			entity.remove_from_group("blood_entities")
			entity.queue_free()
			coffin_hp -= 10.0
			coffin_hp = max(coffin_hp, 0.0)
			reset_combo()
			trigger_hitstop(0.1)  # 관 타격 시 더 강한 히트스탑
			var cm = _get_chat_manager()
			if cm:
				cm.send_chat("hit")
			_viewers += randi_range(1, 8)
			_likes += randi_range(0, 3)
			_update_viewer_ui()
			_trigger_shake()
			_trigger_vignette()
			_trigger_shockwave(hit_pos)
			_trigger_coffin_push(hit_pos)
			_show_hp_bar()
			if coffin_hp <= 0.0:
				_game_over()

func _show_hp_bar(from_damage: bool = true) -> void:
	var hp_fill = $CanvasLayer/CoffinHPBar/HPFill
	var damage_bar = $CanvasLayer/CoffinHPBar/DamageBar
	var label = $CanvasLayer/CoffinHPBar/HPBarLabel

	var ratio: float = coffin_hp / coffin_max_hp

	hp_fill.offset_right = 1200.0 * ratio
	label.text = "HP %d / %d" % [int(coffin_hp), int(coffin_max_hp)]

	if from_damage:
		damage_bar.modulate = Color(1, 1, 1, 1)
		var damage_ratio: float = (coffin_hp + 10.0) / coffin_max_hp
		damage_bar.offset_right = 1200.0 * damage_ratio
		if _damage_tween:
			_damage_tween.kill()
		_damage_tween = create_tween()
		_damage_tween.tween_interval(0.25)
		_damage_tween.tween_property(
			damage_bar, "offset_right", 1200.0 * ratio, 0.85
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	else:
		if _damage_tween:
			_damage_tween.kill()
		damage_bar.offset_right = 1200.0 * ratio
		damage_bar.modulate = Color(1, 1, 1, 0)

	_fade_hp_bar(true)
	_hp_visible = true
	_hp_hide_timer = 2.8

func _apply_shake(delta: float) -> void:
	if _shake_duration > 0:
		_shake_duration -= delta
		_shake_offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		$EntityLayer.position = _shake_offset
	else:
		_shake_offset = Vector2.ZERO
		$EntityLayer.position = Vector2.ZERO

func heal_coffin(amount: float) -> void:
	if coffin_hp >= coffin_max_hp:
		return
	var actual: float = min(amount, coffin_max_hp - coffin_hp)
	var old_ratio: float = coffin_hp / coffin_max_hp
	coffin_hp += actual
	var new_ratio: float = coffin_hp / coffin_max_hp

	_show_hp_bar(false)

	var heal_bar: ColorRect = $CanvasLayer/CoffinHPBar/HealBar
	heal_bar.offset_left = 1200.0 * old_ratio
	heal_bar.offset_right = 1200.0 * old_ratio
	heal_bar.modulate = Color(1, 1, 1, 1)

	var heal_tween: Tween = create_tween()
	heal_tween.tween_property(
		heal_bar, "offset_right", 1200.0 * new_ratio, 0.35
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	heal_tween.tween_property(heal_bar, "modulate", Color(1, 1, 1, 0), 0.25).set_ease(Tween.EASE_IN)
	heal_tween.tween_callback(func():
		heal_bar.offset_left = 0.0
		heal_bar.offset_right = 0.0
	)

	var tween: Tween = create_tween()
	tween.tween_property(_coffin_rect, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(_coffin_rect, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_IN)

func _trigger_coffin_push(hit_pos: Vector2) -> void:
	var coffin_center: Vector2 = _coffin_rect.global_position + _coffin_rect.size / 2
	var push_dir: Vector2 = (coffin_center - hit_pos).normalized()
	if push_dir.is_zero_approx():
		push_dir = Vector2.RIGHT
	var push_amount: float = 14.0
	var pushed_pos: Vector2 = _coffin_base_pos + push_dir * push_amount

	if _coffin_push_tween:
		_coffin_push_tween.kill()
	_coffin_push_tween = create_tween()
	_coffin_push_tween.tween_property(_coffin_rect, "position", pushed_pos, 0.04).set_ease(Tween.EASE_OUT)
	_coffin_push_tween.tween_property(_coffin_rect, "position", _coffin_base_pos, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _trigger_shake() -> void:
	var hp_ratio: float = coffin_hp / coffin_max_hp
	_shake_intensity = lerp(4.0, 12.0, 1.0 - hp_ratio)
	_shake_duration = 0.3

func _trigger_vignette() -> void:
	if _vignette_tween:
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.tween_property(_vignette, "modulate", Color(1, 1, 1, 0.7), 0.05).set_ease(Tween.EASE_OUT)
	_vignette_tween.tween_property(_vignette, "modulate", Color(1, 1, 1, 0), 0.4).set_ease(Tween.EASE_IN)

func _trigger_shockwave(hit_pos: Vector2) -> void:
	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2

	for i in range(12):
		var shard: Node2D = Node2D.new()
		shard.set_script(preload("res://scripts/ShockwaveShardEffect.gd"))
		var base_angle: float = (hit_pos - coffin_center).angle()
		var spread: float = randf_range(-PI * 0.25, PI * 0.25)
		var angle: float = base_angle + spread
		var speed: float = randf_range(500.0, 850.0)
		var size: float = randf_range(4.0, 12.0)
		shard.set("_vel", Vector2(cos(angle), sin(angle)) * speed)
		shard.set("_size", size)
		shard.set("_origin", hit_pos)
		shard.set("_spread_sign", 1.0 if spread >= 0 else -1.0)
		$EntityLayer.add_child(shard)
		shard.global_position = hit_pos

	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1.0, 0.3, 0.3, 0.5)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.set_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(flash)
	var tween: Tween = create_tween()
	tween.tween_property(flash, "color", Color(1.0, 0.3, 0.3, 0.0), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func _fade_hp_bar(show: bool) -> void:
	if _hp_tween:
		_hp_tween.kill()
	if not show:
		$CanvasLayer/CoffinHPBar/DamageBar.modulate = Color(1, 1, 1, 0)
	_hp_tween = create_tween()
	var target_alpha: float = 0.85 if show else 0.0
	_hp_tween.tween_property(
		$CanvasLayer/CoffinHPBar, "modulate", Color(1, 1, 1, target_alpha), 0.3
	).set_ease(Tween.EASE_OUT)

func _game_over() -> void:
	Engine.time_scale = 1.0
	_is_game_over = true
	var cm = _get_chat_manager()
	if cm:
		cm.send_chat("gameover")
	_live_dot.modulate.a = 1.0
	_live_dot.add_theme_color_override("font_color", Color(0.8, 0.0, 0.0, 1.0))
	get_tree().paused = true

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.05, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$CanvasLayer.add_child(overlay)

	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.05, 0.0, 0.0, 0.85), 1.0).set_ease(Tween.EASE_OUT)

	await tween.finished

	var shader_mat: ShaderMaterial = ShaderMaterial.new()
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 col = textureLod(screen_texture, SCREEN_UV, 0.0);
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(col.rgb, vec3(gray), amount), col.a);
}
"""
	shader_mat.shader = shader

	var bw_overlay: ColorRect = ColorRect.new()
	bw_overlay.color = Color(1, 1, 1, 1)
	bw_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bw_overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	bw_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bw_overlay.material = shader_mat
	$CanvasLayer.add_child(bw_overlay)

	var tween_bw: Tween = create_tween()
	tween_bw.tween_method(
		func(v: float): shader_mat.set_shader_parameter("amount", v),
		0.0, 1.0, 1.5
	).set_ease(Tween.EASE_OUT)

	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2

	var label1: Label = Label.new()
	label1.text = "...아직은 아니야"
	label1.add_theme_font_size_override("font_size", 36)
	label1.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.0))
	label1.position = coffin_center + Vector2(-120, -80)
	$CanvasLayer.add_child(label1)

	var tween2: Tween = create_tween()
	tween2.tween_property(label1, "theme_override_colors/font_color", Color(0.8, 0.8, 0.8, 1.0), 0.8)
	await tween2.finished
	await get_tree().create_timer(1.2).timeout

	var label2: Label = Label.new()
	label2.text = "GAME OVER"
	label2.add_theme_font_size_override("font_size", 72)
	label2.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1, 0.0))
	label2.position = coffin_center + Vector2(-240, -30)
	$CanvasLayer.add_child(label2)

	var tween3: Tween = create_tween()
	tween3.tween_property(label2, "theme_override_colors/font_color", Color(1.0, 0.1, 0.1, 1.0), 0.6)
	await tween3.finished
	await get_tree().create_timer(1.5).timeout

	var label3: Label = Label.new()
	label3.text = "[ R ] 재시작"
	label3.add_theme_font_size_override("font_size", 20)
	label3.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	label3.position = coffin_center + Vector2(-60, 60)
	$CanvasLayer.add_child(label3)

func _escape_success() -> void:
	Engine.time_scale = 1.0
	_is_game_over = true
	var cm = _get_chat_manager()
	if cm:
		cm.send_chat("clear")
	_viewers += randi_range(100, 300)
	_likes += randi_range(50, 150)
	_update_viewer_ui()
	ResourceManager.add_ruby(3)
	_show_ruby_popup("클리어 보상! 🔴+3")
	get_tree().paused = true

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.05, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$CanvasLayer.add_child(overlay)

	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.0, 0.0, 0.05, 0.85), 1.2)
	await tween.finished

	var label1: Label = Label.new()
	label1.text = "탈출 성공"
	label1.add_theme_font_size_override("font_size", 28)
	label1.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0, 1.0))
	label1.set_anchors_preset(Control.PRESET_CENTER)
	label1.offset_top = -80
	label1.offset_left = -100
	$CanvasLayer.add_child(label1)

	await get_tree().create_timer(0.8).timeout

	var label2: Label = Label.new()
	label2.text = "획득 재화: 🩸 %d" % ResourceManager.blood
	label2.add_theme_font_size_override("font_size", 24)
	label2.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8, 1.0))
	label2.set_anchors_preset(Control.PRESET_CENTER)
	label2.offset_top = -30
	label2.offset_left = -120
	$CanvasLayer.add_child(label2)

	await get_tree().create_timer(0.8).timeout

	var label3: Label = Label.new()
	label3.text = "생존 시간: %d초" % int(_elapsed_time)
	label3.add_theme_font_size_override("font_size", 20)
	label3.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	label3.set_anchors_preset(Control.PRESET_CENTER)
	label3.offset_top = 10
	label3.offset_left = -100
	$CanvasLayer.add_child(label3)

	await get_tree().create_timer(1.0).timeout

	var label4: Label = Label.new()
	label4.text = "[ R ] 다시 도전"
	label4.add_theme_font_size_override("font_size", 18)
	label4.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	label4.set_anchors_preset(Control.PRESET_CENTER)
	label4.offset_top = 60
	label4.offset_left = -80
	$CanvasLayer.add_child(label4)

func _input(event: InputEvent) -> void:
	# 관( coffin ) 클릭: 루비 1개 소비 → HP +25
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not _is_game_over:
		var coffin_rect2: Rect2 = Rect2(_coffin_rect.global_position, _coffin_rect.size)
		if coffin_rect2.has_point(get_viewport().get_mouse_position()):
			if ResourceManager.spend_ruby(1):
				heal_coffin(25.0)
				_show_ruby_popup("💊 HP +25")
			else:
				_show_ruby_popup("루비 부족! 🔴")
			get_viewport().set_input_as_handled()
			return

	# 우클릭: 시너지 연결 대기 중이면 취소, 아니면 노드 제거 (_input에서 처리해 GUI보다 먼저)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var cm = get_tree().get_first_node_in_group("connection_manager")
		if cm and cm._pending != null:
			# 시너지 연결 취소
			cm._pending.is_pending_connection = false
			cm._pending._is_first_selected = false
			cm._clear_highlights()
			cm._pending = null
			cm.queue_redraw()
			get_viewport().set_input_as_handled()
			return
		# 연결 대기 중 아닐 때 노드 제거
		var clicked_node = _get_hovered_game_node()
		if clicked_node:
			clicked_node.on_right_click()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if _left_open:
				_slide_left_close()
			else:
				_slide_left_open()
			_left_open = !_left_open

		if event.keycode == KEY_E:
			if _right_open:
				_slide_right_close()
			else:
				_slide_right_open()
			_right_open = !_right_open

		if event.keycode == KEY_R and _is_game_over:
			ResourceManager.total_runs += 1
			ResourceManager.total_kills += _kill_count
			Engine.time_scale = 1.0
			get_tree().paused = false
			get_tree().reload_current_scene()

		if event.keycode == KEY_X and event.pressed:
			_recall_slots_to_panel()

func _recall_slots_to_panel() -> void:
	if _slots_in_panel:
		_show_deny_popup("이미 Q 패널에 있습니다 [X]")
		return

	var card = $CanvasLayer/LeftPanel.get_node_or_null("RecalledSlotsHolder")
	if not card:
		_show_deny_popup("보유 노드 카드 없음")
		return

	# SlotsGrid 컨테이너 준비
	var grid = card.get_node_or_null("SlotsGrid")
	if not grid:
		grid = GridContainer.new()
		grid.name = "SlotsGrid"
		grid.columns = 3
		grid.position = Vector2(12, 40)
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		card.add_child(grid)

	# _dots_container에서 슬롯만 추출 (BloodBG, BloodCounter 제외)
	var slot_controls: Array[Control] = []
	for child in _dots_container.get_children():
		if child.name == "BloodBG" or child.name == "BloodCounter":
			continue
		if child is Control:
			slot_controls.append(child)

	for i in range(slot_controls.size()):
		var slot: Control = slot_controls[i]
		slot.reparent(grid)
		slot.position = Vector2.ZERO
		slot.size = Vector2(58, 58)
		slot.custom_minimum_size = Vector2(58, 58)

	_hint_area.visible = false
	_hint_hiding = false
	_hint_hide_tweens.clear()
	_slots_in_panel = true

	if not _left_open:
		_slide_left_open()
		_left_open = true

	_show_deny_popup("슬롯을 Q 패널로 이동 [X]")

func _on_left_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_left_tab_clicked()

func _on_right_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_right_tab_clicked()

func _on_left_tab_clicked() -> void:
	if _left_open:
		_slide_left_close()
	else:
		_slide_left_open()
	_left_open = !_left_open

func _on_right_tab_clicked() -> void:
	if _right_open:
		_slide_right_close()
	else:
		_slide_right_open()
	_right_open = !_right_open

func _slide_left_open() -> void:
	if _left_tween:
		_left_tween.kill()
	_left_tween = create_tween()
	_left_tween.set_parallel(true)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "position", Vector2(40, $CanvasLayer/LeftPanel.position.y), 0.25
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "modulate", Color(1, 1, 1, 1), 0.25
	).set_ease(Tween.EASE_OUT)

func _slide_left_close() -> void:
	if _left_tween:
		_left_tween.kill()
	_left_tween = create_tween()
	_left_tween.set_parallel(true)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "position", Vector2(-220, $CanvasLayer/LeftPanel.position.y), 0.25
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "modulate", Color(1, 1, 1, 0), 0.25
	).set_ease(Tween.EASE_IN)

func _slide_right_open() -> void:
	if _right_tween:
		_right_tween.kill()
	_right_tween = create_tween()
	_right_tween.set_parallel(true)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "position", Vector2(1640, $CanvasLayer/RightPanel.position.y), 0.25
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "modulate", Color(1, 1, 1, 1), 0.25
	).set_ease(Tween.EASE_OUT)

func _on_blood_changed(new_value: int) -> void:
	if _left_blood_label:
		_left_blood_label.text = str(new_value)

func _on_special_changed(new_value: float) -> void:
	var chip_value: Label = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow/ChipValue
	if chip_value:
		chip_value.text = str(int(new_value))
	var row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow
	row.modulate = Color(1, 1, 1, 0.5 if new_value <= 0 else 1.0)

func update_blood_ui(amount: float) -> void:
	_blood_label.text = "🩸 " + str(int(amount))
	if _left_blood_label:
		_left_blood_label.text = str(int(amount))


func _slide_right_close() -> void:
	if _right_tween:
		_right_tween.kill()
	_right_tween = create_tween()
	_right_tween.set_parallel(true)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "position", Vector2(1920, $CanvasLayer/RightPanel.position.y), 0.25
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "modulate", Color(1, 1, 1, 0), 0.25
	).set_ease(Tween.EASE_IN)
