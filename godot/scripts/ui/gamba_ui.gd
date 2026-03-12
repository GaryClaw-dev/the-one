extends CanvasLayer
## Gamba slot machine UI. Spins icons, reveals result, keep/reroll.

@onready var panel: PanelContainer = $Panel
@onready var slot_icon: TextureRect = $Panel/VBox/SlotIcon
@onready var result_name: Label = $Panel/VBox/ResultName
@onready var result_desc: Label = $Panel/VBox/ResultDesc
@onready var result_rarity: Label = $Panel/VBox/ResultRarity
@onready var keep_btn: Button = $Panel/VBox/Buttons/KeepBtn
@onready var reroll_btn: Button = $Panel/VBox/Buttons/RerollBtn
@onready var flash_rect: ColorRect = $FlashRect

var _current_item: ItemData = null
var _gamba_system: Node = null

func _ready() -> void:
	panel.visible = false
	if flash_rect:
		flash_rect.visible = false

	GameEvents.gamba_roll_started.connect(_on_gamba_started)
	keep_btn.pressed.connect(_on_keep)
	reroll_btn.pressed.connect(_on_reroll)

func _on_gamba_started(item: Resource) -> void:
	if not item is ItemData:
		return
	_current_item = item
	_gamba_system = get_tree().current_scene.get_node_or_null("GambaSystem")

	GameManager.pause_game()
	panel.visible = true

	# Spin animation then reveal
	_start_spin(item)

func _start_spin(result: ItemData) -> void:
	# Hide result during spin
	result_name.text = "???"
	result_desc.text = ""
	result_rarity.text = "ROLLING..."
	result_rarity.modulate = Color.WHITE
	keep_btn.visible = false
	reroll_btn.visible = false

	# Animate with tween
	var tween = create_tween()
	var spin_time = 1.5
	var flashes = 15

	for i in range(flashes):
		var t = float(i) / flashes
		var delay = spin_time * t * t  # Decelerate
		tween.tween_callback(func():
			result_rarity.text = Rarity.get_name(randi() % 5).to_upper()
			result_rarity.modulate = Rarity.get_color(randi() % 5)
		).set_delay(delay / flashes if i > 0 else 0.05)

	# Final reveal
	tween.tween_callback(func(): _show_result(result)).set_delay(0.3)

func _show_result(item: ItemData) -> void:
	result_name.text = item.get_display_name()
	result_name.modulate = Rarity.get_color(item.rarity)
	result_desc.text = item.description
	result_rarity.text = Rarity.get_name(item.rarity).to_upper()
	result_rarity.modulate = Rarity.get_color(item.rarity)

	if slot_icon and item.icon:
		slot_icon.texture = item.icon

	# Rarity effects
	match item.rarity:
		Rarity.Type.EPIC:
			_flash_screen(Rarity.get_color(Rarity.Type.EPIC), 0.3)
		Rarity.Type.LEGENDARY:
			_flash_screen(Rarity.get_color(Rarity.Type.LEGENDARY), 0.5)

	# Show buttons
	keep_btn.visible = true
	var rerolls = _gamba_system.rerolls_remaining if _gamba_system else 0
	reroll_btn.visible = rerolls > 0
	reroll_btn.text = "REROLL (%d)" % rerolls

func _on_keep() -> void:
	if not _current_item:
		return

	var hero = get_tree().get_first_node_in_group("hero") as HeroBase
	if hero:
		hero.add_item(_current_item)

	if _gamba_system and _gamba_system.has_method("accept_current_roll"):
		_gamba_system.accept_current_roll()

	_hide()

func _on_reroll() -> void:
	if not _gamba_system:
		return
	var new_item: ItemData = _gamba_system.reroll()
	if new_item:
		_current_item = new_item
		_start_spin(new_item)

func _hide() -> void:
	panel.visible = false
	_current_item = null
	GameManager.resume_game()

func _flash_screen(color: Color, duration: float) -> void:
	if not flash_rect:
		return
	flash_rect.visible = true
	flash_rect.color = Color(color.r, color.g, color.b, 0.5)
	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, duration)
	tween.tween_callback(func(): flash_rect.visible = false)
