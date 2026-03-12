extends HeroBase
## Slingshot family hero: all evolution branches share this script.
## Attack dispatch is based on hero_class meta, not scene swapping.

@export var crit_bonus_per_kill: float = 0.02
@export var max_crit_bonus: float = 0.5
@export var spread_angle: float = 10.0

var _streak_crit_mod: Dictionary = {}

# Wolf companion (Ranger)
var _wolf_timer: float = 0.0

# Preloaded evolution sprites
var _hero_sprites: Dictionary = {}
var _proj_sprites: Dictionary = {}

func _ready() -> void:
	super._ready()
	_hero_sprites = {
		"slingshot": load("res://art/heroes/slingshot/slingshot.png"),
		"archer": load("res://art/heroes/archer/archer.png"),
		"thrower": load("res://art/heroes/thrower/thrower.png"),
		"ranger": load("res://art/heroes/ranger/ranger.png"),
		"crossbow": load("res://art/heroes/crossbow/crossbow.png"),
		"lumberjack": load("res://art/heroes/lumberjack/lumberjack.png"),
		"catapult": load("res://art/heroes/catapult/catapult.png"),
	}
	_proj_sprites = {
		"rock": load("res://art/projectiles/rock/rock.png"),
		"boulder": load("res://art/projectiles/boulder/boulder.png"),
		"poison_arrow": load("res://art/projectiles/poison_arrow/poison_arrow.png"),
		"crossbow_bolt": load("res://art/projectiles/crossbow_bolt/crossbow_bolt.png"),
		"tree_trunk": load("res://art/projectiles/tree_trunk/tree_trunk.png"),
		"flaming_boulder": load("res://art/projectiles/flaming_boulder/flaming_boulder.png"),
	}
	GameEvents.hero_evolved.connect(_on_evolved)

func _on_evolved(new_class: String) -> void:
	var sprite = $Sprite2D as Sprite2D
	if sprite and _hero_sprites.has(new_class):
		sprite.texture = _hero_sprites[new_class]
		sprite.modulate = Color.WHITE

func perform_attack(target_node: Node2D) -> void:
	var dir = (target_node.global_position - global_position).normalized()
	match get_meta("hero_class", "slingshot"):
		"slingshot":
			_attack_slingshot(dir, target_node)
		"archer":
			_attack_archer(dir, target_node)
		"thrower":
			_attack_thrower(dir, target_node)
		"ranger":
			_attack_ranger(dir, target_node)
		"crossbow":
			_attack_crossbow(dir, target_node)
		"lumberjack":
			_attack_lumberjack(dir, target_node)
		"catapult":
			_attack_catapult(dir, target_node)
		_:
			_attack_slingshot(dir, target_node)
	# Flip sprite
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.flip_h = dir.x < 0

