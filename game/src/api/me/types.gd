class_name MeGetResponse
extends RefCounted

var account_id: String
var username: String
var username_updated_at_unix: Variant
var economy_dollars: int
var economy_bonds: int
var loadout_dict: Dictionary


static func parse(me_body: Dictionary) -> MeGetResponse:
	var result: MeGetResponse = MeGetResponse.new()
	result.account_id = str(me_body.get("account_id", "")).strip_edges()
	result.username = str(me_body.get("username", "")).strip_edges()
	result.username_updated_at_unix = me_body.get("username_updated_at_unix", null)
	var economy_dict: Dictionary = me_body.get("economy", {})
	result.economy_dollars = int(economy_dict.get("dollars", 0))
	result.economy_bonds = int(economy_dict.get("bonds", 0))
	result.loadout_dict = me_body.get("loadout", {})
	return result
