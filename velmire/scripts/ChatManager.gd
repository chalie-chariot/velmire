extends Node
class_name ChatManager

# 채팅 메시지 풀
var _chat_pool: Dictionary = {
	"start": [
		{"name": "혈액형B형", "msg": "ㅋㅋㅋㅋ 또 시작이네"},
		{"name": "밤의피츄", "msg": "1빠임?"},
		{"name": "선혈계주민", "msg": "아 기다렸잖아"},
		{"name": "핏방울하츄핑", "msg": "켰더니 마침 시작 ㄷㄷ"},
		{"name": "뱀파덕후99", "msg": "알림 보고 달려옴 🏃"},
		{"name": "붉달", "msg": "ㅇㅇ 왔음"},
		{"name": "심장박동중", "msg": "오늘은 얼마나 버팀?"},
		{"name": "혈관미터기", "msg": "저번에 5분도 못버텼잖아 ㅋㅋ"},
		{"name": "관뚜껑열사", "msg": "또 지는거 보러옴 ㅎ"},
		{"name": "피빨리는중", "msg": "오늘도 관 부서지겠네"},
	],
	"kill": [
		{"name": "혈액형B형", "msg": "ㅋㅋ 갔네"},
		{"name": "핏방울하츄핑", "msg": "ㅇㅇ 당연하지"},
		{"name": "선혈계주민", "msg": "ㄱㅇㄷ"},
		{"name": "붉달", "msg": "👍"},
		{"name": "뱀파덕후99", "msg": "이건 쉽지 않냐"},
		{"name": "심장박동중", "msg": "ㅋㅋ 터졌다"},
		{"name": "혈관미터기", "msg": "잡았네 ㄹㅇ"},
		{"name": "관뚜껑열사", "msg": "오 이번엔 잘하는데?"},
		{"name": "피빨리는중", "msg": "ㄷㄷ"},
		{"name": "선혈왕귀환", "msg": "노드 존잘이네"},
		{"name": "기혈목격자", "msg": "처치완 ㄱㄱ"},
		{"name": "밤의피츄", "msg": "굳"},
		{"name": "핏물결", "msg": "ㅇㅇ 이정도면 됨"},
		{"name": "혈장수집가", "msg": "ㅋㅋ 박살"},
	],
	"combo": [
		{"name": "혈액형B형", "msg": "ㅋㅋㅋㅋ 이거 맞냐"},
		{"name": "관뚜껑열사", "msg": "오 연콤이네 진짜"},
		{"name": "선혈계주민", "msg": "와 연속이다"},
		{"name": "뱀파덕후99", "msg": "ㅋㅋ 갑자기 잘함"},
		{"name": "핏방울하츄핑", "msg": "이게 되네 ㄷㄷ"},
		{"name": "붉달", "msg": "ㄹㅇ? 🔥"},
		{"name": "심장박동중", "msg": "연콤 미쳤는데"},
		{"name": "피빨리는중", "msg": "ㅋㅋㅋ 갑자기 왜 잘해"},
		{"name": "기혈목격자", "msg": "이거 사기 아님? ㅋㅋ"},
		{"name": "혈관미터기", "msg": "연속이다 연속 👀"},
		{"name": "선혈왕귀환", "msg": "오 콤보 터졌다"},
		{"name": "핏물결", "msg": "ㄷㄷ 무서워"},
	],
	"hit": [
		{"name": "혈액형B형", "msg": "ㅋㅋ 맞았네"},
		{"name": "관뚜껑열사", "msg": "그러게 조심하라 했잖아 ㅋ"},
		{"name": "선혈계주민", "msg": "헉 맞았다"},
		{"name": "핏방울하츄핑", "msg": "아ㅋㅋ"},
		{"name": "뱀파덕후99", "msg": "ㅠㅠ 아깝"},
		{"name": "붉달", "msg": "조심 ㅠ"},
		{"name": "심장박동중", "msg": "ㄴㄴ 맞으면 안된다고"},
		{"name": "피빨리는중", "msg": "어 맞았어?? ㅋㅋ"},
		{"name": "혈관미터기", "msg": "HP 깎였다"},
		{"name": "기혈목격자", "msg": "ㅋㅋ 관 터진다"},
		{"name": "선혈왕귀환", "msg": "아 저거 막았어야 했는데"},
		{"name": "핏물결", "msg": "ㄷㄷ 맞으면 안되는데"},
	],
	"danger": [
		{"name": "혈액형B형", "msg": "ㄷㄷ 이제 끝인듯"},
		{"name": "관뚜껑열사", "msg": "ㅋㅋㅋ 다됐다"},
		{"name": "선혈계주민", "msg": "살아 제발 ㅠㅠ"},
		{"name": "핏방울하츄핑", "msg": "어 어 어 어"},
		{"name": "뱀파덕후99", "msg": "위험하다 진짜"},
		{"name": "붉달", "msg": "버텨 ㅠㅠ"},
		{"name": "심장박동중", "msg": "ㅋㅋ 다죽어가네"},
		{"name": "피빨리는중", "msg": "이거 어케함 ㄷㄷ"},
		{"name": "혈관미터기", "msg": "HP 바닥이다"},
		{"name": "기혈목격자", "msg": "여기서 살아나면 전설"},
		{"name": "선혈왕귀환", "msg": "ㅠㅠ 살아줘"},
		{"name": "핏물결", "msg": "뒤지겠다 ㅋㅋ"},
		{"name": "혈장수집가", "msg": "이거 진짜 위험한데"},
		{"name": "밤의피츄", "msg": "살아라 제발 🙏🙏"},
	],
	"synergy": [
		{"name": "혈액형B형", "msg": "오 시너지 터졌다"},
		{"name": "관뚜껑열사", "msg": "이게 되네? ㄷㄷ"},
		{"name": "선혈계주민", "msg": "조합 나왔다 ㄱㄱ"},
		{"name": "핏방울하츄핑", "msg": "ㄹㅇ 연결됨 ㄷㄷ"},
		{"name": "뱀파덕후99", "msg": "오 이거 쌔다"},
		{"name": "붉달", "msg": "시너지 🔥"},
		{"name": "심장박동중", "msg": "조합 존잘"},
		{"name": "피빨리는중", "msg": "ㅋㅋ 이거 사기 아냐"},
		{"name": "혈관미터기", "msg": "연결하니까 다르네"},
		{"name": "기혈목격자", "msg": "오 이 조합 좋은거임?"},
		{"name": "선혈왕귀환", "msg": "시너지 터지면 ㄷㄷ"},
		{"name": "핏물결", "msg": "ㄷㄷ 강해졌다"},
	],
	"clear": [
		{"name": "혈액형B형", "msg": "ㅋㅋㅋ 살았네 진짜"},
		{"name": "관뚜껑열사", "msg": "오 이번엔 클리어했네 ㄷㄷ"},
		{"name": "선혈계주민", "msg": "와 탈출했다!!"},
		{"name": "핏방울하츄핑", "msg": "ㄹㅇ? 클리어됨?"},
		{"name": "뱀파덕후99", "msg": "ㄷㄷ 진짜 살았네"},
		{"name": "붉달", "msg": "🎉🎉"},
		{"name": "심장박동중", "msg": "ㅋㅋ 이번엔 됐네"},
		{"name": "피빨리는중", "msg": "오 클리어 실화?"},
		{"name": "혈관미터기", "msg": "살아남았다 ㄷㄷ"},
		{"name": "기혈목격자", "msg": "탈출 성공 👏"},
		{"name": "선혈왕귀환", "msg": "ㄹㅇ 대단한데"},
		{"name": "핏물결", "msg": "ㅋㅋㅋ 살았다 살았어"},
	],
	"gameover": [
		{"name": "혈액형B형", "msg": "ㅋㅋㅋㅋ 역시나"},
		{"name": "관뚜껑열사", "msg": "그러게 조심하라 했잖아 ㅋㅋ"},
		{"name": "선혈계주민", "msg": "아 ㅠㅠ"},
		{"name": "핏방울하츄핑", "msg": "ㅋㅋ 죽었다"},
		{"name": "뱀파덕후99", "msg": "다시 ㄱㄱ"},
		{"name": "붉달", "msg": "ㅠㅠ"},
		{"name": "심장박동중", "msg": "역시 관이 ㅋㅋ"},
		{"name": "피빨리는중", "msg": "아깝긴 한데 ㅋㅋ"},
		{"name": "혈관미터기", "msg": "또 죽었네"},
		{"name": "기혈목격자", "msg": "다음판은 다를거야 아마"},
		{"name": "선혈왕귀환", "msg": "ㅋㅋ 또 도전"},
		{"name": "핏물결", "msg": "관 뚜껑 열렸다 ㅋㅋ"},
	],
	"idle": [
		{"name": "혈액형B형", "msg": "ㅋㅋ 혈체 저거 뭐임"},
		{"name": "관뚜껑열사", "msg": "저 노드 어케 쓰는거임?"},
		{"name": "선혈계주민", "msg": "재밌어보이는데"},
		{"name": "핏방울하츄핑", "msg": "이거 모바일 나와요?"},
		{"name": "뱀파덕후99", "msg": "시너지 조합 뭐가 제일 쌔요?"},
		{"name": "붉달", "msg": "👀"},
		{"name": "심장박동중", "msg": "저 혈체 4단계부터 다르네"},
		{"name": "피빨리는중", "msg": "재화 어케 빨리 모아요?"},
		{"name": "혈관미터기", "msg": "노드 몇개까지 놓을 수 있어요?"},
		{"name": "기혈목격자", "msg": "ㅋㅋ 관 색 변하네"},
		{"name": "선혈왕귀환", "msg": "이 게임 언제 출시함?"},
		{"name": "핏물결", "msg": "배경 분위기 좋다"},
		{"name": "혈장수집가", "msg": "저 혈체 귀엽긴 함 ㅋㅋ"},
		{"name": "밤의피츄", "msg": "ㅋㅋ 핏방울 튀기는거 존잼"},
		{"name": "혈액형A형", "msg": "시청자 채팅창 있었네"},
		{"name": "뱀파이어왕", "msg": "선혈계 분위기 ㄷㄷ"},
		{"name": "붉은달", "msg": "저거 노드 연결하면 선 나오네"},
		{"name": "심장터짐", "msg": "ㅋㅋ 혈체 개많아지는데"},
		{"name": "피의강", "msg": "재화 저거 핏방울임?"},
		{"name": "관수호자", "msg": "관 지켜야지 ㄱㄱ"},
		{"name": "혈관미터기", "msg": "노드 강화는 언제 나와요?"},
		{"name": "기혈목격자", "msg": "4단계 혈체 뭔가 달라보임"},
		{"name": "선혈왕귀환", "msg": "ㅋㅋ 이거 중독성 있겠는데"},
		{"name": "핏물결", "msg": "다음 스테이지 기대됨"},
		{"name": "혈장수집가", "msg": "슈퍼챗 언제 나와요 ㅋㅋ"},
	]
}

