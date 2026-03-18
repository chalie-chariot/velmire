extends Node2D
## 관-노드 연결선 펄스 도트 (entity_layer 로컬 좌표 사용)

@export var draw_color: Color = Color(1, 1, 1, 0.9)
@export var radius: float = 8.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, draw_color)
