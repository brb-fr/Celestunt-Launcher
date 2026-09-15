extends ColorRect

var downloaded := false
var downloading := false
var logged_in := false
var logging_in := false
var token := ""
@onready var server := $HttpServer

func _enter_tree() -> void:
	await ready
	server.port = 2385
	server.register_router("/", GameOnline.new())
	server.start()
	$LauncherTool.request("http://localhost:2384/launcher_ready")
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
		file.close()
	var gh = await get_json($Changelogs, "https://raw.githubusercontent.com/brb-fr/Parkour-Updates/main/latest-version.json")
	if gh != {}:
		if gh.has("ip"):
			Global.ip = gh.ip
		$Home/Changelogs.text = "[center][b]%s's changelogs:[/b][/center]\n%s"%[gh.version, gh.changelog]
	if FileAccess.file_exists(ProjectSettings.globalize_path("user://Celestunt.exe")) and FileAccess.file_exists("user://game.ver"):
		var file = FileAccess.open("user://game.ver", FileAccess.READ)
		downloaded = float(file.get_var().substr(1)) >= float(gh.version.substr(1))
		file.close()
		if not downloaded:
			$Play.text = "Update\nCelestunt"
			var ver = FileAccess.open("user://game.ver", FileAccess.READ)
			$Play/Status.text = "%s is downloaded, update required"%ver.get_var()
			ver.close()
	if downloaded:
		$Play.text = "Launch\nCelestunt"
		var file = FileAccess.open("user://game.ver", FileAccess.READ)
		$Play/Status.text = "%s is downloaded"%file.get_var()
		file.close()
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
	if downloaded:
		if not FileAccess.file_exists(ProjectSettings.globalize_path("user://Celestunt.exe")): _ready()
	if downloaded and not logged_in:
		$Play.text = "Login or\nRegister"
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
	if Global.online == "" and Global.online != "//launching":
		Global.online = "//launching"
		$Anim2.play_backwards("play")

func _on_play_pressed(animate = true) -> void:
	if logging_in or Global.online != "//launching": return
	$LOWER/Loading.show()
	$LOWER/Bar.value = 0.0
	$LOWER/Bar.show_percentage = true
	if downloaded and logged_in:
		$Anim2.play("play")
		Global.online = "//launching"
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
		$LOWER/Text.text = "[b]Launching Celestunt...[/b]\nPreparing executable..."
	if downloaded and not logged_in:
		logging_in = true
		OS.create_instance(["--login", Global.ip])
	if not downloaded:
		downloading = true
		if animate:
			$Anim2.play("play")
		$LOWER/Text.text = "[b]Preparing download...\nFetching mirrors..."
		var mirror = await get_json($Mirror, "https://raw.githubusercontent.com/brb-fr/Parkour-Updates/main/mirror")
		$LOWER/Bar.max_value = mirror.size
		d = 0.0
		$Downloader.download_file = ProjectSettings.globalize_path("user://Celestunt.exe")
		$Downloader.request(mirror.mirror)

func _on_downloader_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK: 
		downloading = false
		$LOWER/Loading.hide()
		$LOWER/Retry.show()
		$LOWER/Text.text = "[b]Download failed...[/b]\nThat was awkward."
		return
	var gh = await get_json($Changelogs, "https://raw.githubusercontent.com/brb-fr/Parkour-Updates/main/latest-version.json")
	if gh != {}:
		var file = FileAccess.open("user://game.ver", FileAccess.WRITE)
		file.store_var(gh.version)
	$Anim2.play_backwards("play")
	await $Anim2.animation_finished
	get_tree().reload_current_scene()

func _on_user_data_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func _on_logout_pressed() -> void:
	if logged_in:
		$Settings/Logout/Button.disabled = true
		$Settings/Logout/Button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		DirAccess.remove_absolute("user://sensitive.token")
		logged_in = false


func _on_retry_pressed() -> void:
	$LOWER/Retry.hide()
	$LOWER/Loading.show()
	_on_play_pressed(false)


class GameOnline extends HttpRouter:
	func handle_post(request: HttpRequest, response: HttpResponse) -> void:
		var json = JSON.parse_string(request.body)
		if json:
			if json.has("username"):
				Global.online = json["username"]
			else:
				Global.online = ""
			response.json(200, {"message": "Done."})
		else:
			response.json(400, {})
			#Global.online = ""
