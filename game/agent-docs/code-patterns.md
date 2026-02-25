# Code Patterns (LLM-Directed)

This file is written for code-generating agents. Follow it literally.

## 1) Naming and File Basics
- Use tabs for indentation.
- Use `snake_case` for variables/functions.
- Use `PascalCase` for `class_name`.
- Use `snake_case` for scene/resource filenames.

## 2) Node Access and Scene Tree Wiring
- Prefer `%UniqueName` for sibling/child dependencies.
- Avoid deep path lookups in runtime logic.
- Long-lived systems should be scene children, not ad-hoc `new()+add_child()` in many places.

Good:
```gdscript
@onready var network_server: NetworkServer = %Network
@onready var arena_runtime: ArenaRuntime = %ArenaRuntime
```

Bad:
```gdscript
var network_server: Node = get_node("/root/Main/Runtime/Network")
```

## 3) Type Everything You Can
- Prefer typed fields, typed arrays, and typed dictionaries.
- Avoid `Object` unless absolutely necessary.

## 4) Parse at Boundaries, Keep Internals Typed
- RPC payloads and generic dictionaries are trust boundaries.
- Parse/coerce once, then continue with typed values.
- For external time fields (for example HTTP/API payloads), convert at the boundary to Unix timestamp integers (seconds) and use Unix `int` internally.

Good:
```gdscript
var peer_id: int = int(payload.get("peer_id", 0))
var player_name: String = str(payload.get("player_name", ""))
if peer_id <= 0 or player_name.is_empty():
	return
```

Bad:
```gdscript
if payload["peer_id"] > 0:
	do_spawn(payload["peer_id"], payload["player_name"])
```

## 5) Nullable Built-in Types
- GDScript has no `int?` or `T | null` syntax for built-ins.
- Use `Variant` where a value may be null (for example API fields that omit or explicitly null a field).
- Coerce to a concrete type at use sites: `int(v) if v != null else 0`.

Good:
```gdscript
var username_updated_at_unix: Variant = body.get("username_updated_at_unix", null)
if username_updated_at_unix == null or int(username_updated_at_unix) <= 0:
	show_username_prompt()
```

Bad:
```gdscript
var username_updated_at: int = body.get("username_updated_at_unix", 0)
```

## 9) Return Structured Results for Cross-Layer Operations
- For helper calls crossing boundaries, return result dictionaries with explicit status.

Good:
```gdscript
return {
	"success": false,
	"reason": "NO_SPAWN_AVAILABLE",
}
```

Then handle explicitly:
```gdscript
if not result.get("success", false):
	var reason: String = str(result.get("reason", "FAILED"))
	return
```

## 12) Prefer `class_name` Globals for Static APIs
- For utility classes with `class_name`, call static functions directly by class name.
- Do not add local `preload(...)` aliases for globally-registered utility classes unless there is a demonstrated load-order problem.

Good:
```gdscript
var player_data: PlayerData = DataStore.load_or_create(PlayerData, PlayerData.FILE_NAME)
DataStore.save(player_data, PlayerData.FILE_NAME)
```

Bad:
```gdscript
const DATA_STORE := preload("res://src/game_data/data_store.gd")
var player_data: PlayerData = DATA_STORE.load_or_create(PlayerData, PlayerData.FILE_NAME)
DATA_STORE.save(player_data, PlayerData.FILE_NAME)
```

## 13) Cached Resource Binding Pattern (DataStore-Backed)
- For resources loaded through `DataStore.load_or_create(...)`, treat them as cache-backed singleton state objects in runtime usage.
- Preferred binding is top-level typed vars at class scope, then use those vars directly in methods.
- Do not repeatedly call `get_instance()` in the same node/script when a single bound reference is sufficient.
- These resources are considered always available in runtime and are only persisted to disk when `save()` is called explicitly.

Good:
```gdscript
class_name TankDisplayPanel extends Control

var account: Account = Account.get_instance()

func _ready() -> void:
	Utils.connect_checked(
		account.username_updated,
		func(new_username: String) -> void: username_label.text = new_username
	)
	Utils.connect_checked(
		account.loadout.selected_tank_spec_updated, func(_spec: TankSpec) -> void: display_tank()
	)
	display_tank()

func display_tank() -> void:
	var tank_spec: TankSpec = account.loadout.selected_tank_spec
	if tank_spec == null:
		return
	tank_display.texture = tank_spec.preview_texture
```

Bad:
```gdscript
class_name TankDisplayPanel extends Control

func _ready() -> void:
	var account: Account = Account.get_instance()
	Utils.connect_checked(
		account.username_updated,
		func(new_username: String) -> void: username_label.text = new_username
	)
	display_tank()
	Utils.connect_checked(
		account.loadout.selected_tank_spec_updated, func(_spec: TankSpec) -> void: display_tank()
	)

func display_tank() -> void:
	var account: Account = Account.get_instance()
	var tank_spec: TankSpec = account.loadout.selected_tank_spec
	if tank_spec == null:
		return
	tank_display.texture = tank_spec.preview_texture
```

## 14) Resource State via Properties, Not Wrapper Accessors
- For `Resource`-owned state, prefer direct properties and property signals over local `get_*` / `set_*` wrappers.
- Keep fallback/coercion rules in the property `get`/`set`, and consume `resource.field` at callsites.

Good:
```gdscript
var selected_tank_spec: TankSpec = account.loadout.selected_tank_spec
account.loadout.selected_tank_spec = item.tank_spec
Utils.connect_checked(
	account.loadout.selected_tank_spec_updated,
	func(_spec: TankSpec) -> void: _update_item_states()
)
```

