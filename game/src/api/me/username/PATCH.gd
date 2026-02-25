class_name MeUsernamePatch
extends Node


func invoke(username: String) -> ApiResult:
	var client: UserServiceClient = get_parent()
	var session_token: String = AuthManager.session_token
	var normalized_username: String = username.strip_edges()
	if session_token.is_empty() or normalized_username.is_empty():
		var preflight_reason: String = "NOT_SIGNED_IN" if session_token.is_empty() else ""
		if preflight_reason.is_empty() and normalized_username.is_empty():
			preflight_reason = "USERNAME_REQUIRED"
		return ApiResult.fail(preflight_reason)

	var patch_url: String = "%s/me/username" % client.base_url
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
			JSON.stringify({"username": normalized_username})
		)
	)
	if not patch_result.success:
		return ApiResult.fail(patch_result.reason)

	var response: MeUsernamePatchResponse = MeUsernamePatchResponse.parse(patch_result.body)
	if response.username.is_empty():
		return ApiResult.fail("USERNAME_INVALID_RESPONSE")
	Account.username = response.username
	Account.username_updated_at = response.username_updated_at_unix
	return ApiResult.ok(patch_result.body)
