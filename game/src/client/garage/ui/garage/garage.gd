class_name Garage
extends Control

signal play_requested

const LOADOUT_DEBOUNCE_SEC := 0.5

var _loadout_debounce_timer: float = -1.0

@onready var header_panel: HeaderPanel = %HeaderPanel
@onready var tank_list_panel: TankListPanel = %TankListPanel
@onready var tank_display_panel: TankDisplayPanel = %TankDisplayPanel
@onready var upgrade_panel: UpgradePanel = %UpgradePanel


func _ready() -> void:
	Utils.connect_checked(header_panel.play_requested, func() -> void: play_requested.emit())
	Utils.connect_checked(tank_list_panel.unlock_tank_requested, _on_tank_unlock_requested)
	Utils.connect_checked(UiBus.shell_unlock_requested, _on_shell_unlock_requested)
	Utils.connect_checked(
		Account.loadout.selected_tank_spec_updated, _on_selected_tank_spec_updated
	)
	Utils.connect_checked(upgrade_panel.ammo_upgrade_list.loadout_changed, _on_ammo_loadout_changed)


func _process(delta: float) -> void:
	if _loadout_debounce_timer >= 0:
		_loadout_debounce_timer -= delta
		if _loadout_debounce_timer < 0:
			_sync_shell_ammo()


func _on_tank_unlock_requested(tank_spec: TankSpec) -> void:
	assert(tank_spec != null, "Missing tank spec")
	var tank_price: int = CatalogPrices.get_tank_price(tank_spec.tank_id)
	if tank_price == CatalogPrices.PRICE_UNAVAILABLE or Account.economy.dollars < tank_price:
		return
	var first_shell: ShellSpec = (
		tank_spec.allowed_shells[0] if not tank_spec.allowed_shells.is_empty() else null
	)
	if first_shell == null:
		return
	var initial_shell_id: String = ShellManager.get_shell_id(first_shell)
	UiBus.unlock_busy_changed.emit(true)
	var result: Result = await AuthManager.user_service_client.unlock_tank(
		tank_spec.tank_id, initial_shell_id
	)
	UiBus.unlock_busy_changed.emit(false)
	if result.is_err():
		show_online_join_feedback(result.error, true)
		return


func _on_shell_unlock_requested(shell_spec: ShellSpec) -> void:
	var tank_spec: TankSpec = Account.loadout.selected_tank_spec
	if tank_spec == null:
		return
	var shell_id: String = ShellManager.get_shell_id(shell_spec)
	var shell_price: int = CatalogPrices.get_shell_price(shell_id)
	if shell_price == CatalogPrices.PRICE_UNAVAILABLE or Account.economy.dollars < shell_price:
		return
	UiBus.unlock_busy_changed.emit(true)
	var result: Result = await AuthManager.user_service_client.unlock_shell(
		tank_spec.tank_id, shell_id
	)
	UiBus.unlock_busy_changed.emit(false)
	if result.is_err():
		show_online_join_feedback(result.error, true)
		return


func _on_selected_tank_spec_updated(spec: TankSpec) -> void:
	if spec == null:
		return
	var result: Result = await AuthManager.user_service_client.select_tank(spec.tank_id)
	if result.is_err():
		show_online_join_feedback(result.error, true)


func _on_ammo_loadout_changed() -> void:
	_loadout_debounce_timer = LOADOUT_DEBOUNCE_SEC


func _sync_shell_ammo() -> void:
	var tank_spec: TankSpec = Account.loadout.selected_tank_spec
	if tank_spec == null:
		return
	var tank_id: String = tank_spec.tank_id
	var cfg: TankConfig = Account.loadout.tanks.get(tank_spec, null)
	if cfg == null:
		return
	for shell_spec_key: Variant in cfg.shell_loadout_by_spec:
		var shell_spec: ShellSpec = shell_spec_key as ShellSpec
		if shell_spec == null:
			continue
		var shell_id: String = ShellManager.get_shell_id(shell_spec)
		var count: int = int(cfg.shell_loadout_by_spec.get(shell_spec_key, 0))
		var result: Result = await AuthManager.user_service_client.set_shell_ammo(
			tank_id, shell_id, count
		)
		if result.is_err():
			show_online_join_feedback(result.error, true)
			return


func show_online_join_feedback(message: String, is_error: bool) -> void:
	header_panel.display_online_feedback(message, is_error)
