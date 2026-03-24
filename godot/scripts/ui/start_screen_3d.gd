extends CanvasLayer
## Start screen for 3D game. Same UI, spawns 3D hero.

var _overlay: ColorRect
var _noob_scene: PackedScene
var _started: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50

	_noob_scene = preload("res://scenes/hero_noob_3d.tscn")

	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.05, 0.05, 0.1, 0.95)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)

	var main_vbox = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 40)
	center.add_child(main_vbox)

	var title = Label.new()
	title.text = "THE ONE"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "[3D MODE]"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(subtitle)

	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(title, "scale", Vector2(1.02, 1.02), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(spacer)

	var tap_label = Label.new()
	tap_label.text = "TAP TO START"
	tap_label.add_theme_font_size_override("font_size", 28)
	tap_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55))
	tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(tap_label)

	var tween = create_tween().set_loops()
	tween.tween_property(tap_label, "modulate:a", 0.4, 0.8)
	tween.tween_property(tap_label, "modulate:a", 1.0, 0.8)

	_overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_start_game()
		elif event is InputEventScreenTouch and event.pressed:
			_start_game()
	)

	get_tree().paused = true

func _start_game() -> void:
	if _started:
		return
	_started = true
	AudioManager.play("game_start")
	get_tree().paused = false

	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		GameManager.start_game(_noob_scene)
		queue_free()
	)
