extends ColorRect

var downloaded := false
var downloading := false
var logged_in := false
var logging_in := false
var token := ""
var playing := false
func _enter_tree() -> void:
	if "--login" in OS.get_cmdline_args():
		get_tree().change_scene_to_file("res://login.tscn")
	await ready
	var server = $HttpServer
	server.port = 2384
	server.register_router("/", Online.new())
	server.start()

func _ready() -> void:
	for file in DirAccess.get_files_at("user://"):
		if file.ends_with(".killed"):
			DirAccess.remove_absolute("user://"+file)
	logging_in = false
	if FileAccess.file_exists("user://sensitive.token"):
		logged_in = true
		$Settings/Logout/Button.disabled = false
		$Settings/Logout/Button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		var file = FileAccess.open("user://sensitive.token", FileAccess.READ)
		token = file.get_var()
		file.close()
	if FileAccess.file_exists(ProjectSettings.globalize_path("user://Celestunt.exe")) and FileAccess.file_exists("user://game.ver"):
		$Play.text = "Launch\nCelestunt"
		var file = FileAccess.open("user://game.ver", FileAccess.READ)
		$Play/Status.text = "%s is downloaded"%file.get_var()
	var gh = await get_json($Changelogs, "https://raw.githubusercontent.com/brb-fr/Parkour-Updates/main/latest-version.json")
	if gh != {}:
		if gh.has("ip"):
			Global.ip = gh.ip
		$Home/Changelogs.text = "[center][b]%s's changelogs:[/b][/center]\n%s"%[gh.version, gh.changelog]
	if FileAccess.file_exists(ProjectSettings.globalize_path("user://Celestunt.exe")) and FileAccess.file_exists("user://game.ver"):
		var file = FileAccess.open("user://game.ver", FileAccess.READ)
		downloaded = float(file.get_var().substr(1)) >= float(gh.version.substr(1))
		if not downloaded:
			$Play.text = "Update\nCelestunt"
			$Play/Status.text = "%s is downloaded, update required"%file.get_var()
	if downloaded:
		$Play.text = "Launch\nCelestunt"
		var file = FileAccess.open("user://game.ver", FileAccess.READ)
		$Play/Status.text = "%s is downloaded"%file.get_var()

func get_json(requester: HTTPRequest, url: String):
	if requester:
		requester.request(url)
		var res = await requester.request_completed
		if res[1] == 200:
			return JSON.parse_string(res[3].get_string_from_utf8())
		return {}

var d := 0.0
var time_acc := 0.0
var last_bytes := 0.0
var speed = 0.0
func _process(delta: float) -> void:
	if logging_in:
		if FileAccess.file_exists("user://window.killed"):
			_ready()
	d += delta
	time_acc += delta
	if downloading:
		$LOWER/Bar.value = $Downloader.get_downloaded_bytes()
		if last_bytes == 0.0:
			last_bytes = $Downloader.get_downloaded_bytes()
		$LOWER/Text.text = "[b]Downloading Celestunt...[/b]\n%.1f/%.1fMB at %.1fMB/s"%[$Downloader.get_downloaded_bytes() / 1048576.0, $LOWER/Bar.max_value / 1048576.0, speed]
		if time_acc >= 1.0:
			speed = abs(((last_bytes - $Downloader.get_downloaded_bytes()) / 1048576.0) / time_acc)
			last_bytes = $Downloader.get_downloaded_bytes()
			time_acc = 0.0
	if Global.online != "":
		if Global.online == "//launching": return
		$LOWER/Text.text = "[b]Celestunt is running[/b]\nLogged in as %s"%Global.online
		$LOWER/Loading.hide()
		$LOWER/Bar.value = $LOWER/Bar.max_value
		$LOWER/Bar.show_percentage = false
	if Global.online == "" and playing:
		playing = false
		$Anim2.play_backwards("play")
func _on_play_pressed() -> void:
	if logging_in or playing: return
	$LOWER/Loading.show()
	$LOWER/Bar.value = 0.0
	$LOWER/Bar.show_percentage = true
	if downloaded and logged_in:
		playing = true
		logging_in = false
		$LOWER/Text.text = "[b]Preparing launch...\nFetching mirrors..."
		var mirror = await get_json($Mirror, "https://raw.githubusercontent.com/brb-fr/Parkour-Updates/main/mirror")
		if mirror != {}:
			var file = FileAccess.open(ProjectSettings.globalize_path("user://Celestunt.exe"), FileAccess.READ)
			if abs(file.get_length() - mirror.size) > 1250000:
				downloaded = false
				_on_play_pressed()
				return
		OS.execute_with_pipe(ProjectSettings.globalize_path("user://Celestunt.exe"), ["--ip", Global.ip, "--token", token])
		$Anim2.play("play")
		$LOWER/Text.text = "[b]Launching Celestunt...[/b]\nPreparing executable..."
		Global.online = "//launching"
	if downloaded and not logged_in:
		logging_in = true
		OS.create_instance(["--login", Global.ip])
	if not downloaded:
		downloading = true
		$Anim2.play("play")
		$LOWER/Text.text = "[b]Preparing download...\nFetching mirrors..."
		var mirror = await get_json($Mirror, "https://raw.githubusercontent.com/brb-fr/Parkour-Updates/main/mirror")
		$LOWER/Bar.max_value = mirror.size
		d = 0.0
		$Downloader.download_file = ProjectSettings.globalize_path("user://Celestunt.exe")
		$Downloader.request(mirror.mirror)

func _on_downloader_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK: return
	var gh = await get_json($Changelogs, "https://raw.githubusercontent.com/brb-fr/Parkour-Updates/main/latest-version.json")
	if gh != {}:
		var file = FileAccess.open("user://game.ver", FileAccess.WRITE)
		file.store_var(gh.version)
	$Anim2.play_backwards("play")
	await $Anim2.animation_finished
	get_tree().reload_current_scene()
class Online extends HttpRouter:
	func handle_post(request: HttpRequest, response: HttpResponse) -> void:
		var json = JSON.parse_string(request.body)
		print(json)
		if json:
			if json.has("username"):
				Global.online = json["username"]
			else:
				Global.online = ""
			response.json(200, {"message": "Done."})
		else:
			response.json(400, {})
			Global.online = ""


func _on_user_data_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func _on_logout_pressed() -> void:
	if logged_in:
		DirAccess.remove_absolute("user://sensitive.token")
