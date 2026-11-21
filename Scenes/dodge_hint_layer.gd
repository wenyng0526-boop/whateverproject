extends CanvasLayer

signal confirmed

@onready var hint_label: Label = $HintLabel

var waiting: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	hint_label.hide()

func show_hint() -> void:
	waiting = true
	hint_label.show()
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if not waiting:
		return

	if event.is_action_pressed("dodge"):
		waiting = false
		hint_label.hide()
		get_tree().paused = false
		confirmed.emit()
		get_viewport().set_input_as_handled()
