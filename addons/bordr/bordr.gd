@tool
extends ColorRect

@export var window_name: String
@export var icon: Texture2D
@export var dragable: bool = true
@export var show_controls: bool = true
@export var dragobj_color: Color = Color(0,0,0,0.845)

var last_mouse_pos: Vector2i = Vector2i(0,0)
var holding = false

func _on_sensor_button_down() -> void:
	if dragable:
		holding = true
		last_mouse_pos = get_local_mouse_position()

func _on_sensor_button_up() -> void:
	holding = false

func _process(delta: float) -> void:
	#if !show_controls:
		#$X.hide()
		#$"-".hide()
	#else:
		#$X.show()
		#$"-".show()
	if holding:
		var win_pos: Vector2 = DisplayServer.window_get_position()
		win_pos = win_pos.lerp(DisplayServer.mouse_get_position() - last_mouse_pos, 0.1705)
		DisplayServer.window_set_position(win_pos)
	$Icon.texture = icon
	$Icon/Name.text = window_name
	color = dragobj_color

func _on__pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_x_pressed() -> void:
	get_tree().quit()
