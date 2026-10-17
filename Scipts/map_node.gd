extends Node2D

enum NodeType { SHOP, COMBAT }

@export var node_type: NodeType
@export var text: String
@export var node_index: int = 0

@export var next_nodes: Array[int] = []

@onready var button: Button = $Button

func _ready() -> void:
	button.disabled = (
		node_index not in GameState.available_nodes
		or node_index in GameState.completed_nodes
	)

	$Button.text = text
	
func _on_button_pressed() -> void:
	GameState.current_node = node_index
	GameState.current_next_nodes = next_nodes
	match node_type:
		NodeType.SHOP :
			get_tree().change_scene_to_file("res://Scenes/shop_scene.tscn")
		NodeType.COMBAT :
			get_tree().change_scene_to_file("res://Scenes/combat_scene.tscn")
