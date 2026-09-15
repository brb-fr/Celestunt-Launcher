extends Node

var on := false

func _enter_tree() -> void:
	if DisplayServer.get_name() == "headless":
		start()
		Global.on = true
		return
	elif "--notification" in OS.get_cmdline_args():
		get_tree().change_scene_to_file("res://notification.tscn")
		return
	elif "--login" in OS.get_cmdline_args():
		get_tree().change_scene_to_file("res://login.tscn")
		return
	else:
		get_tree().change_scene_to_file("res://control.tscn")
		return

func start() -> void:
	var server = $HttpServer
	server.port = 2384
	server.register_router("/", GameOnline.new())
	server.register_router("/launcher_instance", LauncherInstanceSecond.new())
	server.register_router("/start_download", Download.new())
	server.register_router("/launcher_ready", Ready.new())
	server.register_router("/launcher_killed", LauncherOn.new())
	if server.start() == 22:
		$REQs.request("http://localhost:2384/launcher_instance")
		var res = (await $REQs.request_completed)[3]
		Global.on = JSON.parse_string(res.get_string.from_utf8())["on"]
		if not Global.on:
			OS.create_instance([])
		await get_tree().create_timer(0.3).timeout
		get_tree().quit()
	else:
		OS.create_instance([])

class GameOnline extends HttpRouter:
	func handle_post(request: HttpRequest, response: HttpResponse) -> void:
		var json = JSON.parse_string(request.body)
		Global.online = json["username"] if json.has("username") else "//launching"
		if Global.online == "//launching":
			if not Global.on:
				OS.create_instance(["--notification", "[b]Exit completed[/b]\nCelestunt has been killed."])
		REQ.request("http://localhost:2385", [], HTTPClient.METHOD_POST, request.body)
		response.json(200, {
			"message": "Done."
		})

class LauncherOn extends HttpRouter:
	func handle_delete(request: HttpRequest, response: HttpResponse) -> void:
		response.json(200, {
			"message": "OK"
		})
		Global.on = false
		await REQ.get_tree().create_timer(12.5).timeout
		if Global.abytes != -2:
			OS.create_instance(["--notification", "[b]Background run[/b]\nCelestunt launcher is still running."])
			Global.abytes = -2
class LauncherInstanceSecond extends HttpRouter:
	func handle_get(request: HttpRequest, response: HttpResponse) -> void:
		response.json(200, {
			"on": Global.on
		})
		Global.on = true

class Ready extends HttpRouter:
	func handle_get(request: HttpRequest, response: HttpResponse) -> void:
		if Global.online != "//launching":
			REQ.request("http://localhost:2385", [], HTTPClient.METHOD_POST, JSON.stringify({
				"username": Global.online
			}))
		response.json(200, {
			"message": "OK"
		})

class Download extends HttpRouter:
	var downloading := false
	func handle_post(request: HttpRequest, response: HttpResponse) -> void:
		var url = request.get_body_parsed().url
		response.json(200, {
			"message": "Starting download."
		})
		start_download(url)
	func start_download(url: String):
		downloading = true
		REQ.get_node("Downloader").download_file = ProjectSettings.globalize_path("user://Celestunt.exe")
		REQ.get_node("Downloader").request(url)
		var req = HTTPRequest.new()
		REQ.add_child(req)
		REQ.get_node("Downloader").request_completed.connect(_on_downloader_completed)
		while downloading:
			await REQ.get_tree().create_timer(0.25).timeout
			req.request("http://localhost:2385/download?b=%s"%REQ.get_node("Downloader").get_downloaded_bytes())
			await req.request_completed
		req.queue_free()
		REQ.remove_child(req)
	func _on_downloader_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
		downloading = false
		OS.create_instance(["--notification", "[b]Download completed[/b]\nCelestunt's download has finished."])
