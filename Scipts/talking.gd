extends Label

@export var chars_per_second: float = 40.0

var _last_text: String = ""
var _progress: float = 0.0

func _ready() -> void:
	_last_text = text
	visible_characters = 0

func _process(delta: float) -> void:
	# Text was changed by another script, so start typing it from the beginning
	if text != _last_text:
		_last_text = text
		_progress = 0.0
		visible_characters = 0

	if visible_characters < text.length():
		_progress += chars_per_second * delta
		visible_characters = mini(int(_progress), text.length())
