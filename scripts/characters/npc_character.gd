# scripts/characters/npc_character.gd
extends BaseCharacter
class_name NPCCharacter

@export var model_path: String = ""
@export var outfit_type: String = "casual"
@export var accessories: Array[String] = []

# Ссылка на агента захвата (чтобы не спавнить несколько)
var capture_agent_spawned: bool = false

func setup_character():
	if model_path and ResourceLoader.exists(model_path):
		var model = load(model_path).instantiate()
		mesh_container.add_child(model)
		
		if animation_player:
			for animation in animation_player.get_animation_list():
				if animation.to_lower().contains("walk"):
					animation_player.play(animation)
					animation_player.stop()
	
	add_tag("human")
	add_tag(outfit_type)
	for accessory in accessories:
		add_tag(accessory)
# Переопределяем on_interact для NPC
func on_interact():
	if is_captured:
		print("⚠️ NPC уже захвачен")
		return
	
	if capture_agent_spawned:
		print("⚠️ Агент уже вызван")
		return
	
	print("🖱️ Клик по NPC: ", name)
	
	# Останавливаем NPC
	stop_walking()
	is_walking = false
	
	# Спавним агента захвата
	_spawn_capture_agent()
	
	# Помечаем, что агент вызван
	capture_agent_spawned = true

func _spawn_capture_agent():
	# Находим случайную зону спавна
	var spawn_zone = _get_random_spawn_zone()
	if not spawn_zone:
		print("❌ Нет зон спавна для агента!")
		return
	
	# Получаем точку спавна
	var spawn_pos = spawn_zone.get_random_spawn_point() if spawn_zone.has_method("get_random_spawn_point") else spawn_zone.global_position
	
	# Создаём агента
	var agent = CaptureAgent.new()
	agent.global_position = spawn_pos
	agent.set_target(self)
	
	# Добавляем в сцену
	var level_container = _get_level_container()
	if level_container:
		level_container.add_child(agent)
	else:
		get_tree().root.add_child(agent)
	
	print("🚀 Агент захвата спавнен в: ", spawn_pos)

func _get_random_spawn_zone():
	# Ищем CrowdManager для доступа к зонам спавна
	var crowd_manager = get_node_or_null("/root/CrowdManager")
	if crowd_manager and crowd_manager.has_method("get_random_spawn_zone"):
		return crowd_manager.get_random_spawn_zone()
	
	# Или ищем вручную
	var zones = []
	_find_spawn_zones_recursive(get_tree().root, zones)
	if zones.is_empty():
		return null
	return zones[randi() % zones.size()]

func _find_spawn_zones_recursive(node: Node, zones: Array):
	for child in node.get_children():
		if child is SpawnZone:
			zones.append(child)
		_find_spawn_zones_recursive(child, zones)

func _get_level_container() -> Node:
	var root = get_tree().root
	var container = root.find_child("LevelContainer", true, false)
	if container:
		return container
	container = root.find_child("World", true, false)
	if container:
		return container
	return null
