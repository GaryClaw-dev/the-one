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

# Special ability systems
var special_abilities: Dictionary = {}
var _shot_counter: int = 0
var _arsenal_timer: float = 0.0
var _kill_counter: int = 0
var _rain_cooldown: float = 0.0
var _marked_enemies: Dictionary = {}

# Evolution passives
var _precision_surge_cooldown: float = 0.0
var _precision_surge_shots: int = 0
var _bullet_storm_cooldown: float = 0.0
var _bullet_storm_active: float = 0.0
var _bullet_storm_mod: Dictionary = {}
var _aimed_shot_counter: int = 0

# Archers Tempo
var _archers_tempo_stacks: float = 0.0
var _archers_tempo_mod: Dictionary = {}

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

	# Set up pickup area (optional, orbs auto-fly to hero now)
	var pickup_area = get_node_or_null("PickupArea") as Area2D
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
	_update_special_abilities(delta)

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

	var attack_speed = minf(stats.get_stat(StatSystem.StatType.ATTACK_SPEED), 8.0)  # Hard cap at 8 attacks/sec
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

## Special ability handler
func add_special_ability(type: String, level: int, values: Array) -> void:
	# values[0] is the primary values array, values[1] is special_values if exists
	if values.size() > 1:
		special_abilities[type] = {"level": level, "values": values[0], "special_values": values[1]}
	else:
		special_abilities[type] = {"level": level, "values": values[0]}

func _update_special_abilities(delta: float) -> void:
	# Archer's Arsenal timer
	if special_abilities.has("arsenal"):
		var data = special_abilities["arsenal"]
		_arsenal_timer -= delta
		if _arsenal_timer <= 0:
			# level_values contains the timer intervals, special_values contains projectile counts
			_arsenal_timer = data["values"][data["level"] - 1]  # Timer interval
			var projectile_count = int(data["special_values"][data["level"] - 1])  # Number of projectiles
			_trigger_arsenal_shot(projectile_count)
	
	# Rain of Arrows kill counter (cooldown prevents infinite cascade from AoE kills)
	if special_abilities.has("rain_of_arrows"):
		_rain_cooldown = maxf(0.0, _rain_cooldown - delta)
		if _rain_cooldown <= 0.0:
			var data = special_abilities["rain_of_arrows"]
			var kill_threshold = int(data["values"][data["level"] - 1])
			var arrow_count = int(data["special_values"][data["level"] - 1])
			if _kill_counter >= kill_threshold:
				_kill_counter = 0
				_rain_cooldown = 1.0
				_trigger_rain_of_arrows(arrow_count)

	# Precision Surge: every Ns, next M shots deal 3x damage + guaranteed crit
	if special_abilities.has("precision_surge"):
		if _precision_surge_cooldown > 0.0:
			_precision_surge_cooldown -= delta
			if _precision_surge_cooldown <= 0.0:
				var data = special_abilities["precision_surge"]
				_precision_surge_shots = int(data["special_values"][data["level"] - 1])

	# Archers Tempo: stacking ATK SPD over time
	if special_abilities.has("archers_tempo"):
		var at_data = special_abilities["archers_tempo"]
		var rate = at_data["values"][at_data["level"] - 1]
		var max_bonus = at_data["special_values"][at_data["level"] - 1]
		_archers_tempo_stacks = minf(_archers_tempo_stacks + rate * delta, max_bonus)
		# Update modifier
		if _archers_tempo_mod:
			stats.remove_modifier(_archers_tempo_mod)
		_archers_tempo_mod = stats.add_modifier(
			StatSystem.StatType.ATTACK_SPEED,
			StatSystem.ModType.PERCENT_ADD,
			_archers_tempo_stacks,
			self
		)

	# Bullet Storm: every Ns, triple attack speed for Ms
	if special_abilities.has("bullet_storm"):
		if _bullet_storm_active > 0.0:
			_bullet_storm_active -= delta
			if _bullet_storm_active <= 0.0:
				# Remove speed buff
				if _bullet_storm_mod:
					stats.remove_modifier(_bullet_storm_mod)
					_bullet_storm_mod = {}
		elif _bullet_storm_cooldown > 0.0:
			_bullet_storm_cooldown -= delta
			if _bullet_storm_cooldown <= 0.0:
				# Activate: triple attack speed
				var data = special_abilities["bullet_storm"]
				_bullet_storm_active = data["special_values"][data["level"] - 1]
				_bullet_storm_mod = stats.add_modifier(
					StatSystem.StatType.ATTACK_SPEED,
					StatSystem.ModType.PERCENT_ADD,
					2.0,
					self
				)
				_bullet_storm_cooldown = data["values"][data["level"] - 1]

func _trigger_arsenal_shot(extra_projectiles: int) -> void:
	if not _target:
		return
	for i in extra_projectiles:
		var angle = (i - extra_projectiles/2.0) * 15.0
		var dir = (_target.global_position - global_position).normalized()
		fire_projectile(dir, angle)

