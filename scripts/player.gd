# scripts/player.gd
extends CharacterBody3D
class_name Player

# Настройки движения
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 15.0

# Настройки камеры
@export var mouse_sensitivity: float = 0.002
@export var camera_height: float = 1.7

# Настройки взаимодействия
@export var interaction_distance: float = 10.0
@export var show_interaction_ray: bool = false

# Компоненты
@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay  # 🔥 Луч внутри камеры

# Состояние
var _velocity: Vector3 = Vector3.ZERO
var _mouse_captured: bool = false

func _ready():
	# Захватываем мышь
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true
	
	# Настраиваем камеру
	camera.position = Vector3(0, camera_height, 0)
	
	# Настраиваем raycast
	_setup_interaction_ray()

func _setup_interaction_ray():
	if interaction_ray:
		# Луч уже внутри камеры, просто настраиваем длину
		interaction_ray.target_position = Vector3(0, 0, -interaction_distance)
		interaction_ray.enabled = true
		
		# Включаем отладку если нужно
		if show_interaction_ray:
			interaction_ray.debug_shape_custom_color = Color(1, 0, 0, 0.5)
			interaction_ray.debug_shape_thickness = 2
			interaction_ray.debug_shape_collisions = true
		
		print("InteractionRay настроен: дистанция ", interaction_distance)

func _physics_process(delta: float):
	# Гравитация
	if not is_on_floor():
		_velocity.y -= gravity * delta
	
	# Движение
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	if direction.length() > 0:
		_velocity.x = move_toward(_velocity.x, direction.x * speed, speed * 10 * delta)
		_velocity.z = move_toward(_velocity.z, direction.z * speed, speed * 10 * delta)
	else:
		_velocity.x = move_toward(_velocity.x, 0, speed * 10 * delta)
		_velocity.z = move_toward(_velocity.z, 0, speed * 10 * delta)
	
	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_velocity.y = jump_velocity
	
	velocity = _velocity
	move_and_slide()
	

func _input(event):
	# Обработка мыши
	if event is InputEventMouseMotion and _mouse_captured:
		# Горизонтальный поворот - вращаем всего игрока
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Вертикальный поворот - вращаем только камеру
		var vertical_rotation = -event.relative.y * mouse_sensitivity
		camera.rotation.x += vertical_rotation
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	# ESC для освобождения мыши
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true
	
	# ЛКМ для взаимодействия
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true
		else:
			_handle_interaction()

func _handle_interaction():
	if not interaction_ray:
		return
	
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider:
			print("🔍 Raycast попал в: ", collider.name, " (", collider.get_class(), ")")
			
			# Проверяем объект
			if collider.has_method("on_interact"):
				collider.on_interact()
				print("✅ Взаимодействие с объектом!")
				return
			
			# Проверяем родителя
			var parent = collider.get_parent()
			if parent and parent.has_method("on_interact"):
				parent.on_interact()
				print("✅ Взаимодействие с родителем!")
				return
			
			# Проверяем, может это NPC с компонентом
			if collider.has_method("get_parent"):
				var grand_parent = collider.get_parent()
				if grand_parent and grand_parent.has_method("on_interact"):
					grand_parent.on_interact()
					print("✅ Взаимодействие с дедушкой!")
					return
			
			print("❌ Нет метода on_interact у объекта")

# Вспомогательные функции
func get_player_position() -> Vector3:
	return global_position

func get_camera_position() -> Vector3:
	return camera.global_position

func get_interaction_target() -> Vector3:
	if interaction_ray and interaction_ray.is_colliding():
		return interaction_ray.get_collision_point()
	return Vector3.ZERO
