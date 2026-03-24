extends HeroBase
## Slingshot family hero: all evolution branches share this script.
## Attack dispatch is based on hero_class meta, not scene swapping.

@export var crit_bonus_per_kill: float = 0.02
@export var max_crit_bonus: float = 0.5
@export var spread_angle: float = 10.0

var _streak_crit_mod: Dictionary = {}

# Wolf companion (Ranger/Beastlord)
var _wolf_timer: float = 0.0
var _wolves: Array[Node2D] = []
var _wolf_scene: PackedScene = preload("res://scenes/wolf_companion.tscn")

# Repeater volley counter
var _repeater_volley_count: int = 0

# Stormcaller chain + static charge
var _stormcaller_hit_count: int = 0

# Gunslinger hit counter for Hot Streak
var _gunslinger_hit_count: int = 0

# Deadeye charge timer
var _deadeye_charge_time: float = 0.0
var _deadeye_kill_streak_mult: float = 0.0
var _deadeye_kill_streak_timer: float = 0.0

# Phantom stealth
var _phantom_invisible: bool = false
var _phantom_stealth_cooldown: float = 0.0

# Tempest tornado tracking
var _tempest_tornados: Array[Node2D] = []

# Spirit Archer hawk timer
var _spirit_hawk_timer: float = 5.0

# Siege Master fire zone tracking
var _siege_fire_zones: Array[Node2D] = []

# Thunderlord attack counter
var _thunderlord_attack_count: int = 0

# Demon Hunter curse + desperation
var _demon_lifesteal_pct: float = 0.03

# Preloaded evolution sprites
var _hero_sprites: Dictionary = {}
var _proj_sprites: Dictionary = {}
var _effect_sprites: Dictionary = {}

func _ready() -> void:
	super._ready()
	_hero_sprites = {
		"slingshot": load("res://art/heroes/slingshot/slingshot_ludo.png"),
		"archer": load("res://art/heroes/archer/archer_ludo.png"),
		"repeater": load("res://art/heroes/repeater/repeater_ludo.png"),
		"ranger": load("res://art/heroes/ranger/ranger_ludo.png"),
		"crossbow": load("res://art/heroes/crossbow/crossbow_ludo.png"),
		"windwalker": load("res://art/heroes/windwalker/windwalker.png"),
		"stormcaller": load("res://art/heroes/stormcaller/stormcaller.png"),
		"beastlord": load("res://art/heroes/beastlord/beastlord.png"),
		"phantom": load("res://art/heroes/phantom/phantom.png"),
		"tempest": load("res://art/heroes/tempest/tempest.png"),
		"spirit_archer": load("res://art/heroes/spirit_archer/spirit_archer_ludo.png"),
		"gunslinger": load("res://art/heroes/gunslinger/gunslinger.png"),
		"siege_master": load("res://art/heroes/siege_master/siege_master.png"),
		"thunderlord": load("res://art/heroes/thunderlord/thunderlord.png"),
		"demon_hunter": load("res://art/heroes/demon_hunter/demon_hunter.png"),
	}
	_proj_sprites = {
		"rock": load("res://art/projectiles/rock/rock.png"),
		"poison_arrow": load("res://art/projectiles/poison_arrow/poison_arrow.png"),
		"crossbow_bolt": load("res://art/projectiles/crossbow_bolt/crossbow_bolt.png"),
		"wind_arrow": load("res://art/projectiles/wind_arrow/wind_arrow.png"),
		"lightning_arrow": load("res://art/projectiles/lightning_arrow/lightning_arrow.png"),
		"dark_arrow": load("res://art/projectiles/dark_arrow/dark_arrow.png"),
		"siege_bolt": load("res://art/projectiles/siege_bolt/siege_bolt.png"),
		"ghost_arrow": load("res://art/projectiles/ghost_arrow/ghost_arrow.png"),
	}
	_effect_sprites = {
		"lightning_bolt": load("res://art/effects/lightning_bolt/lightning_bolt.png"),
		"chain_lightning": load("res://art/effects/chain_lightning/chain_lightning.png"),
		"spirit_hawk": load("res://art/effects/spirit_hawk/spirit_hawk.png"),
		"stealth_smoke": load("res://art/effects/stealth_smoke/stealth_smoke.png"),
		"predator_mark": load("res://art/effects/predator_mark/predator_mark.png"),
		"tornado_vortex": load("res://art/effects/tornado_vortex/tornado_vortex.png"),
		"curse_aura": load("res://art/effects/curse_aura/curse_aura.png"),
		"bullet_split": load("res://art/effects/bullet_split/bullet_split.png"),
		"wind_trail": load("res://art/effects/wind_trail/wind_trail.png"),
		"explosive_arrow": load("res://art/effects/explosive_arrow.png"),
	}
	GameEvents.hero_evolved.connect(_on_evolved)
	GameEvents.enemy_killed.connect(_on_enemy_killed_archer)

