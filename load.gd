extends Node

var on := false

func _enter_tree() -> void:
	if DisplayServer.get_name() == "headless":
		start()
		Global.on = true
		return
	if "--login" in OS.get_cmdline_args():
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
		Global.online = json["username"] if json.has("username") else ""
		REQ.request("http://localhost:2385", [], HTTPClient.METHOD_POST, request.body)
		response.json(200, {
			"message": "Done."
		})
class LauncherOn extends HttpRouter:
	func handle_delete(request: HttpRequest, response: HttpResponse) -> void:
		Global.on = false
		response.json(200, {
			"message": "OK"
		})

class LauncherInstanceSecond extends HttpRouter:
	func handle_get(request: HttpRequest, response: HttpResponse) -> void:
		response.json(200, {
			"on": Global.on
		})
		Global.on = true


class Ready extends HttpRouter:
	func handle_get(request: HttpRequest, response: HttpResponse) -> void:
		response.json(200, {
			"message": "OK"
		})
		REQ.request("http://localhost:2385", [], HTTPClient.METHOD_POST, JSON.stringify({
			"username": Global.online
		} if Global.online != "" else {"message": "OK"}))
