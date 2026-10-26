extends CanvasLayer

@export var settings_panel: Control
var can_pause: bool = true

#-----pause lock-----#
func set_can_pause(value: bool) -> void:
	can_pause = value
	if not can_pause and get_tree().paused:
		resume()

#-----func-----#
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and can_pause:
		toggle_pause()

#-----button-----#
func toggle_pause() -> void:
	if get_tree().paused:
		resume()
	else:
		pause()

func pause() -> void:
	get_tree().paused = true
	show()

func resume() -> void:
	get_tree().paused = false
	hide()
	
func _on_resume_button_pressed() -> void:
	resume()
	pass

#we dont have a settings bruh
func _on_settings_button_pressed() -> void:
	pass

func _on_end_run_button_pressed() -> void:
	get_tree().paused = false
	GameState.delete_save_game()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_pause_button_pressed() -> void:
	pause()
