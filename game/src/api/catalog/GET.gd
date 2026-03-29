class_name CatalogGet
extends Node


func invoke() -> Result:
	var client: UserServiceClient = get_parent()
	var get_url: String = "%s/catalog" % client.base_url
	var get_result: Result = await (ApiRequest.request_json(
		client, get_url, HTTPClient.METHOD_GET, PackedStringArray(), ""
	))
	if get_result.is_err():
		return get_result

	CatalogPrices.apply(get_result.value)
	return get_result
