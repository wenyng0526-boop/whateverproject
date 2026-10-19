extends CanvasLayer

@export var settings_panel: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

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
