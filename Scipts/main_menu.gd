extends Control

@export var button: Button
@export var vine: AnimatedSprite2D
@export var requires_save_file: bool = false

# The scene to open when this button is clicked
# Leave this empty for buttons that do not change scenes
@export var animation_name: StringName

var is_clicked: bool = false


func can_interact() -> bool:
	print("requires_save_file = ", requires_save_file)
	print("has_save_game = ", GameState.has_save_game())

	if requires_save_file and not GameState.has_save_game():
		return false

	return true


func _on_mouse_entered() -> void:
	if is_clicked:
		return

	if not can_interact():
		return

	vine.play(animation_name)

func _on_mouse_exited() -> void:
	if is_clicked:
		return

	if not can_interact():
		return

	vine.play_backwards(animation_name)

func _on_pressed() -> void:
	# Prevent multiple clicks
	if is_clicked:
		return

	is_clicked = true


#button way
func _on_start_button_pressed() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://Scenes/map.tscn")

func _on_load_button_pressed() -> void:
	if not can_interact():
		print("NO SAVE FILE")
		return

	var resume_scene: String = GameState.load_game()

	if resume_scene != "":
		get_tree().change_scene_to_file(resume_scene)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
