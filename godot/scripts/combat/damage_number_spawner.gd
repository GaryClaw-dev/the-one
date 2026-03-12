extends Node
## Listens for damage events and spawns floating numbers.

var _damage_number_scene: PackedScene

func _ready() -> void:
	_damage_number_scene = preload("res://scenes/damage_number.tscn")
	GameEvents.damage_dealt.connect(_spawn)

func _spawn(target: Node2D, amount: float, is_crit: bool) -> void:
	if not is_instance_valid(target):
		return
	var dmg_num: Node2D = _damage_number_scene.instantiate()
	get_tree().current_scene.add_child(dmg_num)
	dmg_num.show_damage(amount, is_crit, target.global_position + Vector2(0, -20))
