class_name PlayTicketResponse
extends RefCounted

var ticket: String
var expires_at_unix: int


func _init(next_ticket: String, next_expires_at_unix: int) -> void:
	ticket = next_ticket
	expires_at_unix = next_expires_at_unix


static func parse(body: Dictionary) -> PlayTicketResponse:
	var ticket_val: Variant = body.get("ticket")
	var expires_at_unix_val: Variant = body.get("expires_at_unix")
	if ticket_val == null or str(ticket_val).is_empty():
		return null
	return PlayTicketResponse.new(str(ticket_val), int(expires_at_unix_val))
