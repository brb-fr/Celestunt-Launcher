extends Button





func _on_mouse_entered() -> void:
	if name == "X":
		modulate = Color(0.585, 0.0, 0.0, 1.0)
	if name == "-":
		modulate = Color(0.226, 0.328, 0.77, 1.0)
		
func _on_mouse_exited() -> void:
	modulate = Color.WHITE
