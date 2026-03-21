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
		"description": "Evolves into Archer or Crossbow\nPrecision marksman or mechanical bolts",
		"hero_scene": "res://scenes/hero_archer.tscn",
		"hero_data": "res://resources/heroes/archer.tres",
		"icon_color": Color.CYAN,
		"portrait_path": "res://art/portraits/slingshot_portrait.png"
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

var _dimmer: ColorRect = null

func _ready() -> void:
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	# Style the title
	title_label.text = "CHOOSE YOUR CLASS"
	title_label.add_theme_font_size_override("font_size", UIConst.FONT_TITLE)
	title_label.add_theme_color_override("font_color", UIConst.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Style the panel background
	panel.add_theme_stylebox_override("panel", UIConst.make_panel_style())

func show_class_selection() -> void:
	# Clear old choices
	for child in choices_container.get_children():
		child.queue_free()

	# Add background dimmer
	_show_dimmer()

	# Show panel
	panel.visible = true

	# Animate panel entrance
	UIConst.animate_entrance(panel, get_tree(), 0.0, 0.3)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Your journey begins here"
	subtitle.add_theme_font_size_override("font_size", UIConst.FONT_DESC)
	subtitle.add_theme_color_override("font_color", UIConst.TEXT_TERTIARY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choices_container.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choices_container.add_child(spacer)

	# Create class buttons with portraits
	var btn_index := 0
	for class_key in ["slingshot", "fighter", "apprentice"]:
		var class_info = CLASS_DATA[class_key]
		var is_locked = class_key in LOCKED_CLASSES
		var btn = Button.new()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.custom_minimum_size = UIConst.CLASS_BTN_SIZE

		# Style the button
		var btn_color = Color.GRAY if is_locked else class_info.icon_color
		var style = UIConst.make_card_style(btn_color)
		if is_locked:
			style.bg_color = Color(btn_color, 0.08)
			style.border_color = Color(btn_color, 0.3)
		else:
			style.bg_color = Color(btn_color, 0.15)
			style.border_color = Color(btn_color, 0.8)
		btn.add_theme_stylebox_override("normal", style)

		if is_locked:
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", style)
		else:
			btn.add_theme_stylebox_override("hover", UIConst.make_hover_style(btn_color))
			btn.add_theme_stylebox_override("pressed", UIConst.make_pressed_style(btn_color))

		# HBox: portrait + text
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", UIConst.SPACE_MD)
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if is_locked:
			hbox.modulate = Color(1, 1, 1, 0.4)

		# Portrait
		var portrait_tex = load(class_info.portrait_path) as Texture2D
		if portrait_tex:
			var portrait = TextureRect.new()
			portrait.texture = portrait_tex
			portrait.custom_minimum_size = UIConst.ICON_PORTRAIT
			portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(portrait)

		# Text (name + description)
		var text_vbox = VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 6)

		var name_lbl = Label.new()
		name_lbl.text = class_info.name + ("  —  Coming Soon" if is_locked else "")
		name_lbl.add_theme_font_size_override("font_size", UIConst.FONT_EVO_NAME)
		name_lbl.add_theme_color_override("font_color", Color.GRAY if is_locked else class_info.icon_color)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = class_info.description
		desc_lbl.add_theme_font_size_override("font_size", UIConst.FONT_DESC)
		desc_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45) if is_locked else UIConst.TEXT_SECONDARY)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(desc_lbl)

		hbox.add_child(text_vbox)
		btn.add_child(hbox)

		if not is_locked:
			var captured_key = class_key
			btn.pressed.connect(func(): _select_class(captured_key))
			UIConst.add_press_feedback(btn, get_tree())

		choices_container.add_child(btn)

		# Staggered entrance animation
		UIConst.animate_entrance(btn, get_tree(), btn_index * 0.06)
		btn_index += 1

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
			GameManager.active_hero.set_meta("class_selected", true)
			GameManager.active_hero.set_meta("hero_evolution_tier", 1)

	# Emit class selected event
	GameEvents.class_selected.emit(class_key, class_info)

	# Hide UI
	_hide_dimmer()
	panel.visible = false
	GameManager.resume_game()

func _show_dimmer() -> void:
	if _dimmer:
		return
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = UIConst.DIMMER_COLOR
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dimmer)
	move_child(_dimmer, 0)
	UIConst.animate_dimmer(_dimmer, get_tree())

func _hide_dimmer() -> void:
	if _dimmer:
		_dimmer.queue_free()
		_dimmer = null
