class_name TankSelectPatch
extends Node


func invoke(tank_id: String) -> Result:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return Result.err("NOT_SIGNED_IN")
	var normalized_tank_id: String = str(tank_id).strip_edges()
	if normalized_tank_id.is_empty():
		return Result.err("INVALID_TANK")

	var patch_url: String = "%s/me/tank/%s" % [client.base_url, normalized_tank_id]
	var patch_result: Result = await (
		ApiRequest
		. request_json(
			client,
			patch_url,
			HTTPClient.METHOD_PATCH,
			[
				"Authorization: Bearer %s" % session_token,
			],
			""
		)
	)
	return patch_result
