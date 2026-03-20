extends Node3D

@onready var camera = $Camera3D
@onready var room = $room

var room_origin : Vector3
var cam_rot_origin : Vector3
var current_offset : Vector2 = Vector2.ZERO
var ready_done : bool = false

## 클릭 후 드래그할 때 current_offset으로 들어가는 비율 (클수록 짧은 드래그로 끝까지 도달)
@export var drag_sensitivity : float = 0.004

var is_dragging : bool = false
var drag_start_mouse : Vector2 = Vector2.ZERO
var drag_start_offset : Vector2 = Vector2.ZERO

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	room_origin = room.position
	cam_rot_origin = camera.rotation_degrees
	current_offset = Vector2.ZERO
	ready_done = true

func _input(event):
	if not ready_done:
		return

	# 마우스 클릭 시작
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_mouse = event.position
				drag_start_offset = current_offset
			else:
				is_dragging = false

	# 드래그 중 이동
	if event is InputEventMouseMotion and is_dragging:
		var delta_mouse = event.position - drag_start_mouse

		current_offset = drag_start_offset + \
				Vector2(delta_mouse.x, delta_mouse.y) * drag_sensitivity

		# 회전 범위 제한 (패닝으로 둘러볼 수 있는 범위)
		current_offset.x = clamp(current_offset.x, -2.5, 2.5)
		current_offset.y = clamp(current_offset.y, -3.0, 3.0)

func _process(_delta):
	if not ready_done:
		return

	camera.rotation_degrees.y = cam_rot_origin.y \
			+ (-current_offset.x * 3.0)
	camera.rotation_degrees.x = cam_rot_origin.x \
			+ (current_offset.y * 1.5)

	room.position.x = room_origin.x \
			+ current_offset.x * 0.08
