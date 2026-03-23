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
		obj.set_process(false)
		obj.set_physics_process(false)
		add_child(obj)
		obj.visible = false
		if obj is Area2D:
			obj.monitoring = false
			obj.monitorable = false
		_pool.append(obj)

func acquire() -> Node:
	var obj: Node
	if _pool.size() > 0:
		obj = _pool.pop_back()
	else:
		# Pool exhausted — instantiate overflow
		obj = _scene.instantiate()
		add_child(obj)
	obj.set_process(true)
	obj.set_physics_process(true)
	obj.visible = true
	if obj is Area2D:
		obj.monitoring = true
		obj.monitorable = true
	_active_count += 1
	return obj

func release(obj: Node) -> void:
	if not is_instance_valid(obj):
		return
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.visible = false
	if obj is Area2D:
		obj.monitoring = false
		obj.monitorable = false
	_active_count -= 1
	_pool.append(obj)

func get_active_count() -> int:
	return _active_count
