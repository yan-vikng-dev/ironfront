class_name ShellAmmoPatch
extends Node


func invoke(tank_id: String, shell_id: String, count: int) -> Result:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return Result.err("NOT_SIGNED_IN")
	var normalized_tank_id: String = str(tank_id).strip_edges()
	var normalized_shell_id: String = str(shell_id).strip_edges()
	if normalized_tank_id.is_empty() or normalized_shell_id.is_empty():
		return Result.err("INVALID_SHELL")

	var patch_url: String = (
		"%s/me/tank/%s/shell/%s" % [client.base_url, normalized_tank_id, normalized_shell_id]
	)
	var patch_result: Result = await (
		ApiRequest
		. request_json(
			client,
			patch_url,
			HTTPClient.METHOD_PATCH,
			[
				"Content-Type: application/json",
				"Authorization: Bearer %s" % session_token,
			],
			JSON.stringify({"count": count})
		)
	)
	return patch_result
