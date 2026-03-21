extends Control
## Standalone preview scene for the UI visual refresh.
## Run this scene directly (F6) to see new styling without modifying the game.

func _ready() -> void:
	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07)
	add_child(bg)

	# Scroll container for all previews
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 32)
	scroll.add_child(main_vbox)

	# Top margin
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 16)
	main_vbox.add_child(top_spacer)

	_add_section_title(main_vbox, "FONT SIZE COMPARISON")
	_add_font_comparison(main_vbox)

	_add_section_title(main_vbox, "MOCK LEVEL-UP PANEL (3 ABILITIES)")
	_add_mock_level_up(main_vbox)

	_add_section_title(main_vbox, "MOCK BOSS REWARD PANEL")
	_add_mock_boss_reward(main_vbox)

	_add_section_title(main_vbox, "RARITY GLOW DEMO")
	_add_rarity_glow_demo(main_vbox)

	# Bottom margin
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(bottom_spacer)

func _add_section_title(parent: Control, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func _add_font_comparison(parent: Control) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 48)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	# Old sizes
	var old_vbox = VBoxContainer.new()
	old_vbox.add_theme_constant_override("separation", 8)
	var old_title = Label.new()
	old_title.text = "BEFORE"
	old_title.add_theme_font_size_override("font_size", 16)
	old_title.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	old_vbox.add_child(old_title)
	_add_font_line(old_vbox, "Title: 28px", 28, UIConst.GOLD)
	_add_font_line(old_vbox, "Ability Name: 19px", 19, Color.CYAN)
	_add_font_line(old_vbox, "Description: 14px", 14, UIConst.TEXT_SECONDARY)
	_add_font_line(old_vbox, "Stats: 12px", 12, UIConst.STAT_GREEN)
	_add_font_line(old_vbox, "Passives: 11px", 11, UIConst.PASSIVE_PURPLE)
	hbox.add_child(old_vbox)

	# New sizes
	var new_vbox = VBoxContainer.new()
	new_vbox.add_theme_constant_override("separation", 8)
	var new_title = Label.new()
	new_title.text = "AFTER"
	new_title.add_theme_font_size_override("font_size", 16)
	new_title.add_theme_color_override("font_color", Color(0.3, 0.6, 0.3))
	new_vbox.add_child(new_title)
	_add_font_line(new_vbox, "Title: %dpx" % UIConst.FONT_TITLE, UIConst.FONT_TITLE, UIConst.GOLD)
	_add_font_line(new_vbox, "Ability Name: %dpx" % UIConst.FONT_ABILITY_NAME, UIConst.FONT_ABILITY_NAME, Color.CYAN)
	_add_font_line(new_vbox, "Description: %dpx" % UIConst.FONT_DESC, UIConst.FONT_DESC, UIConst.TEXT_SECONDARY)
	_add_font_line(new_vbox, "Stats: %dpx" % UIConst.FONT_STAT_BONUS, UIConst.FONT_STAT_BONUS, UIConst.STAT_GREEN)
	_add_font_line(new_vbox, "Passives: %dpx" % UIConst.FONT_PASSIVE, UIConst.FONT_PASSIVE, UIConst.PASSIVE_PURPLE)
	hbox.add_child(new_vbox)

func _add_font_line(parent: Control, text: String, size: int, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

func _add_mock_level_up(parent: Control) -> void:
	# Panel container
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UIConst.make_panel_style())

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UIConst.SPACE_SM)

	# Title
	var title = Label.new()
	title.text = "LEVEL UP"
	title.add_theme_font_size_override("font_size", UIConst.FONT_TITLE)
	title.add_theme_color_override("font_color", UIConst.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Mock abilities: Common, Epic, Legendary
	var mock_data = [
		{"name": "Multishot  Lv.3", "desc": "Fire 2 additional projectiles per attack", "rarity": Rarity.Type.COMMON, "color": Rarity.get_color(Rarity.Type.COMMON)},
		{"name": "Chain Lightning", "desc": "Attacks chain to 2 nearby enemies for 60% damage", "rarity": Rarity.Type.EPIC, "color": Rarity.get_color(Rarity.Type.EPIC)},
		{"name": "Phoenix Rebirth", "desc": "Revive once per run with 50% HP and a fire burst", "rarity": Rarity.Type.LEGENDARY, "color": Rarity.get_color(Rarity.Type.LEGENDARY)},
	]

	for i in mock_data.size():
		var data = mock_data[i]
		var btn = _build_ability_card(data.name, data.desc, data.rarity, data.color)
		vbox.add_child(btn)
		# Staggered entrance animation
		UIConst.animate_entrance(btn, get_tree(), i * 0.06)
		UIConst.add_press_feedback(btn, get_tree())

	panel.add_child(vbox)
	parent.add_child(panel)

	# Animate the panel itself
	UIConst.animate_entrance(panel, get_tree(), 0.0, 0.3)

func _build_ability_card(ability_name: String, desc: String, rarity: int, color: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = UIConst.CHOICE_BTN_SIZE

	var style = UIConst.make_card_style(color)
	UIConst.apply_rarity_glow(style, rarity, color)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", UIConst.make_hover_style(color))
	btn.add_theme_stylebox_override("pressed", UIConst.make_pressed_style(color))

	var focus_style = style.duplicate()
	focus_style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("focus", focus_style)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 14)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Placeholder icon
	var icon_rect = ColorRect.new()
	icon_rect.custom_minimum_size = UIConst.ICON_ABILITY
	icon_rect.color = Color(color, 0.3)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_rect)

	var text_vbox = VBoxContainer.new()
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 4)

	var name_lbl = Label.new()
	name_lbl.text = ability_name
	name_lbl.add_theme_font_size_override("font_size", UIConst.FONT_ABILITY_NAME)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", UIConst.FONT_DESC)
	desc_lbl.add_theme_color_override("font_color", UIConst.TEXT_SECONDARY)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(desc_lbl)

	hbox.add_child(text_vbox)
	btn.add_child(hbox)
	return btn

