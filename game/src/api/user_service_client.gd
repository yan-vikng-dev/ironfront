class_name UserServiceClient
extends Node

var base_url: String

@onready var _auth_exchange: AuthExchangePost = %AuthExchangePost
@onready var _me_get: MeGet = %MeGet
@onready var _me_patch: MeUsernamePatch = %MeUsernamePatch


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


func exchange_auth(provider: String, proof: String) -> ApiResult:
	_log_user_service("exchanging provider proof with user-service")
	var exchange_result: ApiResult = await _auth_exchange.invoke(provider, proof)
	if not exchange_result.success:
		return exchange_result

	_log_user_service("exchange succeeded, fetching profile")
	var me_result: ApiResult = await _me_get.invoke(exchange_result.body.session_token)
	if not me_result.success:
		return me_result

	var parsed_me: MeGetResponse = MeGetResponse.parse(me_result.body)
	return ApiResult.ok(ExchangeAuthResult.new(exchange_result.body, parsed_me))


func update_username(username: String) -> ApiResult:
	_log_user_service("updating username")
	return await _me_patch.invoke(username)


func _log_user_service(message: String) -> void:
	print("[user-service-client] %s" % message)