func _on_evolved(new_class: String) -> void:
	var sprite = $Sprite2D as Sprite2D
	if sprite and _hero_sprites.has(new_class):
		sprite.texture = _hero_sprites[new_class]
		sprite.modulate = Color.WHITE
	# Update animation sheets for new class
	var anim_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim_sprite:
		_use_hero_animated = false
		_try_setup_hero_anim(new_class, anim_sprite, sprite)
		if not _use_hero_animated and sprite:
			sprite.visible = true
			anim_sprite.visible = false

func perform_attack(target_node: Node2D) -> void:
	var dir = (target_node.global_position - global_position).normalized()
	match get_meta("hero_class", "slingshot"):
		"slingshot":
			_attack_slingshot(dir, target_node)
		"archer":
			_attack_archer(dir, target_node)
		"repeater":
			_attack_repeater(dir, target_node)
		"ranger":
			_attack_ranger(dir, target_node)
		"crossbow":
			_attack_crossbow(dir, target_node)
		"windwalker":
			_attack_windwalker(dir, target_node)
		"stormcaller":
			_attack_stormcaller(dir, target_node)
		"beastlord":
			_attack_beastlord(dir, target_node)
		"phantom":
			_attack_phantom(dir, target_node)
		"deadeye":
			_attack_deadeye(dir, target_node)
		"tempest":
			_attack_tempest(dir, target_node)
		"spirit_archer":
			_attack_spirit_archer(dir, target_node)
		"gunslinger":
			_attack_gunslinger(dir, target_node)
		"siege_master":
			_attack_siege_master(dir, target_node)
		"thunderlord":
			_attack_thunderlord(dir, target_node)
		"demon_hunter":
			_attack_demon_hunter(dir, target_node)
		_:
			_attack_slingshot(dir, target_node)
	# Flip sprite
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.flip_h = dir.x < 0

