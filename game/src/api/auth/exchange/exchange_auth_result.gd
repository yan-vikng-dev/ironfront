class_name ExchangeAuthResult
extends RefCounted

var exchange: AuthExchangeResponse
var me: MeGetResponse


func _init(next_exchange: AuthExchangeResponse, next_me: MeGetResponse) -> void:
	exchange = next_exchange
	me = next_me
