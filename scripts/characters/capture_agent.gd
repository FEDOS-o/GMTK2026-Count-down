extends CharacterBody3D
class_name CaptureAgent

@export var move_speed: float = 8.0
@export var despawn_distance: float = 60.0

enum State { MOVING_TO_TARGET, CAPTURING, LEAVING }
var state: State = State.MOVING_TO_TARGET
var target_npc: Node3D = null
var leave_direction: Vector3 = Vector3.FORWARD

func _ready():
	# --- Создаём визуал агента ---
	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.6, 1.8, 0.4)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.9)
	body.mesh = box
	body.material_override = mat
	body.position = Vector3(0, 0.9, 0)
	add_child(body)
	
	var head = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.3, 0.3, 1.0)
	head.mesh = sphere
	head.material_override = head_mat
	head.position = Vector3(0, 1.9, 0)
	body.add_child(head)
	
	# --- Коллизия (обязательно для CharacterBody3D) ---
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

func set_target(npc: Node3D):
	target_npc = npc
	if target_npc:
		look_at(target_npc.global_position, Vector3.UP)

func _physics_process(delta: float):
	match state:
		State.MOVING_TO_TARGET: _move_to_target(delta)
		State.CAPTURING:        _capture()
		State.LEAVING:          _leave(delta)

func _move_to_target(delta):
	if not is_instance_valid(target_npc):
		_start_leaving()
		return
	
	var dist = global_position.distance_to(target_npc.global_position)
	if dist < 1.2:
		state = State.CAPTURING
		return
	
	var dir = (target_npc.global_position - global_position).normalized()
	velocity = Vector3(dir.x * move_speed, velocity.y, dir.z * move_speed)
	
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	look_at(target_npc.global_position, Vector3.UP)

func _capture():
	velocity = Vector3.ZERO
	
	if is_instance_valid(target_npc):
		if target_npc.has_method("stop_walking"):
			target_npc.stop_walking()
		
		var tween = create_tween()
		tween.tween_property(target_npc, "scale", Vector3.ZERO, 0.3)
		tween.tween_callback(func():
			if is_instance_valid(target_npc):
				target_npc.queue_free()
			target_npc = null
		)
	
	# Уходим через задержку
	await get_tree().create_timer(0.5).timeout
	_start_leaving()

func _start_leaving():
	if state == State.LEAVING:
		return
	state = State.LEAVING
	leave_direction = -global_transform.basis.z.normalized()

func _leave(delta):
	velocity = Vector3(leave_direction.x * move_speed, velocity.y, leave_direction.z * move_speed)
	
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if leave_direction != Vector3.ZERO:
		var target_rot = atan2(leave_direction.x, leave_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 0.1)
	
	if global_position.distance_to(Vector3.ZERO) > despawn_distance:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
		tween.tween_callback(queue_free)
