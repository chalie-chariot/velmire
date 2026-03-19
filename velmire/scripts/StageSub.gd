extends Node2D

# 루트별 카드 세트 (기획 확정 전 임시값)
# stage_set 인덱스 → 카드 5장
const STAGE_SETS = [
	# 혈도 I
	[
		{"name": "혈도 I - 1막", "difficulty": "🩸🩸",     "enemy": "혈체 (血體)",   "reward": "루비 +3", "modifier": {}},
		{"name": "혈도 I - 2막", "difficulty": "🩸🩸🩸",   "enemy": "혈체 (血體)",   "reward": "루비 +3", "modifier": {}},
		{"name": "혈도 I - 3막", "difficulty": "🩸🩸🩸🩸", "enemy": "기혈 (寄血) 등장", "reward": "루비 +4", "modifier": {}},
		{"name": "혈도 I - 4막", "difficulty": "🩸🩸🩸🩸🩸","enemy": "기혈 다수",     "reward": "루비 +5", "modifier": {}},
		{"name": "혈도 I - 심층", "difficulty": "🩸🩸🩸🩸🩸🩸","enemy": "봉인 해제",  "reward": "루비 +7", "modifier": {"start_stage4": true}}
	],
	# 혈도 II (임시)
	[
		{"name": "혈도 II - 1막", "difficulty": "🩸🩸🩸",    "enemy": "혈체 강화",    "reward": "루비 +4", "modifier": {"speed_mult": 1.2}},
		{"name": "혈도 II - 2막", "difficulty": "🩸🩸🩸🩸",  "enemy": "혈체 강화",    "reward": "루비 +4", "modifier": {"speed_mult": 1.2}},
		{"name": "혈도 II - 3막", "difficulty": "🩸🩸🩸🩸🩸","enemy": "기혈 등장",    "reward": "루비 +5", "modifier": {"speed_mult": 1.2}},
		{"name": "혈도 II - 4막", "difficulty": "🩸🩸🩸🩸🩸🩸","enemy": "기혈 다수",  "reward": "루비 +6", "modifier": {"speed_mult": 1.3}},
		{"name": "혈도 II - 심층","difficulty": "🩸🩸🩸🩸🩸🩸🩸","enemy": "봉인 해제","reward": "루비 +8", "modifier": {"speed_mult": 1.3, "start_stage4": true}}
	],
	# 혈도 III (임시)
	[
		{"name": "혈도 III - 1막","difficulty": "🩸🩸🩸🩸",   "enemy": "기혈 즉시 등장","reward": "루비 +5", "modifier": {"start_stage4": true}},
		{"name": "혈도 III - 2막","difficulty": "🩸🩸🩸🩸🩸", "enemy": "기혈 다수",     "reward": "루비 +5", "modifier": {"start_stage4": true}},
		{"name": "혈도 III - 3막","difficulty": "🩸🩸🩸🩸🩸🩸","enemy": "숙혈 예정",    "reward": "루비 +6", "modifier": {"start_stage4": true}},
		{"name": "혈도 III - 4막","difficulty": "🩸🩸🩸🩸🩸🩸🩸","enemy": "침혈 예정",  "reward": "루비 +7", "modifier": {"start_stage4": true}},
		{"name": "혈도 III - 심층","difficulty": "🩸🩸🩸🩸🩸🩸🩸🩸","enemy": "혈왕 예정","reward": "루비 +10","modifier": {"start_stage4": true, "speed_mult": 1.5}}
	]
]

# 카드 레이아웃 - 선택 빛은 정중앙 고정, 카드가 focus_index에 따라 위치 이동
const CARD_SCALES_BY_DIST = [1.0, 0.75, 0.55]  # 정중앙으로부터 거리 0,1,2에 따른 스케일
const CARD_SIZE := Vector2(280, 420)
const ANIM_DURATION := 0.25
const BOUNCE_DURATION := 0.2  # 스케일 바운스 (TRANS_BACK로 자연스럽게 오버슈트)
const DROP_BOUNCE_DURATION := 0.25  # 핏방울 추가 시 바운스
const DROP_BOUNCE_PEAK := 1.5  # 바운스 시 오버슈트 피크 (1.0 → 1.5 이상)

var center_x: float = 0.0
var center_y: float = 0.0
var card_spacing: float = 0.0  # 카드 간격 (중심 기준)

var focus_index: int = 2   # 현재 포커스된 카드 (0~4, 초기값 중앙)
var current_set: Array = []
var cards: Array = []
var slide_tween: Tween = null
var prev_difficulty_count: int = -1  # 핏방울 바운스 연출용

