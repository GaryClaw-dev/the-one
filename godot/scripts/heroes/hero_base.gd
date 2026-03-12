class_name HeroBase
extends CharacterBody2D
## Abstract base for all heroes. Stationary, auto-attacks nearest enemy.

@export var hero_data: HeroData

var stats: StatSystem = StatSystem.new()
var current_health: float
var max_health: float
var kill_streak: int = 0
var items: Array = []          # Array of ItemData
var abilities: Dictionary = {} # AbilityData -> level

var _attack_timer: float = 0.0
var _target: Node2D = null
var _target_timer: float = 0.0
var _kill_streak_timer: float = 0.0
const KILL_STREAK_WINDOW := 2.0
const TARGET_UPDATE_INTERVAL := 0.1

func _ready() -> void:
	add_to_group("hero")
	if hero_data:
		hero_data.apply_base_stats(stats)

	max_health = stats.get_stat(StatSystem.StatType.MAX_HEALTH)
	current_health = max_health
	GameEvents.hero_health_changed.emit(current_health, max_health)

	stats.stat_changed.connect(_on_stat_changed)
	GameEvents.enemy_killed.connect(_on_enemy_killed)

	# Set up pickup area
	var pickup_area = $PickupArea as Area2D
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_entered)
		pickup_area.area_entered.connect(_on_pickup_area_entered)
		_update_pickup_range()

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	_update_targeting(delta)
	_update_attack(delta)
	_update_kill_streak(delta)
	_update_health_regen(delta)

func _update_targeting(delta: float) -> void:
	_target_timer -= delta
	if _target_timer > 0.0:
		return
	_target_timer = TARGET_UPDATE_INTERVAL
	_target = _find_nearest_enemy()

func _update_attack(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer > 0.0 or _target == null:
		return
	if not is_instance_valid(_target):
		_target = null
		return

	var attack_speed = stats.get_stat(StatSystem.StatType.ATTACK_SPEED)
	var cdr = clampf(stats.get_stat(StatSystem.StatType.COOLDOWN_REDUCTION), 0.0, 0.9)
	var interval = (1.0 / maxf(attack_speed, 0.1)) * (1.0 - cdr)
	_attack_timer = interval

	perform_attack(_target)

func _update_kill_streak(delta: float) -> void:
	if kill_streak <= 0:
		return
	_kill_streak_timer -= delta
	if _kill_streak_timer <= 0.0:
		kill_streak = 0
		GameEvents.kill_streak_changed.emit(0)
		on_kill_streak_reset()

func _update_health_regen(delta: float) -> void:
	var regen = stats.get_stat(StatSystem.StatType.HEALTH_REGEN)
	if regen > 0.0:
		heal(regen * delta)

## Override in subclass
func perform_attack(_target_node: Node2D) -> void:
	pass

## Override in subclass
func on_kill_streak_reset() -> void:
	pass

## Override in subclass
func on_kill_streak_increased(_new_streak: int) -> void:
	pass

func take_damage(amount: float, is_crit: bool = false, attacker: Node2D = null) -> float:
	if current_health <= 0.0:
		return 0.0

	var armor = stats.get_stat(StatSystem.StatType.ARMOR)
	var dmg_reduction = clampf(stats.get_stat(StatSystem.StatType.DAMAGE_REDUCTION), 0.0, 0.9)
	var after_armor = maxf(amount - armor, 1.0)
	var final_damage = after_armor * (1.0 - dmg_reduction)

	current_health = maxf(0.0, current_health - final_damage)
	GameEvents.hero_health_changed.emit(current_health, max_health)
	GameEvents.damage_dealt.emit(self, final_damage, is_crit)

	# Thorns
	var thorns = stats.get_stat(StatSystem.StatType.THORNS)
	if thorns > 0.0 and attacker and is_instance_valid(attacker) and attacker.has_method("take_damage"):
		attacker.take_damage(thorns)

	if current_health <= 0.0:
		_die()

	return final_damage

func heal(amount: float) -> void:
	if current_health <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	GameEvents.hero_health_changed.emit(current_health, max_health)

func fire_projectile(direction: Vector2, angle_offset: float = 0.0) -> void:
	if angle_offset != 0.0:
		direction = direction.rotated(deg_to_rad(angle_offset))

	var projectile_scene = preload("res://scenes/projectile.tscn")
	var proj: Node2D = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	proj.initialize(
		direction,
		stats.get_stat(StatSystem.StatType.PROJECTILE_SPEED),
		stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE),
		stats.get_stat(StatSystem.StatType.CRIT_CHANCE),
		stats.get_stat(StatSystem.StatType.CRIT_MULTIPLIER),
		roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_PIERCE)),
		stats.get_stat(StatSystem.StatType.KNOCKBACK_FORCE),
		stats.get_stat(StatSystem.StatType.LIFESTEAL),
		true
	)

