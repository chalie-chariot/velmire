extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 기존 tscn 자식 제거
	for c in get_children():
		remove_child(c)
		c.queue_free()

	# 배경 (BattleReady와 동일)
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

	# 좌측 패널 (768px, BattleReady와 동일)
	const LEFT_PANEL_W := 768
	var left_panel = ColorRect.new()
	left_panel.color = ThemeColors.BG_PANEL
	left_panel.position = Vector2(0, 0)
	left_panel.size = Vector2(LEFT_PANEL_W, 1080)
	add_child(left_panel)

	# 벨미르 플레이스홀더 (좌하단, BattleReady와 동일)
	var velmire_placeholder = ColorRect.new()
	velmire_placeholder.color = ThemeColors.CARD_BORDER
	velmire_placeholder.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	velmire_placeholder.offset_left = 0
	velmire_placeholder.offset_top = -380
	velmire_placeholder.offset_right = 280
	velmire_placeholder.offset_bottom = 0
	add_child(velmire_placeholder)

	# 타이틀 (중앙)
	var title = Label.new()
	title.text = "VELMIRE : BLOODCAST"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", ThemeColors.TITLE_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -400
	title.offset_top = -30
	title.offset_right = 400
	title.offset_bottom = 30
	add_child(title)

	# 메뉴 버튼들 (우측)
	const RIGHT_X := 1400
	const BTN_W := 400
	const BTN_H := 56
	const BTN_GAP := 16

	var menu_vbox = VBoxContainer.new()
	menu_vbox.position = Vector2(RIGHT_X, 400)
	menu_vbox.add_theme_constant_override("separation", BTN_GAP)
	add_child(menu_vbox)

	# 전투 시작 → BattleReady.tscn
	var btn_battle = _make_menu_button("전투 시작", true)
	btn_battle.pressed.connect(_on_battle_start_pressed)
	menu_vbox.add_child(btn_battle)

	# 상점 → 추후 구현 (준비 중 잠금)
	var btn_shop = _make_menu_button("상점\n준비 중", false)
	menu_vbox.add_child(btn_shop)

	# 룰렛 → 추후 구현 (준비 중 잠금)
	var btn_roulette = _make_menu_button("룰렛\n준비 중", false)
	menu_vbox.add_child(btn_roulette)

	# 설정 → 추후 구현 (준비 중 잠금)
	var btn_settings = _make_menu_button("설정\n준비 중", false)
	menu_vbox.add_child(btn_settings)

func _make_menu_button(text: String, enabled: bool) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(400, 56)
	btn.disabled = not enabled
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", ThemeColors.BTN_BATTLE_TEXT if enabled else ThemeColors.TEXT_SUB)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = ThemeColors.BTN_BATTLE_BG if enabled else ThemeColors.CARD_BORDER
	style_normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style_normal)
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = ThemeColors.CARD_BORDER
	style_disabled.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	return btn

func _on_battle_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleReady.tscn")
