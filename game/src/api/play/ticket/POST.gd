class_name PlayTicketPost
extends Node


func invoke() -> Result:
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return Result.err("NOT_SIGNED_IN")
	var client: UserServiceClient = get_parent()
	var ticket_url: String = "%s/play/ticket" % client.base_url
	var ticket_result: Result = await ApiRequest.request_json(
		client, ticket_url, HTTPClient.METHOD_POST, ["Authorization: Bearer %s" % session_token], ""
	)
	return ticket_result.and_then(PlayTicketResponse.parse, "TICKET_RESPONSE_INVALID")
