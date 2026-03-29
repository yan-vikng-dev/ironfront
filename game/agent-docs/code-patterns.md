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

## 2a) Autoloads and Dependencies
- Prefer script autoloads. Add child nodes (e.g. API clients) in `_ready()` via `instance()` and `add_child()` rather than embedding them in a parent scene.
- Godot forbids `class_name X` when an autoload is named `X`. Use a non-conflicting `class_name` (e.g. `AuthManagerNode`) for type inference.
- Code accesses the singleton by autoload name (e.g. `AuthManager`).

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
- For API/HTTP results, use the typed `Result` class (see pattern 16).

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

## 15) API Client Router and Handler Convention
- API clients use a router + handler pattern mirroring the user-service server routes.
- The router is a scene (for example `user_service_client.tscn`) with handler nodes as children. Handlers use `unique_name_in_owner = true` and are referenced via `%UniqueName` or `@onready` vars. The router owns `base_url` (from AppConfig in `_ready`) and `_cancel_all_requests`.
- Routes are fully defined by folders. Each leaf route folder contains `VERB.gd` (handler) and `types.gd` (DTOs, parsers). Example: `api/me/username/[PATCH.gd, types.gd]`. Handler class names follow `FullRouteVerb`: `AuthExchangePost`, `MeGet`, `MeUsernamePatch`.
- Handlers expose `func invoke(...args) -> Result` (instance method). They call `ApiRequest.request_json(...)` for HTTP; the static transport lives in `api/request.gd`.
- Shared types (`Result`) and transport (`ApiRequest.request_json` in `api/request.gd`) stay at `api/` root.
- Multi-step flows (for example exchange then fetch profile) are orchestrated in the router, not inside a single handler.
- Response DTOs use `*Response` suffix (for example `AuthExchangeResponse`, `MeUsernamePatchResponse`). API contract types use `*Payload` (for example `LoadoutPayload` for serialize/deserialize).
- Response parsers: `static func parse(body: Dictionary) -> T`. Use `null` on validation failure when the response is invalid; return a typed object on success. Parsers returning null compose with `Result.and_then(Parser.parse, "REASON")`.

Good (`src/api/` structure):
```
api/
├── user_service_client.tscn    # Router scene with handlers as unique-name children
├── user_service_client.gd
├── result.gd                   # Shared Result type (Rust-style ok/err/unwrap/and_then)
├── request.gd                  # ApiRequest.request_json (static transport)
├── auth/
│   └── exchange/
│       ├── POST.gd             # POST /auth/exchange
│       ├── types.gd            # AuthExchangeResponse
│       └── exchange_auth_result.gd  # Router-level composite (exchange + me)
├── me/
│   ├── GET.gd                  # GET /me
│   ├── types.gd                # MeGetResponse
│   ├── username/
│   │   ├── PATCH.gd            # PATCH /me/username
│   │   └── types.gd            # MeUsernamePatchResponse
│   ├── loadout/
│   │   ├── PATCH.gd            # PATCH /me/loadout
│   │   └── types.gd            # LoadoutPayload (parse + from_account_loadout)
│   ├── unlock_tank/
│   │   ├── POST.gd             # POST /me/unlock-tank
│   │   └── types.gd            # UnlockTankResponse
│   └── unlock_shell/
│       ├── POST.gd             # POST /me/unlock-shell
│       └── types.gd            # UnlockShellResponse
└── play/
    └── ticket/
        ├── POST.gd             # POST /play/ticket
        └── types.gd            # PlayTicketResponse
```

## 16) Avoid Overdefensive API Methods — Use Rust-Style Result
- The shared `Result` class (`api/result.gd`) follows Rust `Result<T, E>` conventions.
- Constructors: `Result.ok(value)`, `Result.err(reason)`.
- Queries: `is_ok()`, `is_err()`.
- Access: `.value` (ok payload), `.error` (err reason). Access after checking `is_ok()`/`is_err()`.
- Chaining: `and_then(transform, err_reason)` — on ok, calls `transform(value)`; if transform returns null, produces `Result.err(err_reason)`.
- Avoid deeply nested and overdefensive single-method flows for straightforward HTTP operations.
- Prefer direct, linear control flow with a clear success/failure boundary.

Result API:
```gdscript
class Result:
	extends RefCounted
	var value: Variant        # ok payload (access after is_ok check)
	var error: String         # err reason (access after is_err check)
	static func ok(value: Variant = null) -> Result: ...
	static func err(reason: String) -> Result: ...
	func is_ok() -> bool: ...
	func is_err() -> bool: ...
	func and_then(transform: Callable, err_reason: String) -> Result: ...
```

Good — error propagation (GDScript equivalent of Rust's `?` operator):
```gdscript
func invoke() -> Result:
	var http_result: Result = await ApiRequest.request_json(...)
	if http_result.is_err():
		return http_result  # forward error to caller

	var body: Dictionary = http_result.value
	return Result.ok(body)
```

Good — preflight validation before async work:
```gdscript
func invoke(tank_id: String) -> Result:
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return Result.err("NOT_SIGNED_IN")
	if tank_id.strip_edges().is_empty():
		return Result.err("INVALID_TANK")

	var post_result: Result = await ApiRequest.request_json(...)
	if post_result.is_err():
		return post_result
	# ... apply side effects ...
	return post_result
```

Good — `and_then` for parse-or-fail in one call:
```gdscript
func invoke(provider: String, proof: String) -> Result:
	var exchange_result: Result = await ApiRequest.request_json(...)
	return exchange_result.and_then(AuthExchangeResponse.parse, "EXCHANGE_PARSE_FAILED")
```

Good — multi-step orchestration, bailing on first failure:
```gdscript
func exchange_auth(provider: String, proof: String) -> Result:
	var exchange_result: Result = await _auth_exchange_post.invoke(provider, proof)
	if exchange_result.is_err():
		return exchange_result

	var catalog_result: Result = await _catalog_get.invoke()
	if catalog_result.is_err():
		return Result.err("CATALOG_FETCH_FAILED")  # override with contextual reason

	var me_result: Result = await _me_get.invoke(exchange_result.value.session_token)
	if me_result.is_err():
		return me_result

	return Result.ok(ExchangeAuthResult.new(exchange_result.value, me_result.value))
```

Good — consumer-side branching:
```gdscript
var result: Result = await client.update_username(username)
if result.is_ok():
	hide_prompt()
	return
show_error(result.error)
```

Bad (deeply nested alternative; avoid this):
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
			# ... deeply nested HTTP + parse + error handling ...
			pass
	return result
```

## Documentation Requirement
- When a new pattern is adopted in this repo, update this file with a concrete good/bad example.
