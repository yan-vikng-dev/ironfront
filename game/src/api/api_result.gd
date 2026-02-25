class_name ApiResult
extends RefCounted

var success: bool
var reason: String
var body: Variant


func _init(next_success: bool, next_reason: String, next_body: Variant) -> void:
	success = next_success
	reason = next_reason
	body = next_body


static func ok(next_body: Variant) -> ApiResult:
	return ApiResult.new(true, "", next_body)


static func fail(next_reason: String) -> ApiResult:
	return ApiResult.new(false, next_reason, null)
