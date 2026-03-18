extends Node2D
## 혈관 곡선 따라 이동하는 펄스 도트

@export var draw_color: Color = Color(1, 1, 1, 0.9)
@export var radius: float = 8.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, draw_color)
