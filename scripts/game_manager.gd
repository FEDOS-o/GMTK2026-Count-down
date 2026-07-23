extends Node

# Сигналы
signal quest_started(quest_data: Dictionary)
signal quest_completed(quest_id: String)
signal counter_updated(value: int)

# Переменные
var current_quest_id: String = ""
var current_quest_targets: int = 0
var found_count: int = 0
var dialogic_available: bool = false

func _ready():
	# Проверяем, доступен ли Dialogic
	if Engine.has_singleton("Dialogic"):
		dialogic_available = true
		if Dialogic.has_signal("signal_emitted"):
			Dialogic.signal_emitted.connect(_on_dialog_signal)
		if Dialogic.has_signal("timeline_started"):
			Dialogic.timeline_started.connect(_on_timeline_started)
		if Dialogic.has_signal("timeline_ended"):
			Dialogic.timeline_ended.connect(_on_timeline_ended)
	else:
		print("Dialogic не установлен или не включен")
		dialogic_available = false
	
	await get_tree().process_frame
	_test_quest()

func _test_quest():
	print("=== ТЕСТОВЫЙ КВЕСТ ===")
	print("Заказчик: Ученый")
	print("Задание: Найди 10 умных людей")
	print("Подсказка: Ищи людей в очках или с книгами")
	print("======================")
	
	start_quest("quest_1", {
		"title": "Умные люди",
		"targets": 10,
		"description": "Найди людей в очках или с книгами"
	})

func start_quest(quest_id: String, quest_data: Dictionary = {}):
	current_quest_id = quest_id
	current_quest_targets = quest_data.get("targets", 10)
	found_count = 0
	counter_updated.emit(current_quest_targets)
	
	quest_data["quest_id"] = quest_id
	quest_started.emit(quest_data)
	
	print("Квест начат:", quest_data.get("title", "Без названия"))
	
	# Запускаем толпу
	if CrowdManager:
		CrowdManager.start_crowd()
		print("🔥 CrowdManager.start_crowd() вызван!")
	else:
		print("❌ CrowdManager не найден!")
	
	if dialogic_available:
		_start_dialogic_timeline(quest_id)

func _start_dialogic_timeline(timeline_id: String):
	print("Запуск диалога:", timeline_id)

func _on_dialog_signal(signal_name: String, args: Array):
	match signal_name:
		"quest_started":
			print("Сигнал Dialogic: квест начался!")
		"quest_completed":
			print("Сигнал Dialogic: квест завершен!")
			quest_completed.emit(current_quest_id)

func _on_timeline_started():
	print("Диалог начался")

func _on_timeline_ended():
	print("Диалог закончился")

# 🔥 ГЛАВНЫЙ МЕТОД - принимает персонажа
func capture_character(character, is_correct: bool = true, was_captured_by_player: bool = false):
	if current_quest_targets == 0:
		print("Все квесты выполнены!")
		return
	
	# Проверяем через CrowdManager
	if CrowdManager and CrowdManager.has_method("capture_character"):
		CrowdManager.capture_character(character)
	
	# 🔥 Уменьшаем счетчик ТОЛЬКО если персонаж был захвачен игроком
	if was_captured_by_player and is_correct:
		found_count += 1
		var remaining = current_quest_targets - found_count
		counter_updated.emit(remaining)
		
		print("✅ Найден правильный персонаж! Осталось:", remaining)
		
		if found_count >= current_quest_targets:
			print("🎉 КВЕСТ ВЫПОЛНЕН!")
			quest_completed.emit(current_quest_id)
			
			if CrowdManager:
				CrowdManager.stop_crowd()
			
			if dialogic_available:
				_emit_dialogic_signal("quest_completed")
	elif is_correct:
		# Персонаж правильный, но захвачен автоматически (без клика)
		print("🔹 Персонаж достиг зоны и исчез (без клика)")
	else:
		print("❌ Неправильный персонаж!")
		_show_wrong_selection()

func _show_wrong_selection():
	print("Показываем анимацию ошибки")

func _emit_dialogic_signal(signal_name: String):
	print("Отправлен сигнал Dialogic:", signal_name)

func set_quest_targets(count: int):
	current_quest_targets = count
	counter_updated.emit(count - found_count)

func reset_counter():
	found_count = 0
	counter_updated.emit(current_quest_targets)
