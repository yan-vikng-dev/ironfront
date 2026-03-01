class_name UnlockShellResponse
extends RefCounted

var economy_dollars: int
var economy_bonds: int
var loadout_tanks: Dictionary
var loadout_selected_spec: TankSpec


static func parse(body: Dictionary) -> UnlockShellResponse:
	var economy_dict: Dictionary = body.get("economy", {})
	var loadout_dict: Dictionary = body.get("loadout", {})
	var loadout_parsed: Dictionary = LoadoutPayload.parse(loadout_dict)
	var result: UnlockShellResponse = UnlockShellResponse.new()
	result.economy_dollars = int(economy_dict.get("dollars", 0))
	result.economy_bonds = int(economy_dict.get("bonds", 0))
	result.loadout_tanks = loadout_parsed.get("tanks", {})
	result.loadout_selected_spec = loadout_parsed.get("selected_spec", null)
	return result
