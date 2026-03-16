extends Node
## 아이템 획득 시 적용할 효과들. 암전 밝기 등.
##
## 사용 예 (등불 아이템 - 관 주변 밝히기):
##   var coffin = get_tree().get_first_node_in_group("coffin")
##   var center = coffin.global_position + coffin.size / 2
##   ItemEffects.set_vignette_bright(0, center, 120.0, 1.0)
##
## 해제: ItemEffects.clear_vignette_bright(0)

func _ready() -> void:
	pass

## 암전의 특정 영역을 밝힘. 아이템 획득 시 호출.
## area_index: 0 또는 1 (최대 2개 영역)
## center: 화면 좌표 (Vector2)
## radius: 밝은 반경(px), 예: 80~150
## strength: 0~1, 1이면 해당 영역 암전 완전 제거
func set_vignette_bright(area_index: int, center: Vector2, radius: float, strength: float = 1.0) -> void:
	var main = _get_main()
	if main and main.has_method("set_vignette_bright_area"):
		main.set_vignette_bright_area(area_index, center, radius, strength)

## 밝은 영역 해제. 아이템 효과 종료 시 호출.
func clear_vignette_bright(area_index: int) -> void:
	var main = _get_main()
	if main and main.has_method("clear_vignette_bright_area"):
		main.clear_vignette_bright_area(area_index)

func _get_main():
	var tree = Engine.get_main_loop()
	if tree is SceneTree:
		return (tree as SceneTree).get_first_node_in_group("main")
	return null
