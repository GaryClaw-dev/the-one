extends Node
## Autoloaded as "GameManager". Controls game state and flow.

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: int = State.MENU
var active_hero: Node2D = null
var _pause_depth: int = 0

func start_game(hero_scene: PackedScene) -> void:
	current_state = State.PLAYING
	_pause_depth = 0
	get_tree().paused = false

	# Spawn hero at origin
	if hero_scene:
		active_hero = hero_scene.instantiate()
		active_hero.position = Vector2.ZERO
		get_tree().current_scene.add_child(active_hero)

	GameEvents.game_started.emit()

func pause_game() -> void:
	_pause_depth += 1
	if _pause_depth == 1:
		current_state = State.PAUSED
		get_tree().paused = true
		GameEvents.game_paused.emit(true)

func resume_game() -> void:
	_pause_depth = maxi(0, _pause_depth - 1)
	if _pause_depth == 0:
		current_state = State.PLAYING
		get_tree().paused = false
		GameEvents.game_paused.emit(false)

func toggle_pause() -> void:
	if _pause_depth > 0:
		resume_game()
	else:
		pause_game()

func game_over() -> void:
	current_state = State.GAME_OVER

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state == State.PLAYING:
		toggle_pause()
