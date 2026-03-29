class_name AuthExchangePost
extends Node


func invoke(provider: String, proof: String) -> Result:
	var client: UserServiceClient = get_parent()
	var exchange_url: String = "%s/auth/exchange" % client.base_url
	var exchange_payload: Dictionary[String, Variant] = {
		"provider": provider,
		"proof": proof,
	}
	var exchange_result: Result = await ApiRequest.request_json(
		client,
		exchange_url,
		HTTPClient.METHOD_POST,
		["Content-Type: application/json"],
		JSON.stringify(exchange_payload)
	)
	return exchange_result.and_then(
		AuthExchangeResponse.parse, "USER_SERVICE_EXCHANGE_PARSE_FAILED"
	)
