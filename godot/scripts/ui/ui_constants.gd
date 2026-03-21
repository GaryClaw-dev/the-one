class_name UIConst
## Single source of truth for all UI design tokens, style builders, and animation helpers.

# ── Color Palette ────────────────────────────────────────────────────
const BG_DARK = Color(0.08, 0.08, 0.12, 0.95)
const BG_DARKER = Color(0.06, 0.06, 0.1, 0.95)
const BG_ELEVATED = Color(0.05, 0.05, 0.08, 0.65)

const GOLD = Color(0.95, 0.85, 0.4)
const GOLD_BORDER = Color(0.95, 0.85, 0.4, 0.6)
const GOLD_DIM = Color(0.95, 0.85, 0.4, 0.25)

const TEXT_PRIMARY = Color(0.9, 0.9, 0.85)
const TEXT_SECONDARY = Color(0.75, 0.75, 0.7)
const TEXT_TERTIARY = Color(0.6, 0.6, 0.55)
const STAT_GREEN = Color(0.55, 0.9, 0.55)
const PASSIVE_PURPLE = Color(0.7, 0.6, 0.9)
const DIMMER_COLOR = Color(0, 0, 0, 0.7)

# ── Typography Scale ─────────────────────────────────────────────────
const FONT_TITLE = 36
const FONT_ABILITY_NAME = 26
const FONT_EVO_NAME = 24
const FONT_DESC = 17
const FONT_STAT_BONUS = 15
const FONT_PASSIVE = 14
const FONT_SUBTITLE = 17
const FONT_HUD_LEVEL = 22
const FONT_HUD_WAVE = 18
const FONT_HUD_KILL = 16
const FONT_HUD_STREAK = 22
const FONT_HUD_STAT_NAME = 13
const FONT_HUD_STAT_VAL = 13
const FONT_HUD_PANEL_TITLE = 14
const FONT_HUD_ITEM = 12
const FONT_HUD_CLASS = 17
const FONT_GAMEOVER_TITLE = 32
const FONT_GAMEOVER_STATS = 18
const FONT_GAMEOVER_SHARDS = 24
const FONT_GAMEOVER_ABILITIES = 15
const FONT_START_TITLE = 72
const FONT_START_TAP = 32

# ── Spacing (8px grid) ──────────────────────────────────────────────
const SPACE_XS = 4
const SPACE_SM = 8
const SPACE_MD = 16
const SPACE_LG = 24
const SPACE_XL = 32

# ── Button / Card Sizes ─────────────────────────────────────────────
const CHOICE_BTN_SIZE = Vector2(560, 120)
const CLASS_BTN_SIZE = Vector2(620, 140)
const EVO_CARD_SIZE = Vector2(300, 440)
const GAMEOVER_BTN_SIZE = Vector2(160, 64)

# ── Icon Sizes ───────────────────────────────────────────────────────
const ICON_ABILITY = Vector2(72, 72)
const ICON_ITEM = Vector2(64, 64)
const ICON_PORTRAIT = Vector2(104, 104)
const ICON_EVO_PORTRAIT = Vector2(80, 80)

# ── Panel Constants ──────────────────────────────────────────────────
const PANEL_CORNER_RADIUS = 16
const PANEL_BORDER_WIDTH = 2
const PANEL_CONTENT_MARGIN = 20
const CARD_CORNER_RADIUS = 10
const CARD_BORDER_WIDTH = 2
const CARD_CONTENT_MARGIN = 12

# ── Style Builders ───────────────────────────────────────────────────

static func make_panel_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = BG_DARK
	s.border_color = GOLD_BORDER
	s.set_border_width_all(PANEL_BORDER_WIDTH)
	s.set_corner_radius_all(PANEL_CORNER_RADIUS)
	s.set_content_margin_all(PANEL_CONTENT_MARGIN)
	return s

static func make_card_style(color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(color, 0.12)
	s.border_color = Color(color, 0.7)
	s.set_border_width_all(CARD_BORDER_WIDTH)
	s.set_corner_radius_all(CARD_CORNER_RADIUS)
	s.set_content_margin_all(CARD_CONTENT_MARGIN)
	return s

static func make_hover_style(color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(color, 0.3)
	s.border_color = color
	s.set_border_width_all(CARD_BORDER_WIDTH)
	s.set_corner_radius_all(CARD_CORNER_RADIUS)
	s.set_content_margin_all(CARD_CONTENT_MARGIN)
	return s

static func make_pressed_style(color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(color, 0.45)
	s.border_color = color
	s.set_border_width_all(CARD_BORDER_WIDTH)
	s.set_corner_radius_all(CARD_CORNER_RADIUS)
	s.set_content_margin_all(CARD_CONTENT_MARGIN)
	return s

# ── Rarity Glow ─────────────────────────────────────────────────────

static func apply_rarity_glow(style: StyleBoxFlat, rarity: int, color: Color) -> void:
	if rarity == Rarity.Type.EPIC:
		style.shadow_color = Color(color, 0.35)
		style.shadow_size = 4
	elif rarity == Rarity.Type.LEGENDARY:
		style.shadow_color = Color(color, 0.5)
		style.shadow_size = 6

# ── Animation Helpers ────────────────────────────────────────────────

static func animate_entrance(node: Control, tree: SceneTree, delay: float = 0.0, duration: float = 0.25) -> void:
	node.scale = Vector2(0.85, 0.85)
	node.modulate.a = 0.0
	node.pivot_offset = node.size / 2.0
	var tw = tree.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.6)

static func animate_dimmer(dimmer: ColorRect, tree: SceneTree, duration: float = 0.2) -> void:
	var target_alpha = dimmer.color.a
	dimmer.color.a = 0.0
	var tw = tree.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(dimmer, "color:a", target_alpha, duration)

static func add_press_feedback(btn: Button, tree: SceneTree) -> void:
	btn.button_down.connect(func():
		var tw = tree.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		btn.pivot_offset = btn.size / 2.0
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.05)
	)
	btn.button_up.connect(func():
		var tw = tree.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
