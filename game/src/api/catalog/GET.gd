class_name CatalogGet
extends Node


func invoke() -> ApiResult:
	var client: UserServiceClient = get_parent()
	var get_url: String = "%s/catalog" % client.base_url
	var get_result: ApiResult = await (ApiRequest.request_json(
		client, get_url, HTTPClient.METHOD_GET, PackedStringArray(), ""
	))
	if not get_result.success:
		return ApiResult.fail(get_result.reason)

	var body: Dictionary = get_result.body if get_result.body is Dictionary else {}
	CatalogPrices.apply(body)
	return get_result
