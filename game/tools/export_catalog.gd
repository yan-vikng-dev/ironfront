extends Node

const TankManager = preload("res://src/entities/tank/tank_manager.gd")
const ShellManager = preload("res://src/entities/shell/shell_manager.gd")


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var output_dir: String = args[0] if args.size() > 0 else "dist/catalog"
	var output_path: String = output_dir.path_join("catalog.json")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var catalog: Dictionary = _build_catalog()
	var json_str: String = JSON.stringify(catalog)
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("[export_catalog] failed to open %s for write" % output_path)
		get_tree().quit(1)
		return
	file.store_string(json_str)
	file.close()
	print("[export_catalog] wrote %s" % output_path)
	get_tree().quit(0)


func _build_catalog() -> Dictionary:
	var tanks: Dictionary = {}
	var shells: Dictionary = {}
	for tank_id: String in TankManager.get_tank_ids():
		ShellManager.get_shell_ids_for_tank(tank_id)
	for tank_id: String in TankManager.get_tank_ids():
		var tank_spec: TankSpec = TankManager.require_tank_spec(tank_id)
		var allowed_shell_ids: Array[String] = ShellManager.get_shell_ids_for_tank(tank_id)
		var shell_ids_json: Array = []
		for sid: String in allowed_shell_ids:
			shell_ids_json.append(sid)
		tanks[tank_id] = {
			"dollar_cost": tank_spec.dollar_cost,
			"allowed_shell_ids": shell_ids_json,
		}
		for shell_id: String in shell_ids_json:
			var shell_spec: ShellSpec = ShellManager.require_shell_spec(shell_id)
			shells[shell_id] = {"unlock_cost": shell_spec.unlock_cost}
	return {"tanks": tanks, "shells": shells}
