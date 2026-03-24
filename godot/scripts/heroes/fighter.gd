extends HeroBase
## Fighter family hero: all evolution branches share this script.
## Melee attack dispatch is based on hero_class meta, not scene swapping.

# Melee range (affected by AOE_RADIUS stat)
const BASE_MELEE_RANGE := 120.0
# Shockwave hits ranged enemies beyond melee range at reduced damage
const SHOCKWAVE_RANGE := 450.0
const SHOCKWAVE_DAMAGE_MULT := 0.01

# Berserker rage tracking
var _berserker_frenzy_stacks: int = 0
var _berserker_frenzy_mod: Dictionary = {}
var _berserker_frenzy_timer: float = 0.0

# Knight shield wall state
var _shield_wall_mod: Dictionary = {}
var _shield_wall_active: bool = false

# Warlord war cry
var _war_cry_timer: float = 0.0
var _war_cry_mod: Dictionary = {}
var _war_cry_active: float = 0.0

# Whirlwind timer
var _whirlwind_cooldown: float = 0.0

# Shield bash timer
var _shield_bash_cooldown: float = 0.0

# Paladin heal aura
var _paladin_heal_timer: float = 0.0

# Guardian thorns mod
var _guardian_thorns_mod: Dictionary = {}

# Blademaster combo
var _blademaster_combo: int = 0
var _blademaster_combo_timer: float = 0.0

# Preloaded evolution sprites
var _hero_sprites: Dictionary = {}

func _ready() -> void:
	super._ready()
	_hero_sprites = {
		"fighter": load("res://art/heroes/fighter/fighter.png"),
		"knight": _try_load("res://art/heroes/knight/knight.png"),
		"berserker": _try_load("res://art/heroes/berserker/berserker.png"),
		"paladin": _try_load("res://art/heroes/paladin/paladin.png"),
		"guardian": _try_load("res://art/heroes/guardian/guardian.png"),
		"blademaster": _try_load("res://art/heroes/blademaster/blademaster.png"),
		"warlord": _try_load("res://art/heroes/warlord/warlord.png"),
	}
	GameEvents.hero_evolved.connect(_on_evolved)
	GameEvents.enemy_killed.connect(_on_enemy_killed_fighter)

func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _on_evolved(new_class: String) -> void:
	var sprite = $Sprite2D as Sprite2D
	if sprite and _hero_sprites.has(new_class) and _hero_sprites[new_class]:
		sprite.texture = _hero_sprites[new_class]
		sprite.modulate = Color.WHITE

func _get_melee_range() -> float:
	return BASE_MELEE_RANGE + stats.get_stat(StatSystem.StatType.AOE_RADIUS)

# ── Main attack dispatch ──────────────────────────────────────────

func perform_attack(target_node: Node2D) -> void:
	var dir = (target_node.global_position - global_position).normalized()
	match get_meta("hero_class", "fighter"):
		"fighter": _attack_fighter(dir)
		"knight": _attack_knight(dir)
		"berserker": _attack_berserker(dir)
		"paladin": _attack_paladin(dir)
		"guardian": _attack_guardian(dir)
		"blademaster": _attack_blademaster(dir)
		"warlord": _attack_warlord(dir)
		_: _attack_fighter(dir)
	# Flip sprite toward attack direction
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.flip_h = dir.x < 0

# ── Melee hit helper ─────────────────────────────────────────────

