class_name ClassEvolution
extends Resource
## Data definition for class evolution paths

@export var class_name: String = "Class"
@export_multiline var description: String = ""
@export var evolution_level: int = 15
@export var required_class: String = ""  # Previous class requirement
@export var hero_scene: PackedScene
@export var portrait: Texture2D

@export_group("Stat Modifiers")
@export var attack_speed_mult: float = 1.0
@export var attack_damage_mult: float = 1.0
@export var crit_chance_add: float = 0.0
@export var crit_damage_mult: float = 1.0
@export var projectile_speed_mult: float = 1.0
@export var projectile_count_add: int = 0
@export var move_speed_mult: float = 1.0
@export var max_health_mult: float = 1.0
@export var aoe_radius_add: float = 0.0

@export_group("New Mechanics")
@export var passive_abilities: Array[String] = []
@export var active_abilities: Array[String] = []
@export var new_ability_pool: Array[Resource] = []  # Additional abilities for this class

func apply_evolution(hero: HeroBase) -> void:
	var stats = hero.stats
	
	# Apply stat modifiers
	if attack_speed_mult != 1.0:
		stats.add_modifier(StatSystem.StatType.ATTACK_SPEED, StatSystem.ModType.PERCENT_ADD, 
			(attack_speed_mult - 1.0) * 100, self)
	
	if attack_damage_mult != 1.0:
		stats.add_modifier(StatSystem.StatType.ATTACK_DAMAGE, StatSystem.ModType.PERCENT_ADD,
			(attack_damage_mult - 1.0) * 100, self)
	
	if crit_chance_add != 0.0:
		stats.add_modifier(StatSystem.StatType.CRIT_CHANCE, StatSystem.ModType.FLAT, 
			crit_chance_add, self)
	
	if crit_damage_mult != 1.0:
		stats.add_modifier(StatSystem.StatType.CRIT_MULTIPLIER, StatSystem.ModType.PERCENT_ADD,
			(crit_damage_mult - 1.0) * 100, self)
	
	if projectile_speed_mult != 1.0:
		stats.add_modifier(StatSystem.StatType.PROJECTILE_SPEED, StatSystem.ModType.PERCENT_ADD,
			(projectile_speed_mult - 1.0) * 100, self)
	
	if projectile_count_add != 0:
		stats.add_modifier(StatSystem.StatType.PROJECTILE_COUNT, StatSystem.ModType.FLAT,
			projectile_count_add, self)
	
	if move_speed_mult != 1.0:
		stats.add_modifier(StatSystem.StatType.MOVE_SPEED, StatSystem.ModType.PERCENT_ADD,
			(move_speed_mult - 1.0) * 100, self)
	
	if max_health_mult != 1.0:
		stats.add_modifier(StatSystem.StatType.MAX_HEALTH, StatSystem.ModType.PERCENT_ADD,
			(max_health_mult - 1.0) * 100, self)
		hero.heal(hero.max_health)  # Full heal on evolution
	
	if aoe_radius_add != 0.0:
		stats.add_modifier(StatSystem.StatType.AOE_RADIUS, StatSystem.ModType.FLAT,
			aoe_radius_add, self)
	
	# Apply new mechanics
	for passive in passive_abilities:
		if hero.has_method("add_passive_ability"):
			hero.add_passive_ability(passive)
	
	for active in active_abilities:
		if hero.has_method("add_active_ability"):
			hero.add_active_ability(active)