func _add_mock_boss_reward(parent: Control) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UIConst.make_panel_style())

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UIConst.SPACE_SM)

	var title = Label.new()
	title.text = "BOSS DEFEATED"
	title.add_theme_font_size_override("font_size", UIConst.FONT_TITLE)
	title.add_theme_color_override("font_color", UIConst.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Choose a reward"
	subtitle.add_theme_font_size_override("font_size", UIConst.FONT_SUBTITLE)
	subtitle.add_theme_color_override("font_color", UIConst.TEXT_TERTIARY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var mock_items = [
		{"name": "[Rare]  Vampiric Blade", "desc": "Heal 3% of damage dealt", "mods": "+3% Lifesteal  |  +10% ATK", "rarity": Rarity.Type.RARE, "color": Rarity.get_color(Rarity.Type.RARE)},
		{"name": "[Epic]  Storm Shield", "desc": "Lightning strikes nearby enemies every 5s", "mods": "+15% Armor  |  +20 Thorns", "rarity": Rarity.Type.EPIC, "color": Rarity.get_color(Rarity.Type.EPIC)},
	]

	for i in mock_items.size():
		var data = mock_items[i]
		var btn = Button.new()
		btn.custom_minimum_size = UIConst.CHOICE_BTN_SIZE

		var style = UIConst.make_card_style(data.color)
		UIConst.apply_rarity_glow(style, data.rarity, data.color)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", UIConst.make_hover_style(data.color))
		btn.add_theme_stylebox_override("pressed", UIConst.make_pressed_style(data.color))

		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 14)
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var icon_rect = ColorRect.new()
		icon_rect.custom_minimum_size = UIConst.ICON_ITEM
		icon_rect.color = Color(data.color, 0.3)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_rect)

		var text_vbox = VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 3)

		var name_lbl = Label.new()
		name_lbl.text = data.name
		name_lbl.add_theme_font_size_override("font_size", UIConst.FONT_ABILITY_NAME)
		name_lbl.add_theme_color_override("font_color", data.color)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = data.desc
		desc_lbl.add_theme_font_size_override("font_size", UIConst.FONT_DESC)
		desc_lbl.add_theme_color_override("font_color", UIConst.TEXT_SECONDARY)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(desc_lbl)

		var mod_lbl = Label.new()
		mod_lbl.text = data.mods
		mod_lbl.add_theme_font_size_override("font_size", UIConst.FONT_STAT_BONUS)
		mod_lbl.add_theme_color_override("font_color", UIConst.STAT_GREEN)
		mod_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(mod_lbl)

		hbox.add_child(text_vbox)
		btn.add_child(hbox)
		vbox.add_child(btn)

		UIConst.animate_entrance(btn, get_tree(), i * 0.06)
		UIConst.add_press_feedback(btn, get_tree())

	panel.add_child(vbox)
	parent.add_child(panel)
	UIConst.animate_entrance(panel, get_tree(), 0.0, 0.3)

func _add_rarity_glow_demo(parent: Control) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	var rarities = [
		{"name": "Common", "type": Rarity.Type.COMMON},
		{"name": "Uncommon", "type": Rarity.Type.UNCOMMON},
		{"name": "Rare", "type": Rarity.Type.RARE},
		{"name": "Epic", "type": Rarity.Type.EPIC},
		{"name": "Legendary", "type": Rarity.Type.LEGENDARY},
	]

	for data in rarities:
		var color = Rarity.get_color(data.type)
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(120, 80)
		var style = UIConst.make_card_style(color)
		UIConst.apply_rarity_glow(style, data.type, color)
		card.add_theme_stylebox_override("panel", style)

		var lbl = Label.new()
		lbl.text = data.name
		lbl.add_theme_font_size_override("font_size", UIConst.FONT_STAT_BONUS)
		lbl.add_theme_color_override("font_color", color)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(lbl)
		hbox.add_child(card)