@onready var rm = get_tree().get_first_node_in_group("resource_manager")
@onready var info_panel: PanelContainer = $CanvasLayer/InfoPanel
@onready var red_line: ColorRect = $CanvasLayer/RedLine
@onready var center_glow: ColorRect = $CanvasLayer/CenterGlow
@onready var back_button: Button = $CanvasLayer/BackButton
@onready var stage_name_label = $CanvasLayer/InfoPanel/VBoxContainer/StageNameLabel
@onready var difficulty_label   = $CanvasLayer/InfoPanel/VBoxContainer/DifficultyLabel
@onready var difficulty_dots_container = $CanvasLayer/InfoPanel/VBoxContainer/DifficultyDotsContainer
@onready var enemy_label       = $CanvasLayer/InfoPanel/VBoxContainer/EnemyPreviewLabel
@onready var reward_label      = $CanvasLayer/InfoPanel/VBoxContainer/RewardLabel
@onready var route_label       = $CanvasLayer/TopBar/RouteLabel

func _ready():
	var vp: Vector2 = get_viewport().get_visible_rect().size

	# InfoPanel: 우측 하단 배치, 텍스트 짤림 방지 (여유 높이·패딩)
	var panel_w: float = vp.x * 0.22
	var panel_h: float = vp.y * 0.28
	var margin: float = 24.0
	info_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_panel.offset_left = vp.x - panel_w - margin
	info_panel.offset_top = vp.y - panel_h - margin
	info_panel.offset_right = vp.x - margin
	info_panel.offset_bottom = vp.y - margin

	back_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_button.offset_left = vp.x * 0.02
	back_button.offset_top = vp.y * 0.88
	back_button.offset_right = back_button.offset_left + 180.0
	back_button.offset_bottom = back_button.offset_top + 40.0

	# 화면 좌표: 카드를 위로 (center_y 40%), 가로 중앙
	center_x = vp.x / 2.0
	center_y = vp.y * 0.4

	# 수평 라인 (카드 중앙 y에, 카드 뒤)
	red_line.position = Vector2(0, center_y - 2)
	red_line.size = Vector2(vp.x, 4)

	# 선택 글로우: 정중앙에 고정 (카드와 무관하게 항상 같은 위치)
	center_glow.size = Vector2(120, vp.y)
	center_glow.position = Vector2(center_x - center_glow.size.x / 2.0, 0)
	center_glow.visible = true

	# 카드 간격 (1.5배 축소: span/1.5 기준)
	var span: float = vp.x * 1.0 / 1.5
	card_spacing = span / 4.0

	cards = [
		$CanvasLayer/Card0,
		$CanvasLayer/Card1,
		$CanvasLayer/Card2,
		$CanvasLayer/Card3,
		$CanvasLayer/Card4
	]

	# 루트별 카드 세트 로드
	var set_idx = rm.get_meta("stage_set") if rm.has_meta("stage_set") else 0
	current_set = STAGE_SETS[set_idx]

	# 루트명 표시
	route_label.text = ["혈도 I", "혈도 II", "혈도 III"][rm.selected_route]

	_apply_carousel()
	_update_info_panel()

	$CanvasLayer/InfoPanel/VBoxContainer/ConfirmButton.pressed.connect(_on_confirm)
	back_button.pressed.connect(_on_back)

	for i in cards.size():
		cards[i].gui_input.connect(_on_card_input.bind(i))

# 포커스 기준 카드 i의 목표 중심 좌표 (선택 빛은 정중앙 고정, 카드만 이동)
func _get_card_center(i: int) -> Vector2:
	var offset: float = (i - focus_index) * card_spacing
	return Vector2(center_x + offset, center_y)

