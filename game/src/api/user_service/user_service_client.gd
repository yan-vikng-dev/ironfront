class_name UserServiceClient
extends Node

var _base_url: String


func _init(next_base_url: String) -> void:
	_base_url = next_base_url


func _exit_tree() -> void:
	_cancel_all_requests()


class ApiResult:
	extends RefCounted
	var success: bool
	var reason: String
	var body: Variant

	func _init(next_success: bool, next_reason: String, next_body: Variant) -> void:
		success = next_success
		reason = next_reason
		body = next_body

	static func ok(next_body: Variant) -> ApiResult:
		return ApiResult.new(true, "", next_body)

	static func fail(next_reason: String) -> ApiResult:
		return ApiResult.new(false, next_reason, null)


func exchange_auth(provider: String, proof: String) -> ApiResult:
	_log_user_service("exchanging provider proof with user-service")
	var exchange_url: String = "%s/auth/exchange" % _base_url
	var exchange_payload: Dictionary[String, Variant] = {
		"provider": provider,
		"proof": proof,
	}
	var exchange_result: ApiResult = await _request_json(
		exchange_url,
		HTTPClient.METHOD_POST,
		["Content-Type: application/json"],
		JSON.stringify(exchange_payload)
	)
	if not exchange_result.success:
		return ApiResult.fail(exchange_result.reason)

	var exchange_body: UserServiceExchangeResponseBody = UserServiceExchangeResponseBody.from_dict(
		exchange_result.body
	)
	if exchange_body == null:
		return ApiResult.fail("USER_SERVICE_EXCHANGE_PARSE_FAILED")

	_log_user_service("exchange succeeded, fetching profile")
	var me_url: String = "%s/me" % _base_url
	var me_result: ApiResult = await _request_json(
		me_url,
		HTTPClient.METHOD_GET,
		["Authorization: Bearer %s" % exchange_body.session_token],
		""
	)
	if not me_result.success:
		return ApiResult.fail(me_result.reason)

	var me_body: Dictionary = me_result.body
	UserServiceMeResponseParser.hydrate_account_from_me_body(me_body)

	return ApiResult.ok(exchange_body)


func update_username(username: String) -> ApiResult:
	var session_token: String = AuthManager.session_token
	var normalized_username: String = username.strip_edges()
	if session_token.is_empty() or normalized_username.is_empty():
		var preflight_reason: String = "NOT_SIGNED_IN" if session_token.is_empty() else ""
		if preflight_reason.is_empty() and normalized_username.is_empty():
			preflight_reason = "USERNAME_REQUIRED"
		return ApiResult.fail(preflight_reason)

	_log_user_service("updating username")
	var patch_url: String = "%s/me/username" % _base_url
	var patch_result: ApiResult = await _request_json(
		patch_url,
		HTTPClient.METHOD_PATCH,
		[
			"Content-Type: application/json",
			"Authorization: Bearer %s" % session_token,
		],
		JSON.stringify({"username": normalized_username})
	)
	if not patch_result.success:
		return ApiResult.fail(patch_result.reason)

	var parsed_dictionary: Dictionary = patch_result.body
	var response_username: String = str(parsed_dictionary.get("username", "")).strip_edges()
	if response_username.is_empty():
		return ApiResult.fail("USERNAME_INVALID_RESPONSE")
	Account.username = response_username
	var username_updated_at_unix: Variant = parsed_dictionary.username_updated_at_unix
	Account.username_updated_at = (
		int(username_updated_at_unix) if username_updated_at_unix != null else 0
	)
	return ApiResult.ok(parsed_dictionary)


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

	var transport_result: int = int(response[0])
	if transport_result != HTTPRequest.RESULT_SUCCESS:
		return ApiResult.fail("USER_SERVICE_HTTP_TRANSPORT_FAILED")
	var response_code: int = int(response[1])
	var response_body: PackedByteArray = response[3]
	var parsed_body: Variant = JSON.parse_string(response_body.get_string_from_utf8())
	var parsed_dictionary: Dictionary = parsed_body if parsed_body is Dictionary else {}
	if response_code < 200 or response_code >= 300:
		return ApiResult.fail(str(parsed_dictionary.get("error", "USER_SERVICE_HTTP_ERROR")))
	return ApiResult.ok(parsed_dictionary)


func _cancel_all_requests() -> void:
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


func _log_user_service(message: String) -> void:
	print("[user-service-client] %s" % message)
