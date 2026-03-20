extends Control

const SLOT_UNLOCK_COSTS: Array = [2, 3, 4, 5]  # 루비 비용 (슬롯 3~6)
const DEFAULT_TRAIT_SLOTS: int = 2
const MAX_TRAIT_SLOTS: int = 6
const QUICK_SLOT_COUNT: int = 6

var _unlocked_trait_slots: int = DEFAULT_TRAIT_SLOTS
var _quick_slot_data: Array = []  # [node_id or ""] 6개
var _owned_nodes: Array = []  # 보유 노드 목록 (BattleReady용 샘플)

func _ready() -> void:
	_build_owned_nodes_sample()
	_build_ui()

func _build_owned_nodes_sample() -> void:
	# Main.gd _owned_nodes 형식 참고 (실제로는 저장 데이터에서 로드)
	_owned_nodes = [
		{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1), "grade": 0},
		{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9), "grade": 0},
		{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2), "grade": 1},
		{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1), "grade": 2},
	]
	# TODO: 실제 배포 전 반드시 제거할 것 — 테스트용 빈 노드 40개
	for i in range(40):
		var dummy = {
			"id": "empty_%d" % i,
			"type": "빈 노드",
			"color": Color(0.3, 0.3, 0.3),
			"cost": 0
		}
		_owned_nodes.append(dummy)
	for i in QUICK_SLOT_COUNT:
		_quick_slot_data.append("")

func _clear_ui() -> void:
	for c in get_children():
		if c.name == "NodeGridController":
			continue
		remove_child(c)
		c.queue_free()