func _apply_carousel(animate: bool = false):
	if slide_tween and slide_tween.is_valid():
		slide_tween.kill()

	var target_positions: Array = []

	for i in cards.size():
		var card: PanelContainer = cards[i]
		var rel: int = i - focus_index
		# 스케일: 정중앙(focus) 1.0, ±1칸 0.75, ±2칸 0.55
		var dist: int = abs(rel)
		var scale_val: float = CARD_SCALES_BY_DIST[clamp(dist, 0, 2)]

		card.pivot_offset = CARD_SIZE / 2.0
		# 애니 중이면 포커스 카드는 스케일 트윈으로 처리 (바운스)
		if animate and rel == 0:
			pass  # 스케일은 아래 트윈에서 설정
		else:
			card.scale = Vector2(scale_val, scale_val)
		card.z_index = 10 if rel == 0 else 0

		var target_center := _get_card_center(i)
		var target_pos: Vector2 = target_center - CARD_SIZE / 2.0
		target_positions.append(target_pos)

		# 포커스: 빨간 글로우 / 비포커스: 어두운 스타일 (즉시 반영)
		var style := StyleBoxFlat.new()
		# 위2·아래2 모서리 동일한 라운드 (12 → 24, 2배 이상)
		style.set_corner_radius_all(24)
		if rel == 0:
			style.bg_color = Color(0.12, 0.0, 0.0)
			style.set_border_width_all(3)
			style.border_color = Color(1.0, 0.1, 0.1)
			style.shadow_color = Color(0.8, 0.0, 0.0)
			style.shadow_size = 20
		else:
			style.bg_color = Color(0.05, 0.0, 0.0)
			style.set_border_width_all(2)
			style.border_color = Color(0.4, 0.05, 0.05)
		card.add_theme_stylebox_override("panel", style)

		if not animate:
			card.position = target_positions[i]

	if animate:
		slide_tween = create_tween()
		slide_tween.set_parallel(true)
		for i in cards.size():
			slide_tween.tween_property(cards[i], "position", target_positions[i], ANIM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# 선택된 카드(중앙)에 스케일 바운스 1회: 현재→1.0, TRANS_BACK으로 자연스럽게 오버슈트
		var focus_card: PanelContainer = cards[focus_index]
		slide_tween.tween_property(focus_card, "scale", Vector2.ONE, BOUNCE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _update_info_panel():
	var data = current_set[focus_index % current_set.size()]
	stage_name_label.text  = "STAGE  —  " + data["name"]
	difficulty_label.text  = "난이도"
	_set_difficulty_dots(data["difficulty"])
	enemy_label.text       = "적: " + data["enemy"]
	reward_label.text      = "보상: " + data["reward"]

func _set_difficulty_dots(difficulty_str: String):
	var count: int = difficulty_str.count("🩸")
	for c in difficulty_dots_container.get_children():
		c.queue_free()
	# 추가되는 핏방울 인덱스 (난이도 증가 시)
	var bounce_indices: Array = []
	if prev_difficulty_count >= 0 and count > prev_difficulty_count:
		for i in range(prev_difficulty_count, count):
			bounce_indices.append(i)
	prev_difficulty_count = count

	for i in count:
		var lbl := Label.new()
		lbl.text = "🩸"
		lbl.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15, 1))
		difficulty_dots_container.add_child(lbl)

	# 바운스 대상: 새로 추가된 것만, 또는 카드 전환 시 전부(시각적 확인용)
	if bounce_indices.size() > 0:
		call_deferred("_schedule_drop_bounces", bounce_indices)

func _schedule_drop_bounces(bounce_indices: Array):
	await get_tree().process_frame
	for i in bounce_indices:
		if i < difficulty_dots_container.get_child_count():
			var lbl: Label = difficulty_dots_container.get_child(i)
			_bounce_difficulty_drop(lbl)

func _bounce_difficulty_drop(lbl: Label):
	if not is_instance_valid(lbl):
		return
	# 레이아웃 후 size 반영
	var w: float = maxf(lbl.size.x, 1.0)
	var h: float = maxf(lbl.size.y, 1.0)
	lbl.pivot_offset = Vector2(w / 2.0, h / 2.0)
	lbl.scale = Vector2(0.2, 0.2)
	# 바운스: 0.2 → 피크(1.5) → 1.0 (2배 이상 확실한 스케일 업)
	var tween := create_tween()
	tween.tween_property(lbl, "scale", Vector2(DROP_BOUNCE_PEAK, DROP_BOUNCE_PEAK), DROP_BOUNCE_DURATION * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(lbl, "scale", Vector2.ONE, DROP_BOUNCE_DURATION * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

func _on_arrow_left():
	var new_focus: int = (focus_index - 1 + current_set.size()) % current_set.size()
	if new_focus == focus_index:
		return
	focus_index = new_focus
	_apply_carousel(true)
	_update_info_panel()

func _on_arrow_right():
	var new_focus: int = (focus_index + 1) % current_set.size()
	if new_focus == focus_index:
		return
	focus_index = new_focus
	_apply_carousel(true)
	_update_info_panel()

func _on_card_input(event: InputEvent, card_idx: int):
	if event is InputEventMouseButton and event.pressed:
		if card_idx == focus_index:
			return
		focus_index = card_idx
		_apply_carousel(true)
		_update_info_panel()

func _on_confirm():
	var data = current_set[focus_index % current_set.size()]
	rm.selected_stage = focus_index

	# 모디파이어 적용
	var mod = data["modifier"]
	if mod.has("speed_mult"):
		rm.set_meta("stage_speed_mult", mod["speed_mult"])
	elif rm.has_meta("stage_speed_mult"):
		rm.remove_meta("stage_speed_mult")

	if mod.has("start_stage4"):
		rm.set_meta("stage_start_stage4", true)
	elif rm.has_meta("stage_start_stage4"):
		rm.remove_meta("stage_start_stage4")

	get_tree().change_scene_to_file("res://scenes/BattleReady.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/StageMain.tscn")

func _input(event: InputEvent):
	if event.is_action_pressed("ui_left"):
		_on_arrow_left()
	if event.is_action_pressed("ui_right"):
		_on_arrow_right()

