extends Node2D

## 심장 수정 용기 외형 - 타원형 시각

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# 타원형 용기 (밝은 색으로 가시성 확보)
	draw_arc(Vector2.ZERO, 36.0, 0, TAU, 32, Color(1.0, 0.25, 0.3, 1.0), 5.0)
	draw_circle(Vector2.ZERO, 28.0, Color(0.4, 0.05, 0.08, 0.95))