const MAX_VISIBLE_LINES: int = 10  # 넘어간 채팅은 사라짐
var _chat_label: RichTextLabel = null
var _idle_timer: float = 0.0
var _idle_interval: float = 3.0
var _idle_interval_min: float = 2.0
var _idle_interval_max: float = 5.0
var _ai_chat_enabled: bool = false
var _ai_chat_timer: float = 0.0
var _ai_chat_interval: float = 8.0
var _game_state: Dictionary = {}
var _last_name: String = ""
var _last_msg: String = ""
var _last_pool_index: Dictionary = {}


func _ready() -> void:
	add_to_group("chat_manager")


func setup(label: RichTextLabel) -> void:
	_chat_label = label


func set_idle_interval_range(min_val: float, max_val: float) -> void:
	_idle_interval_min = min_val
	_idle_interval_max = max_val


func update_game_state(state: Dictionary) -> void:
	_game_state = state


func _process(delta: float) -> void:
	_idle_timer += delta
	if _idle_timer >= _idle_interval:
		_idle_timer = 0.0
		_idle_interval = randf_range(_idle_interval_min, _idle_interval_max)
		send_chat("idle")

	if not _ai_chat_enabled:
		return
	_ai_chat_timer += delta
	if _ai_chat_timer >= _ai_chat_interval:
		_ai_chat_timer = 0.0
		_ai_chat_interval = randf_range(6.0, 12.0)
		_request_ai_chat()


