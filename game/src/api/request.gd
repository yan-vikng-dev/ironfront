class_name ApiRequest
extends RefCounted


static func request_json(
	parent: Node, url: String, method: HTTPClient.Method, headers: PackedStringArray, body: String
) -> Result:
	var request: HTTPRequest = HTTPRequest.new()
	parent.add_child(request)
	var request_error: Error = request.request(url, headers, method, body)
	if request_error != OK:
		request.queue_free()
		return Result.err("USER_SERVICE_HTTP_REQUEST_FAILED")

	var response: Array = await request.request_completed
	if is_instance_valid(request):
		request.queue_free()

	var transport_result: int = int(response[0])
	if transport_result != HTTPRequest.RESULT_SUCCESS:
		return Result.err("USER_SERVICE_HTTP_TRANSPORT_FAILED")
	var response_code: int = int(response[1])
	var response_body: PackedByteArray = response[3]
	var parsed_body: Variant = JSON.parse_string(response_body.get_string_from_utf8())
	var parsed_dictionary: Dictionary = parsed_body if parsed_body is Dictionary else {}
	if response_code < 200 or response_code >= 300:
		return Result.err(str(parsed_dictionary.get("error", "USER_SERVICE_HTTP_ERROR")))
	return Result.ok(parsed_dictionary)
