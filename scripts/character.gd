# scripts/character.gd
extends CharacterBody3D
class_name BaseCharacter

# Настройки персонажа
@export var walk_speed: float = 3.0
@export var min_walk_speed: float = 2.0
@export var max_walk_speed: float = 4.0
@export var direction: Vector3 = Vector3.FORWARD
@export var target_position: Vector3 = Vector3.ZERO

# Компоненты
@onready var mesh_container: Node3D = $MeshContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Состояние
var is_walking: bool = true
var is_captured: bool = false
var tags: Array[String] = []
var is_moving_to_target: bool = false
var target_zone: TargetZone = null
var has_reached_target: bool = false
var is_being_captured: bool = false  # 🔥 Новый флаг для предотвращения повторного захвата

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
	if is_captured or is_being_captured:
		return
		
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
	# 🔥 Если персонаж захвачен или в процессе захвата - не двигаемся
	if is_captured or is_being_captured or not is_walking or has_reached_target:
		return
	
	# Если есть цель - двигаемся к ней
	if is_moving_to_target and target_position != Vector3.ZERO:
		var distance = global_position.distance_to(target_position)
		
		if distance < 0.8:
			# Достигли цели
			has_reached_target = true
			is_moving_to_target = false
			stop_walking()
			
			if target_zone:
				print("✅ Персонаж достиг зоны назначения!")
				target_zone.check_character_entered(self)
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
	if direction != Vector3.ZERO and not is_captured:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

# Функция для взаимодействия (клик)
func on_interact():
	if is_captured or is_being_captured:
		print("⚠️ Персонаж уже захвачен или в процессе захвата")
		return
	
	if has_reached_target:
		print("⚠️ Персонаж уже достиг цели и будет автоматически захвачен")
		return
	
	print("🖱️ Клик по персонажу: ", name)
	
	# Отмечаем, что персонаж был захвачен игроком
	set_meta("captured_by_player", true)
	
	# Проверяем, находится ли персонаж в зоне назначения
	if target_zone:
		var captured = target_zone.try_capture_character(self)
		if captured:
			print("✅ Персонаж захвачен через зону!")
			return
	
	# Если персонаж не в зоне или зоны нет - просто проверяем через GameManager
	var gm = get_tree().root.get_node("GameManager")
	if gm and gm.has_method("capture_character"):
		var is_correct = false
		if "wearing_glasses" in tags or "has_book" in tags:
			is_correct = true
		
		print("🔍 Теги персонажа: ", tags, " подходит: ", is_correct)
		gm.capture_character(self, is_correct, true)
	else:
		print("❌ GameManager не найден!")

# Функция захвата персонажа
func capture():
	if is_captured or is_being_captured:
		return
	
	is_being_captured = true
	is_captured = true
	stop_walking()
	
	# 🔥 Останавливаем физику - обнуляем скорость
	velocity = Vector3.ZERO
	
	# 🔥 ОТКЛЮЧАЕМ ФИЗИКУ - делаем персонажа статичным
	set_physics_process(false)
	
	print("Персонаж захвачен: ", name)
	
	# 🔥 Анимация исчезновения через SCALE
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1e-6, 1e-6, 1e-6), 0.5)
	tween.tween_callback(_on_capture_complete)

func _on_capture_complete():
	# 🔥 Включаем физику обратно перед удалением (на всякий случай)
	set_physics_process(true)
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