Bad:
```gdscript
var selected_tank_spec: TankSpec = account.loadout.get_selected_tank_spec()
account.set_selected_tank_spec(item.tank_spec)
Utils.connect_checked(account.selected_tank_spec_updated, _update_item_states)
```

## 15) Avoid Overdefensive API Methods
- Avoid deeply nested and overdefensive single-method flows for straightforward HTTP operations.
- Prefer direct, linear control flow with a clear success/failure boundary.

Good (current `src/api/user_service/user_service_client.gd` pattern):
```gdscript
class ApiResult:
	extends RefCounted
	var success: bool
	var reason: String
	var body: Variant

	static func ok(next_body: Variant) -> ApiResult:
		return ApiResult.new(true, "", next_body)

	static func fail(next_reason: String) -> ApiResult:
		return ApiResult.new(false, next_reason, null)


func update_username(username: String) -> ApiResult:
	var session_token: String = AuthManager.session_token
	var normalized_username: String = username.strip_edges()
	if session_token.is_empty() or normalized_username.is_empty():
		var preflight_reason: String = "NOT_SIGNED_IN" if session_token.is_empty() else ""
		if preflight_reason.is_empty() and normalized_username.is_empty():
			preflight_reason = "USERNAME_REQUIRED"
		return ApiResult.fail(preflight_reason)

	var patch_result: ApiResult = await _request_json(
		"%s/me/username" % _base_url,
		HTTPClient.METHOD_PATCH,
		[
			"Content-Type: application/json",
			"Authorization: Bearer %s" % session_token,
		],
		JSON.stringify({"username": normalized_username})
	)
	if not patch_result.success:
		return ApiResult.fail(patch_result.reason)

	var body: Dictionary = patch_result.body
	var response_username: String = str(body.get("username", "")).strip_edges()
	if response_username.is_empty():
		return ApiResult.fail("USERNAME_INVALID_RESPONSE")

	Account.username = response_username
	var username_updated_at_unix: Variant = body.username_updated_at_unix
	Account.username_updated_at = int(username_updated_at_unix) if username_updated_at_unix != null else 0
	return ApiResult.ok(body)


func _request_json(
	url: String, method: HTTPClient.Method, headers: PackedStringArray, body: String
) -> ApiResult:
	if not is_inside_tree():
		return ApiResult.fail("USER_SERVICE_HTTP_REQUEST_CANCELED")
	var request: HTTPRequest = HTTPRequest.new()
	add_child(request)
	var request_error: Error = request.request(url, headers, method, body)
	if request_error != OK:
		request.queue_free()
		return ApiResult.fail("USER_SERVICE_HTTP_REQUEST_FAILED")
	var response: Array = await request.request_completed
	if is_instance_valid(request):
		request.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		return ApiResult.fail("USER_SERVICE_HTTP_TRANSPORT_FAILED")
	var response_code: int = int(response[1])
	var parsed_body: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	var parsed: Dictionary = parsed_body if parsed_body is Dictionary else {}
	if response_code < 200 or response_code >= 300:
		return ApiResult.fail(str(parsed.get("error", "USER_SERVICE_HTTP_ERROR")))
	return ApiResult.ok(parsed)
```

Bad (from `src/api/user_service/user_service_client.gd:update_username`):
```gdscript
func update_username(username: String) -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {"success": false, "reason": "", "data": {}}
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		result.reason = "NOT_SIGNED_IN"
	else:
		var normalized_username: String = username.strip_edges()
		if normalized_username.is_empty():
			result.reason = "USERNAME_REQUIRED"
		else:
			_log_user_service("updating username")
			var patch_url: String = "%s/me/username" % _base_url
			var request: HTTPRequest = HTTPRequest.new()
			add_child(request)
			var request_error: Error = (
				request
				. request(
					patch_url,
					[
						"Content-Type: application/json",
						"Authorization: Bearer %s" % session_token,
					],
					HTTPClient.METHOD_PATCH,
					JSON.stringify({"username": normalized_username})
				)
			)
			if request_error != OK:
				request.queue_free()
				result.reason = "USER_SERVICE_HTTP_REQUEST_FAILED"
			else:
				var response: Array = await request.request_completed
				if is_instance_valid(request):
					request.queue_free()
				var transport_result: int = int(response[0])
				if transport_result != HTTPRequest.RESULT_SUCCESS:
					result.reason = "USER_SERVICE_HTTP_TRANSPORT_FAILED"
				else:
					var response_code: int = int(response[1])
					var response_body: PackedByteArray = response[3]
					var parsed_body: Variant = JSON.parse_string(
						response_body.get_string_from_utf8()
					)
					var parsed_dictionary: Dictionary = (
						parsed_body if parsed_body is Dictionary else {}
					)
					result.data = parsed_dictionary
					if response_code < 200 or response_code >= 300:
						result.reason = str(
							parsed_dictionary.get("error", "USERNAME_UPDATE_FAILED")
						)
					else:
						var response_username: String = (
							str(parsed_dictionary.get("username", "")).strip_edges()
						)
						if response_username.is_empty():
							result.reason = "USERNAME_INVALID_RESPONSE"
						else:
							Account.username = response_username
							Account.username_updated_at = int(
								parsed_dictionary.get("username_updated_at_unix", 0)
							)
							result.success = true
							result.reason = ""

	return result
```

## Documentation Requirement
- When a new pattern is adopted in this repo, update this file with a concrete good/bad example.
