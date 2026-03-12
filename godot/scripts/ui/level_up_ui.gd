extends CanvasLayer
## Level-up choice panel. Shows 3 random abilities to pick from.

@onready var panel: PanelContainer = $Panel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/Choices

var _hero: HeroBase = null

func _ready() -> void:
	panel.visible = false
	GameEvents.level_up.connect(_on_level_up)
	GameEvents.game_started.connect(func():
		_hero = get_tree().get_first_node_in_group("hero") as HeroBase
	)

func _on_level_up(_new_level: int) -> void:
	if not _hero:
		return

	var abilities = ItemDatabase.get_random_abilities(3, _hero)
	if abilities.is_empty():
		return

	_show_choices(abilities)

func _show_choices(abilities: Array[AbilityData]) -> void:
	GameManager.pause_game()

	# Clear old choices
	for child in choices_container.get_children():
		child.queue_free()

	# Create choice buttons
	for ability in abilities:
		var btn = Button.new()
		var current_level = _hero.get_ability_level(ability)
		var new_level = current_level + 1

		var label_text = ability.ability_name
		if current_level > 0:
			label_text += " (Lv.%d)" % new_level

		btn.text = label_text
		btn.custom_minimum_size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 18)

		# Color by rarity
		var style = StyleBoxFlat.new()
		style.bg_color = Color(Rarity.get_color(ability.rarity), 0.2)
		style.border_color = Rarity.get_color(ability.rarity)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style = style.duplicate()
		hover_style.bg_color = Color(Rarity.get_color(ability.rarity), 0.4)
		btn.add_theme_stylebox_override("hover", hover_style)

		var captured = ability
		btn.pressed.connect(func(): _select_ability(captured))

		choices_container.add_child(btn)

		# Add description label
		if ability.description:
			var desc = Label.new()
			desc.text = "  " + ability.description
			desc.add_theme_font_size_override("font_size", 13)
			desc.modulate = Color(0.7, 0.7, 0.7)
			choices_container.add_child(desc)

	panel.visible = true

func _select_ability(ability: AbilityData) -> void:
	_hero.add_ability(ability)
	_hide()

func _hide() -> void:
	panel.visible = false
	GameManager.resume_game()
