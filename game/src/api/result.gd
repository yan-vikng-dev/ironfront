class_name Result
extends RefCounted

var value: Variant
var error: String
var _is_ok: bool


func _init(next_is_ok: bool, next_value: Variant, next_error: String) -> void:
	_is_ok = next_is_ok
	value = next_value
	error = next_error


static func ok(next_value: Variant = null) -> Result:
	return Result.new(true, next_value, "")


static func err(reason: String) -> Result:
	return Result.new(false, null, reason)


func is_ok() -> bool:
	return _is_ok


func is_err() -> bool:
	return not _is_ok


func and_then(transform: Callable, err_reason: String) -> Result:
	if not _is_ok:
		return self
	var result: Variant = transform.call(value)
	if result == null:
		return Result.err(err_reason)
	return Result.ok(result)
