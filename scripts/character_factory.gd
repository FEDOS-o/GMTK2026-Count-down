# character_factory.gd
extends Node

# 🔥 Убираем статическую переменную instance
# Используем только как Autoload

func _ready():
	# Не нужно присваивать instance
	pass

# 🔥 Все методы делаем статическими
static func create_character(level: LevelData, position: Vector3, parent: Node) -> BaseCharacter:
	if not level:
		print("❌ Нет данных уровня для создания персонажа")
		return null
	
	# Получаем случайную сцену из пула
	var scene = level.get_weighted_scene()
	if not scene:
		print("❌ Нет сцен для спавна")
		return null
	
	# Инстанцируем персонажа
	var character = scene.instantiate()
	if not character is BaseCharacter:
		print("❌ Сцена не является BaseCharacter")
		return null
	
	# Добавляем в дерево
	if parent:
		parent.add_child(character)
	else:
		# Ищем корневой контейнер
		var root = Engine.get_main_loop().root
		var container = root.find_child("LevelContainer", true, false)
		if container:
			container.add_child(character)
		else:
			root.add_child(character)
	
	# Устанавливаем позицию
	character.global_position = position
	
	# Добавляем теги из пула
	var tags = level.get_tags_for_spawn()
	for tag in tags:
		character.add_tag(tag)
	
	# Если это капсульный персонаж - генерируем цвет
	if character is CapsuleCharacter:
		_setup_capsule_character(character, level)
	
	return character

static func _setup_capsule_character(character: CapsuleCharacter, level: LevelData):
	# Генерируем случайный цвет
	var colors = [
		Color(0.8, 0.2, 0.2),  # Красный
		Color(0.2, 0.6, 0.8),  # Синий
		Color(0.2, 0.8, 0.2),  # Зеленый
		Color(0.8, 0.8, 0.2),  # Желтый
		Color(0.8, 0.4, 0.8),  # Фиолетовый
		Color(0.2, 0.8, 0.8),  # Голубой
		Color(0.8, 0.6, 0.2),  # Оранжевый
		Color(0.6, 0.6, 0.6),  # Серый
	]
	
	var color = colors[randi() % colors.size()]
	character.character_color = color
	
	# Проверяем, красный ли персонаж
	var is_red = (color.r > 0.6 and color.g < 0.3 and color.b < 0.3)
	if is_red:
		character.add_tag("red")
		character.is_red = true
		print("🔴 Создан красный персонаж")
	
	# Обновляем меш
	character.setup_character()