# ── Slingshot (tier 1) ──────────────────────────────────────────────
func _attack_slingshot(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	_fire_spread(dir, proj_count, spread_angle, target_node, false, 0)

# ── Archer (tier 2) ─────────────────────────────────────────────────
func _attack_archer(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	# Aimed Shot: every 5th attack = guaranteed crit + 2 extra pierce
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	_fire_spread(dir, proj_count, spread_angle, target_node, aimed_crit, aimed_pierce)
	_try_gunslinger(dir, proj_count, spread_angle)

# ── Thrower (tier 2) — boulders with built-in AoE ──────────────────
func _attack_thrower(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aoe = stats.get_stat(StatSystem.StatType.AOE_RADIUS)
	var throw_spread = 20.0
	if proj_count <= 1:
		var proj = fire_projectile(dir, 0.0, aoe, 1.0, target_node)
		_set_proj_sprite(proj, "rock", 0.04)
	else:
		var total = throw_spread * (proj_count - 1)
		var start = -total / 2.0
		for i in range(proj_count):
			var proj = fire_projectile(dir, start + throw_spread * i, aoe, 1.0, target_node)
			_set_proj_sprite(proj, "rock", 0.04)

# ── Ranger (tier 3, from Archer) — poison arrows ───────────────────
func _attack_ranger(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	# Inherits aimed shot from archer
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	if proj_count <= 1:
		var proj = fire_projectile(dir, 0.0, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
		_apply_poison_meta(proj)
		_set_proj_sprite(proj, "poison_arrow", 0.03)
	else:
		var total = spread_angle * (proj_count - 1)
		var start = -total / 2.0
		for i in range(proj_count):
			var proj = fire_projectile(dir, start + spread_angle * i, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
			_apply_poison_meta(proj)
			_set_proj_sprite(proj, "poison_arrow", 0.03)

# ── Crossbow (tier 3, from Archer) — 30° cone spread ───────────────
func _attack_crossbow(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	# Inherits aimed shot
	var aimed_crit = false
	var aimed_pierce = 0
	_aimed_shot_counter += 1
	if _aimed_shot_counter >= 5:
		_aimed_shot_counter = 0
		aimed_crit = true
		aimed_pierce = 2
	# Wide 30° cone spread
	var cone_spread = 30.0 / maxf(proj_count - 1, 1)
	if proj_count <= 1:
		var proj = fire_projectile(dir, 0.0, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
		_set_proj_sprite(proj, "crossbow_bolt", 0.03)
	else:
		var total = cone_spread * (proj_count - 1)
		var start = -total / 2.0
		for i in range(proj_count):
			var proj = fire_projectile(dir, start + cone_spread * i, 0.0, 1.0, target_node, aimed_crit, aimed_pierce)
			_set_proj_sprite(proj, "crossbow_bolt", 0.03)
	_try_gunslinger(dir, proj_count, cone_spread)

# ── Lumberjack (tier 3, from Thrower) — massive tree projectile ─────
func _attack_lumberjack(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aoe = stats.get_stat(StatSystem.StatType.AOE_RADIUS)
	var throw_spread = 25.0
	if proj_count <= 1:
		var proj = fire_projectile(dir, 0.0, aoe, 1.5, target_node)
		_set_proj_sprite(proj, "tree_trunk", 0.05)
		proj.set_meta("splinter", true)
		proj.set_meta("splinter_count", _get_splinter_count())
		proj.set_meta("splinter_damage_mult", _get_splinter_damage_mult())
	else:
		var total = throw_spread * (proj_count - 1)
		var start = -total / 2.0
		for i in range(proj_count):
			var proj = fire_projectile(dir, start + throw_spread * i, aoe, 1.5, target_node)
			_set_proj_sprite(proj, "tree_trunk", 0.05)
			proj.set_meta("splinter", true)
			proj.set_meta("splinter_count", _get_splinter_count())
			proj.set_meta("splinter_damage_mult", _get_splinter_damage_mult())

# ── Catapult (tier 3, from Thrower) — slow flaming boulders ─────────
func _attack_catapult(dir: Vector2, target_node: Node2D) -> void:
	var proj_count = _get_final_proj_count()
	var aoe = stats.get_stat(StatSystem.StatType.AOE_RADIUS)
	if proj_count <= 1:
		var proj = fire_projectile(dir, 0.0, aoe, 2.0, target_node)
		_set_proj_sprite(proj, "flaming_boulder", 0.05)
		_apply_catapult_meta(proj)
	else:
		var throw_spread = 25.0
		var total = throw_spread * (proj_count - 1)
		var start = -total / 2.0
		for i in range(proj_count):
			var proj = fire_projectile(dir, start + throw_spread * i, aoe, 2.0, target_node)
			_set_proj_sprite(proj, "flaming_boulder", 0.05)
			_apply_catapult_meta(proj)

# ── Shared helpers ──────────────────────────────────────────────────

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
	if count <= 1:
		fire_projectile(dir, 0.0, 0.0, 1.0, target_node, force_crit, extra_pierce)
	else:
		var total = spread * (count - 1)
		var start = -total / 2.0
		for i in range(count):
			fire_projectile(dir, start + spread * i, 0.0, 1.0, target_node, force_crit, extra_pierce)

func _try_gunslinger(dir: Vector2, proj_count: int, spread: float) -> void:
	if special_abilities.has("gunslinger"):
		var gs_data = special_abilities["gunslinger"]
		var dupe_chance = gs_data["values"][gs_data["level"] - 1]
		if randf() < dupe_chance:
			call_deferred("_gunslinger_extra_attack", dir, proj_count, spread)

func _gunslinger_extra_attack(dir: Vector2, proj_count: int, spread: float) -> void:
	if proj_count <= 1:
		fire_projectile(dir)
	else:
		var total = spread * (proj_count - 1)
		var start = -total / 2.0
		for i in range(proj_count):
			fire_projectile(dir, start + spread * i)

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
	# Poison coat: all ranger shots apply poison
	if special_abilities.has("poison_coat"):
		var pc_data = special_abilities["poison_coat"]
		var dps = pc_data["special_values"][pc_data["level"] - 1]
		proj.set_meta("poison_dps", dps)
		proj.set_meta("poison_duration", 4.0)

func _apply_catapult_meta(proj: Node2D) -> void:
	if not proj:
		return
	# Always ignite — built-in burn
	proj.set_meta("incendiary_chance", 1.0)
	proj.set_meta("incendiary_dps", 15.0)
	proj.set_meta("incendiary_duration", 3.0)
	# Scorched earth fire zone
	if special_abilities.has("scorched_earth"):
		var se_data = special_abilities["scorched_earth"]
		proj.set_meta("scorched_earth_duration", se_data["values"][se_data["level"] - 1])
		proj.set_meta("scorched_earth_dps", se_data["special_values"][se_data["level"] - 1])

func _get_splinter_count() -> int:
	if special_abilities.has("splinter_storm"):
		var ss_data = special_abilities["splinter_storm"]
		return int(ss_data["values"][ss_data["level"] - 1])
	return 5  # Default

func _get_splinter_damage_mult() -> float:
	if special_abilities.has("splinter_storm"):
		var ss_data = special_abilities["splinter_storm"]
		return ss_data["special_values"][ss_data["level"] - 1]
	return 0.3  # Default 30%

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

# ── Wolf companion update (Ranger) ──────────────────────────────────

func _update_special_abilities(delta: float) -> void:
	super._update_special_abilities(delta)
	# Wolf companion timer
	if special_abilities.has("wolf_companion"):
		var wc_data = special_abilities["wolf_companion"]
		var interval = wc_data["special_values"][wc_data["level"] - 1]
		var wolf_count = int(wc_data["values"][wc_data["level"] - 1])
		_wolf_timer -= delta
		if _wolf_timer <= 0.0:
			_wolf_timer = interval
			_wolf_attack(wolf_count)

func _wolf_attack(wolf_count: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var valid_enemies: Array[Node2D] = []
	for e in enemies:
		if is_instance_valid(e) and e is Node2D and not (e.has_method("is_dead") and e.is_dead()):
			valid_enemies.append(e)
	if valid_enemies.is_empty():
		return
	var dmg = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * 0.6
	for i in range(wolf_count):
		var target = valid_enemies[randi() % valid_enemies.size()]
		if is_instance_valid(target) and target.has_method("take_damage"):
			var dealt = target.take_damage(dmg, false, self)
			GameEvents.damage_dealt.emit(target, dealt, false)
