class_name ExchangeAuthResult
extends RefCounted

var exchange: UserServiceExchangeResponseBody
var me: MeGetResponse


func _init(next_exchange: UserServiceExchangeResponseBody, next_me: MeGetResponse) -> void:
	exchange = next_exchange
	me = next_me
