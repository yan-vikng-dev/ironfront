class_name MeLoadoutPatch
extends Node


func invoke(loadout_payload: Dictionary) -> Result:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return Result.err("NOT_SIGNED_IN")

	var patch_url: String = "%s/me/loadout" % client.base_url
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
			JSON.stringify(loadout_payload)
		)
	)
	if patch_result.is_err():
		return patch_result

	var body: Dictionary = patch_result.value
	var loadout_dict: Dictionary = body.get("loadout", {})
	if loadout_dict.is_empty():
		return patch_result
	var parsed: Dictionary = LoadoutPayload.parse(loadout_dict)
	Account.loadout.tanks = parsed.get("tanks", {})
	Account.loadout.selected_tank_spec = parsed.get("selected_spec", null)
	return patch_result
