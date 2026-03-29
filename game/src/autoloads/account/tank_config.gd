class_name TankConfig
extends RefCounted

var tank_spec: TankSpec
var unlocked_shell_specs: Array[ShellSpec] = []
var shell_loadout_by_spec: Dictionary[ShellSpec, int] = {}


static func from_server_dict(spec: TankSpec, payload: Dictionary) -> TankConfig:
	var cfg: TankConfig = TankConfig.new()
	cfg.tank_spec = spec
	var unlocked_specs: Array[ShellSpec] = []
	for shell_id_variant: Variant in payload.get("unlocked_shell_ids", []):
		var shell_id: String = str(shell_id_variant).strip_edges()
		if shell_id.is_empty():
			continue
		var shell_spec: ShellSpec = ShellManager.find_shell_spec(shell_id)
		if shell_spec == null or not spec.allowed_shells.has(shell_spec):
			continue
		unlocked_specs.append(shell_spec)
	cfg.unlocked_shell_specs = unlocked_specs
	var shell_loadout: Dictionary[ShellSpec, int] = {}
	var shell_loadout_input: Dictionary = payload.get("shell_loadout_by_id", {})
	for shell_id_variant: Variant in shell_loadout_input.keys():
		var shell_id: String = str(shell_id_variant).strip_edges()
		if shell_id.is_empty():
			continue
		var shell_spec: ShellSpec = ShellManager.find_shell_spec(shell_id)
		if shell_spec == null or not spec.allowed_shells.has(shell_spec):
			continue
		shell_loadout[shell_spec] = int(shell_loadout_input.get(shell_id_variant, 0))
	cfg.shell_loadout_by_spec = shell_loadout
	return cfg
