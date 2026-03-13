extends Node2D

var speed: float = 90.0
var hp: float = 30.0
var damage: float = 10.0
var target: Vector2 = Vector2(960, 540)
var _rotation_speed: float = 0.0
var _points: PackedVector2Array = []

func _ready() -> void:
	_rotation_speed = randf_range(-0.3, 0.3)
	_generate_points()

func _generate_points() -> void:
	var num: int = randi_range(6, 9)
	var base_r: float = randf_range(27.0, 42.0)
	_points.clear()
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = base_r + randf_range(-8.0, 8.0)
		_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _get_smooth_points() -> PackedVector2Array:
	var smooth: PackedVector2Array = []
	var count: int = _points.size()
	for i in range(count):
		var curr: Vector2 = _points[i]
		var next: Vector2 = _points[(i + 1) % count]
		var prev: Vector2 = _points[(i - 1 + count) % count]
		smooth.append(curr.lerp(prev, 0.16))
		smooth.append(curr.lerp((prev + next) / 2.0, 0.08))
		smooth.append(curr.lerp(next, 0.16))
	return smooth

func _process(delta: float) -> void:
	rotation += _rotation_speed * delta
	var dir: Vector2 = (target - global_position).normalized()
	global_position += dir * speed * delta
	queue_redraw()

func _draw() -> void:
	if _points.size() == 0:
		return
	var smooth: PackedVector2Array = _get_smooth_points()
	draw_colored_polygon(smooth, Color(0.55, 0.0, 0.0, 1.0))
	for i in range(smooth.size()):
		var a: Vector2 = smooth[i]
		var b: Vector2 = smooth[(i + 1) % smooth.size()]
		draw_line(a, b, Color(1.0, 0.2, 0.2, 1.0), 1.5)
