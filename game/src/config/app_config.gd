extends Node

const STAGE_DEV: String = "dev"
const STAGE_PROD: String = "prod"
const DEV_USER_SERVICE_BASE_URL: String = "http://localhost:8080"
const PROD_USER_SERVICE_BASE_URL: String = "https://api.ironfront.live"
const DEFAULT_PGS_SERVER_CLIENT_ID: String = (
	"556532261549-5sfh8fmkgs232240dviunjr3e4kqeh8a" + ".apps.googleusercontent.com"
)

var stage: String = STAGE_DEV
var user_service_base_url: String = DEV_USER_SERVICE_BASE_URL
var pgs_server_client_id: String = ""
var ticket_verification_public_key: CryptoKey


func _enter_tree() -> void:
	var raw_stage: String = str(Env.get_env("stage", STAGE_DEV)).strip_edges().to_lower()
	stage = STAGE_PROD if raw_stage == STAGE_PROD else STAGE_DEV
	if raw_stage != STAGE_DEV and raw_stage != STAGE_PROD:
		print("[app-config] invalid stage '%s', defaulting to %s" % [raw_stage, STAGE_DEV])

	var override_url: String = str(Env.get_env("user-service-url", "")).strip_edges()
	var default_url: String = PROD_USER_SERVICE_BASE_URL if is_prod() else DEV_USER_SERVICE_BASE_URL
	user_service_base_url = override_url.rstrip("/") if not override_url.is_empty() else default_url

	var override_client_id: String = str(Env.get_env("pgs-server-client-id", "")).strip_edges()
	pgs_server_client_id = (
		override_client_id if not override_client_id.is_empty() else DEFAULT_PGS_SERVER_CLIENT_ID
	)

	ticket_verification_public_key = CryptoKey.new()
	ticket_verification_public_key.load_from_string(
		FileAccess.get_file_as_string("res://src/config/ticket_public.pem"), true
	)


func _ready() -> void:
	print(
		(
			"[app-config] stage=%s user_service_base_url=%s pgs_server_client_id=%s"
			% [stage, user_service_base_url, pgs_server_client_id]
		)
	)


func is_prod() -> bool:
	return stage == STAGE_PROD