# ── Slingshot (tier 2) ──────────────────────────────────────────────
func _attack_slingshot(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	_fire_spread(dir, proj_count, spread_angle, target_node, false, 0)

# ── Archer (tier 3, precision path) ─────────────────────────────────
func _attack_archer(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	_fire_spread(dir, proj_count, spread_angle, target_node, aimed_crit, aimed_pierce)
	_try_gunslinger(dir, proj_count, spread_angle)

# ── Repeater (tier 3, from Crossbow) — rapid-fire barrage ───────────────────────────────────
func _attack_repeater(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count() + 1  # Always +1 projectile
	_repeater_volley_count += 1
	var actual_count = proj_count
	# Rapid Volley: every 4th volley fires +50%
	if _repeater_volley_count % 4 == 0:
		actual_count = ceili(proj_count * 1.5)
	var cone = 20.0
	for offset in _get_spread_offsets(actual_count, cone):
		var proj = fire_projectile(dir, offset, 0.0, 0.7, target_node)
		# Suppressive Fire: hits slow enemies slightly
		if proj:
			proj.set_meta("frostbite_chance", 0.3)
			proj.set_meta("frostbite_slow", 0.15)
			proj.set_meta("frostbite_duration", 1.0)

# ── Ranger (tier 4, from Archer) — poison arrows ───────────────────
func _attack_ranger(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	for offset in _get_spread_offsets(proj_count, spread_angle):
		var proj = fire_projectile(dir, offset, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
		_apply_poison_meta(proj)
		_set_proj_sprite(proj, "poison_arrow", 0.03)

# ── Windwalker (tier 4, from Archer) — homing wind arrows ──────────
func _attack_windwalker(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	for offset in _get_spread_offsets(proj_count, spread_angle):
		var proj = fire_projectile(dir, offset, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
		_set_proj_sprite(proj, "wind_arrow", 0.03)
		if proj:
			proj.set_meta("wind_trail", true)
		if proj and proj.has_method("enable_homing"):
			proj.enable_homing(target_node, 5.0)

# ── Crossbow (tier 2, mechanical bolts) — 30° cone spread ─────────────
func _attack_crossbow(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	_aimed_shot_counter += 1
	var aimed_crit = false
	var aimed_pierce = 0
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	var cone_spread = 30.0 / maxf(proj_count - 1, 1)
	for offset in _get_spread_offsets(proj_count, cone_spread):
		var proj = fire_projectile(dir, offset, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
		_set_proj_sprite(proj, "crossbow_bolt", 0.03)
	_try_gunslinger(dir, proj_count, cone_spread)

# ── Stormcaller (tier 3, from Crossbow) — lightning chains ──────────
func _attack_stormcaller(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	_stormcaller_hit_count += 1  # Count attacks, not projectiles fired
	var cone = 20.0
	for offset in _get_spread_offsets(proj_count, cone):
		var proj = fire_projectile(dir, offset, 0.0, 1.0, target_node)
		_apply_chain_lightning_meta(proj, 2)
		_set_proj_sprite(proj, "lightning_arrow", 0.03)
	# Static Charge: every 10th hit triggers sky bolt
	if _stormcaller_hit_count >= 10:
		_stormcaller_hit_count -= 10
		_trigger_lightning_bolt(target_node, 3.0)

# ── Beastlord (tier 5, from Ranger) — wolf army + marks ─────────────
func _attack_beastlord(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	for offset in _get_spread_offsets(proj_count, spread_angle):
		var proj = fire_projectile(dir, offset, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
		_apply_poison_meta(proj)
		_set_proj_sprite(proj, "poison_arrow", 0.03)
		if proj:
			proj.set_meta("predators_mark", true)

# ── Phantom (tier 5, from Ranger) — stealth assassin ────────────────
func _attack_phantom(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var damage_mult = 1.2  # Higher base damage
	var force_crit = false
	var extra_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		force_crit = true
		extra_pierce = 2
	# Shadow Strike: first shot from stealth deals 2x + guaranteed crit
	if _phantom_invisible:
		damage_mult *= 2.0
		force_crit = true
		_phantom_invisible = false
		# Make visible again
		modulate.a = 1.0
		_spawn_effect("stealth_smoke", global_position, 0.06, 0.4)
	for offset in _get_spread_offsets(proj_count, spread_angle):
		var proj = fire_projectile(dir, offset, 0.0, damage_mult, target_node, force_crit, extra_pierce)
		_apply_poison_meta(proj)
		_set_proj_sprite(proj, "poison_arrow", 0.03)

# ── Deadeye (tier 5, from Ranger) — sniper one-shot ─────────────────
func _attack_deadeye(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var damage_mult = 2.0  # High base multiplier
	var force_crit = false
	var extra_pierce = 0
	# Every 3rd shot is aimed (not 5th)
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 3:
		_aimed_shot_counter = 0
		force_crit = true
		extra_pierce = 3
	# Charged shot: builds between attacks (resets on fire)
	if _deadeye_charge_time >= 2.0:
		damage_mult += 1.0  # +100% for fully charged
		extra_pierce = 5
		_deadeye_charge_time = 0.0
	elif _deadeye_charge_time >= 1.0:
		damage_mult += 0.5  # +50% for half charged
		_deadeye_charge_time = 0.0
	# Kill streak bonus (capped at +150%)
	if _deadeye_kill_streak_mult > 0.0:
		damage_mult *= (1.0 + minf(_deadeye_kill_streak_mult, 1.5))
	for offset in _get_spread_offsets(proj_count, spread_angle):
		fire_projectile(dir, offset, 0.0, damage_mult, target_node, force_crit, extra_pierce)

# ── Tempest (tier 5, from Windwalker) — tornado attacks ──────────────
func _attack_tempest(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	for offset in _get_spread_offsets(proj_count, spread_angle):
		var proj = fire_projectile(dir, offset, 40.0, 1.0, target_node, aimed_crit, aimed_pierce)
		_set_proj_sprite(proj, "wind_arrow", 0.03)
		if proj and proj.has_method("enable_homing"):
			proj.enable_homing(target_node, 5.0)
		if proj:
			proj.set_meta("wind_trail", true)
			proj.set_meta("vortex_pull", true)
			proj.set_meta("vortex_radius", 60.0)
			proj.set_meta("vortex_duration", 2.0)

# ── Spirit Archer (tier 5, from Windwalker) — ghost arrows ──────────
func _attack_spirit_archer(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aimed_crit = false
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
	# Ethereal Arrows: high pierce, 80% damage per target
	var extra_pierce = 8  # High pierce but not infinite
	var damage_mult = 0.8  # 80% per target but hits many
	for offset in _get_spread_offsets(proj_count, spread_angle):
		var proj = fire_projectile(dir, offset, 0.0, damage_mult, target_node, aimed_crit, extra_pierce)
		_set_proj_sprite(proj, "ghost_arrow", 0.03)
		if proj and proj.has_method("enable_homing"):
			proj.enable_homing(target_node, 5.0)
		if proj:
			proj.set_meta("resonance_bonus", 0.10)

# ── Gunslinger (tier 4, from Repeater) — bullet hell ────────────────
func _attack_gunslinger(dir: Vector2, target_node: Node2D) -> void:
	# Double-fire: 50% chance to attack twice
	var volleys = 2 if randf() < 0.5 else 1
	for _volley in range(volleys):
		_gunslinger_hit_count += 1  # Count per volley, not per projectile
		var force_crit = _gunslinger_hit_count % 10 == 0  # Hot Streak
		var proj_count = _get_final_proj_count()
		var cone_spread = 45.0 / maxf(proj_count - 1, 1)
		for offset in _get_spread_offsets(proj_count, cone_spread):
			# Gunslinger adds slight random jitter to center shot
			var jitter = randf_range(-5, 5) if offset == 0.0 else 0.0
			var proj = fire_projectile(dir, offset + jitter, 0.0, 0.7, target_node, force_crit, 0)
			_set_proj_sprite(proj, "crossbow_bolt", 0.03)
			if proj:
				proj.set_meta("split_chance", 0.2)

# ── Siege Master (tier 4, from Repeater) — explosive AoE ────────────
func _attack_siege_master(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aoe = 80.0 + stats.get_stat(StatSystem.StatType.AOE_RADIUS)
	# Payload: fewer projectiles = bigger AoE
	if proj_count <= 1:
		aoe *= 1.5
	var damage_mult = 1.6
	var throw_spread = 25.0
	for offset in _get_spread_offsets(proj_count, throw_spread):
		var proj = fire_projectile(dir, offset, aoe, damage_mult, target_node)
		_set_proj_sprite(proj, "siege_bolt", 0.05)
		_apply_siege_meta(proj)

# ── Thunderlord (tier 5, from Stormcaller) — massive chains ─────────
func _attack_thunderlord(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	_thunderlord_attack_count += 1
	var cone = 20.0
	for offset in _get_spread_offsets(proj_count, cone):
		var proj = fire_projectile(dir, offset, 0.0, 1.2, target_node)
		_apply_chain_lightning_meta(proj, 4)
		_set_proj_sprite(proj, "lightning_arrow", 0.03)
	# Thunderstrike: every 5th attack triggers massive sky bolt
	if _thunderlord_attack_count >= 5:
		_thunderlord_attack_count = 0
		_trigger_lightning_bolt(target_node, 5.0)

# ── Demon Hunter (tier 5, from Stormcaller) — cursed lifesteal ──────
func _attack_demon_hunter(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	# Desperation: more damage as HP drops
	var hp_ratio = current_health / max_health if max_health > 0 else 1.0
	var damage_mult = 1.0
	if hp_ratio < 0.25:
		damage_mult = 2.0  # +100% below 25%
	elif hp_ratio < 0.5:
		damage_mult = 1.5  # +50% below 50%
	var cone = 20.0
	for offset in _get_spread_offsets(proj_count, cone):
		var proj = fire_projectile(dir, offset, 0.0, damage_mult, target_node, hp_ratio < 0.25, 0)
		_apply_curse_meta(proj)
		_apply_chain_lightning_meta(proj, 2)
		_set_proj_sprite(proj, "dark_arrow", 0.03)

# ── Shared helpers ──────────────────────────────────────────────────

## Returns angle offsets for `count` projectiles with one always at center.
## E.g. count=3, spread=10 → [0, 10, -10]. count=2 → [0, 10].
func _get_spread_offsets(count: int, spread: float) -> Array[float]:
	var offsets: Array[float] = [0.0]
	for i in range(1, count):
		var side = 1.0 if i % 2 == 1 else -1.0
		offsets.append(ceili(i / 2.0) * spread * side)
	return offsets

func _get_final_proj_count() -> int:
	var base = roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_COUNT))
	var multishot_chance = 0.0
	if special_abilities.has("multishot"):
		var data = special_abilities["multishot"]
		multishot_chance = data["values"][data["level"] - 1]
	var final = base
	if multishot_chance >= 1.0:
		final = maxi(2, base)
		if randf() < (multishot_chance - 1.0):
			final += 1
	elif randf() < multishot_chance:
		final = maxi(2, base)
	return final

func _fire_spread(dir: Vector2, count: int, spread: float, target_node: Node2D, force_crit: bool, extra_pierce: int) -> void:
	# Always fire one projectile dead-center at the target, extras fan out
	fire_projectile(dir, 0.0, 0.0, 1.0, target_node, force_crit, extra_pierce)
	for i in range(1, count):
		# Alternate sides: +spread, -spread, +2*spread, -2*spread, ...
		var side = 1 if i % 2 == 1 else -1
		var offset = ceili(i / 2.0) * spread * side
		fire_projectile(dir, offset, 0.0, 1.0, target_node, force_crit, extra_pierce)

func _try_gunslinger(dir: Vector2, proj_count: int, spread: float) -> void:
	if special_abilities.has("gunslinger"):
		var gs_data = special_abilities["gunslinger"]
		var dupe_chance = gs_data["values"][gs_data["level"] - 1]
		if randf() < dupe_chance:
			call_deferred("_gunslinger_extra_attack", dir, proj_count, spread)

func _gunslinger_extra_attack(dir: Vector2, proj_count: int, spread: float) -> void:
	for offset in _get_spread_offsets(proj_count, spread):
		fire_projectile(dir, offset)

func _tint_projectile(proj: Node2D, color: Color, scale_mult: float = 1.0) -> void:
	if not proj:
		return
	var sprite = proj.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = color
		sprite.scale *= scale_mult

func _set_proj_sprite(proj: Node2D, sprite_key: String, scale_val: float = 0.03) -> void:
	if not proj or not _proj_sprites.has(sprite_key):
		return
	var sprite = proj.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.texture = _proj_sprites[sprite_key]
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(scale_val, scale_val)

func _apply_poison_meta(proj: Node2D) -> void:
	if not proj:
		return
	if special_abilities.has("poison_coat"):
		var pc_data = special_abilities["poison_coat"]
		var dps = pc_data["special_values"][pc_data["level"] - 1]
		proj.set_meta("poison_dps", dps)
		proj.set_meta("poison_duration", 4.0)

func _apply_chain_lightning_meta(proj: Node2D, chain_count: int) -> void:
	if not proj:
		return
	proj.set_meta("chain_chance", 1.0)
	proj.set_meta("chain_targets", chain_count)

func _apply_siege_meta(proj: Node2D) -> void:
	if not proj:
		return
	# Scorched Earth: explosions leave fire zones
	proj.set_meta("scorched_earth_duration", 3.0)
	proj.set_meta("scorched_earth_dps", 15.0)
	# Concussive Force: push + slow
	proj.set_meta("frostbite_chance", 1.0)
	proj.set_meta("frostbite_slow", 0.4)
	proj.set_meta("frostbite_duration", 2.0)

func _apply_curse_meta(proj: Node2D) -> void:
	if not proj:
		return
	# Curse: +30% damage taken for 3s
	proj.set_meta("curse_damage_mult", 0.3)
	proj.set_meta("curse_duration", 3.0)
	# Lifesteal is handled by the LIFESTEAL stat from evolution bonus — no duplicate here

func _spawn_effect(effect_key: String, pos: Vector2, effect_scale: float = 0.06, duration: float = 0.4) -> void:
	if not _effect_sprites.has(effect_key):
		return
	var sprite = Sprite2D.new()
	sprite.texture = _effect_sprites[effect_key]
	sprite.global_position = pos
	sprite.scale = Vector2(effect_scale, effect_scale)
	sprite.z_index = 10
	get_tree().current_scene.add_child(sprite)
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	tween.tween_callback(sprite.queue_free)

func _trigger_lightning_bolt(target_node: Node2D, damage_mult: float) -> void:
	if not is_instance_valid(target_node):
		return
	# Visual: lightning bolt at target position
	_spawn_effect("lightning_bolt", target_node.global_position, 0.08, 0.5)
	var base_dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * damage_mult
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = target_node.global_position.distance_to(enemy.global_position)
		if dist <= 80.0 and enemy.has_method("take_damage"):
			var dealt = enemy.take_damage(base_dmg, true, self)
			GameEvents.damage_dealt.emit(enemy, dealt, true, "lightning")

# ── Kill streak (Eagle Eye) ─────────────────────────────────────────

func on_kill_streak_increased(new_streak: int) -> void:
	if _streak_crit_mod:
		stats.remove_modifier(_streak_crit_mod)
	var bonus = minf(new_streak * crit_bonus_per_kill, max_crit_bonus)
	_streak_crit_mod = stats.add_modifier(
		StatSystem.StatType.CRIT_CHANCE,
		StatSystem.ModType.FLAT,
		bonus,
		self
	)

func on_kill_streak_reset() -> void:
	if _streak_crit_mod:
		stats.remove_modifier(_streak_crit_mod)
		_streak_crit_mod = {}
	# Deadeye kill streak resets
	_deadeye_kill_streak_mult = 0.0

# ── Wolf companion update (Ranger/Beastlord) ────────────────────────

func _update_special_abilities(delta: float) -> void:
	super._update_special_abilities(delta)
	var cdr = clampf(stats.get_stat(StatSystem.StatType.COOLDOWN_REDUCTION), 0.0, 0.5)

	# Wolf companion timer
	if special_abilities.has("wolf_companion"):
		var wc_data = special_abilities["wolf_companion"]
		var interval = wc_data["special_values"][wc_data["level"] - 1]
		var wolf_count = int(wc_data["values"][wc_data["level"] - 1])
		_wolf_timer -= delta * (1.0 + cdr)
		if _wolf_timer <= 0.0:
			_wolf_timer = interval
			_wolf_attack(wolf_count)

	# Deadeye: charge while standing (hero is always still, so just accumulate)
	var hero_class = get_meta("hero_class", "slingshot")
	if hero_class == "deadeye":
		_deadeye_charge_time += delta
		# Kill streak timer decay
		if _deadeye_kill_streak_timer > 0.0:
			_deadeye_kill_streak_timer -= delta
			if _deadeye_kill_streak_timer <= 0.0:
				_deadeye_kill_streak_mult = 0.0

	# Phantom: stealth cooldown
	if hero_class == "phantom":
		if _phantom_stealth_cooldown > 0.0:
			_phantom_stealth_cooldown -= delta

	# Spirit Archer: hawk summon timer
	if hero_class == "spirit_archer":
		_spirit_hawk_timer -= delta * (1.0 + cdr)
		if _spirit_hawk_timer <= 0.0:
			_spirit_hawk_timer = 5.0
			_trigger_spirit_hawk()

func _wolf_attack(wolf_count: int) -> void:
	_sync_wolf_count(wolf_count)
	var dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * 0.6
	for wolf in _wolves:
		if is_instance_valid(wolf):
			wolf.damage = dmg

func _sync_wolf_count(desired: int) -> void:
	_wolves = _wolves.filter(func(w): return is_instance_valid(w))
	while _wolves.size() > desired:
		var w = _wolves.pop_back()
		if is_instance_valid(w):
			w.queue_free()
	while _wolves.size() < desired:
		var w = _wolf_scene.instantiate()
		w.hero = self
		w.global_position = global_position
		# Beastlord gets dire wolves
		if get_meta("hero_class", "slingshot") == "beastlord":
			w.is_dire = true
		get_tree().current_scene.add_child(w)
		_wolves.append(w)

func _trigger_spirit_hawk() -> void:
	# Spirit hawk dive-bombs nearest enemy for 200% damage
	var target = _find_nearest_enemy()
	if not target:
		return
	# Visual: hawk diving at target
	_spawn_effect("spirit_hawk", target.global_position, 0.06, 0.5)
	var base_dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * 2.0
	if target.has_method("take_damage"):
		var dealt = target.take_damage(base_dmg, true, self)
		GameEvents.damage_dealt.emit(target, dealt, true, "normal")

func _on_enemy_killed_archer(enemy: Node2D) -> void:
	# Phantom: kills grant instant invisibility (2.5s cooldown)
	var hero_class = get_meta("hero_class", "slingshot")
	if hero_class == "phantom" and _phantom_stealth_cooldown <= 0.0 and not _phantom_invisible:
		_phantom_invisible = true
		_phantom_stealth_cooldown = 2.5
		modulate.a = 0.3
		_spawn_effect("stealth_smoke", global_position, 0.06, 0.4)
	# Deadeye: kill streak stacks +30% per kill within 3s
	if hero_class == "deadeye":
		_deadeye_kill_streak_mult += 0.3
		_deadeye_kill_streak_timer = 3.0

func _exit_tree() -> void:
	for w in _wolves:
		if is_instance_valid(w):
			w.queue_free()
	_wolves.clear()
