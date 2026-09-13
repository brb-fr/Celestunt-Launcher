extends ColorRect

var login := true
var timer: SceneTreeTimer

func _ready() -> void:
	Global.ip = OS.get_cmdline_args()[OS.get_cmdline_args().find("--login") + 1]
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_title("Login or Register")
	get_tree().auto_accept_quit = false
	$Username.grab_focus()

func _on_reg_or_login_meta_clicked(meta: Variant) -> void:
	if meta == "register":
		login = false
		$Title.text = "Register to Celestunt"
		$Button.text = "Register"
		$RegOrLogin.text = "Have an account?\n[url='login']Login[/url] instead.\n\n[b]Not done:[/b]\nUsing a 3rd party server?\n[url='ip-change']Change game's IP address[/url]."
	elif meta == "login":
		login = true
		$Title.text = "Login to Celestunt"
		$Button.text = "Login"
		$RegOrLogin.text = "Don't have an account?\n[url='register']Register[/url] instead.\n\n[b]Not done:[/b]\nUsing a 3rd party server?\n[url='ip-change']Change game's IP address[/url]."
	elif meta.begins_with("http"):
		OS.shell_open(meta)

func _on_button_pressed() -> void:
	var req = $REQ.request("%s/api/%s"%[Global.ip, ("login" if login else "register")], [], HTTPClient.METHOD_POST, JSON.stringify({
		"username": $Username.text,
		"password": $Password.text,
		"email": ""
	}))
	var res = await $REQ.request_completed
	if req == OK:
		if res[1] == 200:
			var json = JSON.parse_string(res[3].get_string_from_utf8())
			save_token(json["token"])
			_notification(1006)
		else:
			if timer:
				timer = null
			var json = JSON.parse_string(res[3].get_string_from_utf8())
			$Error.text = json.message
			timer = get_tree().create_timer(3)
			await timer.timeout
			$Error.text = ""
	else:
		if timer:
			timer = null
		$Error.text = "Error sending request..."
		timer = get_tree().create_timer(3)
		await timer.timeout
		$Error.text = ""
func save_token(token: String):
	var file = FileAccess.open("user://sensitive.token", FileAccess.WRITE)
	file.store_var(token)
	file.close()

func _notification(what: int) -> void:
	if what == 1006:
		var file = FileAccess.open("user://window.killed", FileAccess.WRITE)
		file.store_8(1)
		file.close()
		await get_tree().create_timer(0.1).timeout
		get_tree().quit()


func _on_username_text_submitted(new_text: String) -> void:
	$Password.grab_focus()

func _on_password_text_submitted(new_text: String) -> void:
	_on_button_pressed()
