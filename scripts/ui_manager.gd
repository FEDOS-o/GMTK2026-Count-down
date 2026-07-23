# scripts/ui_manager.gd
extends CanvasLayer

@onready var counter_label: Label = $Counter
@onready var quest_info: Label = $Info
@onready var debug_label: Label = $Debug

func _ready():
	# Проверяем, что GameManager доступен
	if not get_tree().root.has_node("GameManager"):
		print("GameManager не найден как Autoload!")
		return
	
	# Подключаемся к сигналам GameManager
	var gm = get_tree().root.get_node("GameManager")
	
	# Подключаемся к сигналам
	if gm.has_signal("counter_updated"):
		gm.counter_updated.connect(_update_counter)
	else:
		print("Сигнал counter_updated не найден!")
	
	if gm.has_signal("quest_completed"):
		gm.quest_completed.connect(_on_quest_completed)
	else:
		print("Сигнал quest_completed не найден!")
	
	if gm.has_signal("quest_started"):
		gm.quest_started.connect(_on_quest_started)
	else:
		print("Сигнал quest_started не найден!")
	
	# 🔥 Подключаемся к сигналу level_updated
	if gm.has_signal("level_updated"):
		gm.level_updated.connect(_on_level_updated)

func _update_counter(remaining: int):
	counter_label.text = "Осталось: " + str(remaining)
	if remaining <= 0:
		counter_label.text = "🎉 ВСЕ НАЙДЕНЫ!"

func _on_quest_started(quest_data: Dictionary):
	var title = quest_data.get("title", "Квест")
	var description = quest_data.get("description", "")
	quest_info.text = "📋 " + title + "\n" + description
	print("UI: Квест начат -", title)

func _on_quest_completed(quest_id: String):
	quest_info.text = "✅ Квест выполнен! 🎉"
	counter_label.text = "0"
	print("UI: Квест завершен -", quest_id)

# 🔥 Новый обработчик для обновления уровня
func _on_level_updated(level_data):
	if level_data:
		var title = level_data.level_name
		var description = level_data.level_description
		quest_info.text = "📋 " + title + "\n" + description
		print("UI: Уровень обновлен -", title)

# Для отладки
func _process(_delta):
	if debug_label:
		var gm = get_tree().root.get_node("GameManager")
		if gm:
			# 🔥 Используем current_level вместо current_quest_id
			var level_name = "Нет уровня"
			var found = 0
			var target = 0
			
			if gm.has_method("get_current_level"):
				var level = gm.get_current_level()
				if level:
					level_name = level.level_name
					target = level.target_count
			
			if gm.has_method("get_found_count"):
				found = gm.get_found_count()
			
			debug_label.text = "Уровень: %s\nНайдено: %d/%d" % [
				level_name,
				found,
				target
			]
