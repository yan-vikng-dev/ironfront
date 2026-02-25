class_name MeUsernamePatchResponse
extends RefCounted

var username: String
var username_updated_at_unix: Variant


static func parse(body: Dictionary) -> MeUsernamePatchResponse:
	var parsed: MeUsernamePatchResponse = MeUsernamePatchResponse.new()
	parsed.username = str(body.get("username", "")).strip_edges()
	parsed.username_updated_at_unix = body.get("username_updated_at_unix", null)
	return parsed
