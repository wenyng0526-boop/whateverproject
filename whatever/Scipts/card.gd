class_name CardUI
extends Control

@export var card_data: Resource
@export var name_label: Label
@export var attack_label: Label
@export var health_label: Label
@export var cost_label: Label
@export var picture : TextureRect

var current_health: int
var current_attack: int
var team: String = ""

func _ready() -> void:
	set_card_data(card_data)
	

func set_card_data(new_data: Resource) -> void:
	card_data = new_data
	
	if card_data == null:
		hide()
		return
		
	show()
	current_health = card_data.health
	current_attack = card_data.attack
	if name_label:
		name_label.text = str(card_data.name)
	if attack_label:
		attack_label.text = str(card_data.attack)
	if health_label:
		health_label.text = str(card_data.health)
	if picture:
		picture.texture = card_data.image
	if cost_label:
		cost_label.text = str(card_data.cost)
		

		
func take_damage(amount: int) -> void:
	current_health -= amount
	health_label.text = str(current_health)
	if current_health <= 0:
		die()

func die() -> void:
	queue_free() # Removes minion from the battlefield
