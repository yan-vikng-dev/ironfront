class_name PlayTicketVerifier
extends RefCounted


static func verify_and_extract(ticket: String, public_key: CryptoKey) -> Dictionary:
	var parts: PackedStringArray = ticket.split(".")
	if parts.size() != 3:
		return {}
	var message: String = parts[0] + "." + parts[1]
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(message.to_utf8_buffer())
	var message_hash: PackedByteArray = ctx.finish()
	var signature: PackedByteArray = _base64url_decode(parts[2])
	var crypto: Crypto = Crypto.new()
	if not crypto.verify(HashingContext.HASH_SHA256, message_hash, signature, public_key):
		return {}
	var payload: Variant = JSON.parse_string(_base64url_decode(parts[1]).get_string_from_utf8())
	if not payload is Dictionary:
		return {}
	var claims: Dictionary = payload
	if int(claims.get("exp", 0)) < int(Time.get_unix_time_from_system()):
		return {}
	return {
		"username": str(claims.get("username", "")).strip_edges(),
		"loadout": claims.get("loadout", {})
	}


static func _base64url_decode(s: String) -> PackedByteArray:
	var b64: String = s.replace("-", "+").replace("_", "/")
	var pad: int = (4 - b64.length() % 4) % 4
	for i in range(pad):
		b64 += "="
	return Marshalls.base64_to_raw(b64)
