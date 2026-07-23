extends Node

# Массив путей к вашим skybox'ам (HDR, EXR, PNG — любая панорама 360°)
@export var skybox_paths: Array[String] = [
	"res://assets/skyboxes/skybox-alien.png",
	"res://assets/skyboxes/skybox-day.png",
	"res://assets/skyboxes/skybox-morning.png",
	"res://assets/skyboxes/skybox-night.png",
	"res://assets/skyboxes/skybox-space.png"
]

# Текущий индекс
var current_index: int = 0

# Ссылка на WorldEnvironment (создаём программно)
var world_env: WorldEnvironment
var sky_material: PanoramaSkyMaterial

func _ready():
	_create_world_environment()
	# Устанавливаем первый skybox при старте
	set_skybox(2)

# Создаём WorldEnvironment один раз
func _create_world_environment():
	world_env = WorldEnvironment.new()
	
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	
	var sky = Sky.new()
	sky_material = PanoramaSkyMaterial.new()
	sky.sky_material = sky_material
	
	environment.sky = sky
	world_env.environment = environment
	
	add_child(world_env)
	print("🌌 SkyboxManager инициализирован")

# Установить skybox по индексу
func set_skybox(index: int) -> bool:
	if skybox_paths.is_empty():
		push_error("❌ Массив skybox_paths пуст!")
		return false
	
	# Зацикливаем индекс
	index = wrapi(index, 0, skybox_paths.size())
	current_index = index
	
	var path = skybox_paths[index]
	var texture = load(path)
	
	if not texture is Texture2D:
		push_error("❌ Не удалось загрузить текстуру: " + path)
		return false
	
	sky_material.panorama = texture
	print("🌅 Skybox изменён на: ", path, " [", index, "]")
	return true

# Следующий skybox
func next_skybox() -> bool:
	return set_skybox(current_index + 1)

# Предыдущий skybox
func prev_skybox() -> bool:
	return set_skybox(current_index - 1)

# Случайный skybox
func random_skybox() -> bool:
	if skybox_paths.size() <= 1:
		return set_skybox(0)
	var random_index = randi() % skybox_paths.size()
	return set_skybox(random_index)

# Получить текущий индекс
func get_current_index() -> int:
	return current_index

# Получить количество skybox'ов
func get_skybox_count() -> int:
	return skybox_paths.size()
