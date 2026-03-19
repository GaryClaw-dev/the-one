extends Node2D
## Wolf companion that roams the map hunting and attacking enemies.

var hero: Node2D
var damage: float = 5.0
var move_speed: float = 80.0
var is_dire: bool = false

var _target: Node2D = null
var _attacking: bool = false
var _slash_sprite: Sprite2D
var _wolf_sprite: Sprite2D
var _retarget_timer: float = 0.0
const RETARGET_INTERVAL: float = 0.3
const ATTACK_RANGE: float = 25.0

func _ready() -> void:
	_wolf_sprite = $Sprite2D
	_slash_sprite = $SlashSprite
	_slash_sprite.visible = false
	_slash_sprite.scale = Vector2(0.03, 0.03)
	if is_dire:
		var dire_tex = load("res://art/companion/dire_wolf.png") as Texture2D
		if dire_tex:
			_wolf_sprite.texture = dire_tex
			_wolf_sprite.scale = Vector2(0.05, 0.05)  # Slightly bigger

func _process(delta: float) -> void:
	if _attacking:
		return

	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget_timer = RETARGET_INTERVAL
		_target = _find_nearest_enemy()

	if not is_instance_valid(_target):
		_target = null
		# Idle: drift back toward hero
		if is_instance_valid(hero):
			var dir = (hero.global_position - global_position)
			if dir.length() > 40.0:
				global_position += dir.normalized() * move_speed * 0.5 * delta
		return

	var dir = (_target.global_position - global_position)
	var dist = dir.length()

	# Flip sprite based on movement direction
	_wolf_sprite.flip_h = dir.x < 0.0

	if dist <= ATTACK_RANGE:
		_do_attack(_target)
	else:
		global_position += dir.normalized() * move_speed * delta

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_dist: float = INF
	for e in enemies:
		if not is_instance_valid(e) or not e is Node2D:
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		var d = global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best

func _do_attack(target: Node2D) -> void:
	_attacking = true
	var target_pos = target.global_position

	var tween = create_tween()
	# Lunge at target
	tween.tween_property(self, "global_position", target_pos, 0.1).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): if is_instance_valid(target): _hit_target(target))
	tween.tween_interval(0.15)
	tween.tween_callback(func(): _attacking = false)

func _hit_target(target: Node2D) -> void:
	_slash_sprite.visible = true
	if is_instance_valid(target) and target.has_method("take_damage"):
		var dealt = target.take_damage(damage, false, hero)
		GameEvents.damage_dealt.emit(target, dealt, false, "normal")
	get_tree().create_timer(0.15).timeout.connect(func(): _slash_sprite.visible = false)
