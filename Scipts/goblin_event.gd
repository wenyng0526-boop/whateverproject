extends Control

@onready var hand_container: HBoxContainer = $HandCenter/HandContainer
@export var card_ui: PackedScene
@export var greed_gobbler_card: card_resource
@onready var narrator_label: Label = $Narrator
@onready var dialogue_label: Label = $Dialogue
@onready var submit_button: Button = $SubmitButton
@onready var reject_button: Button = $RejectButton
@onready var proceed_button: Button = $ProceedButton
@onready var currency_label: Label = $CurrencyUI/Control/Label
@onready var card_fan: AudioStreamPlayer = $CardFan
@onready var card_draw: AudioStreamPlayer = $CardDraw
@onready var refuse_sound: AudioStreamPlayer = $RefuseSound
@onready var blip_sound: AudioStreamPlayer = $BlipSound

var event_completed: bool = false

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	reject_button.pressed.connect(_on_reject_pressed)
	proceed_button.pressed.connect(_on_proceed_pressed)
	proceed_button.hide()
	card_fan.play()
	spawn_hand_cards()
	narrator_label.text = "You encounter a big goblin eating some coins. It seems to be friendly."
	dialogue_label.text = "\"Look, I'm not looking for a fight but man do I love the taste of money! " + \
	"Can you give me some more I could feast on? (4 should be enough) \""

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
		
func _on_submit_pressed():
	if event_completed:
		return
	
	if GameState.currency < 4:
		refuse_sound.play()
		narrator_label.text = "The goblin doesn't look amused."
		dialogue_label.text = "Don't make fun of me, you clearly dont have any money. Now scram! Don't disturb my dinner."
	else:
		card_draw.play()
		var lost_currency: int = min(4, GameState.currency)
		GameState.currency -= lost_currency
		#currency label flash red
		var original_color: Color = currency_label.modulate

		var tween := create_tween()
		tween.tween_property(
			currency_label,
			"modulate",
			Color(1.0, 0.15, 0.15, 1.0),
			0.2
		)
		tween.tween_interval(0.5)
		tween.tween_property(
			currency_label,
			"modulate",
			original_color,
			0.4
		)
		
		if GameState.hand_cards.size() >= GameState.MAX_HAND:
			narrator_label.text = "You gave him the money anyway, even though your hand is full."
			dialogue_label.text = "Wow some good stuff you got there, I would help you but it would seem your minions are full, I am therfore unable to join you."
			return
			
		else:
			if greed_gobbler_card != null:
				GameState.hand_cards.append(greed_gobbler_card.duplicate(true))
				narrator_label.text = "The goblin takes your coins with excitement. " + \
			"You lose 4 currency. He decides to join your team so that he could get more coins."
			dialogue_label.text = "\"OM NOM NOM. You seem to be quite lavished yourself. I think I'll ally myself with you. Trust me I'm pretty strong. Don't mind me taking some money for meself though! \""
			spawn_hand_cards()
	
	event_completed = true
	
	submit_button.hide()
	reject_button.hide()
	proceed_button.show()
	

func _on_reject_pressed():
	if event_completed:
		return
	
	refuse_sound.play()
	event_completed = true
	
	submit_button.hide()
	reject_button.hide()
	proceed_button.show()
	
	narrator_label.text = "He continues to eat his coins without paying you any mind."
	dialogue_label.text = "\"OM NOM NOM NOM. " +\
	"This one's quite delicious. I wonder where can I find more. \""
	
func _on_proceed_pressed():
	blip_sound.play()
	await blip_sound.finished
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().change_scene_to_file("res://Scenes/map.tscn")


func _on_submit_button_pressed() -> void:
	pass # Replace with function body.
