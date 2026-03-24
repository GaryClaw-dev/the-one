extends Node
## Spawns floating damage numbers for 3D targets.
## Projects 3D positions to 2D screen coordinates.

const ObjectPool = preload("res://scripts/core/object_pool.gd")
var _pool: Node
var _damage_number_scene: PackedScene

func _ready() -> void:
	_damage_number_scene = preload("res://scenes/damage_number.tscn")
	_pool = ObjectPool.new()
	_pool.setup(_damage_number_scene, 50)
	add_child(_pool)
	GameEvents.damage_dealt.connect(_spawn)

func _spawn(target: Node, amount: float, is_crit: bool, damage_type: String = "normal") -> void:
	if not is_instance_valid(target):
		return
	if amount <= 0.0:
		return

	var screen_pos := Vector2.ZERO
	if target is Node3D:
		var cam = get_viewport().get_camera_3d()
		if cam:
			var world_pos = (target as Node3D).global_position + Vector3(0, 2, 0)
			screen_pos = cam.unproject_position(world_pos)
		else:
			return
	elif target is Node2D:
		screen_pos = (target as Node2D).global_position + Vector2(0, -20)
	else:
		return

	var dmg_num = _pool.acquire()
	dmg_num._pool = _pool
	dmg_num.show_damage(amount, is_crit, screen_pos, damage_type)