func _build_ui() -> void:
	_clear_ui()
	# 배경: 전체 #0D0008 + 중앙 방사형 그라디언트
	var bg_base = ColorRect.new()
	bg_base.color = ThemeColors.BG_BASE
	bg_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_base.set_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_base)

	var grad = ColorRect.new()
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad.set_offsets_preset(Control.PRESET_FULL_RECT)
	grad.size = Vector2(1920, 1080)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/radial_gradient_bg.gdshader") as Shader
	mat.set_shader_parameter("center_color", ThemeColors.BG_CENTER)
	mat.set_shader_parameter("outer_color", ThemeColors.BG_BASE)
	grad.material = mat
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grad)

	# VignetteOverlay (map_vignette 재활용)
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.set_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.size = Vector2(1920, 1080)
	vignette.color = Color(0, 0, 0, 0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vmat = ShaderMaterial.new()
	vmat.shader = load("res://shaders/map_vignette.gdshader") as Shader
	vmat.set_shader_parameter("viewport_size", Vector2(1920, 1080))
	vmat.set_shader_parameter("darken_strength", 0.35)
	vignette.material = vmat
	add_child(vignette)

	# 좌측 패널 (768px)
	const LEFT_PANEL_W := 768
	var left_panel = ColorRect.new()
	left_panel.color = ThemeColors.BG_PANEL
	left_panel.position = Vector2(0, 0)
	left_panel.size = Vector2(LEFT_PANEL_W, 1080)
	add_child(left_panel)

	# 특성 슬롯 (y:60, x:280 벨미르 플레이스홀더 우측 정렬)
	var trait_vbox = VBoxContainer.new()
	trait_vbox.position = Vector2(280, 60)
	trait_vbox.add_theme_constant_override("separation", 8)
	add_child(trait_vbox)

	var trait_label = Label.new()
	trait_label.text = "특성 슬롯"
	trait_label.add_theme_font_size_override("font_size", 28)
	trait_label.add_theme_color_override("font_color", ThemeColors.TEXT)
	trait_vbox.add_child(_make_section_top_spacer())
	trait_vbox.add_child(trait_label)
	trait_vbox.add_child(_make_section_line())
	trait_vbox.add_child(_make_section_spacer())

	for i in range(MAX_TRAIT_SLOTS):
		var slot = _make_slot_panel(i < _unlocked_trait_slots, i)
		trait_vbox.add_child(slot)

	# 벨미르 플레이스홀더 (280x380, anchor bottom_left, 특성 슬롯과 겹쳐도 자연스럽게)
	var velmire_placeholder = ColorRect.new()
	velmire_placeholder.color = ThemeColors.CARD_BORDER
	velmire_placeholder.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	velmire_placeholder.offset_left = 0
	velmire_placeholder.offset_top = -380
	velmire_placeholder.offset_right = 280
	velmire_placeholder.offset_bottom = 0
	add_child(velmire_placeholder)

	# 우측 패널 (x:768, w:1152)
	const RIGHT_PANEL_X := 768
	const RIGHT_PANEL_W := 1152
	const QUICK_AREA_H := 160  # 상단 (대폭 축소)
	var right_panel = ColorRect.new()
	right_panel.color = ThemeColors.BG_PANEL
	right_panel.position = Vector2(RIGHT_PANEL_X, 0)
	right_panel.size = Vector2(RIGHT_PANEL_W, 1080)
	add_child(right_panel)

	# 퀵슬롯 영역 (상단 h:160, 카드 균등 분할 / 여백 16px)
	var quick_area = VBoxContainer.new()
	quick_area.position = Vector2(RIGHT_PANEL_X + 24, 24)
	quick_area.size = Vector2(RIGHT_PANEL_W - 48, QUICK_AREA_H)
	quick_area.add_theme_constant_override("separation", 4)
	add_child(quick_area)

	var quick_label = Label.new()
	quick_label.text = "퀵슬롯 (배치 순서 = 체이닝 순서)"
	quick_label.add_theme_font_size_override("font_size", 28)
	quick_label.add_theme_color_override("font_color", ThemeColors.TEXT)
	quick_area.add_child(_make_section_top_spacer())
	quick_area.add_child(quick_label)
	quick_area.add_child(_make_section_line())
	quick_area.add_child(_make_section_spacer())

	var quick_hbox = HBoxContainer.new()
	quick_hbox.add_theme_constant_override("separation", 16)
	quick_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quick_area.add_child(quick_hbox)

	for i in range(QUICK_SLOT_COUNT):
		var qs = _make_quick_slot(i)
		qs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quick_hbox.add_child(qs)

	# 보유 노드 영역 (퀵슬롯 하단 ~ 보유노드 상단 간격 32px)
	# UI(제목·선·스크롤 프레임)는 기본 위치 유지, 그리드만 안쪽에서 우측으로 밀어 스케일 시 좌측 클리핑 방지
	const OWNED_NODES_GRID_MARGIN_LEFT := 200
	const GAP_QUICK_TO_NODES := 32
	const TOP_SPACER_H := 24
	const LABEL_H := 34  # font 28 기준
	const LINE_H := 2
	const SPACER_H := 16
	var node_area_y := QUICK_AREA_H + 24 + GAP_QUICK_TO_NODES + TOP_SPACER_H + LABEL_H + LINE_H + SPACER_H
	const SCROLL_BOTTOM_Y := 880
	var scroll_h := SCROLL_BOTTOM_Y - node_area_y
	var owned_nodes_left := RIGHT_PANEL_X + 24
	var owned_nodes_w := RIGHT_PANEL_W - 48

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(owned_nodes_left, node_area_y)
	scroll.size = Vector2(owned_nodes_w, scroll_h)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var list_label = Label.new()
	list_label.text = "보유 노드"
	list_label.add_theme_font_size_override("font_size", 28)
	list_label.add_theme_color_override("font_color", ThemeColors.TEXT)
	list_label.z_index = 10

	var node_header = VBoxContainer.new()
	node_header.position = Vector2(owned_nodes_left, QUICK_AREA_H + 24 + GAP_QUICK_TO_NODES)
	node_header.custom_minimum_size.x = owned_nodes_w
	node_header.add_theme_constant_override("separation", 0)
	node_header.add_child(_make_section_top_spacer())
	node_header.add_child(list_label)
	node_header.add_child(_make_section_line())
	node_header.add_child(_make_section_spacer())
	add_child(node_header)

	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = ThemeColors.SCROLL_INDICATOR
	scroll.get_v_scroll_bar().add_theme_stylebox_override("grabber", scroll_style)

	var scroll_inner = VBoxContainer.new()
	scroll_inner.add_theme_constant_override("separation", 0)
	scroll.add_child(scroll_inner)

	var grid_wrap = MarginContainer.new()
	grid_wrap.add_theme_constant_override("margin_left", OWNED_NODES_GRID_MARGIN_LEFT)
	grid_wrap.add_theme_constant_override("margin_right", 0)
	grid_wrap.add_theme_constant_override("margin_top", 0)
	grid_wrap.add_theme_constant_override("margin_bottom", 0)
	grid_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_inner.add_child(grid_wrap)

	var grid = GridContainer.new()
	grid.name = "OwnedNodesGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid_wrap.add_child(grid)

	for node_data in _owned_nodes:
		var card = _make_node_card(node_data)
		grid.add_child(card)

	var ngc = get_node_or_null("NodeGridController")
	if ngc and ngc.has_method("setup_grid"):
		ngc.setup_grid(grid)

	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 24)
	scroll_inner.add_child(bottom_spacer)

	# 전투 시작 버튼 (anchor bottom_right, y:900 이하 고정 영역, ScrollContainer과 겹치지 않음)
	var start_btn = Button.new()
	start_btn.text = "전투 시작"
	start_btn.custom_minimum_size = Vector2(300, 100)
	start_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	start_btn.offset_left = -320
	start_btn.offset_top = -120
	start_btn.offset_right = -20
	start_btn.offset_bottom = -20
	start_btn.add_theme_font_size_override("font_size", 28)
	start_btn.add_theme_color_override("font_color", ThemeColors.BTN_BATTLE_TEXT)
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = ThemeColors.BTN_BATTLE_BG
	btn_normal.set_corner_radius_all(8)
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = ThemeColors.BTN_BATTLE_HOVER
	btn_hover.set_corner_radius_all(8)
	start_btn.add_theme_stylebox_override("normal", btn_normal)
	start_btn.add_theme_stylebox_override("hover", btn_hover)
	start_btn.add_theme_stylebox_override("pressed", btn_hover)
	start_btn.pressed.connect(_on_battle_start_pressed)
	add_child(start_btn)

	# 루비 표시 (버튼 좌측)
	var ruby_label = Label.new()
	ruby_label.name = "RubyLabel"
	ruby_label.text = "🔴 %d" % ResourceManager.ruby
	ruby_label.add_theme_font_size_override("font_size", 24)
	ruby_label.add_theme_color_override("font_color", ThemeColors.COLOR_BLOOD)
	ruby_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ruby_label.offset_left = -420
	ruby_label.offset_top = -48
	ruby_label.offset_right = -340
	ruby_label.offset_bottom = -20
	add_child(ruby_label)

