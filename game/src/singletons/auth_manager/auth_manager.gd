extends Node

signal sign_in_attempt_completed(success: bool, reason: String, username_setup_required: bool)

const DEV_PROVIDER_SCENE: PackedScene = preload(
	"res://src/singletons/auth_manager/providers/dev_auth_provider.tscn"
)
const PGS_PROVIDER_SCENE: PackedScene = preload(
	"res://src/singletons/auth_manager/providers/pgs_auth_provider.tscn"
)

var active_provider: AuthProvider
var user_service_client: UserServiceClient
var session_token: String = ""
var expires_at_unix: int = 0


func _ready() -> void:
	if user_service_client != null:
		return
	user_service_client = UserServiceClient.new(AppConfig.user_service_base_url)
	add_child(user_service_client)
	active_provider = _instantiate_provider()
	Utils.connect_checked(active_provider.sign_in_succeeded, _on_provider_sign_in_succeeded)
	Utils.connect_checked(active_provider.sign_in_failed, _on_provider_sign_in_failed)


func retry_sign_in() -> bool:
	if active_provider == null:
		return false
	if not session_token.is_empty() or active_provider.has_sign_in_operation():
		_log_auth("sign-in ignored (already signed in or in progress)")
		return false
	_log_auth("sign-in started")
	active_provider.sign_in()
	return true


func sign_out() -> void:
	if active_provider == null:
		return
	_log_auth("sign-out requested")
	_clear_session()
	Account.clear()
	active_provider.sign_out()


func is_signed_in() -> bool:
	if session_token.is_empty():
		return false
	return expires_at_unix > int(Time.get_unix_time_from_system())


func _on_provider_sign_in_succeeded(provider: String, proof: String) -> void:
	_log_auth("provider sign-in succeeded provider=%s" % provider)
	var exchange_result: UserServiceClient.ApiResult = await user_service_client.exchange_auth(
		provider, proof
	)
	if not is_inside_tree():
		return
	if not exchange_result.success:
		_clear_session()
		_log_auth("user-service exchange failed reason=%s" % exchange_result.reason)
		sign_in_attempt_completed.emit(false, exchange_result.reason, false)
		return
	var exchange_body: UserServiceExchangeResponseBody = exchange_result.body
	if exchange_body == null:
		_clear_session()
		_log_auth("user-service exchange failed invalid response shape")
		sign_in_attempt_completed.emit(false, "USER_SERVICE_INVALID_RESPONSE", false)
		return

	session_token = exchange_body.session_token
	expires_at_unix = exchange_body.expires_at_unix
	_log_auth(
		"sign-in completed account_id=%s username=%s" % [Account.account_id, Account.username]
	)
	var username_setup_required: bool = Account.username_updated_at <= 0
	sign_in_attempt_completed.emit(true, "", username_setup_required)


func _on_provider_sign_in_failed(reason: String) -> void:
	_clear_session()
	_log_auth("provider sign-in failed reason=%s" % reason)
	sign_in_attempt_completed.emit(false, reason, false)


func _clear_session() -> void:
	session_token = ""
	expires_at_unix = 0


func _instantiate_provider() -> AuthProvider:
	var provider_scene: PackedScene = (
		PGS_PROVIDER_SCENE
		if AppConfig.is_prod() or OS.has_feature("android")
		else DEV_PROVIDER_SCENE
	)
	var provider: AuthProvider = provider_scene.instantiate()
	add_child(provider)
	return provider


func _log_auth(message: String) -> void:
	print("[auth-manager] %s" % message)
