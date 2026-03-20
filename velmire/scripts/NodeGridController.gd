extends Control

## BattleReady._build_ui() 끝에서 setup_grid(그리드) 호출로 연결됩니다.

var grid: GridContainer
var buttons: Array = []
var selected_idx: int = -1
## 마우스가 그리드 버튼 위에 없으면 -1
var hovered_idx: int = -1

## 기본(비호버): 작게 / 호버: 커짐(딱 1.0)
const SCALE_IDLE := Vector2(0.8, 0.8)
const SCALE_HOVER := Vector2(1.0, 1.0)
const LERP_SPEED := 12.0

var cols: int = 4


func setup_grid(p_grid: GridContainer) -> void:
	grid = p_grid
	if grid:
		cols = maxi(1, grid.columns)
	await get_tree().process_frame
	_collect_buttons()


func _collect_buttons() -> void:
	buttons.clear()
	selected_idx = -1
	hovered_idx = -1
	if grid == null:
		return
	for child in grid.get_children():
		if child is Button:
			buttons.append(child)
			var btn = child as Button
			btn.pivot_offset = btn.size * 0.5
			btn.scale = SCALE_IDLE
			var idx = buttons.size() - 1
			btn.pressed.connect(_on_button_pressed.bind(idx))
			btn.mouse_entered.connect(_on_mouse_enter.bind(idx))
			btn.mouse_exited.connect(_on_mouse_exit.bind(idx))


func _process(delta: float) -> void:
	if buttons.is_empty():
		return
	for i in range(buttons.size()):
		var btn = buttons[i] as Button
		var target_scale: Vector2
		if hovered_idx == -1:
			# 호버 없음 → 전부 작은 기본 크기
			target_scale = SCALE_IDLE
		else:
			# 마우스 올린 칸만 크게, 나머지는 작게
			target_scale = SCALE_HOVER if i == hovered_idx else SCALE_IDLE
		btn.scale = btn.scale.lerp(target_scale, delta * LERP_SPEED)
		btn.pivot_offset = btn.size * 0.5


func _input(event: InputEvent) -> void:
	if buttons.is_empty():
		return
	if selected_idx == -1:
		selected_idx = 0
		_update_focus()
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_right"):
		selected_idx = mini(selected_idx + 1, buttons.size() - 1)
		_update_focus()
	elif event.is_action_pressed("ui_left"):
		selected_idx = maxi(selected_idx - 1, 0)
		_update_focus()
	elif event.is_action_pressed("ui_down"):
		selected_idx = mini(selected_idx + cols, buttons.size() - 1)
		_update_focus()
	elif event.is_action_pressed("ui_up"):
		selected_idx = maxi(selected_idx - cols, 0)
		_update_focus()
	elif event.is_action_pressed("ui_accept"):
		(buttons[selected_idx] as Button).pressed.emit()


func _on_mouse_enter(idx: int) -> void:
	hovered_idx = idx
	selected_idx = idx
	_update_focus()


func _on_mouse_exit(_idx: int) -> void:
	call_deferred("_deferred_check_mouse_left_buttons")


func _deferred_check_mouse_left_buttons() -> void:
	if buttons.is_empty():
		return
	var m := get_viewport().get_mouse_position()
	for i in range(buttons.size()):
		var btn = buttons[i] as Button
		if btn.get_global_rect().has_point(m):
			return
	hovered_idx = -1
	_update_focus()


func _on_button_pressed(idx: int) -> void:
	selected_idx = idx
	_update_focus()


func _update_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i] as Button
		if hovered_idx >= 0:
			# 마우스가 그리드 위에 있을 때만 포커스 링(테마) 표시
			if i == hovered_idx:
				btn.grab_focus()
			else:
				btn.release_focus()
		else:
			# 호버 없음 → 포커스 해제로 기본 색/스타일
			btn.release_focus()
