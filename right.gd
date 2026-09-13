extends TextureRect

var in_settings := false

func _on_home_pressed() -> void:
	if in_settings:
		$"../Anim2".play_backwards("goto_settings")
		in_settings = false
		$Container/Home.modulate = Color.from_rgba8(25,123,255)
		$Container/Settings.modulate = Color.from_rgba8(135,135,135)

func _on_settings_pressed() -> void:
	if !in_settings:
		in_settings = true
		$"../Anim2".play("goto_settings")
		$Container/Settings.modulate = Color.from_rgba8(25,123,255)
		$Container/Home.modulate = Color.from_rgba8(135,135,135)
