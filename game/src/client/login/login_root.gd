class_name LoginRoot
extends Control

signal login_completed
signal login_failed(reason: String)

const BOOTSTRAP_PANEL_SCENE: PackedScene = preload(
	"res://src/client/login/ui/bootstrap_login_panel.tscn"
)

var _panel: BootstrapLoginPanel
var _awaiting_sign_in_result: bool = false


func _ready() -> void:
	_panel = BOOTSTRAP_PANEL_SCENE.instantiate()
	add_child(_panel)
	Utils.connect_checked(_panel.sign_in_pressed, _on_panel_sign_in_pressed)
	Utils.connect_checked(_panel.quit_pressed, _on_panel_quit_pressed)
	Utils.connect_checked(_panel.username_submitted, _on_panel_username_submitted)
	_attempt_sign_in()


func _on_panel_sign_in_pressed() -> void:
	_attempt_sign_in()


func _on_panel_quit_pressed() -> void:
	UiBus.quit_pressed.emit()


func _on_panel_username_submitted(username: String) -> void:
	var update_result: UserServiceClient.ApiResult = await (
		AuthManager.user_service_client.update_username(username)
	)
	if not is_inside_tree():
		return
	if update_result.success:
		_panel.hide_username_prompt()
		login_completed.emit()
		return
	_panel.set_username_idle()
	_panel.show_username_error(update_result.reason)


func _attempt_sign_in() -> void:
	if _awaiting_sign_in_result:
		return
	_panel.hide_username_prompt()
	_panel.set_signing_in()
	_awaiting_sign_in_result = true
	AuthManager.sign_in_attempt_completed.connect(_on_sign_in_attempt_completed, CONNECT_ONE_SHOT)
	var started: bool = AuthManager.retry_sign_in()
	if not started:
		_awaiting_sign_in_result = false
		_panel.set_idle("RETRY AUTH")
		return


func _on_sign_in_attempt_completed(
	success: bool, reason: String, username_setup_required: bool
) -> void:
	_awaiting_sign_in_result = false
	if not is_inside_tree():
		return
	if not success:
		_panel.hide_username_prompt()
		_panel.set_idle("RETRY AUTH")
		login_failed.emit(reason)
		return
	if username_setup_required:
		_panel.set_idle("RETRY AUTH")
		_panel.show_username_prompt(Account.username)
		return
	_panel.hide_username_prompt()
	login_completed.emit()
