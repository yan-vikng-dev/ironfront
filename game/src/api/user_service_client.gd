class_name UserServiceClient
extends Node

var base_url: String

@onready var _auth_exchange_post: AuthExchangePost = %AuthExchangePost
@onready var _catalog_get: CatalogGet = %CatalogGet
@onready var _me_get: MeGet = %MeGet
@onready var _me_loadout_patch: MeLoadoutPatch = %MeLoadoutPatch
@onready var _me_username_patch: MeUsernamePatch = %MeUsernamePatch
@onready var _play_ticket_post: PlayTicketPost = %PlayTicketPost
@onready var _unlock_shell_post: UnlockShellPost = %UnlockShellPost
@onready var _unlock_tank_post: UnlockTankPost = %UnlockTankPost


func _ready() -> void:
	base_url = AppConfig.user_service_base_url


func _exit_tree() -> void:
	for child: Node in get_children():
		var request: HTTPRequest = child as HTTPRequest
		if request == null:
			continue
		request.cancel_request()
		request.emit_signal(
			"request_completed",
			HTTPRequest.RESULT_CANT_CONNECT,
			0,
			PackedStringArray(),
			PackedByteArray()
		)
		request.queue_free()


func exchange_auth(provider: String, proof: String) -> Result:
	_log_user_service("exchanging provider proof with user-service")
	var exchange_result: Result = await _auth_exchange_post.invoke(provider, proof)
	if exchange_result.is_err():
		return exchange_result

	_log_user_service("exchange succeeded, fetching catalog + profile")
	var catalog_result: Result = await _catalog_get.invoke()
	if catalog_result.is_err():
		return Result.err("CATALOG_FETCH_FAILED")

	var exchange_body: AuthExchangeResponse = exchange_result.value
	var me_result: Result = await _me_get.invoke(exchange_body.session_token)
	if me_result.is_err():
		return me_result

	var parsed_me: MeGetResponse = MeGetResponse.parse(me_result.value)
	return Result.ok(ExchangeAuthResult.new(exchange_body, parsed_me))


func update_username(username: String) -> Result:
	_log_user_service("updating username")
	return await _me_username_patch.invoke(username)


func fetch_play_ticket() -> Result:
	_log_user_service("fetching play ticket")
	return await _play_ticket_post.invoke()


func update_loadout(loadout_payload: Dictionary) -> Result:
	_log_user_service("updating loadout")
	return await _me_loadout_patch.invoke(loadout_payload)


func unlock_tank(tank_id: String, initial_shell_id: String) -> Result:
	_log_user_service("unlocking tank tank_id=%s" % tank_id)
	return await _unlock_tank_post.invoke(tank_id, initial_shell_id)


func unlock_shell(tank_id: String, shell_id: String) -> Result:
	_log_user_service("unlocking shell tank_id=%s shell_id=%s" % [tank_id, shell_id])
	return await _unlock_shell_post.invoke(tank_id, shell_id)


func _log_user_service(message: String) -> void:
	print("[user-service-client] %s" % message)
