class_name MeLoadoutPatch
extends Node


func invoke(loadout_payload: Dictionary) -> ApiResult:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	if session_token.is_empty():
		return ApiResult.fail("NOT_SIGNED_IN")

	var patch_url: String = "%s/me/loadout" % client.base_url
	var patch_result: ApiResult = await (
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
	if not patch_result.success:
		return ApiResult.fail(patch_result.reason)

	var body: Dictionary = patch_result.body if patch_result.body is Dictionary else {}
	var loadout_dict: Dictionary = body.get("loadout", {})
	if loadout_dict.is_empty():
		return patch_result
	var parsed: Dictionary = LoadoutPayload.parse(loadout_dict)
	Account.loadout.tanks = parsed.get("tanks", {})
	Account.loadout.selected_tank_spec = parsed.get("selected_spec", null)
	return patch_result
