# crowd_manager.gd
extends Node

# Сигналы
signal character_spawned(character)
signal character_captured(character)
signal crowd_updated(count: int)

# Настройки
@export var character_scenes: Array[PackedScene] = []
@export var character_weights: Array[float] = []

# Ссылки
var all_characters: Array = []
var spawn_zones: Array = []
var target_zones: Array = []
var level_container: Node3D = null

func _ready():
	find_level_container()
	find_zones()
	load_character_scenes()
	
	print("CrowdManager инициализирован")
	print("Найдено зон спавна: ", spawn_zones.size())
	print("Найдено зон назначения: ", target_zones.size())

func find_level_container():
	var root = get_tree().root
	
	var container = root.find_child("LevelContainer", true, false)
	if container and container is Node3D:
		level_container = container as Node3D
		print("Контейнер уровня: ", level_container.name)
		return
	
	container = root.find_child("World", true, false)
	if container and container is Node3D:
		level_container = container as Node3D
		print("Контейнер World: ", level_container.name)
		return
	
	level_container = Node3D.new()
	level_container.name = "LevelContainer"
	root.add_child(level_container)
	print("Создан новый контейнер уровня")

func find_zones():
	spawn_zones.clear()
	target_zones.clear()
	
	if not level_container:
		return
	
	_find_zones_recursive(level_container)
	
	if spawn_zones.is_empty() and target_zones.is_empty():
		_create_test_zones()

func _find_zones_recursive(parent: Node):
	for child in parent.get_children():
		if child is SpawnZone:
			spawn_zones.append(child)
			print("Найдена зона спавна: ", child.name)
		elif child is TargetZone:
			target_zones.append(child)
			print("Найдена зона назначения: ", child.name)
		
		_find_zones_recursive(child)

func _create_test_zones():
	print("Создаю тестовые зоны...")
	
	if not level_container:
		return
	
	# Загружаем скрипты
	var spawn_script = load("res://scripts/zones/spawn_zone.gd")
	var target_script = load("res://scripts/zones/target_zone.gd")
	
	if not spawn_script or not target_script:
		print("❌ Не удалось загрузить скрипты зон!")
		return
	
	# --- СОЗДАЕМ ЗОНУ СПАВНА ---
	var spawn_zone = Area3D.new()
	spawn_zone.set_script(spawn_script)
	spawn_zone.name = "TestSpawnZone"
	spawn_zone.position = Vector3(0, 0, -5)  # 🔥 Сдвигаем подальше
	
	# Добавляем коллизию
	var spawn_collision = CollisionShape3D.new()
	var spawn_box = BoxShape3D.new()
	spawn_box.size = Vector3(4, 1, 2)
	spawn_collision.shape = spawn_box
	spawn_collision.position = Vector3(0, 0, 0)  # 🔥 Явно указываем позицию
	spawn_zone.add_child(spawn_collision)
	
	# Устанавливаем параметры
	spawn_zone.spawn_rate = 2.0
	spawn_zone.max_characters = 8
	spawn_zone.show_debug = true
	
	level_container.add_child(spawn_zone)
	spawn_zones.append(spawn_zone)
	print("✅ Создана зона спавна: ", spawn_zone.name, " позиция: ", spawn_zone.position)
	
	# --- СОЗДАЕМ ЗОНУ НАЗНАЧЕНИЯ ---
	var target_zone = Area3D.new()
	target_zone.set_script(target_script)
	target_zone.name = "TestTargetZone"
	target_zone.position = Vector3(0, 0, 5)  # 🔥 Сдвигаем подальше
	
	# Добавляем коллизию
	var target_collision = CollisionShape3D.new()
	var target_box = BoxShape3D.new()
	target_box.size = Vector3(3, 1, 2)
	target_collision.shape = target_box
	target_collision.position = Vector3(0, 0, 0)  # 🔥 Явно указываем позицию
	target_zone.add_child(target_collision)
	
	# Устанавливаем параметры
	target_zone.target_name = "Сбор"
	target_zone.auto_capture = true
	target_zone.show_debug = true
	target_zone.debug_color = Color(1, 0, 0, 0.3)
	
	level_container.add_child(target_zone)
	target_zones.append(target_zone)
	print("✅ Создана зона назначения: ", target_zone.name, " позиция: ", target_zone.position)

