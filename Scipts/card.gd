class_name CardUI
extends Control
signal clicked(card: CardUI)
signal right_clicked(card: CardUI)
signal attack_hit
signal board_drag_ended(card: CardUI, drop_position: Vector2)
signal board_drag_started(card: CardUI)
signal board_drag_moved(card: CardUI, drag_position: Vector2)


@export var card_data: Resource
@export var name_label: Label
@export var attack_label: Label
@export var health_label: Label
@export var picture: TextureRect
@onready var card_visual: Control = $CardVisual
@export var animation_player: AnimationPlayer

enum CardLocation { SHOP, BOARD, HAND }
var current_location: CardLocation = CardLocation.BOARD

var current_health: int
var current_attack: int
var team: String = "" #Enemy or Player

var is_hovered = false
var hover_tween: Tween
var board_mouse_pressed: bool = false
var board_dragging: bool = false
var board_drag_enabled: bool = false
var board_press_position: Vector2
var board_drag_start_position: Vector2
#The mouse must move more than 10 pixels to be considered a drag operation.
@export var board_drag_threshold: float = 10.0

@export var hover_offset: float = -30.0 # How high the card lifts when hovered
@export var hover_duration: float = 0.15 # Speed of the animation

const FUSION_Z := 3000

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
			# Board cards wait to see if this becomes a click or a drag
			if current_location == CardLocation.BOARD:
				if not board_drag_enabled:
					return

				board_mouse_pressed = true
				board_dragging = false
				board_press_position = get_global_mouse_position()
				board_drag_start_position = card_visual.position
			else:
				# Shop and Hand cards keep their normal click behavior
				clicked.emit(self)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(self)

func _input(event: InputEvent) -> void:
	if not board_drag_enabled:
		return

	if current_location != CardLocation.BOARD:
		return

	if not board_mouse_pressed:
		return

	if event is InputEventMouseMotion:
		var distance = board_press_position.distance_to(get_global_mouse_position())

		if distance >= board_drag_threshold:
			if not board_dragging:
				start_board_drag()

			update_board_drag()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			board_mouse_pressed = false

			if board_dragging:
				board_dragging = false
				board_drag_ended.emit(self, get_global_mouse_position())
			else:
				clicked.emit(self)


func start_board_drag() -> void:
	board_dragging = true

	if hover_tween:
		hover_tween.kill()

	z_index = 100

	# Tell CombatManager that this card has started dragging
	board_drag_started.emit(self)


func update_board_drag() -> void:
	global_position = get_global_mouse_position() - size / 2.0

	# Tell CombatManager where the dragged card currently is
	board_drag_moved.emit(self, get_global_mouse_position())


func reset_board_drag() -> void:
	z_index = 0

	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	hover_tween.tween_property(card_visual, "position", board_drag_start_position, hover_duration)

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

func play_fusion_animation() -> void:
	animation_player.play("fusion")
	await animation_player.animation_finished

func fusion_tween(other_card:CardUI):
	card_visual.z_as_relative = false
	other_card.card_visual.z_as_relative = false
	card_visual.z_index = FUSION_Z + 1
	other_card.card_visual.z_index = FUSION_Z
	
	var visual_a: Control = card_visual
	var visual_b: Control = other_card.card_visual
	# Find the midpoint between the two card visuals.
	var midpoint: Vector2 = get_viewport_rect().size / 2.0
	var target_a: Vector2 = midpoint - visual_a.size / 2.0
	var target_b: Vector2 = midpoint - visual_b.size / 2.0
	
	target_a.x -= 35.0
	target_b.x += 35.0
	# Make scaling happen around each card's center.
	visual_a.pivot_offset = visual_a.size / 2.0
	visual_b.pivot_offset = visual_b.size / 2.0
	
	# Move and shrink both visuals at the same time.
	var tween_a := create_tween()
	tween_a.set_parallel(true)
	tween_a.set_trans(Tween.TRANS_CUBIC)
	tween_a.set_ease(Tween.EASE_IN)
	
	tween_a.tween_property(
		visual_a, "global_position", target_a, 0.4
	)
	tween_a.tween_property(visual_a, "scale", Vector2(0.7, 0.7), 0.4)
	
	var tween_b := other_card.create_tween()
	tween_b.set_parallel(true)
	tween_b.set_trans(Tween.TRANS_CUBIC)
	tween_b.set_ease(Tween.EASE_IN)
	
	tween_b.tween_property(
		visual_b, "global_position", target_b, 0.4
	)
	tween_b.tween_property(visual_b, "scale", Vector2(0.7, 0.7), 0.4)
	
	await tween_a.finished
	await tween_b.finished
	
	var absorb_tween := other_card.create_tween()
	absorb_tween.set_parallel(true)
	absorb_tween.set_trans(Tween.TRANS_CUBIC)
	absorb_tween.set_ease(Tween.EASE_IN)
	
	absorb_tween.tween_property(
		visual_b, "scale", Vector2.ZERO, 0.25
	)
	absorb_tween.tween_property(
		visual_b, "modulate:a", 0.0, 0.25
	)
	await absorb_tween.finished
	
	
func trigger_attack_hit() -> void:
	attack_hit.emit()

func _get_hover_offset() -> float:
	match current_location:
		CardLocation.HAND:
			return -305.0 # Lifts much higher in hand
		CardLocation.BOARD:
			return 0.0 # Subtle lift on the board
		_:
			return hover_offset # Default shop lift

func _on_mouse_entered() -> void:
	if current_location == CardLocation.BOARD and not board_drag_enabled:
		return
	
	if board_dragging:
		return
	is_hovered = true
	# Optional: Bring the card to the front visually so it overlaps neighbors neatly
	z_index = 1 
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Animate position.y upward relative to its starting layout spot
	hover_tween.tween_property(card_visual, "position:y", _get_hover_offset(), hover_duration)

func _on_mouse_exited() -> void:
	if current_location == CardLocation.BOARD and not board_drag_enabled:
		return
		
	if board_dragging:
		return
	is_hovered = false
	z_index = 0
	
	if hover_tween:
		hover_tween.kill()
		
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Animate position.y back down to 0 (its default container layout position)
	hover_tween.tween_property(card_visual, "position:y", 0.0, hover_duration)