## Deals damage to all enemies within radius of hero. Returns hit count.
func _melee_strike(damage_mult: float, range_mult: float = 1.0, force_crit: bool = false, knockback_mult: float = 1.0) -> int:
	var melee_range = _get_melee_range() * range_mult
	var base_dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * damage_mult
	var crit_chance = 1.0 if force_crit else stats.get_stat(StatSystem.StatType.CRIT_CHANCE)
	var crit_mult = stats.get_stat(StatSystem.StatType.CRIT_MULTIPLIER)
	var lifesteal = stats.get_stat(StatSystem.StatType.LIFESTEAL)
	var knockback = stats.get_stat(StatSystem.StatType.KNOCKBACK_FORCE) * knockback_mult

	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count := 0
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist > melee_range:
			continue
		if not enemy.has_method("take_damage"):
			continue

		var is_crit = randf() < crit_chance
		var final_dmg = base_dmg * (crit_mult if is_crit else 1.0)

		# Rend (bleed) on-hit
		if special_abilities.has("rend"):
			var rd = special_abilities["rend"]
			var bleed_chance = rd["values"][rd["level"] - 1]
			var bleed_dps = rd["special_values"][rd["level"] - 1]
			if randf() < bleed_chance and enemy.has_method("apply_bleed"):
				enemy.apply_bleed(bleed_dps * base_dmg, 3.0)

		# Sunder armor on-hit
		if special_abilities.has("sunder"):
			var sd = special_abilities["sunder"]
			var sunder_chance = sd["values"][sd["level"] - 1]
			if randf() < sunder_chance and enemy.has_method("apply_armor_shred"):
				enemy.apply_armor_shred(sd["special_values"][sd["level"] - 1], 4.0)

		var dealt = enemy.take_damage(final_dmg, is_crit, self)
		GameEvents.damage_dealt.emit(enemy, dealt, is_crit, "melee")
		hit_count += 1

		# Knockback
		if knockback > 0 and enemy.has_method("apply_knockback"):
			var kb_dir = (enemy.global_position - global_position).normalized()
			enemy.apply_knockback(kb_dir * knockback)

		# Lifesteal
		if lifesteal > 0 and dealt > 0:
			heal(dealt * lifesteal)

	# Shockwave: hit enemies beyond melee range at reduced damage
	# Spawners/drummers take 25% damage instead of 1% — fighter's answer to ranged summoners
	var shockwave_dmg = base_dmg * SHOCKWAVE_DAMAGE_MULT
	var shockwave_dmg_spawner = base_dmg * 0.25
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= melee_range or dist > SHOCKWAVE_RANGE:
			continue
		if not enemy.has_method("take_damage"):
			continue
		var is_crit = randf() < crit_chance
		# Spawners/bosses get hit harder — they're high-value targets sitting at range
		var is_priority = false
		var enemy_data = enemy.get("data")
		if enemy_data and enemy_data is EnemyData:
			if enemy_data.behavior == EnemyData.Behavior.SPAWNER or enemy_data.behavior == EnemyData.Behavior.RANGED or enemy_data.is_boss:
				is_priority = true
		var raw_dmg = shockwave_dmg_spawner if is_priority else shockwave_dmg
		var sw_dmg = maxf(raw_dmg * (crit_mult if is_crit else 1.0), 1.0)
		var dealt = enemy.take_damage(sw_dmg, is_crit, self)
		GameEvents.damage_dealt.emit(enemy, dealt, is_crit, "shockwave")
		hit_count += 1
		if lifesteal > 0 and dealt > 0:
			heal(dealt * lifesteal)

	# Spawn slash visual
	_spawn_slash_visual(melee_range)
	AudioManager.play("hit")

	return hit_count

# ── Base Fighter (Tier 1) ────────────────────────────────────────

func _attack_fighter(dir: Vector2) -> void:
	_melee_strike(1.0)

# ── Knight (Tier 2, defensive) ───────────────────────────────────

func _attack_knight(dir: Vector2) -> void:
	_melee_strike(0.9, 1.0, false, 1.5)  # Less damage, more knockback

# ── Berserker (Tier 2, offensive) ────────────────────────────────

func _attack_berserker(dir: Vector2) -> void:
	# Damage scales with missing HP: +1% ATK per 1% missing HP
	var hp_ratio = current_health / max_health if max_health > 0 else 1.0
	var rage_mult = 1.0 + (1.0 - hp_ratio)
	_melee_strike(rage_mult)

# ── Paladin (Tier 3, from Knight) ────────────────────────────────

func _attack_paladin(dir: Vector2) -> void:
	var hits = _melee_strike(1.1, 1.2)  # Slightly more damage and range
	# Heal-on-hit: 2% of damage dealt per enemy hit
	if hits > 0:
		var heal_amount = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * 0.02 * hits
		heal(heal_amount)

# ── Guardian (Tier 3, from Knight) ───────────────────────────────

func _attack_guardian(dir: Vector2) -> void:
	_melee_strike(0.8, 1.3, false, 2.0)  # Wide range, heavy knockback, less damage

# ── Blademaster (Tier 3, from Berserker) ─────────────────────────

func _attack_blademaster(dir: Vector2) -> void:
	# Multi-strike: combo counter, every 3rd attack hits twice
	_blademaster_combo += 1
	var strikes = 2 if _blademaster_combo % 3 == 0 else 1
	var hp_ratio = current_health / max_health if max_health > 0 else 1.0
	var rage_mult = 1.0 + (1.0 - hp_ratio) * 0.5  # Reduced rage scaling
	for i in range(strikes):
		_melee_strike(rage_mult * 0.9, 1.1)

