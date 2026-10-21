extends Camera2D

@export var scroll_speed: float = 120.0
@export var min_y: float = 300.0
@export var max_y: float = 1000.0

@export var start_y: float = 1000.0

func _ready() -> void:
	position.y = start_y
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:

		# Scroll upward
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			position.y -= scroll_speed

		# Scroll downward
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			position.y += scroll_speed

		# Prevent the camera from scrolling outside the map
		position.y = clamp(position.y, min_y, max_y)
