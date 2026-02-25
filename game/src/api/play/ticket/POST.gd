class_name PlayTicketPost
extends Node


func invoke() -> ApiResult:
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return ApiResult.fail("NOT_SIGNED_IN")
	var client: UserServiceClient = get_parent()
	var ticket_url: String = "%s/play/ticket" % client.base_url
	var ticket_result: ApiResult = await ApiRequest.request_json(
		client, ticket_url, HTTPClient.METHOD_POST, ["Authorization: Bearer %s" % session_token], ""
	)
	if not ticket_result.success:
		return ticket_result
	if not ticket_result.body is Dictionary:
		return ApiResult.fail("TICKET_RESPONSE_INVALID")
	var response: PlayTicketResponse = PlayTicketResponse.parse(ticket_result.body)
	if response == null:
		return ApiResult.fail("TICKET_RESPONSE_INVALID")
	return ApiResult.ok(response)
