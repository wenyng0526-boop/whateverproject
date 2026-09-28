class_name CardUI
extends Control
signal clicked(card: CardUI)
signal right_clicked(card: CardUI)
signal attack_hit

@export var card_data: Resource
@export var name_label: Label
@export var attack_label: Label
@export var health_label: Label
@export var cost_label: Label
@export var picture : TextureRect
@export var desc_name_label: Label
@export var description_label: Label
@onready var card_description: Control = $CardVisual/CardDescription
@export var animation_player: AnimationPlayer


var current_health: int
var current_attack: int
var team: String = "" #Enemy or Player

var is_hovered = false

func _ready() -> void:
	set_card_data(card_data)
	card_description.hide()

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
	if desc_name_label:
		desc_name_label.text = str(card_data.name)
	if description_label:
		description_label.text = str(card_data.description)

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
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(self)

func _on_mouse_entered() -> void:
	var timer = get_tree().create_timer(1.0)
	is_hovered = true
	await timer.timeout
	if is_hovered == true:
		card_description.show()

func _on_mouse_exited() -> void:
	is_hovered = false
	card_description.hide()


func _on_card_description_mouse_entered() -> void:
	card_description.hide()
	

#card been attaked or dead, it play aniamation
func play_hit_animation() -> void:
	animation_player.play("hit")
	await animation_player.animation_finished

#card attack animation
func play_attack_animation() -> void:
	if team == "Player":
		animation_player.play("attack_player")
	else:
		animation_player.play("attack_enemy")


func trigger_attack_hit() -> void:
	attack_hit.emit()
