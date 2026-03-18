extends Node2D

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _color: Color = Color.WHITE
var _node_type: String = ""  # "흡혈" / "결계" / "증폭"
var _alpha: float = 0.9
var _width: float = 2.0
var _pulse_tween: Tween

# 연결선 기본 속성 (타입별 색상)
const LINE_COLOR_MAP: Dictionary = {
	"흡혈": Color(0.9, 0.1, 0.1),   # 레드
	"결계": Color(0.1, 0.3, 0.9),   # 블루
	"증폭": Color(0.1, 0.8, 0.2),   # 그린
}

func _ready() -> void:
	_start_pulse()

func _start_pulse() -> void:
	_width = 1.5
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "_width", 4.0, 0.3)
	_pulse_tween.tween_property(self, "_width", 1.5, 0.3)

func _process(delta: float) -> void:
	_alpha -= delta * 0.5
	if _alpha <= 0.0:
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		queue_free()
		return
	queue_redraw()

func _get_line_color() -> Color:
	if _node_type != "" and LINE_COLOR_MAP.has(_node_type):
		return LINE_COLOR_MAP[_node_type]
	return _color

func _draw() -> void:
	var c: Color = _get_line_color()
	draw_line(_from, _to, Color(c.r, c.g, c.b, _alpha), _width)
	draw_circle(_to, 4.0, Color(1.0, 1.0, 1.0, _alpha * 0.6))