func add_item(item: ItemData) -> void:
	items.append(item)
	for mod in item.modifiers:
		stats.add_modifier(mod["stat"], mod["type"], mod["value"], item)
	if item.category == ItemData.Category.CURSED:
		for curse in item.curse_modifiers:
			stats.add_modifier(curse["stat"], curse["type"], curse["value"], item)
	_check_evolutions()
	GameEvents.item_acquired.emit(item)

func add_ability(ability: AbilityData) -> void:
	var current_level: int = abilities.get(ability, 0)
	if current_level >= ability.max_level:
		return
	if current_level > 0:
		ability.remove(stats, ability)
	abilities[ability] = current_level + 1
	ability.apply(stats, current_level + 1, ability)

func get_ability_level(ability: AbilityData) -> int:
	return abilities.get(ability, 0)

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = INF

	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _on_enemy_killed(_enemy: Node2D) -> void:
	kill_streak += 1
	_kill_streak_timer = KILL_STREAK_WINDOW
	GameEvents.kill_streak_changed.emit(kill_streak)
	on_kill_streak_increased(kill_streak)

func _on_stat_changed(stat_type: int, new_value: float) -> void:
	if stat_type == StatSystem.StatType.MAX_HEALTH:
		var ratio = current_health / max_health if max_health > 0 else 1.0
		max_health = new_value
		current_health = max_health * ratio
		GameEvents.hero_health_changed.emit(current_health, max_health)
	if stat_type == StatSystem.StatType.PICKUP_RANGE:
		_update_pickup_range()

func _update_pickup_range() -> void:
	var pickup_area = $PickupArea as Area2D
	if pickup_area:
		var shape = pickup_area.get_node("CollisionShape2D") as CollisionShape2D
		if shape and shape.shape is CircleShape2D:
			(shape.shape as CircleShape2D).radius = stats.get_stat(StatSystem.StatType.PICKUP_RANGE)

func _on_pickup_entered(body: Node2D) -> void:
	if body.is_in_group("xp_orb") and body.has_method("collect"):
		body.collect(self)
	elif body.is_in_group("loot_orb") and body.has_method("collect"):
		body.collect()

func _on_pickup_area_entered(area: Area2D) -> void:
	# XP orbs and loot orbs are Area2D root nodes, so check area directly
	if area.is_in_group("xp_orb") and area.has_method("collect"):
		area.collect(self)
	elif area.is_in_group("loot_orb") and area.has_method("collect"):
		area.collect()
	else:
		# Fallback: check parent in case the area is a child node
		var parent = area.get_parent()
		if parent and parent.is_in_group("xp_orb") and parent.has_method("collect"):
			parent.collect(self)
		elif parent and parent.is_in_group("loot_orb") and parent.has_method("collect"):
			parent.collect()

func _check_evolutions() -> void:
	for i in range(items.size()):
		var item_a: ItemData = items[i]
		if not item_a.evolution_partner:
			continue
		for j in range(i + 1, items.size()):
			if items[j] == item_a.evolution_partner and item_a.evolution_result:
				stats.remove_all_from_source(items[i])
				stats.remove_all_from_source(items[j])
				items.remove_at(j)
				items.remove_at(i)
				add_item(item_a.evolution_result)
				return

func _die() -> void:
	GameEvents.game_over.emit()
	GameManager.game_over()