# ── Warlord (Tier 3, from Berserker) ─────────────────────────────

func _attack_warlord(dir: Vector2) -> void:
	var hp_ratio = current_health / max_health if max_health > 0 else 1.0
	var rage_mult = 1.0 + (1.0 - hp_ratio)
	var hits = _melee_strike(rage_mult * 1.1)
	# Execution: enemies below 15% HP take 3x damage (checked inside take_damage meta isn't feasible, so bonus swing)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if not enemy.has_method("take_damage"):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist > _get_melee_range():
			continue
		if enemy.has_method("get_health_ratio"):
			if enemy.get_health_ratio() < 0.15:
				var exec_dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * rage_mult * 2.0
				var dealt = enemy.take_damage(exec_dmg, true, self)
				GameEvents.damage_dealt.emit(enemy, dealt, true, "execute")

# ── Special ability updates ──────────────────────────────────────

func _update_special_abilities(delta: float) -> void:
	super._update_special_abilities(delta)
	var cdr = clampf(stats.get_stat(StatSystem.StatType.COOLDOWN_REDUCTION), 0.0, 0.5)
	var hero_class = get_meta("hero_class", "fighter")

	# Knight: Shield Wall — +50% armor when below 50% HP
	if hero_class == "knight" or hero_class == "paladin" or hero_class == "guardian":
		var hp_ratio = current_health / max_health if max_health > 0 else 1.0
		if hp_ratio < 0.5 and not _shield_wall_active:
			_shield_wall_active = true
			var armor_bonus = stats.get_stat(StatSystem.StatType.ARMOR) * 0.5
			_shield_wall_mod = stats.add_modifier(StatSystem.StatType.ARMOR, StatSystem.ModType.FLAT, armor_bonus, self)
		elif hp_ratio >= 0.5 and _shield_wall_active:
			_shield_wall_active = false
			if _shield_wall_mod:
				stats.remove_modifier(_shield_wall_mod)
				_shield_wall_mod = {}

	# Berserker: Frenzy stacks decay
	if hero_class == "berserker" or hero_class == "blademaster" or hero_class == "warlord":
		if _berserker_frenzy_timer > 0.0:
			_berserker_frenzy_timer -= delta
			if _berserker_frenzy_timer <= 0.0:
				_berserker_frenzy_stacks = 0
				if _berserker_frenzy_mod:
					stats.remove_modifier(_berserker_frenzy_mod)
					_berserker_frenzy_mod = {}

	# Whirlwind: periodic 360-degree AoE
	if special_abilities.has("whirlwind"):
		_whirlwind_cooldown -= delta * (1.0 + cdr)
		if _whirlwind_cooldown <= 0.0:
			var ww = special_abilities["whirlwind"]
			var cooldown = ww["values"][ww["level"] - 1]
			var damage_mult = ww["special_values"][ww["level"] - 1]
			_trigger_whirlwind(damage_mult)
			_whirlwind_cooldown = cooldown

	# Shield Bash: periodic stun slam
	if special_abilities.has("shield_bash"):
		_shield_bash_cooldown -= delta * (1.0 + cdr)
		if _shield_bash_cooldown <= 0.0:
			var sb = special_abilities["shield_bash"]
			var cooldown = sb["values"][sb["level"] - 1]
			var stun_dur = sb["special_values"][sb["level"] - 1]
			_trigger_shield_bash(stun_dur)
			_shield_bash_cooldown = cooldown

	# War Cry: periodic ATK buff
	if special_abilities.has("war_cry"):
		if _war_cry_active > 0.0:
			_war_cry_active -= delta
			if _war_cry_active <= 0.0 and _war_cry_mod:
				stats.remove_modifier(_war_cry_mod)
				_war_cry_mod = {}
		else:
			_war_cry_timer -= delta * (1.0 + cdr)
			if _war_cry_timer <= 0.0:
				var wc = special_abilities["war_cry"]
				var cooldown = wc["values"][wc["level"] - 1]
				var atk_bonus = wc["special_values"][wc["level"] - 1]
				_war_cry_mod = stats.add_modifier(StatSystem.StatType.ATTACK_DAMAGE, StatSystem.ModType.PERCENT_ADD, atk_bonus, self)
				_war_cry_active = 5.0
				_war_cry_timer = cooldown
				AudioManager.play("boss")

	# Paladin: passive heal aura (heals 1% max HP per second)
	if hero_class == "paladin":
		_paladin_heal_timer += delta
		if _paladin_heal_timer >= 1.0:
			_paladin_heal_timer -= 1.0
			heal(max_health * 0.01)

	# Blademaster combo timer decay
	if _blademaster_combo_timer > 0.0:
		_blademaster_combo_timer -= delta
		if _blademaster_combo_timer <= 0.0:
			_blademaster_combo = 0

