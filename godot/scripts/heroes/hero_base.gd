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
var _rain_kill_counter: int = 0
var _rain_cooldown: float = 0.0
var _bolt_barrage_counter: int = 0
var _camo_timer: float = 0.0
var _camo_ready: bool = false
var _marked_enemies: Dictionary = {}

# Stacking per-kill legendaries
var _bloodlust_stacks: int = 0
var _bloodlust_mod: Dictionary = {}
var _reapers_harvest_stacks: int = 0
var _reapers_harvest_mod: Dictionary = {}
var _rampage_stacks: int = 0
var _rampage_crit_mod: Dictionary = {}
var _rampage_speed_mod: Dictionary = {}

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
	GameEvents.level_up.connect(_on_level_up_luck)

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
	var interval = (1.0 / maxf(attack_speed, 0.1))
	_attack_timer = maxf(interval, 0.125)  # Hard floor: never faster than 8 attacks/sec

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
	# For abilities that overlap with evolution innates (e.g. explosive),
	# merge so the ability level never downgrades the evolution baseline.
	var existing = special_abilities.get(type, {})
	var new_entry: Dictionary
	if values.size() > 1:
		new_entry = {"level": level, "values": values[0], "special_values": values[1]}
	else:
		new_entry = {"level": level, "values": values[0]}

	# If evolution already granted this ability, ensure each level value
	# is at least as strong as the evolution baseline
	if existing and existing.has("values") and new_entry["values"].size() > 0:
		var evo_val = existing["values"][0] if existing["values"].size() == 1 else 0.0
		var evo_sp = existing.get("special_values", [0.0])[0] if existing.get("special_values", []).size() == 1 else 0.0
		if evo_val > 0 and new_entry["values"].size() > 1:
			for i in range(new_entry["values"].size()):
				new_entry["values"][i] = maxf(new_entry["values"][i], evo_val)
			if new_entry.has("special_values"):
				for i in range(new_entry["special_values"].size()):
					new_entry["special_values"][i] = maxf(new_entry["special_values"][i], evo_sp)

	special_abilities[type] = new_entry

	# Initialize timers for timed abilities so they actually start
	match type:
		"bullet_storm":
			_bullet_storm_cooldown = values[0][level - 1]
		"precision_surge":
			_precision_surge_cooldown = values[0][level - 1]