func send_chat(event: String) -> void:
	if not _chat_label:
		return
	var pool: Array = _chat_pool.get(event, [])
	if pool.is_empty():
		return
	var last_idx: int = _last_pool_index.get(event, -1)
	var idx: int = randi() % pool.size()
	var attempts: int = 0
	while idx == last_idx and attempts < 5:
		idx = randi() % pool.size()
		attempts += 1
	_last_pool_index[event] = idx
	var msg: Dictionary = pool[idx]
	_add_message(msg.name, msg.msg)


func _add_message(name: String, msg: String) -> void:
	if not _chat_label:
		return
	if name == _last_name:
		return
	if msg == _last_msg:
		return
	_last_name = name
	_last_msg = msg
	var colors: Array = [
		"#FF6B6B", "#FF9F43", "#54A0FF",
		"#5F27CD", "#00D2D3", "#FF9FF3"
	]
	var color: String = colors[randi() % colors.size()]
	var text: String = "[color=%s]%s[/color]: %s\n" % [color, name, msg]
	_chat_label.append_text(text)
	# 화면 넘어간 채팅 제거 (최근 N줄만 유지)
	var lines: PackedStringArray = _chat_label.text.split("\n", false)
	if lines.size() > MAX_VISIBLE_LINES:
		var from_idx: int = lines.size() - MAX_VISIBLE_LINES
		_chat_label.text = "\n".join(lines.slice(from_idx, lines.size())) + "\n"
	call_deferred("_scroll_chat_to_bottom")


