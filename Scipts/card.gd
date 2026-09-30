class_name CardUI
extends Control
signal clicked(card: CardUI)
signal right_clicked(card: CardUI)
signal attack_hit

@export var card_data: Resource
@export var name_label: Label
@export var attack_label: Label
@export var health_label: Label
@export var picture: TextureRect
@onready var card_description: Control = $CardVisual/CardDescription
@export var animation_player: AnimationPlayer

enum CardLocation { SHOP, BOARD, HAND }
var current_location: CardLocation = CardLocation.BOARD

var current_health: int
var current_attack: int
var team: String = "" #Enemy or Player

var is_hovered = false
var hover_tween: Tween
@export var hover_offset: float = -30.0 # How high the card lifts when hovered
@export var hover_duration: float = 0.15 # Speed of the animation

func _ready() -> void:
	set_card_data(card_data)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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

func _get_hover_offset() -> float:
	match current_location:
		CardLocation.HAND:
			return -305.0 # Lifts much higher in hand
		CardLocation.BOARD:
			return 0.0 # Subtle lift on the board
		_:
			return -30.0 # Default shop lift

func _on_mouse_entered() -> void:
	is_hovered = true
	# Optional: Bring the card to the front visually so it overlaps neighbors neatly
	z_index = 1 
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Animate position.y upward relative to its starting layout spot
	hover_tween.tween_property(self, "position:y", _get_hover_offset(), hover_duration)

func _on_mouse_exited() -> void:
	is_hovered = false
	z_index = 0
	
	if hover_tween:
		hover_tween.kill()
		
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Animate position.y back down to 0 (its default container layout position)
	hover_tween.tween_property(self, "position:y", 0.0, hover_duration)
