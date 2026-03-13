extends CanvasLayer
## Class selection UI shown at level 5.
## Player chooses between Slingshot, Fighter, or Apprentice.

@onready var panel: PanelContainer = $Panel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/Choices
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

const LOCKED_CLASSES = ["fighter", "apprentice"]

const CLASS_DATA = {
	"slingshot": {
		"name": "Slingshot",
		"description": "Evolves into Archer or Thrower\nFast ranged damage or AoE power",
		"hero_scene": "res://scenes/hero_archer.tscn",
		"hero_data": "res://resources/heroes/archer.tres",
		"icon_color": Color.CYAN,
		"portrait_path": "res://art/portraits/archer_portrait.png"
	},
	"fighter": {
		"name": "Fighter",
		"description": "Evolves into Knight → Berserker → Warlord\nTanky melee bruiser",
		"hero_scene": "res://scenes/hero_noob.tscn",
		"hero_data": "res://resources/heroes/noob.tres",
		"icon_color": Color.ORANGE,
		"portrait_path": "res://art/portraits/fighter_portrait.png"
	},
	"apprentice": {
		"name": "Apprentice",
		"description": "Evolves into Mage → Warlock → Archmage\nAoE magic damage",
		"hero_scene": "res://scenes/hero_wizard.tscn",
		"hero_data": "res://resources/heroes/wizard.tres",
		"icon_color": Color.PURPLE,
		"portrait_path": "res://art/portraits/apprentice_portrait.png"
	}
}

func _ready() -> void:
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = "Choose Your Class!"
	title_label.add_theme_font_size_override("font_size", 32)

func show_class_selection() -> void:
	# Clear old choices
	for child in choices_container.get_children():
		child.queue_free()
	
	# Show panel
	panel.visible = true
	
	# Create class buttons with portraits
	for class_key in ["slingshot", "fighter", "apprentice"]:
		var class_info = CLASS_DATA[class_key]
		var is_locked = class_key in LOCKED_CLASSES
		var btn = Button.new()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.custom_minimum_size = Vector2(600, 140)

		# Style the button
		var btn_color = Color.GRAY if is_locked else class_info.icon_color
		var style = StyleBoxFlat.new()
		style.bg_color = Color(btn_color, 0.1 if is_locked else 0.2)
		style.border_color = Color(btn_color, 0.4 if is_locked else 1.0)
		style.set_border_width_all(3)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", style)

		if is_locked:
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", style)
		else:
			var hover_style = style.duplicate()
			hover_style.bg_color = Color(btn_color, 0.4)
			btn.add_theme_stylebox_override("hover", hover_style)

			var pressed_style = style.duplicate()
			pressed_style.bg_color = Color(btn_color, 0.6)
			btn.add_theme_stylebox_override("pressed", pressed_style)

		# HBox: portrait + text
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 16)
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if is_locked:
			hbox.modulate = Color(1, 1, 1, 0.4)

		# Portrait
		var portrait_tex = load(class_info.portrait_path) as Texture2D
		if portrait_tex:
			var portrait = TextureRect.new()
			portrait.texture = portrait_tex
			portrait.custom_minimum_size = Vector2(100, 100)
			portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(portrait)

		# Text (name + description)
		var text_vbox = VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 4)

		var name_lbl = Label.new()
		name_lbl.text = class_info.name + (" — Coming Soon" if is_locked else "")
		name_lbl.add_theme_font_size_override("font_size", 24)
		name_lbl.add_theme_color_override("font_color", Color.GRAY if is_locked else class_info.icon_color)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = class_info.description
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if is_locked else Color(0.8, 0.8, 0.8))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(desc_lbl)

		hbox.add_child(text_vbox)
		btn.add_child(hbox)

		if not is_locked:
			var captured_key = class_key
			btn.pressed.connect(func(): _select_class(captured_key))

		choices_container.add_child(btn)
	
	# Pause the game
	GameManager.pause_game()

func _select_class(class_key: String) -> void:
	AudioManager.play("click")
	var class_info = CLASS_DATA[class_key]
	
	# Load the new hero scene
	var hero_scene = load(class_info.hero_scene)
	if hero_scene:
		# Swap to new hero class
		GameManager.swap_hero(hero_scene)
		
		# Set hero class meta
		if GameManager.active_hero:
			GameManager.active_hero.set_meta("hero_class", class_key)
			GameManager.active_hero.set_meta("hero_branch", class_key)
			GameManager.active_hero.set_meta("hero_evolution_tier", 1)
	
	# Emit class selected event
	GameEvents.class_selected.emit(class_key, class_info)
	
	# Hide UI
	panel.visible = false
	GameManager.resume_game()