func _update_special_abilities(delta: float) -> void:
	var cdr = clampf(stats.get_stat(StatSystem.StatType.COOLDOWN_REDUCTION), 0.0, 0.5)

	# Archer's Arsenal timer
	if special_abilities.has("arsenal"):
		var data = special_abilities["arsenal"]
		_arsenal_timer -= delta * (1.0 + cdr)
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
			if _rain_kill_counter >= kill_threshold:
				_rain_kill_counter = 0
				_rain_cooldown = 1.0
				_trigger_rain_of_arrows(arrow_count)

	# Precision Surge: every Ns, next M shots deal 3x damage + guaranteed crit
	if special_abilities.has("precision_surge"):
		if _precision_surge_cooldown > 0.0:
			_precision_surge_cooldown -= delta * (1.0 + cdr)
			if _precision_surge_cooldown <= 0.0:
				var data = special_abilities["precision_surge"]
				_precision_surge_shots = int(data["special_values"][data["level"] - 1])

	# Archers Tempo: stacking ATK SPD over time (update only when value changes)
	if special_abilities.has("archers_tempo"):
		var at_data = special_abilities["archers_tempo"]
		var rate = at_data["values"][at_data["level"] - 1]
		var max_bonus = at_data["special_values"][at_data["level"] - 1]
		var old_stacks = _archers_tempo_stacks
		_archers_tempo_stacks = minf(_archers_tempo_stacks + rate * delta, max_bonus)
		# Only update modifier when value changes meaningfully (avoid 60 recalcs/sec)
		if absf(_archers_tempo_stacks - old_stacks) > 0.005 or (old_stacks == 0.0 and _archers_tempo_stacks > 0.0):
			if _archers_tempo_mod:
				stats.remove_modifier(_archers_tempo_mod)
			_archers_tempo_mod = stats.add_modifier(
				StatSystem.StatType.ATTACK_SPEED,
				StatSystem.ModType.PERCENT_ADD,
				_archers_tempo_stacks,
				self
			)

	# Camouflage: accumulate unhit time; next shot deals bonus damage when ready
	if special_abilities.has("camouflage") and not _camo_ready:
		_camo_timer += delta
		var cm_data = special_abilities["camouflage"]
		var cm_threshold = cm_data["values"][cm_data["level"] - 1]
		if _camo_timer >= cm_threshold:
			_camo_ready = true

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
			_bullet_storm_cooldown -= delta * (1.0 + cdr)
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
			GameEvents.damage_dealt.emit(enemy, dealt, true, "explosion")
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
	var armor_mult = 50.0 / (50.0 + maxf(armor, 0.0))
	var after_armor = amount * armor_mult
	var final_damage = maxf(after_armor * (1.0 - dmg_reduction), 1.0)

	current_health = maxf(0.0, current_health - final_damage)
	GameEvents.hero_health_changed.emit(current_health, max_health)
	GameEvents.damage_dealt.emit(self, final_damage, is_crit, "normal")

	# Thorns
	var thorns = stats.get_stat(StatSystem.StatType.THORNS)
	if thorns > 0.0 and attacker and is_instance_valid(attacker) and attacker.has_method("take_damage"):
		attacker.take_damage(thorns)

	if current_health <= 0.0:
		_die()

	# Camouflage: reset stealth timer on hit
	if special_abilities.has("camouflage"):
		_camo_timer = 0.0
		_camo_ready = false

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

	# Camouflage: consume stealth bonus on next shot
	if _camo_ready:
		var cm_data = special_abilities.get("camouflage", {})
		if cm_data:
			damage_mult *= cm_data["special_values"][cm_data["level"] - 1]
		_camo_ready = false
		_camo_timer = 0.0

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

	# Mark for death: subsequent hits to marked enemies deal bonus damage
	if special_abilities.has("mark") and target_node:
		var mark_data = special_abilities["mark"]
		var mark_bonus = mark_data["values"][mark_data["level"] - 1]
		if _marked_enemies.has(target_node):
			# Target already marked — apply damage bonus
			proj.set_meta("mark_multiplier", 1.0 + mark_bonus)
		else:
			# First hit marks the target (no bonus on this hit)
			_marked_enemies[target_node] = mark_bonus

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
	_rain_kill_counter += 1
	_kill_streak_timer = KILL_STREAK_WINDOW
	GameEvents.kill_streak_changed.emit(kill_streak)
	on_kill_streak_increased(kill_streak)

	# Clean up marked enemies
	if _marked_enemies.has(enemy):
		_marked_enemies.erase(enemy)

	# Reload Discipline: reset aimed shot counter + higher-level bonuses
	if special_abilities.has("reload_discipline"):
		var rd_data = special_abilities["reload_discipline"]
		var rd_level = rd_data["level"]
		_aimed_shot_counter = 0
		# Level 2-3: temporary ATK SPD buff on kill
		if rd_level >= 2:
			var spd_bonus = rd_data["values"][rd_level - 1]
			var spd_dur = rd_data["special_values"][rd_level - 1]
			var mod = stats.add_modifier(
				StatSystem.StatType.ATTACK_SPEED,
				StatSystem.ModType.PERCENT_ADD,
				spd_bonus,
				null
			)
			var spd_timer = Timer.new()
			spd_timer.wait_time = spd_dur
			spd_timer.one_shot = true
			add_child(spd_timer)
			spd_timer.timeout.connect(stats.remove_modifier.bind(mod))
			spd_timer.timeout.connect(spd_timer.queue_free)
			spd_timer.start()

	# Heavy Ordnance: kill-counter orbital strike
	if special_abilities.has("heavy_ordnance"):
		var ho_data = special_abilities["heavy_ordnance"]
		var kill_threshold = int(ho_data["values"][ho_data["level"] - 1])
		var dmg_mult = ho_data["special_values"][ho_data["level"] - 1]
		if _kill_counter >= kill_threshold:
			_kill_counter = 0
			_trigger_orbital_strike(dmg_mult)

	# Bolt Barrage: every N kills, fire bolts in all directions
	if special_abilities.has("bolt_barrage"):
		_bolt_barrage_counter += 1
		var bb_data = special_abilities["bolt_barrage"]
		var bb_level = bb_data["level"]
		var bb_threshold = int(bb_data["values"][bb_level - 1])
		if _bolt_barrage_counter >= bb_threshold:
			_bolt_barrage_counter = 0
			_trigger_bolt_barrage(int(bb_data["special_values"][bb_level - 1]))

	# Bloodlust: +ATK speed per kill
	if special_abilities.has("bloodlust"):
		_bloodlust_stacks += 1
		_apply_bloodlust()

	# Reaper's Harvest: +ATK damage per kill
	if special_abilities.has("reapers_harvest"):
		_reapers_harvest_stacks += 1
		_apply_reapers_harvest()

	# Rampage: +crit chance + proj speed per kill
	if special_abilities.has("rampage"):
		_rampage_stacks += 1
		_apply_rampage()

	# Poison Cloud: every kill spawns a lingering poison zone at the kill position
	if special_abilities.has("poison_cloud") and is_instance_valid(enemy) and enemy is Node2D:
		var pc_data = special_abilities["poison_cloud"]
		var pc_level = pc_data["level"]
		var pc_radius = pc_data["values"][pc_level - 1]
		var pc_dps = pc_data["special_values"][pc_level - 1]
		var pc_duration = 4.0 if pc_level < 5 else 5.0
		_spawn_poison_cloud(enemy.global_position, pc_dps, pc_radius, pc_duration)

