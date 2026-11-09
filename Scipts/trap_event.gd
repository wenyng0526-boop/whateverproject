extends Control

@onready var hand_container: HBoxContainer = $HandCenter/HandContainer
@export var card_ui: PackedScene
@onready var narrator_label: Label = $Narrator
@onready var battle_button: Button = $BattleButton
@onready var undesired_effect: AudioStreamPlayer= $UndesiredEffect
@onready var blip_sound: AudioStreamPlayer = $BlipSound

var event_completed: bool = false

func _ready() -> void:

	undesired_effect.play()
	battle_button.pressed.connect(_on_battle_pressed)
	narrator_label.text = "You walk carelessly through the labyrinth and you got ensnared by a mouse trap. All your minions attacks have been reduced by 2. Being caught, some enemies attempt to assassinate you."
	mouse_trap()
	spawn_hand_cards()

func spawn_hand_cards() -> void:
	# Clear the current hand UI
	for child in hand_container.get_children():
		child.queue_free()

	# Create one CardUI for every card stored in the player's hand
	for data in GameState.hand_cards:
		var card_instance: CardUI = card_ui.instantiate()
		hand_container.add_child(card_instance)
		card_instance.set_card_data(data)
		card_instance.current_location = CardUI.CardLocation.HAND
		card_instance.z_index = GameState.hand_cards.find(data) * 10
		card_instance.normal_z_index = card_instance.z_index
		
func mouse_trap():
	for data in GameState.hand_cards:
		data.attack = max(0, data.attack - 2)

func _on_battle_pressed():
	blip_sound.play()
	await blip_sound.finished
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().change_scene_to_file("res://Scenes/combat_scene.tscn")
