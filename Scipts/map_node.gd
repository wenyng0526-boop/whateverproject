extends Node2D

enum NodeType { SHOP, COMBAT, EVENT, CHEST, BOSS}

@export var node_type: NodeType
@export var text: String
@export var node_index: int = 0
@export var event_scenes: Array[PackedScene] = []
@export var next_nodes: Array[int] = []

# 0 = SHOP, 1 = COMBAT, 2 = EVENT, 3 = CHEST, 4 = BOSS
@export var normal_textures: Array[Texture2D] = []
@export var hover_textures: Array[Texture2D] = []
@export var pressed_textures: Array[Texture2D] = []
@export var disabled_textures: Array[Texture2D] = []

@onready var button: TextureButton = $Button

@onready var blip_sound: AudioStreamPlayer = $BlipSound
const chest_popup = preload("res://Scenes/chest.tscn")


func _ready() -> void:
	
	button.texture_normal = _get_texture(normal_textures, "normal_textures")
	button.texture_hover = _get_texture(hover_textures, "hover_textures")
	button.texture_pressed = _get_texture(pressed_textures, "pressed_textures")
	button.texture_disabled = _get_texture(disabled_textures, "disabled_textures")
	
		
	button.disabled = (
		node_index not in GameState.available_nodes
		or node_index in GameState.completed_nodes
	)

func _get_texture(textures: Array[Texture2D], array_name: String) -> Texture2D:
	if node_type >= textures.size():
		push_warning("%s: %s has %d entries but node_type is %d. Check for an empty override in the scene." % [name, array_name, textures.size(), node_type])
		return null
	return textures[node_type]


func _on_button_pressed() -> void:
	blip_sound.play()
	GameState.current_node = node_index
	GameState.current_next_nodes = next_nodes

	match node_type:
		NodeType.SHOP:
			get_tree().change_scene_to_file("res://Scenes/shop_scene.tscn")

		NodeType.COMBAT:
			get_tree().change_scene_to_file("res://Scenes/combat_scene.tscn")

		NodeType.EVENT:
			random_event()

		NodeType.CHEST:
			var chest_instance = chest_popup.instantiate()
			get_tree().current_scene.add_child(chest_instance)
			
		NodeType.BOSS:
			get_tree().change_scene_to_file("res://Scenes/boss_scene.tscn")

func random_event() -> void:
	var chosen_event: PackedScene = event_scenes.pick_random()
	get_tree().change_scene_to_packed(chosen_event)
