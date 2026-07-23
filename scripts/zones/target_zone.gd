# scripts/zones/target_zone.gd
extends Area3D
class_name TargetZone

@export var target_name: String = "Цель"
@export var accept_tags: Array[String] = []
@export var auto_capture: bool = true

# Сигналы
signal character_entered_zone(character: BaseCharacter)
signal character_exited_zone(character: BaseCharacter)
signal character_captured(character: BaseCharacter)

# Визуализация
@export var show_debug: bool = true
@export var debug_color: Color = Color(1, 0, 0, 0.2)

var characters_in_zone: Array[BaseCharacter] = []
var zone_bounds: AABB

func _ready():
	calculate_bounds()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if show_debug:
		show_debug_zone()

func calculate_bounds():
	var found = false
	for child in get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			var box = child.shape as BoxShape3D
			var half_size = box.size / 2
			var collider_pos = child.position
			zone_bounds = AABB(global_position + collider_pos - half_size, box.size)
			found = true
			print("Границы зоны назначения вычислены: ", zone_bounds)
			break
	
	if not found:
		zone_bounds = AABB(global_position - Vector3(1, 0.5, 1), Vector3(2, 1, 2))
		print("Используются дефолтные границы зоны назначения")

func get_random_point() -> Vector3:
	var random_x = randf_range(zone_bounds.position.x, zone_bounds.position.x + zone_bounds.size.x)
	var random_z = randf_range(zone_bounds.position.z, zone_bounds.position.z + zone_bounds.size.z)
	var y = zone_bounds.position.y + 0.1
	return Vector3(random_x, y, random_z)

func check_character_entered(character: BaseCharacter):
	if character.is_captured or character.is_being_captured:
		return
	
	if character in characters_in_zone:
		return
	
	characters_in_zone.append(character)
	character_entered_zone.emit(character)
	
	if auto_capture:
		print("🔄 Автоматический захват персонажа: ", character.name)
		capture_character(character)

func _on_body_entered(body: Node):
	if body is BaseCharacter:
		var character = body as BaseCharacter
		
		if character.is_captured or character.is_being_captured:
			return
		
		if character not in characters_in_zone:
			characters_in_zone.append(character)
			character_entered_zone.emit(character)
			
			if auto_capture:
				print("🔄 Автоматический захват персонажа: ", character.name)
				capture_character(character)

func _on_body_exited(body: Node):
	if body is BaseCharacter:
		characters_in_zone.erase(body)
		character_exited_zone.emit(body)

func is_valid_target(character: BaseCharacter) -> bool:
	# 🔥 Проверяем теги
	if accept_tags.is_empty():
		return true
	
	for tag in accept_tags:
		if character.has_tag(tag):
			return true
	return false

func try_capture_character(character: BaseCharacter) -> bool:
	if character.is_captured or character.is_being_captured:
		print("⚠️ Персонаж уже захвачен!")
		return false
	
	if character not in characters_in_zone:
		print("⚠️ Персонаж не в зоне назначения!")
		return false
	
	if not is_valid_target(character):
		print("⚠️ Персонаж не подходит по тегам!")
		return false
	
	capture_character(character)
	return true

func capture_character(character: BaseCharacter):
	if character.is_captured or character.is_being_captured:
		print("⚠️ Персонаж уже захвачен, пропускаем")
		return
	
	if character in characters_in_zone:
		characters_in_zone.erase(character)
		character_captured.emit(character)
		
		var was_captured_by_player = character.has_meta("captured_by_player")
		
		# 🔥 Проверяем, красный ли персонаж
		var is_red = false
		if character.has_method("is_red_character"):
			is_red = character.is_red_character()
		elif character.has_tag("red"):
			is_red = true
		
		print("📦 Захват персонажа: ", character.name, " (красный: ", is_red, ", игроком: ", was_captured_by_player, ")")
		
		var gm = get_tree().root.get_node("GameManager")
		if gm and gm.has_method("capture_character"):
			gm.capture_character(character, is_red, was_captured_by_player)
		else:
			if character.has_method("capture"):
				character.capture()

func show_debug_zone():
	var debug_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = zone_bounds.size
	
	var material = StandardMaterial3D.new()
	material.albedo_color = debug_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = debug_color.a
	
	debug_mesh.mesh = box_mesh
	debug_mesh.material_override = material
	debug_mesh.position = zone_bounds.position + zone_bounds.size / 2
	add_child(debug_mesh)
