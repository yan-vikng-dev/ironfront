class_name UnlockShellPost
extends Node


func invoke(tank_id: String, shell_id: String) -> Result:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return Result.err("NOT_SIGNED_IN")
	var normalized_tank_id: String = str(tank_id).strip_edges()
	var normalized_shell_id: String = str(shell_id).strip_edges()
	if normalized_tank_id.is_empty() or normalized_shell_id.is_empty():
		return Result.err("INVALID_SHELL")

	var post_url: String = "%s/me/unlock-shell" % client.base_url
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
			JSON.stringify({"tank_id": normalized_tank_id, "shell_id": normalized_shell_id})
		)
	)
	if post_result.is_err():
		return post_result

	var body: Dictionary = post_result.value
	var response: UnlockShellResponse = UnlockShellResponse.parse(body)
	Account.economy.dollars = response.economy_dollars
	Account.economy.bonds = response.economy_bonds
	Account.loadout.tanks = response.loadout_tanks
	Account.loadout.selected_tank_spec = response.loadout_selected_spec
	return post_result
