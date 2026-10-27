extends Control

@onready var hand_container: HBoxContainer = $HandCenter/HandContainer
@export var card_ui: PackedScene
@onready var card_slot: CenterContainer = $CardSlot
@onready var narrator_label: Label = $Narrator
@onready var dialogue_label: Label = $Dialogue
@onready var submit_button: Button = $SubmitButton
@onready var reject_button: Button = $RejectButton
@onready var proceed_button: Button = $ProceedButton

var selected_card: CardUI = null
var original_hand_index: int = -1
var event_completed: bool = false

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	reject_button.pressed.connect(_on_reject_pressed)
	proceed_button.pressed.connect(_on_proceed_pressed)
	spawn_hand_cards()
	submit_button.disabled = true
	proceed_button.hide()
	narrator_label.text = "You encounter a frail old woman, she walks up to you and begs for help."
	dialogue_label.text = "\"Oh dearie, it would seem osteoporosis is getting the best of me. " + \
	"Is there a way you can help refine my bones of old? \""
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
		# Connect this hand card's click signal
		card_instance.clicked.connect(_on_hand_card_clicked)

func _on_hand_card_clicked(card: CardUI) -> void:
	if event_completed:
		return
	
	if card == selected_card:
		return_card_to_hand()
		return
		
	if selected_card != null:
		return
		
	# Find card inside the hand data
	original_hand_index = hand_container.get_children().find(card)
	selected_card = card
	card.current_location = CardUI.CardLocation.EVENT
	if card.hover_tween:
		card.hover_tween.kill()
	card.reparent(card_slot)
	update_submit_button()
	

func update_submit_button():
	var is_valid: bool = false
	if selected_card != null:
		if selected_card.card_data != null:
			is_valid = (
				selected_card.card_data.minon_type
				== card_resource.type.Skeleton
			)
		submit_button.disabled = not is_valid

func return_card_to_hand():
	if selected_card == null:
		return
	
	var card := selected_card
	
	card.current_location = CardUI.CardLocation.HAND
	card.reparent(hand_container)
	
	var last_index := hand_container.get_child_count() - 1
	var target_index := clampi(
		original_hand_index, 0, last_index
	)
	hand_container.move_child(card, target_index)
	
	selected_card = null
	original_hand_index = -1
	
	update_submit_button()
	
func _on_submit_pressed():
	if event_completed or selected_card == null:
		return
		
	if selected_card.card_data == null:
		return
		
	if selected_card.card_data.minon_type != card_resource.type.Skeleton:
		update_submit_button()
		return
	var sacrificed_card = selected_card
	
	if GameState.hand_cards.has(sacrificed_card):
		GameState.hand_cards.erase(sacrificed_card.card_data)
	
	GameState.currency += 7
	
	event_completed = true
	selected_card = null
	
	sacrificed_card.queue_free()
	
	submit_button.hide()
	reject_button.hide()
	proceed_button.show()
	narrator_label.text = "The bones you offered is fused with the old woman." + \
	"She gives you 7 currency as thanks."
	dialogue_label.text = "\"Thank you dearie, here are some currency I have to spare.\""

func _on_reject_pressed():
	if event_completed:
		return
	
	if card_slot != null:
		return_card_to_hand()
	
	event_completed = true
	
	submit_button.hide()
	reject_button.hide()
	proceed_button.show()
	
	narrator_label.text = "The old woman sighs in sorrow."
	dialogue_label.text = "\"Well dearie I... I guess its for the best. " +\
	"I sure hope you do escape this labyrinth. I know you can.\""
	
func _on_proceed_pressed():
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
