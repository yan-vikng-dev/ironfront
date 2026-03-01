class_name LoadoutPayload
extends RefCounted


static func parse(loadout_dict: Dictionary) -> Dictionary:
	var selected_tank_id_input: String = str(loadout_dict.get("selected_tank_id", "")).strip_edges()
	var next_tanks: Dictionary[TankSpec, TankConfig] = {}
	var source_tanks: Dictionary = loadout_dict.get("tanks", {})

	for tank_id_variant: Variant in source_tanks.keys():
		var tank_id: String = str(tank_id_variant).strip_edges()
		if tank_id.is_empty():
			continue
		var tank_spec: TankSpec = TankManager.find_tank_spec(tank_id)
		if tank_spec == null:
			continue
		var tank_payload: Dictionary = source_tanks.get(tank_id_variant, {})
		var cfg: TankConfig = TankConfig.new()
		cfg.tank_spec = tank_spec

		var unlocked_specs: Array[ShellSpec] = []
		for shell_id_variant: Variant in tank_payload.get("unlocked_shell_ids", []):
			var shell_id: String = str(shell_id_variant).strip_edges()
			if shell_id.is_empty():
				continue
			var shell_spec: ShellSpec = ShellManager.find_shell_spec(shell_id)
			if shell_spec == null:
				continue
			if not tank_spec.allowed_shells.has(shell_spec):
				continue
			unlocked_specs.append(shell_spec)
		cfg.unlocked_shell_specs = unlocked_specs

		var shell_loadout: Dictionary[ShellSpec, int] = {}
		var shell_loadout_input: Dictionary = tank_payload.get("shell_loadout_by_id", {})
		for shell_id_variant: Variant in shell_loadout_input.keys():
			var shell_id: String = str(shell_id_variant).strip_edges()
			if shell_id.is_empty():
				continue
			var shell_spec: ShellSpec = ShellManager.find_shell_spec(shell_id)
			if shell_spec == null:
				continue
			if not tank_spec.allowed_shells.has(shell_spec):
				continue
			shell_loadout[shell_spec] = int(shell_loadout_input.get(shell_id_variant, 0))
		cfg.shell_loadout_by_spec = shell_loadout

		next_tanks[tank_spec] = cfg

	var default_spec: TankSpec = TankManager.find_tank_spec(TankManager.TANK_ID_M4A1_SHERMAN)
	var selected_spec: TankSpec = null
	if not selected_tank_id_input.is_empty():
		selected_spec = TankManager.find_tank_spec(selected_tank_id_input)
		if selected_spec != null and not next_tanks.has(selected_spec):
			selected_spec = null
	if selected_spec == null and not next_tanks.is_empty():
		selected_spec = next_tanks.keys()[0] as TankSpec
	if selected_spec == null and default_spec != null:
		selected_spec = default_spec

	if (
		next_tanks.is_empty()
		and default_spec != null
		and not default_spec.allowed_shells.is_empty()
	):
		var first_shell: ShellSpec = default_spec.allowed_shells[0]
		var starter_cfg: TankConfig = TankConfig.new()
		starter_cfg.tank_spec = default_spec
		starter_cfg.unlocked_shell_specs = [first_shell]
		var starter_shell_loadout: Dictionary[ShellSpec, int] = {}
		starter_shell_loadout[first_shell] = default_spec.shell_capacity
		starter_cfg.shell_loadout_by_spec = starter_shell_loadout
		next_tanks[default_spec] = starter_cfg
		if selected_spec == null:
			selected_spec = default_spec

	return {"tanks": next_tanks, "selected_spec": selected_spec}


static func from_account_loadout(loadout: AccountLoadout) -> Dictionary:
	var tanks_payload: Dictionary = {}
	for tank_spec: TankSpec in loadout.tanks.keys():
		var tank_id: String = str(tank_spec.tank_id) if tank_spec != null else ""
		if tank_id.is_empty():
			continue
		var cfg: TankConfig = loadout.tanks.get(tank_spec, null)
		if cfg == null:
			continue
		var unlocked_shell_ids: Array[String] = []
		var shell_loadout_by_id: Dictionary = {}
		for shell_spec: ShellSpec in cfg.unlocked_shell_specs:
			if shell_spec != null:
				var shell_id: String = ShellManager.get_shell_id(shell_spec)
				if not shell_id.is_empty():
					unlocked_shell_ids.append(shell_id)
		for shell_spec_key: Variant in cfg.shell_loadout_by_spec.keys():
			var shell_spec: ShellSpec = shell_spec_key as ShellSpec
			if shell_spec != null:
				var shell_id: String = ShellManager.get_shell_id(shell_spec)
				if not shell_id.is_empty():
					shell_loadout_by_id[shell_id] = int(
						cfg.shell_loadout_by_spec.get(shell_spec_key, 0)
					)
		tanks_payload[tank_id] = {
			"unlocked_shell_ids": unlocked_shell_ids, "shell_loadout_by_id": shell_loadout_by_id
		}
	var selected_tank_id: String = ""
	if loadout.selected_tank_spec != null:
		selected_tank_id = str(loadout.selected_tank_spec.tank_id)
	return {"selected_tank_id": selected_tank_id, "tanks": tanks_payload}
