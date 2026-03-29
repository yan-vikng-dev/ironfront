class_name TankUnlockPost
extends Node


func invoke(tank_id: String, initial_shell_id: String) -> Result:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return Result.err("NOT_SIGNED_IN")
	var normalized_tank_id: String = str(tank_id).strip_edges()
	var normalized_shell_id: String = str(initial_shell_id).strip_edges()
	if normalized_tank_id.is_empty() or normalized_shell_id.is_empty():
		return Result.err("INVALID_TANK")

	var post_url: String = "%s/me/tank/%s" % [client.base_url, normalized_tank_id]
	var post_result: Result = await (
		ApiRequest
		. request_json(
			client,
			post_url,
			HTTPClient.METHOD_POST,
			[
				"Content-Type: application/json",
				"Authorization: Bearer %s" % session_token,
			],
			JSON.stringify({"initial_shell_id": normalized_shell_id})
		)
	)
	if post_result.is_err():
		return post_result

	var body: Dictionary = post_result.value
	var response: TankUnlockResponse = TankUnlockResponse.parse(body)
	Account.economy.dollars = response.economy_dollars
	Account.economy.bonds = response.economy_bonds
	Account.loadout.apply_server_loadout(response.loadout_dict)
	return post_result