func _scroll_chat_to_bottom() -> void:
	if not _chat_label or not is_instance_valid(_chat_label):
		return
	# ScrollContainer 스크롤을 맨 아래로
	var scroll: ScrollContainer = _chat_label.get_parent() as ScrollContainer
	if scroll:
		var vbar: VScrollBar = scroll.get_v_scroll_bar()
		if vbar:
			scroll.scroll_vertical = int(vbar.max_value)


func _request_ai_chat() -> void:
	var state: Dictionary = _game_state
	var hp_ratio: float = state.get("hp_ratio", 1.0)
	var combo: int = state.get("combo", 0)
	var connected: bool = state.get("connected", false)
	var difficulty: int = state.get("difficulty", 0)
	var placed_nodes: int = state.get("placed_nodes", 0)
	var time_left: float = state.get("time_left", 120.0)
	var blood: int = state.get("blood", 0)

	# 상황별 우선순위로 채팅 선택
	if hp_ratio <= 0.15:
		send_chat("danger")
	elif hp_ratio <= 0.4:
		send_chat("hit")
	elif combo >= 5:
		send_chat("combo")
	elif combo >= 3:
		send_chat("combo")
	elif connected and difficulty >= 2:
		send_chat("synergy")
	elif time_left <= 30.0:
		_send_time_warning_chat()
	elif placed_nodes == 0:
		_send_no_node_chat()
	elif blood >= 50:
		_send_rich_chat()
	else:
		send_chat("idle")


func _send_time_warning_chat() -> void:
	var msgs: Array = [
		{"name": "심장박동중", "msg": "시간 얼마 안남았다 ㄷㄷ"},
		{"name": "혈관미터기", "msg": "30초 남았는데 버티나?"},
		{"name": "붉달", "msg": "시간 빠르다 진짜"},
		{"name": "관뚜껑열사", "msg": "곧 끝나네 ㄷㄷ"},
		{"name": "핏방울하츄핑", "msg": "탈출할 수 있을까 ㄷㄷ"},
	]
	var msg: Dictionary = msgs[randi() % msgs.size()]
	_add_message(msg.name, msg.msg)


func _send_no_node_chat() -> void:
	var msgs: Array = [
		{"name": "선혈계주민", "msg": "노드 안깔아도 됨? ㅋㅋ"},
		{"name": "혈액형B형", "msg": "노드 좀 배치해봐요"},
		{"name": "기혈목격자", "msg": "노드 없으면 힘들텐데"},
		{"name": "핏물결", "msg": "관 혼자 버팀? ㄷㄷ"},
	]
	var msg: Dictionary = msgs[randi() % msgs.size()]
	_add_message(msg.name, msg.msg)


func _send_rich_chat() -> void:
	var msgs: Array = [
		{"name": "혈장수집가", "msg": "재화 많이 모았네 ㄷㄷ"},
		{"name": "피의강", "msg": "재화 뭐에 쓸거야?"},
		{"name": "선혈왕귀환", "msg": "재화 부자네 ㅋㅋ"},
		{"name": "붉달", "msg": "슬롯 해금해 빨리"},
		{"name": "심장터짐", "msg": "재화 낭비하지 말고 ㄱㄱ"},
	]
	var msg: Dictionary = msgs[randi() % msgs.size()]
	_add_message(msg.name, msg.msg)