func load_character_scenes():
	if character_scenes.is_empty():
		var default_scenes = [
			"res://scenes/characters/capsule_character.tscn",
		]
		
		for scene_path in default_scenes:
			if ResourceLoader.exists(scene_path):
				var scene = load(scene_path)
				if scene:
					character_scenes.append(scene)
					character_weights.append(1.0)
					print("Загружена сцена персонажа: ", scene_path)

func start_crowd():
	for zone in spawn_zones:
		if zone.has_method("start_spawning"):
			zone.start_spawning()
	print("Толпа активирована")

func stop_crowd():
	for zone in spawn_zones:
		if zone.has_method("stop_spawning"):
			zone.stop_spawning()
	print("Толпа остановлена")

func spawn_character(position: Vector3):
	if character_scenes.is_empty():
		print("Нет сцен персонажей для спавна!")
		return null
	
	var selected_scene = _select_weighted_scene()
	if not selected_scene:
		return null
	
	var character = selected_scene.instantiate()
	if not character:
		return null
	
	if level_container:
		level_container.add_child(character)
	else:
		add_child(character)
	
	character.global_position = position
	
	if randf() > 0.5:
		character.direction = Vector3.FORWARD
	else:
		character.direction = Vector3.BACK
	
	
	
	all_characters.append(character)
	character.character_destroyed.connect(_on_character_destroyed)
	
	# Получаем целевую зону
	var target_zone = get_random_target_zone()
	if target_zone and target_zone.has_method("get_random_point"):
		var target_pos = target_zone.get_random_point()
		if character.has_method("set_target"):
			character.set_target(target_pos)
			character.target_zone = target_zone
			print("🎯 Персонажу назначена цель: ", target_pos)
	
	character_spawned.emit(character)
	crowd_updated.emit(all_characters.size())
	
	return character

func _select_weighted_scene():
	if character_scenes.is_empty():
		return null
	
	if character_weights.is_empty() or character_weights.size() != character_scenes.size():
		return character_scenes[randi() % character_scenes.size()]
	
	var total_weight = 0.0
	for weight in character_weights:
		total_weight += weight
	
	var random_value = randf_range(0, total_weight)
	var cumulative = 0.0
	
	for i in range(character_scenes.size()):
		cumulative += character_weights[i]
		if random_value <= cumulative:
			return character_scenes[i]
	
	return character_scenes[character_scenes.size() - 1]

func _on_character_destroyed(character):
	if character in all_characters:
		all_characters.erase(character)
		crowd_updated.emit(all_characters.size())

func capture_character(character):
	if character in all_characters:
		all_characters.erase(character)
		character_captured.emit(character)
		crowd_updated.emit(all_characters.size())
		if character.has_method("capture"):
			character.capture()

func clear_all_characters():
	for character in all_characters:
		character.queue_free()
	all_characters.clear()
	crowd_updated.emit(0)

func get_random_target_zone():
	if target_zones.is_empty():
		return null
	return target_zones[randi() % target_zones.size()]

func get_random_spawn_zone():
	if spawn_zones.is_empty():
		return null
	return spawn_zones[randi() % spawn_zones.size()]

func print_crowd_info():
	print("=== Информация о толпе ===")
	print("Всего персонажей: ", all_characters.size())
	print("Зон спавна: ", spawn_zones.size())
	print("Зон назначения: ", target_zones.size())
	
	var tags_stats = {}
	for character in all_characters:
		if character.has_method("tags"):
			for tag in character.tags:
				tags_stats[tag] = tags_stats.get(tag, 0) + 1
	
	print("Теги:")
	for tag in tags_stats:
		print("  ", tag, ": ", tags_stats[tag])
