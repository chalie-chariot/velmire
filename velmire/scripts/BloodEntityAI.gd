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
	var num: int = randi_range(5, 8)
	var base_r: float = randf_range(27.0, 42.0)
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = base_r + randf_range(-12.0, 12.0)
		_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _process(delta: float) -> void:
	rotation += _rotation_speed * delta
	var dir: Vector2 = (target - global_position).normalized()
	global_position += dir * speed * delta
	queue_redraw()

func _draw() -> void:
	if _points.size() == 0:
		return
	draw_colored_polygon(_points, Color(0.55, 0.0, 0.0, 1.0))
	for i in range(_points.size()):
		var a: Vector2 = _points[i]
		var b: Vector2 = _points[(i + 1) % _points.size()]
		draw_line(a, b, Color(1.0, 0.2, 0.2, 1.0))
