class_name CatalogPrices
extends RefCounted

static var tank_prices: Dictionary[String, int] = {}
static var shell_prices: Dictionary[String, int] = {}


static func get_tank_price(tank_id: String) -> int:
	return tank_prices.get(tank_id, 0)


static func get_shell_price(shell_id: String) -> int:
	return shell_prices.get(shell_id, 0)


static func apply(body: Dictionary) -> void:
	tank_prices.clear()
	shell_prices.clear()
	var tanks_dict: Dictionary = body.get("tanks", {})
	for tank_id_variant: Variant in tanks_dict.keys():
		var tank_id: String = str(tank_id_variant).strip_edges()
		if tank_id.is_empty():
			continue
		var tank_data: Dictionary = tanks_dict.get(tank_id_variant, {})
		tank_prices[tank_id] = int(tank_data.get("dollar_cost", 0))
	var shells_dict: Dictionary = body.get("shells", {})
	for shell_id_variant: Variant in shells_dict.keys():
		var shell_id: String = str(shell_id_variant).strip_edges()
		if shell_id.is_empty():
			continue
		var shell_data: Dictionary = shells_dict.get(shell_id_variant, {})
		shell_prices[shell_id] = int(shell_data.get("unlock_cost", 0))
