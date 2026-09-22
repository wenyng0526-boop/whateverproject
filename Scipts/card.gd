class_name CardUI
extends Control
signal clicked(card: CardUI)

@export var card_data: Resource
@export var name_label: Label
@export var attack_label: Label
@export var health_label: Label
@export var cost_label: Label
@export var picture : TextureRect

var current_health: int
var current_attack: int
var team: String = "" #Enemy or Player

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
	# Reduce this card's current health
	current_health -= amount
	# Prevent health from going below 0
	current_health = max(current_health, 0)
	# Update the health UI
	if health_label:
		health_label.text = str(current_health)

func is_dead() -> bool:
	# Returns true if this card has no health left
	return current_health <= 0

func die() -> void:
	# Remove this card from the battlefield
	queue_free()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
