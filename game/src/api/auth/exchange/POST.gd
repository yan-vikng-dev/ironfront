class_name AuthExchangePost
extends Node


func invoke(provider: String, proof: String) -> ApiResult:
	var client: UserServiceClient = get_parent()
	var exchange_url: String = "%s/auth/exchange" % client.base_url
	var exchange_payload: Dictionary[String, Variant] = {
		"provider": provider,
		"proof": proof,
	}
	var exchange_result: ApiResult = await ApiRequest.request_json(
		client,
		exchange_url,
		HTTPClient.METHOD_POST,
		["Content-Type: application/json"],
		JSON.stringify(exchange_payload)
	)
	if not exchange_result.success:
		return ApiResult.fail(exchange_result.reason)

	var exchange_body: AuthExchangeResponse = AuthExchangeResponse.parse(exchange_result.body)
	if exchange_body == null:
		return ApiResult.fail("USER_SERVICE_EXCHANGE_PARSE_FAILED")

	return ApiResult.ok(exchange_body)