# ── Triggered abilities ──────────────────────────────────────────

func _trigger_whirlwind(damage_mult: float) -> void:
	var range_val = _get_melee_range() * 1.3
	var base_dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * damage_mult
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= range_val and enemy.has_method("take_damage"):
			var dealt = enemy.take_damage(base_dmg, false, self)
			GameEvents.damage_dealt.emit(enemy, dealt, false, "whirlwind")
	_spawn_whirlwind_visual(range_val)
	AudioManager.play("hit")

func _trigger_shield_bash(stun_duration: float) -> void:
	var range_val = _get_melee_range() * 0.8
	var base_dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * 0.5
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= range_val:
			if enemy.has_method("take_damage"):
				var dealt = enemy.take_damage(base_dmg, false, self)
				GameEvents.damage_dealt.emit(enemy, dealt, false, "bash")
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(0.9, stun_duration)  # 90% slow = near-stun
	AudioManager.play("hit")

# ── Kill tracking ────────────────────────────────────────────────

func _on_enemy_killed_fighter(enemy: Node) -> void:
	var hero_class = get_meta("hero_class", "fighter")
	# Berserker family: Frenzy — kills grant stacking ATK speed
	if hero_class in ["berserker", "blademaster", "warlord"]:
		_berserker_frenzy_stacks = mini(_berserker_frenzy_stacks + 1, 20)
		_berserker_frenzy_timer = 3.0
		if _berserker_frenzy_mod:
			stats.remove_modifier(_berserker_frenzy_mod)
		_berserker_frenzy_mod = stats.add_modifier(
			StatSystem.StatType.ATTACK_SPEED,
			StatSystem.ModType.PERCENT_ADD,
			_berserker_frenzy_stacks * 0.03,
			self
		)

func on_kill_streak_reset() -> void:
	_berserker_frenzy_stacks = 0
	_berserker_frenzy_timer = 0.0
	if _berserker_frenzy_mod:
		stats.remove_modifier(_berserker_frenzy_mod)
		_berserker_frenzy_mod = {}

# ── Visual effects ───────────────────────────────────────────────

func _spawn_slash_visual(melee_range: float) -> void:
	var tex = _try_load("res://art/effects/melee_slash/melee_slash.png")
	if not tex:
		# Fallback: simple expanding circle
		var sprite = Sprite2D.new()
		sprite.global_position = global_position
		sprite.z_index = 10
		sprite.modulate = Color(1.0, 0.8, 0.3, 0.6)
		get_tree().current_scene.call_deferred("add_child", sprite)
		sprite.ready.connect(func():
			var tw = sprite.create_tween()
			tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
			tw.tween_callback(sprite.queue_free)
		)
		return
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.global_position = global_position
	var target_scale = melee_range * 2.0 / tex.get_width()
	sprite.scale = Vector2(target_scale, target_scale)
	sprite.modulate = Color(1.0, 0.8, 0.3, 0.7)
	sprite.z_index = 10
	get_tree().current_scene.call_deferred("add_child", sprite)
	sprite.ready.connect(func():
		var tw = sprite.create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tw.tween_callback(sprite.queue_free)
	)

func _spawn_whirlwind_visual(range_val: float) -> void:
	var tex = _try_load("res://art/effects/whirlwind/whirlwind.png")
	var sprite = Sprite2D.new()
	if tex:
		sprite.texture = tex
		var target_scale = range_val * 2.0 / tex.get_width()
		sprite.scale = Vector2(target_scale * 0.5, target_scale * 0.5)
	sprite.global_position = global_position
	sprite.modulate = Color(0.8, 0.8, 1.0, 0.7)
	sprite.z_index = 10
	get_tree().current_scene.call_deferred("add_child", sprite)
	sprite.ready.connect(func():
		var tw = sprite.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sprite, "rotation", TAU, 0.3)
		tw.tween_property(sprite, "scale", sprite.scale * 2.0, 0.3)
		tw.set_parallel(false)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tw.tween_callback(sprite.queue_free)
	)
