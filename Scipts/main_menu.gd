extends Control

@export var button: Button
@export var vine: AnimatedSprite2D

# The scene to open when this button is clicked
# Leave this empty for buttons that do not change scenes
@export var animation_name: StringName

var is_clicked: bool = false

func _on_mouse_entered() -> void:
	# Stop hover effects after the button has been clicked
	if is_clicked:
		return

	# Play the vine animation
	vine.play(animation_name)

func _on_mouse_exited() -> void:
	# Stop hover effects after the button has been clicked
	if is_clicked:
		return

	# Play the same animation backwards
	vine.play_backwards(animation_name)

func _on_pressed() -> void:
	# Prevent multiple clicks
	if is_clicked:
		return

	is_clicked = true


#button way
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/shop_scene.tscn")

func _on_load_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/shop_scene.tscn") #not sure about this

func _on_exit_button_pressed() -> void:
	get_tree().quit()
