# scripts/zones/spawn_zone.gd
extends Area3D
class_name SpawnZone

@export var spawn_rate: float = 2.0
@export var max_characters: int = 10

# Визуализация
@export var show_debug: bool = true
@export var debug_color: Color = Color(0, 1, 0, 0.2)

var characters_in_zone: Array[BaseCharacter] = []
var spawn_timer: Timer
var zone_bounds: AABB

func _ready():
	# Вычисляем границы зоны
	calculate_bounds()
	
	# Настраиваем таймер
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_rate
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	if show_debug:
		show_debug_zone()

func calculate_bounds():
	# Получаем границы зоны из CollisionShape3D
	var found = false
	for child in get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			var box = child.shape as BoxShape3D
			var half_size = box.size / 2
			# 🔥 Учитываем позицию самой зоны и позицию коллизии
			var collider_pos = child.position
			zone_bounds = AABB(global_position + collider_pos - half_size, box.size)
			found = true
			print("Границы зоны спавна вычислены: ", zone_bounds)
			break
	
	if not found:
		# Если нет коллизии, создаем дефолтные границы
		zone_bounds = AABB(global_position - Vector3(1.5, 0.25, 1.5), Vector3(3, 0.5, 3))
		print("Используются дефолтные границы зоны спавна")

func get_random_spawn_point() -> Vector3:
	# Генерируем случайную точку внутри зоны
	var random_x = randf_range(zone_bounds.position.x, zone_bounds.position.x + zone_bounds.size.x)
	var random_z = randf_range(zone_bounds.position.z, zone_bounds.position.z + zone_bounds.size.z)
	var y = zone_bounds.position.y + 0.1  # Чуть выше пола
	
	return Vector3(random_x, y, random_z)

func start_spawning():
	if spawn_timer:
		spawn_timer.start()
		print("Зона спавна активирована: ", name)

func stop_spawning():
	if spawn_timer:
		spawn_timer.stop()
		print("Зона спавна остановлена: ", name)

func _on_spawn_timer_timeout():
	if characters_in_zone.size() >= max_characters:
		return
	
	# Генерируем случайную точку внутри зоны
	var spawn_pos = get_random_spawn_point()
	
	# Просим CrowdManager создать персонажа
	if CrowdManager:
		var character = CrowdManager.spawn_character(spawn_pos)
		if character:
			character.spawn_zone = self
			characters_in_zone.append(character)
			
			# Подписываемся на сигнал исчезновения
			character.character_destroyed.connect(_on_character_destroyed)
			
			print("Спавн персонажа в зоне: ", name, " позиция: ", spawn_pos)

func _on_character_destroyed(character: BaseCharacter):
	if character in characters_in_zone:
		characters_in_zone.erase(character)
		if character.character_destroyed.is_connected(_on_character_destroyed):
			character.character_destroyed.disconnect(_on_character_destroyed)

func show_debug_zone():
	# Визуализация зоны (полупрозрачный куб)
	var debug_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = zone_bounds.size
	
	var material = StandardMaterial3D.new()
	material.albedo_color = debug_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = debug_color.a
	
	debug_mesh.mesh = box_mesh
	debug_mesh.material_override = material
	# 🔥 Позиционируем дебаг-меш в центр зоны
	debug_mesh.position = zone_bounds.position + zone_bounds.size / 2
	add_child(debug_mesh)
