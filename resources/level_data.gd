# resources/level_data.gd
extends Resource
class_name LevelData

# ===== ОСНОВНЫЕ ПАРАМЕТРЫ УРОВНЯ =====
@export var level_id: String = "level_1"
@export var level_name: String = "Красные люди"
@export var level_description: String = "Найди 10 человек в красной одежде"

# ===== ПАРАМЕТРЫ СПАВНА =====
# Структура: { "scene_path": "res://...", "weight": 1.0, "tags": ["tag1", "tag2"] }
@export var spawn_pool: Array[Dictionary] = []
@export var spawn_rate: float = 2.0
@export var max_characters: int = 15

# ===== ЦЕЛЬ КВЕСТА =====
@export var target_count: int = 10
@export var required_tags: Array[String] = []  # Теги, которые должны быть у персонажа
@export var required_combination: String = "ALL"  # ALL - все теги, ANY - хотя бы один

# ===== СПОСОБ ЗАХВАТА =====
@export var capture_method: String = "agent"  # "agent", "beam", "portal", "teleport", "manual"
@export var capture_agent_scene: PackedScene = null  # Если нужен кастомный агент
@export var capture_animation: String = "default"

# ===== ВИЗУАЛЬНЫЕ ПАРАМЕТРЫ =====
@export var background_color: Color = Color(0.2, 0.2, 0.3)
@export var ambient_light: Color = Color(0.5, 0.5, 0.6)
@export var ui_theme: String = "default"

# ===== ДИАЛОГИ =====
@export var intro_dialog: String = ""  # ID диалога из Dialogic
@export var success_dialog: String = ""
@export var fail_dialog: String = ""

# ===== ДОПОЛНИТЕЛЬНЫЕ ПАРАМЕТРЫ =====
@export var time_limit: float = 0.0  # 0 = без ограничения
@export var allowed_mistakes: int = 3  # -1 = бесконечно
@export var bonus_score: int = 0

# ===== МЕТОДЫ ДЛЯ ПРОВЕРКИ =====
func is_character_valid(character: BaseCharacter) -> bool:
	if required_tags.is_empty():
		return true
	
	var has_all = true
	var has_any = false
	
	for tag in required_tags:
		if character.has_tag(tag):
			has_any = true
		else:
			has_all = false
	
	match required_combination:
		"ALL":
			return has_all
		"ANY":
			return has_any
		_:
			return has_all

func get_spawn_entries() -> Array[Dictionary]:
	return spawn_pool

func get_weighted_scene() -> PackedScene:
	if spawn_pool.is_empty():
		return null
	
	var total_weight = 0.0
	for entry in spawn_pool:
		total_weight += entry.get("weight", 1.0)
	
	var random_value = randf_range(0, total_weight)
	var cumulative = 0.0
	
	for entry in spawn_pool:
		cumulative += entry.get("weight", 1.0)
		if random_value <= cumulative:
			var scene_path = entry.get("scene", "")
			if ResourceLoader.exists(scene_path):
				return load(scene_path)
			else:
				print("❌ Ресурс не найден: ", scene_path)
				return null
	
	return null

func get_tags_for_spawn() -> Array[String]:
	if spawn_pool.is_empty():
		return []
	
	var entry = spawn_pool[randi() % spawn_pool.size()]
	# 🔥 Явно приводим к Array[String]
	var tags: Array = entry.get("tags", [])
	return tags as Array[String]

func get_capture_agent() -> PackedScene:
	if capture_agent_scene:
		return capture_agent_scene
	
	# Возвращаем дефолтного агента
	match capture_method:
		"agent":
			return load("res://scenes/agents/default_agent.tscn")
		"beam":
			return load("res://scenes/agents/beam_agent.tscn")
		"portal":
			return load("res://scenes/agents/portal_agent.tscn")
		_:
			return load("res://scenes/agents/default_agent.tscn")

# ===== СОЗДАНИЕ РЕСУРСА =====
static func create_test_level() -> LevelData:
	var level = LevelData.new()
	level.level_id = "test_level"
	level.level_name = "Красные люди"
	level.level_description = "Найди 10 человек в красной одежде"
	
	level.spawn_pool = [
		{
			"scene": "res://scenes/characters/capsule_character.tscn",
			"weight": 1.0,
			"tags": ["human", "civilian"]
		}
	]
	
	level.target_count = 10
	level.required_tags = ["red"]
	level.required_combination = "ANY"
	
	level.capture_method = "agent"
	level.capture_animation = "default"
	
	return level
