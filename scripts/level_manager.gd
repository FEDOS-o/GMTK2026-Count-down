# level_manager.gd
extends Node

signal level_loaded(level_data: LevelData)
signal level_completed(level_id: String)
signal level_failed(level_id: String)

# 🔥 Убираем статическую переменную
# Используем только как Autoload

var current_level: LevelData = null
var available_levels: Array[LevelData] = []
var character_scenes_cache: Dictionary = {}

func _ready():
	_load_all_levels()

func _load_all_levels():
	# Загружаем все ресурсы уровней из папки
	var dir = DirAccess.open("res://resources/levels/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var path = "res://resources/levels/" + file_name
				if ResourceLoader.exists(path):
					var level = load(path)
					if level is LevelData:
						available_levels.append(level)
						print("✅ Загружен уровень: ", level.level_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Если нет уровней - создаем тестовый
	if available_levels.is_empty():
		print("⚠️ Нет уровней, создаю тестовый...")
		var test_level = LevelData.create_test_level()
		available_levels.append(test_level)
		
		# Сохраняем для будущего использования
		ResourceSaver.save(test_level, "res://resources/levels/test_level.tres")
		print("✅ Создан тестовый уровень")

func load_level(level_id: String) -> bool:
	for level in available_levels:
		if level.level_id == level_id:
			current_level = level
			level_loaded.emit(level)
			print("📂 Загружен уровень: ", level.level_name)
			return true
	
	print("❌ Уровень не найден: ", level_id)
	return false

func load_level_by_index(index: int) -> bool:
	if index < 0 or index >= available_levels.size():
		return false
	return load_level(available_levels[index].level_id)

func get_current_level() -> LevelData:
	return current_level

func get_next_level() -> LevelData:
	var current_index = available_levels.find(current_level)
	if current_index == -1 or current_index >= available_levels.size() - 1:
		return null
	return available_levels[current_index + 1]

func get_level_count() -> int:
	return available_levels.size()

func get_levels() -> Array[LevelData]:
	return available_levels

func complete_level(level_id: String):
	if current_level and current_level.level_id == level_id:
		level_completed.emit(level_id)
		print("🏆 Уровень завершен: ", level_id)

func fail_level(level_id: String):
	if current_level and current_level.level_id == level_id:
		level_failed.emit(level_id)
		print("💀 Уровень провален: ", level_id)
