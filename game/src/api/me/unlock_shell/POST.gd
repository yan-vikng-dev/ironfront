class_name UnlockShellPost
extends Node


func invoke(tank_id: String, shell_id: String) -> ApiResult:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return ApiResult.fail("NOT_SIGNED_IN")
	var normalized_tank_id: String = str(tank_id).strip_edges()
	var normalized_shell_id: String = str(shell_id).strip_edges()
	if normalized_tank_id.is_empty() or normalized_shell_id.is_empty():
		return ApiResult.fail("INVALID_SHELL")

	var post_url: String = "%s/me/unlock-shell" % client.base_url
	var post_result: ApiResult = await (
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
	if not post_result.success:
		return ApiResult.fail(post_result.reason)

	var body: Dictionary = post_result.body if post_result.body is Dictionary else {}
	var response: UnlockShellResponse = UnlockShellResponse.parse(body)
	Account.economy.dollars = response.economy_dollars
	Account.economy.bonds = response.economy_bonds
	Account.loadout.tanks = response.loadout_tanks
	Account.loadout.selected_tank_spec = response.loadout_selected_spec
	return post_result