func _apply_bloodlust() -> void:
	if _bloodlust_mod:
		stats.remove_modifier(_bloodlust_mod)
	var data = special_abilities["bloodlust"]
	var rate = data["values"][0]
	var cap = data["special_values"][0]
	var bonus = minf(_bloodlust_stacks * rate, cap)
	_bloodlust_mod = stats.add_modifier(StatSystem.StatType.ATTACK_SPEED, StatSystem.ModType.PERCENT_ADD, bonus, self)

func _apply_reapers_harvest() -> void:
	if _reapers_harvest_mod:
		stats.remove_modifier(_reapers_harvest_mod)
	var data = special_abilities["reapers_harvest"]
	var rate = data["values"][0]
	var cap = data["special_values"][0]
	var bonus = minf(_reapers_harvest_stacks * rate, cap)
	_reapers_harvest_mod = stats.add_modifier(StatSystem.StatType.ATTACK_DAMAGE, StatSystem.ModType.PERCENT_ADD, bonus, self)

func _apply_rampage() -> void:
	if _rampage_crit_mod:
		stats.remove_modifier(_rampage_crit_mod)
	if _rampage_speed_mod:
		stats.remove_modifier(_rampage_speed_mod)
	var data = special_abilities["rampage"]
	var rate = data["values"][0]
	var cap = data["special_values"][0]
	var bonus = minf(_rampage_stacks * rate, cap)
	_rampage_crit_mod = stats.add_modifier(StatSystem.StatType.CRIT_CHANCE, StatSystem.ModType.FLAT, bonus, self)
	_rampage_speed_mod = stats.add_modifier(StatSystem.StatType.PROJECTILE_SPEED, StatSystem.ModType.PERCENT_ADD, bonus, self)

func _spawn_poison_cloud(pos: Vector2, dps: float, radius: float, duration: float) -> void:
	# Visual: translucent green cloud fading over duration
	var tex = load("res://art/effects/poison_cloud/poison_cloud.png") as Texture2D
	if tex:
		var sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.global_position = pos
		sprite.scale = Vector2.ONE * (radius * 2.0 / 1024.0)
		sprite.modulate = Color(0.4, 1.0, 0.4, 0.5)
		sprite.z_index = 5
		get_tree().current_scene.add_child(sprite)
		var tween = sprite.create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, duration)
		tween.tween_callback(sprite.queue_free)
	# Damage: tick every 0.2s for duration
	var tick_interval = 0.2
	var ticks = int(duration / tick_interval)
	for i in range(ticks):
		get_tree().create_timer(tick_interval * (i + 1)).timeout.connect(_poison_tick.bind(pos, radius, dps, tick_interval))

func _poison_tick(pos: Vector2, radius: float, dps: float, tick_interval: float) -> void:
	if not is_instance_valid(self):
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e is Node2D:
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		if pos.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
			var dealt = e.take_damage(dps * tick_interval, false, self)
			GameEvents.damage_dealt.emit(e, dealt, false, "poison")

func _trigger_bolt_barrage(count: int) -> void:
	var angle_step = TAU / maxf(count, 1)
	for i in range(count):
		var dir = Vector2.from_angle(angle_step * i)
		fire_projectile(dir)

func _on_level_up_luck(_level: int) -> void:
	# Passive +2 luck per level — luck naturally builds over a run
	stats.add_modifier(StatSystem.StatType.LUCK, StatSystem.ModType.FLAT, 2.0, self)

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
	timer.timeout.connect(_fire_falling_arrow.bind(target_pos, timer))
	timer.start()

func _fire_falling_arrow(target_pos: Vector2, timer: Timer) -> void:
	var proj = fire_projectile(Vector2.DOWN, 0, 50.0)
	if proj:
		proj.global_position = target_pos + Vector2(0, -300)
	timer.queue_free()