func _trigger_rain_of_arrows(arrow_count: int) -> void:
	for i in arrow_count:
		var angle = randf() * TAU
		var distance = randf_range(50, 200)
		var pos = global_position + Vector2.from_angle(angle) * distance
		_spawn_falling_arrow(pos)

func _trigger_orbital_strike(dmg_mult: float) -> void:
	# AoE blast at random positions around the hero
	var base_dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * dmg_mult
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= 250.0 and enemy.has_method("take_damage"):
			var dealt = enemy.take_damage(base_dmg, true, self)
			GameEvents.damage_dealt.emit(enemy, dealt, true)
	AudioManager.play("boss")

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
	var dmg_reduction = clampf(stats.get_stat(StatSystem.StatType.DAMAGE_REDUCTION), 0.0, 0.75)
	# Diminishing returns armor: damage * 100/(100+armor)
	var armor_mult = 100.0 / (100.0 + maxf(armor, 0.0))
	var after_armor = amount * armor_mult
	var final_damage = maxf(after_armor * (1.0 - dmg_reduction), 1.0)

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

func fire_projectile(direction: Vector2, angle_offset: float = 0.0, aoe_radius: float = 0.0, damage_mult: float = 1.0, target_node: Node2D = null, force_crit: bool = false, extra_pierce: int = 0) -> Node2D:
	if angle_offset != 0.0:
		direction = direction.rotated(deg_to_rad(angle_offset))

	var projectile_scene = preload("res://scenes/projectile.tscn")
	var proj: Node2D = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	# Hunter's Focus damage multiplier
	if special_abilities.has("hunter_focus"):
		_shot_counter += 1
		var data = special_abilities["hunter_focus"]
		var shot_interval = int(data["values"][data["level"] - 1])
		var damage_bonus = data["special_values"][data["level"] - 1]
		if _shot_counter % shot_interval == 0:
			damage_mult *= (1.0 + damage_bonus)

	# Precision Surge: consume a buffed shot
	if _precision_surge_shots > 0:
		_precision_surge_shots -= 1
		damage_mult *= 3.0
		force_crit = true
		if _precision_surge_shots <= 0:
			# Reset cooldown for next surge
			var ps_data = special_abilities.get("precision_surge", {})
			_precision_surge_cooldown = ps_data.get("values", [10.0])[ps_data.get("level", 1) - 1]

	# Explosive chance
	var explosive_chance = 0.0
	var explosive_damage = 0.0
	if special_abilities.has("explosive"):
		var data = special_abilities["explosive"]
		explosive_chance = data["values"][data["level"] - 1]
		explosive_damage = data["special_values"][data["level"] - 1]

	var crit_chance = 1.0 if force_crit else stats.get_stat(StatSystem.StatType.CRIT_CHANCE)
	var pierce = roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_PIERCE)) + extra_pierce

	proj.initialize(
		direction,
		stats.get_stat(StatSystem.StatType.PROJECTILE_SPEED),
		stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * damage_mult,
		crit_chance,
		stats.get_stat(StatSystem.StatType.CRIT_MULTIPLIER),
		pierce,
		stats.get_stat(StatSystem.StatType.KNOCKBACK_FORCE),
		stats.get_stat(StatSystem.StatType.LIFESTEAL),
		true,
		aoe_radius
	)

	# Add explosion chance
	if explosive_chance > 0 and randf() < explosive_chance:
		proj.set_meta("explosive", true)
		proj.set_meta("explosive_damage", explosive_damage)

	# Mark for death
	if special_abilities.has("mark") and target_node:
		var mark_mult = 1.0 + special_abilities["mark"]["values"][special_abilities["mark"]["level"] - 1]
		if not _marked_enemies.has(target_node):
			_marked_enemies[target_node] = mark_mult
			proj.set_meta("mark_multiplier", mark_mult)

	# Headshot: bonus crit damage multiplier
	if special_abilities.has("headshot"):
		var hs_data = special_abilities["headshot"]
		var crit_dmg_bonus = hs_data["values"][hs_data["level"] - 1]
		proj.set_meta("headshot_bonus", crit_dmg_bonus)
		var execute_threshold = hs_data["special_values"][hs_data["level"] - 1]
		if execute_threshold > 0:
			proj.set_meta("execute_threshold", execute_threshold)

	# Ricochet: enable bouncing on projectiles
	if special_abilities.has("ricochet"):
		var ric_data = special_abilities["ricochet"]
		var bounces = int(ric_data["values"][ric_data["level"] - 1])
		var dmg_bonus = ric_data["special_values"][ric_data["level"] - 1]
		if proj.has_method("enable_bounce"):
			proj.enable_bounce(bounces, 150.0, dmg_bonus)

	# Incendiary Clips: set burn meta on projectile
	if special_abilities.has("incendiary"):
		var inc_data = special_abilities["incendiary"]
		var lvl = inc_data["level"]
		var chance = inc_data["values"][lvl - 1]
		var dps = inc_data["special_values"][lvl - 1]
		var duration = 3.0 if lvl <= 2 else 4.0
		proj.set_meta("incendiary_chance", chance)
		proj.set_meta("incendiary_dps", dps)
		proj.set_meta("incendiary_duration", duration)

	# Wind Guidance: enable homing on projectiles (archer branch only)
	if has_evolved_through("archer") and target_node and proj.has_method("enable_homing"):
		proj.enable_homing(target_node, 3.0)

	# Frostbite: chance to slow on hit
	if special_abilities.has("frostbite"):
		var fb_data = special_abilities["frostbite"]
		var lvl = fb_data["level"]
		proj.set_meta("frostbite_chance", fb_data["values"][lvl - 1])
		proj.set_meta("frostbite_slow", fb_data["special_values"][lvl - 1])
		proj.set_meta("frostbite_duration", 3.0)

	# Chain Lightning: chance to chain to nearby enemies
	if special_abilities.has("chain_lightning"):
		var cl_data = special_abilities["chain_lightning"]
		var lvl = cl_data["level"]
		proj.set_meta("chain_chance", cl_data["values"][lvl - 1])
		proj.set_meta("chain_targets", cl_data["special_values"][lvl - 1])

	# Bleed: chance to apply bleed DoT
	if special_abilities.has("bleed"):
		var bl_data = special_abilities["bleed"]
		var lvl = bl_data["level"]
		proj.set_meta("bleed_chance", bl_data["values"][lvl - 1])
		proj.set_meta("bleed_damage_pct", bl_data["special_values"][lvl - 1])

	# Vampiric Strikes: chance to heal on hit
	if special_abilities.has("vampiric_strikes"):
		var vs_data = special_abilities["vampiric_strikes"]
		var lvl = vs_data["level"]
		proj.set_meta("vampiric_chance", vs_data["values"][lvl - 1])
		proj.set_meta("vampiric_heal_pct", vs_data["special_values"][lvl - 1])

	# Shatter Shot: chance to shred enemy armor
	if special_abilities.has("shatter"):
		var sh_data = special_abilities["shatter"]
		var lvl = sh_data["level"]
		proj.set_meta("shatter_chance", sh_data["values"][lvl - 1])
		proj.set_meta("shatter_armor_pct", sh_data["special_values"][lvl - 1])

	# Unstable Rounds: chance for bonus damage multiplier
	if special_abilities.has("unstable_rounds"):
		var ur_data = special_abilities["unstable_rounds"]
		var lvl = ur_data["level"]
		proj.set_meta("unstable_chance", ur_data["values"][lvl - 1])
		proj.set_meta("unstable_multiplier", ur_data["special_values"][lvl - 1])

	return proj

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

