# scripts/character.gd
extends CharacterBody3D
class_name BaseCharacter

# Настройки персонажа
@export var walk_speed: float = 3.0
@export var min_walk_speed: float = 2.0
@export var max_walk_speed: float = 4.0
@export var direction: Vector3 = Vector3.FORWARD
@export var target_position: Vector3 = Vector3.ZERO  # Целевая позиция для движения

# Компоненты
@onready var mesh_container: Node3D = $MeshContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Состояние
var is_walking: bool = true
var is_captured: bool = false
var tags: Array[String] = []
var is_moving_to_target: bool = false
var target_zone: TargetZone = null
var has_reached_target: bool = false  # 🔥 Новый флаг

# Сигналы
signal character_destroyed(character: BaseCharacter)

# Ссылка на зону спавна
var spawn_zone: SpawnZone = null

func _ready():
	# Случайная скорость
	walk_speed = randf_range(min_walk_speed, max_walk_speed)
	
	# Настраиваем персонажа
	setup_character()
	
	# Стартуем с задержкой
	await get_tree().create_timer(randf_range(0, 0.5)).timeout
	start_walking()

func setup_character():
	# Переопределяется в дочерних классах
	pass

func start_walking():
	is_walking = true
	if animation_player and animation_player.has_animation("walk"):
		animation_player.play("walk")

func stop_walking():
	is_walking = false
	if animation_player:
		animation_player.stop()

func set_target(target_pos: Vector3):
	target_position = target_pos
	is_moving_to_target = true
	has_reached_target = false
	# Поворачиваемся к цели
	var direction_to_target = (target_pos - global_position).normalized()
	direction = direction_to_target
	print("Персонаж идет к цели: ", target_pos)

func _physics_process(delta: float):
	if not is_walking or is_captured or has_reached_target:
		return
	
	# Если есть цель - двигаемся к ней
	if is_moving_to_target and target_position != Vector3.ZERO:
		var distance = global_position.distance_to(target_position)
		
		# 🔥 Увеличиваем радиус обнаружения для надежности
		if distance < 0.8:
			# Достигли цели
			has_reached_target = true
			is_moving_to_target = false
			stop_walking()
			
			# 🔥 Проверяем, не в зоне ли мы назначения
			if target_zone:
				print("✅ Персонаж достиг зоны назначения!")
				target_zone.check_character_entered(self)
			else:
				print("⚠️ У персонажа нет target_zone!")
			return
		
		# Двигаемся к цели
		var direction_to_target = (target_position - global_position).normalized()
		direction = direction_to_target
		
		var velocity_vec = direction * walk_speed
		velocity.x = velocity_vec.x
		velocity.z = velocity_vec.z
	else:
		# Обычное движение
		var velocity_vec = direction * walk_speed
		velocity.x = velocity_vec.x
		velocity.z = velocity_vec.z
	
	# Гравитация
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	
	move_and_slide()
	
	# Поворачиваем персонажа в направлении движения
	if direction != Vector3.ZERO:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

# Функция для взаимодействия (клик)
var capture_agent_spawned: bool = false

func on_interact():
	print("🖱️ Клик по персонажу: ", name)
	
	if is_captured:
		print("⚠️ Уже захвачен")
		return
	
	if has_reached_target:
		print("⚠️ Уже достиг цели")
		return
	
	if capture_agent_spawned:
		print("⚠️ Агент уже вызван")
		return
	
	# 🔥 НОВАЯ ЛОГИКА: останавливаемся и зовём агента
	stop_walking()
	is_walking = false
	capture_agent_spawned = true
	_spawn_capture_agent()
	
# Функция захвата персонажа
func capture():
	if is_captured:
		return
	
	is_captured = true
	stop_walking()
	
	print("Персонаж захвачен: ", name)
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(_on_capture_complete)

func _on_capture_complete():
	character_destroyed.emit(self)
	queue_free()

# Добавление тегов
func add_tag(tag: String):
	if not tag in tags:
		tags.append(tag)

func has_tag(tag: String) -> bool:
	return tag in tags

# Получение данных персонажа
func get_character_data() -> Dictionary:
	return {
		"name": name,
		"tags": tags,
		"position": global_position
	}

func _spawn_capture_agent():
	var spawn_zone = _get_random_spawn_zone()
	if not spawn_zone:
		print("❌ Нет зон спавна!")
		return
	
	var spawn_pos = global_position
	if spawn_zone.has_method("get_random_spawn_point"):
		spawn_pos = spawn_zone.get_random_spawn_point()
	
	print("📍 Спавн агента в: ", spawn_pos)
	
	var agent = CaptureAgent.new()
	agent.global_position = spawn_pos
	agent.set_target(self)
	
	var container = _get_level_container()
	if container:
		container.add_child(agent)
	else:
		get_tree().root.add_child(agent)
	
	print("✅ Агент создан")

func _get_random_spawn_zone():
	var cm = get_node_or_null("/root/CrowdManager")
	if cm and cm.has_method("get_random_spawn_zone"):
		return cm.get_random_spawn_zone()
	
	var zones: Array = []
	_find_zones_recursive(get_tree().root, zones)
	return zones[randi() % zones.size()] if zones.size() > 0 else null

func _find_zones_recursive(node: Node, zones: Array):
	for child in node.get_children():
		if child is SpawnZone:
			zones.append(child)
		_find_zones_recursive(child, zones)

func _get_level_container() -> Node:
	var root = get_tree().root
	var c = root.find_child("LevelContainer", true, false)
	if c: return c
	c = root.find_child("World", true, false)
	if c: return c
	return null
