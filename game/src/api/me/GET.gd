class_name MeGet
extends Node


func invoke(session_token: String) -> ApiResult:
	var client: UserServiceClient = get_parent()
	var me_url: String = "%s/me" % client.base_url
	return await ApiRequest.request_json(
		client, me_url, HTTPClient.METHOD_GET, ["Authorization: Bearer %s" % session_token], ""
	)