func has_evolved_through(evo_class: String) -> bool:
	return evo_class in get_meta("hero_branch", "").split(".")

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

func _on_enemy_killed(enemy: Node2D) -> void:
	kill_streak += 1
	_kill_counter += 1
	_kill_streak_timer = KILL_STREAK_WINDOW
	GameEvents.kill_streak_changed.emit(kill_streak)
	on_kill_streak_increased(kill_streak)

	# Clean up marked enemies
	if _marked_enemies.has(enemy):
		_marked_enemies.erase(enemy)

	# Reload Discipline: reset aimed shot counter on kill
	if special_abilities.has("reload_discipline"):
		_aimed_shot_counter = 0

	# Heavy Ordnance: kill-counter orbital strike
	if special_abilities.has("heavy_ordnance"):
		var ho_data = special_abilities["heavy_ordnance"]
		var kill_threshold = int(ho_data["values"][ho_data["level"] - 1])
		var dmg_mult = ho_data["special_values"][ho_data["level"] - 1]
		if _kill_counter >= kill_threshold:
			_kill_counter = 0
			_trigger_orbital_strike(dmg_mult)

func _on_stat_changed(stat_type: int, new_value: float) -> void:
	if stat_type == StatSystem.StatType.MAX_HEALTH:
		var ratio = current_health / max_health if max_health > 0 else 1.0
		max_health = new_value
		current_health = max_health * ratio
		GameEvents.hero_health_changed.emit(current_health, max_health)
	if stat_type == StatSystem.StatType.PICKUP_RANGE:
		_update_pickup_range()

func _update_pickup_range() -> void:
	var pickup_area = get_node_or_null("PickupArea") as Area2D
	if pickup_area:
		var shape = pickup_area.get_node("CollisionShape2D") as CollisionShape2D
		if shape and shape.shape is CircleShape2D:
			(shape.shape as CircleShape2D).radius = stats.get_stat(StatSystem.StatType.PICKUP_RANGE)

func _on_pickup_entered(body: Node2D) -> void:
	if body.is_in_group("xp_orb") and body.has_method("collect"):
		body.collect(self)

func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("xp_orb") and area.has_method("collect"):
		area.collect(self)
	else:
		var parent = area.get_parent()
		if parent and parent.is_in_group("xp_orb") and parent.has_method("collect"):
			parent.collect(self)

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

func _spawn_falling_arrow(target_pos: Vector2) -> void:
	# Create a delayed projectile that falls from above
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.timeout.connect(func():
		var proj = fire_projectile(Vector2.DOWN, 0, 50.0)
		if proj:
			proj.global_position = target_pos + Vector2(0, -300)
		timer.queue_free()
	)
	timer.start()
