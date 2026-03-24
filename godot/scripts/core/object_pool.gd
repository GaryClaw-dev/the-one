extends Node
## Generic object pool. Pre-instantiates scenes and recycles them.
## Usage: var pool = ObjectPool.new(scene, 50); add_child(pool)
##        var obj = pool.acquire(); ... pool.release(obj)

var _scene: PackedScene
var _pool: Array[Node] = []
var _active_count: int = 0

func _init(scene: PackedScene = null, pool_size: int = 0) -> void:
	_scene = scene
	if scene and pool_size > 0:
		call_deferred("_prewarm", pool_size)

func setup(scene: PackedScene, pool_size: int) -> void:
	_scene = scene
	_prewarm(pool_size)

func _prewarm(count: int) -> void:
	for _i in range(count):
		var obj = _scene.instantiate()
		_deactivate(obj)
		add_child(obj)
		_pool.append(obj)

func acquire() -> Node:
	var obj: Node = null
	while _pool.size() > 0 and obj == null:
		var candidate = _pool.pop_back()
		if is_instance_valid(candidate):
			obj = candidate
	if obj == null:
		obj = _scene.instantiate()
		add_child(obj)
	obj.set_process(true)
	obj.set_physics_process(true)
	obj.visible = true
	# Use set_deferred for physics state — acquire may be called during physics callbacks
	if obj is Area2D:
		obj.set_deferred("monitoring", true)
		obj.set_deferred("monitorable", true)
	for child in obj.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
	_active_count += 1
	return obj

func release(obj: Node) -> void:
	if not is_instance_valid(obj):
		return
	_deactivate(obj)
	# Reparent back to pool so it doesn't get freed with the scene
	if obj.get_parent() != self:
		obj.get_parent().call_deferred("remove_child", obj)
		call_deferred("add_child", obj)
	_active_count -= 1
	_pool.append(obj)

func _deactivate(obj: Node) -> void:
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.visible = false
	if obj is Area2D:
		obj.set_deferred("monitoring", false)
		obj.set_deferred("monitorable", false)
	for child in obj.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)

func get_active_count() -> int:
	return _active_count
