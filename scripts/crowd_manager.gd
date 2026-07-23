# crowd_manager.gd
extends Node

signal character_spawned(character)
signal character_captured(character)
signal crowd_updated(count: int)

@export var character_scenes: Array[PackedScene] = []  # Fallback

var all_characters: Array = []
var spawn_zones: Array = []
var target_zones: Array = []
var level_container: Node3D = null
var current_level: LevelData = null

func _ready():
	find_level_container()
	find_zones()
	
	# 🔥 Подключаемся к менеджеру уровней
	if LevelManager:
		LevelManager.level_loaded.connect(_on_level_loaded)
	
	# Загружаем дефолтные сцены как fallback
	load_character_scenes()

func _on_level_loaded(level: LevelData):
	current_level = level
	print("📂 CrowdManager получил уровень: ", level.level_name)
	
	# Обновляем параметры спавна
	for zone in spawn_zones:
		if zone.has_method("set_spawn_rate"):
			zone.set_spawn_rate(level.spawn_rate)
		if zone.has_method("set_max_characters"):
			zone.set_max_characters(level.max_characters)

func find_level_container():
	var root = get_tree().root
	var container = root.find_child("LevelContainer", true, false)
	if container and container is Node3D:
		level_container = container as Node3D
		return
	
	container = root.find_child("World", true, false)
	if container and container is Node3D:
		level_container = container as Node3D
		return
	
	level_container = Node3D.new()
	level_container.name = "LevelContainer"
	root.add_child(level_container)

func find_zones():
	spawn_zones.clear()
	target_zones.clear()
	
	if not level_container:
		return
	
	_find_zones_recursive(level_container)

func _find_zones_recursive(parent: Node):
	for child in parent.get_children():
		if child is SpawnZone:
			spawn_zones.append(child)
		elif child is TargetZone:
			target_zones.append(child)
		_find_zones_recursive(child)

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

# crowd_manager.gd
# В функции spawn_character:

func spawn_character(position: Vector3):
	if not current_level:
		print("⚠️ Нет загруженного уровня!")
		return null
	
	# 🔥 Используем фабрику через ее имя (как Autoload)
	if CharacterFactory:
		var character = CharacterFactory.create_character(current_level, position, level_container)
		if character:
			all_characters.append(character)
			character.character_destroyed.connect(_on_character_destroyed)
			
			# Назначаем цель
			var target_zone = get_random_target_zone()
			if target_zone and target_zone.has_method("get_random_point"):
				var target_pos = target_zone.get_random_point()
				character.set_target(target_pos)
				character.target_zone = target_zone
			
			character_spawned.emit(character)
			crowd_updated.emit(all_characters.size())
			return character
	
	# Fallback: старая логика
	return _spawn_character_fallback(position)

func _spawn_character_fallback(position: Vector3) -> BaseCharacter:
	if character_scenes.is_empty():
		return null
	
	var scene = character_scenes[randi() % character_scenes.size()]
	var character = scene.instantiate()
	
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
	
	var target_zone = get_random_target_zone()
	if target_zone and target_zone.has_method("get_random_point"):
		var target_pos = target_zone.get_random_point()
		character.set_target(target_pos)
		character.target_zone = target_zone
	
	character_spawned.emit(character)
	crowd_updated.emit(all_characters.size())
	
	return character

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

func get_random_target_zone():
	if target_zones.is_empty():
		return null
	return target_zones[randi() % target_zones.size()]

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
