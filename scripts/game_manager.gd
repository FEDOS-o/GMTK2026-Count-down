# game_manager.gd
extends Node

signal quest_started(quest_data: Dictionary)
signal quest_completed(quest_id: String)
signal counter_updated(value: int)
signal level_updated(level_data)

var current_level: LevelData = null
var found_count: int = 0
var dialogic_available: bool = false

func _ready():
	# Проверяем Dialogic
	if Engine.has_singleton("Dialogic"):
		dialogic_available = true
		if Dialogic.has_signal("signal_emitted"):
			Dialogic.signal_emitted.connect(_on_dialog_signal)
	
	# Подключаемся к менеджеру уровней
	if LevelManager:
		LevelManager.level_loaded.connect(_on_level_loaded)
		
		await get_tree().process_frame
		
		if LevelManager.get_level_count() > 0:
			LevelManager.load_level_by_index(0)
		else:
			print("❌ Нет доступных уровней!")
	else:
		print("❌ LevelManager не найден!")

# 🔥 Геттеры для UI
func get_current_level() -> LevelData:
	return current_level

func get_found_count() -> int:
	return found_count

func get_target_count() -> int:
	if current_level:
		return current_level.target_count
	return 0

func _on_level_loaded(level: LevelData):
	current_level = level
	level_updated.emit(level)
	
	# Запускаем квест
	start_quest(level.level_id, {
		"title": level.level_name,
		"targets": level.target_count,
		"description": level.level_description,
		"required_tags": level.required_tags
	})

func start_quest(quest_id: String, quest_data: Dictionary = {}):
	found_count = 0
	var targets = quest_data.get("targets", 10)
	counter_updated.emit(targets)
	
	quest_data["quest_id"] = quest_id
	quest_started.emit(quest_data)
	
	print("📋 Квест начат: ", quest_data.get("title", "Без названия"))
	print("🎯 Нужно найти: ", targets, " персонажей")
	
	# Запускаем толпу
	if CrowdManager:
		CrowdManager.start_crowd()

func character_selected(character, is_valid: bool):
	if not current_level or found_count >= current_level.target_count:
		print("Все квесты выполнены!")
		return
	
	if is_valid:
		found_count += 1
		var remaining = current_level.target_count - found_count
		counter_updated.emit(remaining)
		
		print("✅ Правильный персонаж! Осталось:", remaining)
		
		# Забираем персонажа
		if CrowdManager and CrowdManager.has_method("capture_character"):
			CrowdManager.capture_character(character)
		
		if found_count >= current_level.target_count:
			print("🏆 УРОВЕНЬ ВЫПОЛНЕН!")
			quest_completed.emit(current_level.level_id)
			if LevelManager:
				LevelManager.complete_level(current_level.level_id)
			if CrowdManager:
				CrowdManager.stop_crowd()
	else:
		print("❌ Неправильный персонаж!")
		_show_wrong_selection()
		
		# Забираем неправильного персонажа
		if CrowdManager and CrowdManager.has_method("capture_character"):
			CrowdManager.capture_character(character)

func _show_wrong_selection():
	print("❌ Анимация ошибки")

func _on_dialog_signal(signal_name: String, _args: Array):
	match signal_name:
		"quest_completed":
			print("Диалог: квест завершен!")

# 🔥 Оставляем для совместимости с capture_character
func capture_character(character, is_correct: bool = false, was_captured_by_player: bool = false):
	if not current_level:
		print("⚠️ Нет текущего уровня!")
		return
	
	# Проверяем, красный ли персонаж
	var is_red = false
	if character.has_method("is_red_character"):
		is_red = character.is_red_character()
	elif character.has_tag("red"):
		is_red = true
	
	if was_captured_by_player:
		character_selected(character, is_red)
	else:
		# Автоматический захват (без клика игрока)
		print("🔹 Персонаж исчез автоматически: ", character.name)
		if CrowdManager and CrowdManager.has_method("capture_character"):
			CrowdManager.capture_character(character)
