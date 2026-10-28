extends Control

@export var card_ui: PackedScene
@onready var narrator_label: Label = $Narrator
@onready var dialogue_label: Label = $Dialogue
@onready var submit_button: Button = $SubmitButton
@onready var reject_button: Button = $RejectButton
@onready var proceed_button: Button = $ProceedButton
@onready var currency_label: Label = $CurrencyUI/Control/Label

var event_completed: bool = false

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	reject_button.pressed.connect(_on_reject_pressed)
	proceed_button.pressed.connect(_on_proceed_pressed)
	proceed_button.hide()
	narrator_label.text = "A suspicious figure walks up to you, he tries to threaten you."
	dialogue_label.text = "\"Quick, give me some money right now and I'll spare your life. " + \
	"Give it now, or I'll show no mercy. \""

func _on_submit_pressed():
	if event_completed:
		return
		
	var lost_currency: int = min(5, GameState.currency)
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
	event_completed = true
	
	submit_button.hide()
	reject_button.hide()
	proceed_button.show()
	if lost_currency == 0:
		narrator_label.text = "The man looks at you with disgust. " + \
	"You avoided battle. "
		dialogue_label.text = "\"You're broke?! Hmph, how pathetic.\""
	elif lost_currency < 5:
		narrator_label.text = "The man takes your money without much delight. " + \
	"You lose all your money. "
		dialogue_label.text = "\"That sure as hell ain't much. Now get lost!\""
	else:
		narrator_label.text = "The man takes your money with delight. " + \
		"You lose 5 currency. "
		dialogue_label.text = "\"Oh why thank you, I always knew you are a generous guy. \""

func _on_reject_pressed():
	if event_completed:
		return
	
	event_completed = true
	
	submit_button.hide()
	reject_button.hide()
	proceed_button.show()
	
	narrator_label.text = "He starts to summon his band of minions to attack you."
	dialogue_label.text = "\"Prepare to die fool! " +\
	"You should've submit to me when you had the chance. \""
	await get_tree().create_timer(3.0).timeout
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().change_scene_to_file("res://Scenes/combat_scene.tscn")
	
func _on_proceed_pressed():
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
