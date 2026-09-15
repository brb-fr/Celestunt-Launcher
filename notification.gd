extends Control

var screen_size = DisplayServer.screen_get_size()
var window_size = Vector2i(430, 120)
var target_x = screen_size.x - window_size.x - 50
var target_y = screen_size.y - window_size.y - 50 - 48

func _ready() -> void:
	$Notis/Text.text = OS.get_cmdline_args()[OS.get_cmdline_args().find("--notification") + 1].replace(r"\n", "\n")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(Vector2(target_x + window_size.x + 100, target_y))
	while target_x != DisplayServer.window_get_position().x:
		DisplayServer.window_set_position(Vector2i(lerp(DisplayServer.window_get_position().x, target_x, 0.08), target_y))
		await get_tree().physics_frame
	await get_tree().create_timer(5).timeout
	get_tree().quit()

func _on_quit_pressed() -> void:
	get_tree().quit()
