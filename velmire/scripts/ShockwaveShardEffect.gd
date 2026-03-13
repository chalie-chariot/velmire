extends Node2D
var _vel: Vector2 = Vector2.ZERO
var _alpha: float = 1.0
var _size: float = 6.0
var _gravity: float = 280.0
var _rotation_speed: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _spread_sign: float = 1.0

func _ready() -> void:
	_rotation_speed = randf_range(-8.0, 8.0)

func _process(delta: float) -> void:
	var dist: float = global_position.distance_to(_origin)
	var perp: Vector2 = Vector2(-_vel.y, _vel.x).normalized()
	_vel += perp * _spread_sign * dist * 0.002 * delta
	_vel.y += _gravity * delta
	global_position += _vel * delta
	_vel *= 0.97
	_alpha -= 0.7 * delta
	rotation += _rotation_speed * delta
	if _alpha <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var s: float = max(_size, 1.0)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -s * 2.0),
		Vector2(s * 0.6, s),
		Vector2(-s * 0.6, s)
	])
	draw_colored_polygon(pts, Color(0.85, 0.05, 0.05, _alpha))
	for i in range(pts.size()):
		draw_line(
			pts[i], pts[(i + 1) % pts.size()],
			Color(1.0, 0.5, 0.4, _alpha * 0.7), 1.2
		)
	var trail_pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -s * 1.2),
		Vector2(s * 0.4, s * 0.6),
		Vector2(-s * 0.4, s * 0.6)
	])
	draw_colored_polygon(trail_pts, Color(1.0, 0.2, 0.2, _alpha * 0.25))
