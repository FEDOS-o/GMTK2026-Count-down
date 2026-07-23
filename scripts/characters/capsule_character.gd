# scripts/characters/capsule_character.gd
extends BaseCharacter
class_name CapsuleCharacter

@export var character_color: Color = Color(0.2, 0.6, 0.8)
@export var character_height: float = 1.8
@export var character_radius: float = 0.3

func setup_character():
	# Создаем капсулу
	var capsule = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = character_radius
	capsule_mesh.height = character_height
	
	# Создаем материал с цветом
	var material = StandardMaterial3D.new()
	material.albedo_color = character_color
	material.metallic = 0.1
	material.roughness = 0.8
	
	capsule.mesh = capsule_mesh
	capsule.material_override = material
	capsule.position = Vector3(0, character_height / 2, 0)
	
	mesh_container.add_child(capsule)
	
	# Добавляем случайные теги для фильтрации
	var possible_tags = ["human", "civilian"]
	var tag = possible_tags[randi() % possible_tags.size()]
	add_tag(tag)
	
	# Добавляем случайный аксессуар (для будущих фильтров)
	if randf() > 0.7:
		add_tag("wearing_glasses")
	if randf() > 0.8:
		add_tag("has_book")

	print("Создан капсульный персонаж: ", name, " цвет: ", character_color)
