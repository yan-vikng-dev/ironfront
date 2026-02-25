class_name MeGet
extends Node


func invoke(session_token: String) -> ApiResult:
	var client: UserServiceClient = get_parent()
	var me_url: String = "%s/me" % client.base_url
	var me_result: ApiResult = await ApiRequest.request_json(
		client, me_url, HTTPClient.METHOD_GET, ["Authorization: Bearer %s" % session_token], ""
	)
	if not me_result.success:
		return me_result

	return ApiResult.ok(me_result.body)
