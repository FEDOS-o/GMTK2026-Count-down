# scripts/ui_manager.gd
extends CanvasLayer

@onready var counter_label: Label = $Counter
@onready var quest_info: Label = $Info
@onready var debug_label: Label = $Debug  # Добавим для отладки

func _ready():
	# Проверяем, что GameManager доступен
	if not get_tree().root.has_node("GameManager"):
		print("GameManager не найден как Autoload!")
		return
	
	# Подключаемся к сигналам GameManager
	var gm = get_tree().root.get_node("GameManager")
	
	# Проверяем, есть ли сигналы
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

func _update_counter(remaining: int):
	counter_label.text = "Осталось: " + str(remaining)
	if remaining <= 0:
		counter_label.text = "🎉 ВСЕ НАЙДЕНЫ!"

func _on_quest_started(quest_data: Dictionary):
	var title = quest_data.get("title", "Квест")
	var targets = quest_data.get("targets", 0)
	var description = quest_data.get("description", "")
	quest_info.text = "📋 " + title + "\n" + description
	print("UI: Квест начат -", title)

func _on_quest_completed(quest_id: String):
	quest_info.text = "✅ Квест выполнен! 🎉"
	counter_label.text = "0"
	print("UI: Квест завершен -", quest_id)

# Для отладки
func _process(delta):
	if debug_label:
		var gm = get_tree().root.get_node("GameManager")
		if gm:
			debug_label.text = "Квест: %s\nНайдено: %d/%d" % [
				gm.current_quest_id,
				gm.found_count,
				gm.current_quest_targets
			]