func _make_slot_panel(unlocked: bool, index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(320, 48)
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeColors.BG_PANEL
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.border_color = ThemeColors.LINE_HOVER if unlocked else ThemeColors.LINE_DEFAULT
	panel.add_theme_stylebox_override("panel", style)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var lbl = Label.new()
	lbl.text = "슬롯 %d" % (index + 1) if unlocked else "🔒 해금 🔴%d" % _get_trait_unlock_cost()
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", ThemeColors.TEXT)
	h.add_child(lbl)
	if not unlocked:
		var unlock_btn = Button.new()
		unlock_btn.text = "해금"
		unlock_btn.custom_minimum_size = Vector2(60, 32)
		unlock_btn.pressed.connect(_on_trait_slot_unlock.bind(index))
		h.add_child(unlock_btn)
	panel.add_child(h)
	return panel

func _get_trait_unlock_cost() -> int:
	var idx = _unlocked_trait_slots - DEFAULT_TRAIT_SLOTS
	if idx >= 0 and idx < SLOT_UNLOCK_COSTS.size():
		return SLOT_UNLOCK_COSTS[idx]
	return 99

func _on_trait_slot_unlock(index: int) -> void:
	var cost = _get_trait_unlock_cost()
	if ResourceManager.ruby < cost:
		return
	if ResourceManager.spend_ruby(cost):
		_unlocked_trait_slots += 1
		_build_ui()

func _make_quick_slot(index: int) -> PanelContainer:
	# 카드 크기 균등 분할 (축소)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 80)
	panel.name = "QuickSlot%d" % index
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeColors.BG_PANEL
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.border_color = ThemeColors.LINE_DEFAULT
	panel.add_theme_stylebox_override("panel", style)
	var v = VBoxContainer.new()
	var order_lbl = Label.new()
	order_lbl.text = "%d" % (index + 1)
	order_lbl.add_theme_font_size_override("font_size", 14)
	order_lbl.add_theme_color_override("font_color", ThemeColors.TEXT)
	v.add_child(order_lbl)
	var drop_lbl = Label.new()
	drop_lbl.text = "여기에 배치" if _quick_slot_data[index] == "" else _quick_slot_data[index]
	drop_lbl.add_theme_font_size_override("font_size", 12)
	drop_lbl.add_theme_color_override("font_color", ThemeColors.TEXT_SUB)
	v.add_child(drop_lbl)
	panel.add_child(v)
	panel.set_meta("slot_index", index)
	# TODO: 드래그앤드롭 연결
	return panel

func _make_owned_node_btn_style(stage: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(6)
	match stage:
		"normal":
			s.bg_color = Color(0.101961, 0, 0.062745)  # #1A0010
			s.border_color = Color(0.266667, 0, 0.133333)  # #440022
			s.set_border_width_all(1)
		"hover", "focus":
			s.bg_color = Color(0.133333, 0, 0.082353)  # #220015
			s.border_color = Color(1, 0.266667, 0.666667)  # #FF44AA
			s.set_border_width_all(2)
		"pressed":
			s.bg_color = Color(0.164706, 0, 0.094118)  # #2A0018
			s.border_color = Color(1, 0.533333, 0.8)  # #FF88CC
			s.set_border_width_all(2)
		_:
			s.bg_color = Color(0.101961, 0, 0.062745)
			s.border_color = Color(0.266667, 0, 0.133333)
			s.set_border_width_all(1)
	s.set_content_margin_all(12)
	return s


func _make_node_card(node_data: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 92)
	btn.flat = false
	btn.focus_mode = Control.FOCUS_ALL
	btn.text = "%s" % node_data.get("type", "?")
	btn.add_theme_font_size_override("font_size", 22)
	var white := Color(1, 1, 1)  # #FFFFFF
	btn.add_theme_color_override("font_color", white)
	btn.add_theme_color_override("font_hover_color", white)
	btn.add_theme_color_override("font_focus_color", white)
	btn.add_theme_color_override("font_pressed_color", white)
	btn.add_theme_stylebox_override("normal", _make_owned_node_btn_style("normal"))
	btn.add_theme_stylebox_override("hover", _make_owned_node_btn_style("hover"))
	btn.add_theme_stylebox_override("focus", _make_owned_node_btn_style("focus"))
	btn.add_theme_stylebox_override("pressed", _make_owned_node_btn_style("pressed"))
	btn.set_meta("node_data", node_data)
	# TODO: 드래그 시작 연결
	return btn

func _make_section_line() -> ColorRect:
	var line = ColorRect.new()
	line.color = Color(0.5, 0.0, 0.3)  # #800050 채도 죽인 마젠타
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line

func _make_section_top_spacer() -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	return spacer

func _make_section_spacer() -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	return spacer

func _update_ruby_label() -> void:
	var lbl = get_node_or_null("RubyLabel")
	if lbl and lbl is Label:
		lbl.text = "🔴 %d" % ResourceManager.ruby

func _on_battle_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
