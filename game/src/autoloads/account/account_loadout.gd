class_name AccountLoadout
extends RefCounted

signal selected_tank_spec_updated(new_selected_tank_spec: TankSpec)
signal tanks_updated(new_tanks: Dictionary[TankSpec, TankConfig])

var selected_tank_spec: TankSpec:
	get:
		if _selected_tank_spec != null:
			return _selected_tank_spec
		return _first_unlocked_tank_spec_or_default()
	set(value):
		var effective_new: TankSpec = _coerce_selected_tank_spec(value)
		var effective_old: TankSpec = (
			_selected_tank_spec
			if _selected_tank_spec != null
			else _first_unlocked_tank_spec_or_default()
		)
		if effective_new == effective_old:
			return
		_selected_tank_spec = effective_new
		selected_tank_spec_updated.emit(effective_new)

var tanks: Dictionary[TankSpec, TankConfig] = {}:
	set(value):
		tanks = value
		_selected_tank_spec = _coerce_selected_tank_spec(_selected_tank_spec)
		tanks_updated.emit(tanks)

var _selected_tank_spec: TankSpec = null


static func _default_tank_spec() -> TankSpec:
	return TankManager.require_tank_spec(TankManager.TANK_ID_M4A1_SHERMAN)


func _first_unlocked_tank_spec_or_default() -> TankSpec:
	for key: Variant in tanks.keys():
		var spec: TankSpec = key as TankSpec
		if spec != null:
			return spec
	return _default_tank_spec()


func _coerce_selected_tank_spec(candidate: TankSpec) -> TankSpec:
	if candidate != null and (tanks.is_empty() or tanks.has(candidate)):
		return candidate
	return _first_unlocked_tank_spec_or_default()


static func _spec_with_shells() -> TankSpec:
	var default_spec: TankSpec = _default_tank_spec()
	if default_spec != null and not default_spec.allowed_shells.is_empty():
		return default_spec
	for tank_id: String in TankManager.get_tank_ids():
		var s: TankSpec = TankManager.find_tank_spec(tank_id)
		if s != null and not s.allowed_shells.is_empty():
			return s
	return _default_tank_spec()


func has_tank(tank_spec: TankSpec) -> bool:
	return tanks.has(tank_spec)


func get_tank_specs() -> Array[TankSpec]:
	var result: Array[TankSpec] = []
	for key: Variant in tanks.keys():
		if key is TankSpec:
			result.append(key)
	return result


func get_tank_config(tank_spec: TankSpec) -> TankConfig:
	return tanks.get(tank_spec, null)


func apply_server_loadout(loadout_dict: Dictionary) -> void:
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
		next_tanks[tank_spec] = TankConfig.from_server_dict(
			tank_spec, source_tanks.get(tank_id_variant, {})
		)
	var default_spec: TankSpec = _default_tank_spec()
	var new_selected: TankSpec = null
	if not selected_tank_id_input.is_empty():
		new_selected = TankManager.find_tank_spec(selected_tank_id_input)
		if new_selected != null and not next_tanks.has(new_selected):
			new_selected = null
	if new_selected == null and not next_tanks.is_empty():
		new_selected = next_tanks.keys()[0] as TankSpec
	if new_selected == null and default_spec != null:
		new_selected = default_spec
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
		if new_selected == null:
			new_selected = default_spec
	tanks = next_tanks
	selected_tank_spec = new_selected


func get_selected_tank_config() -> TankConfig:
	if tanks.has(selected_tank_spec):
		return tanks.get(selected_tank_spec)
	_repair_selected_tank_in_tanks()
	return tanks.get(selected_tank_spec)


func _repair_selected_tank_in_tanks() -> void:
	var spec: TankSpec = selected_tank_spec
	if spec != null and spec.allowed_shells.is_empty():
		push_warning("AccountLoadout: selected tank has no allowed_shells, falling back to default")
		spec = _spec_with_shells()
		_selected_tank_spec = spec
		selected_tank_spec_updated.emit(spec)
	if spec == null:
		spec = _default_tank_spec()
	var cfg: TankConfig = TankConfig.new()
	cfg.tank_spec = spec
	if not spec.allowed_shells.is_empty():
		var first_shell: ShellSpec = spec.allowed_shells[0]
		cfg.unlocked_shell_specs = [first_shell]
		var shell_loadout_by_spec: Dictionary[ShellSpec, int] = {}
		shell_loadout_by_spec[first_shell] = spec.shell_capacity
		cfg.shell_loadout_by_spec = shell_loadout_by_spec
	var next_tanks: Dictionary[TankSpec, TankConfig] = {}
	for k in tanks:
		next_tanks[k] = tanks[k]
	next_tanks[spec] = cfg
	tanks = next_tanks


func unlock_tank(tank_spec: TankSpec) -> bool:
	if tanks.has(tank_spec):
		return false
	if tank_spec.allowed_shells.is_empty():
		push_warning("AccountLoadout: no shells for tank_spec=%s" % tank_spec.tank_id)
		return false
	var first_shell: ShellSpec = tank_spec.allowed_shells[0]
	var cfg: TankConfig = TankConfig.new()
	cfg.tank_spec = tank_spec
	cfg.unlocked_shell_specs = [first_shell]
	var shell_loadout_by_spec: Dictionary[ShellSpec, int] = {}
	shell_loadout_by_spec[first_shell] = tank_spec.shell_capacity
	cfg.shell_loadout_by_spec = shell_loadout_by_spec
	var next_tanks: Dictionary[TankSpec, TankConfig] = {}
	for k in tanks:
		next_tanks[k] = tanks[k]
	next_tanks[tank_spec] = cfg
	tanks = next_tanks
	if next_tanks.size() == 1:
		selected_tank_spec = tank_spec
	return true
