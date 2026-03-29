class_name ShellUnlockResponse
extends RefCounted

var economy_dollars: int
var economy_bonds: int
var loadout_dict: Dictionary


static func parse(body: Dictionary) -> ShellUnlockResponse:
	var economy_dict: Dictionary = body.get("economy", {})
	var result: ShellUnlockResponse = ShellUnlockResponse.new()
	result.economy_dollars = int(economy_dict.get("dollars", 0))
	result.economy_bonds = int(economy_dict.get("bonds", 0))
	result.loadout_dict = body.get("loadout", {})
	return result
