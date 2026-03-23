extends Node
## Listens for damage events and spawns floating numbers via object pool.

const ObjectPool = preload("res://scripts/core/object_pool.gd")
var _pool: Node
var _damage_number_scene: PackedScene

func _ready() -> void:
	_damage_number_scene = preload("res://scenes/damage_number.tscn")
	_pool = ObjectPool.new()
	_pool.setup(_damage_number_scene, 50)
	add_child(_pool)
	GameEvents.damage_dealt.connect(_spawn)

func _spawn(target: Node2D, amount: float, is_crit: bool, damage_type: String = "normal") -> void:
	if not is_instance_valid(target):
		return
	if amount <= 0.0:
		return
	var dmg_num = _pool.acquire()
	dmg_num._pool = _pool
	dmg_num.show_damage(amount, is_crit, target.global_position + Vector2(0, -20), damage_type)
