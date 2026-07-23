# scripts/characters/capsule_character.gd
extends BaseCharacter
class_name CapsuleCharacter

@export var character_color: Color = Color(0.2, 0.6, 0.8)
@export var character_height: float = 1.8
@export var character_radius: float = 0.3

# 🔥 Добавляем возможность задать цвет при спавне
var is_red: bool = false

func setup_character():
	# Создаем капсулу
	var capsule = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = character_radius
	capsule_mesh.height = character_height
	
	# 🔥 Случайный цвет или заданный
	var color = character_color
	if color == Color(0.2, 0.6, 0.8):  # Если цвет не изменен в инспекторе
		color = _get_random_color()
	
	character_color = color
	
	# Создаем материал с цветом
	var material = StandardMaterial3D.new()
	material.albedo_color = character_color
	material.metallic = 0.1
	material.roughness = 0.8
	
	capsule.mesh = capsule_mesh
	capsule.material_override = material
	capsule.position = Vector3(0, character_height / 2, 0)
	
	mesh_container.add_child(capsule)
	
	# 🔥 Добавляем тег с цветом
	add_tag("human")
	add_tag("civilian")
	
	# 🔥 Определяем красный цвет
	var red_threshold = 0.6
	is_red = (color.r > red_threshold and color.g < 0.3 and color.b < 0.3)
	
	if is_red:
		add_tag("red")
		print("🔴 Красный персонаж создан: ", name)
	
	# Добавляем случайные аксессуары
	if randf() > 0.7:
		add_tag("wearing_glasses")
	if randf() > 0.8:
		add_tag("has_book")

func _get_random_color() -> Color:
	# 🔥 Генерируем случайный цвет
	var colors = [
		Color(0.2, 0.6, 0.8),  # Синий
		Color(0.8, 0.2, 0.2),  # Красный
		Color(0.2, 0.8, 0.2),  # Зеленый
		Color(0.8, 0.8, 0.2),  # Желтый
		Color(0.8, 0.4, 0.8),  # Фиолетовый
		Color(0.2, 0.8, 0.8),  # Голубой
		Color(0.8, 0.6, 0.2),  # Оранжевый
		Color(0.6, 0.6, 0.6),  # Серый
		Color(0.8, 0.2, 0.6),  # Розовый
	]
	
	return colors[randi() % colors.size()]

# 🔥 Метод для проверки цвета
func is_red_character() -> bool:
	return is_red
	
# 🔥 Возвращаем цвет персонажа
func get_character_color() -> Color:
	return character_color

# capsule_character.gd
# Добавьте метод для принудительной установки цвета

func set_character_color(color: Color):
	character_color = color
	is_red = (color.r > 0.6 and color.g < 0.3 and color.b < 0.3)
	
	if is_red:
		add_tag("red")
	
	# Обновляем визуал
	_update_mesh()

func _update_mesh():
	# Пересоздаем меш с новым цветом
	for child in mesh_container.get_children():
		child.queue_free()
	
	var capsule = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = character_radius
	capsule_mesh.height = character_height
	
	var material = StandardMaterial3D.new()
	material.albedo_color = character_color
	material.metallic = 0.1
	material.roughness = 0.8
	
	capsule.mesh = capsule_mesh
	capsule.material_override = material
	capsule.position = Vector3(0, character_height / 2, 0)
	
	mesh_container.add_child(capsule)
