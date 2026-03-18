extends Node
## 색상 상수 (모든 씬 공통)

# 배경
const BG_BASE: Color = Color(0.051, 0.0, 0.031, 1.0)      # #0D0008 전체 배경 (어둡게)
const BG_CENTER: Color = Color(0.102, 0.0, 0.082, 1.0)    # #1A0015 방사형 그라디언트 중심
const BG_PANEL: Color = Color(0.102, 0.0, 0.059, 1.0)     # #1A000F 패널/슬롯 배경 (CARD_BG와 동일)

# UI 라인
const LINE_DEFAULT: Color = Color(0.29, 0.0, 0.188, 1.0)  # #4A0030 기본 (어둡고 은은)
const LINE_HOVER: Color = Color(0.545, 0.0, 0.314, 1.0)   # #8B0050 활성/호버
const LINE_ACCENT: Color = Color(0.784, 0.0, 0.416, 1.0)  # #C8006A 강조 포인트 (최소화)

# 텍스트
const TEXT: Color = Color(0.784, 0.627, 0.722, 1.0)       # #C8A0B8 기본 (연한 로즈그레이)
const TEXT_SUB: Color = Color(0.478, 0.314, 0.408, 1.0)    # #7A5068 서브
const TITLE_ACCENT: Color = Color(1.0, 0.0, 0.667, 1.0)   # #FF00AA READY 타이틀

# 노드 카드
const CARD_BG: Color = Color(0.102, 0.0, 0.059, 1.0)      # #1A000F 카드 배경
const CARD_BORDER: Color = Color(0.29, 0.0, 0.188, 1.0)   # #4A0030 카드 테두리
const CARD_ACTIVE: Color = Color(0.784, 0.0, 0.416, 1.0)  # #C8006A 활성 카드

# 전투 시작 버튼
const BTN_BATTLE_BG: Color = Color(0.42, 0.0, 0.25, 1.0)  # #6B0040 배경
const BTN_BATTLE_HOVER: Color = Color(0.784, 0.0, 0.416, 1.0)  # #C8006A 호버
const BTN_BATTLE_TEXT: Color = Color(1.0, 0.816, 0.91, 1.0)   # #FFD0E8 텍스트

# 스크롤바
const SCROLL_TRACK: Color = Color(0.165, 0.0, 0.125, 1.0)   # #2A0020 트랙
const SCROLL_INDICATOR: Color = Color(0.784, 0.0, 0.416, 1.0)  # #C8006A 인디케이터
const SCROLL_ARROW: Color = Color(1.0, 0.0, 0.667, 1.0)    # #FF00AA 화살표

# 하위 호환
const LINE_ACTIVE: Color = LINE_ACCENT
const COLOR_BLOOD: Color = Color(1.0, 0.2, 0.4, 1.0)      # #FF3366 혈액/데미지
const COLOR_RARE: Color = LINE_ACCENT
const COLOR_S: Color = Color(1.0, 0.843, 0.0, 1.0)        # #FFD700 S급
