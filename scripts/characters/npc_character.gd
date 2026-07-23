# scripts/characters/npc_character.gd
extends BaseCharacter
class_name NPCCharacter

@export var model_path: String = ""
@export var outfit_type: String = "casual"
@export var accessories: Array[String] = []

func setup_character():
	if model_path and ResourceLoader.exists(model_path):
		# Загружаем 3D модель
		var model = load(model_path).instantiate()
		mesh_container.add_child(model)
		
		# Настраиваем анимации
		if animation_player:
			# Ищем анимации в модели
			for animation in animation_player.get_animation_list():
				if animation.to_lower().contains("walk"):
					animation_player.play(animation)
					animation_player.stop()
	
	# Добавляем теги
	add_tag("human")
	add_tag(outfit_type)
	
	for accessory in accessories:
		add_tag(accessory)
