class_name ClientSessionApi
extends Node

signal server_hello_ack_received(server_protocol_version: int, server_unix_time: int)
signal join_arena_ack_received(
	success: bool, message: String, spawn_position: Vector2, spawn_rotation: float
)
signal leave_arena_ack_received(success: bool, message: String)


func send_client_hello(protocol_version: int) -> void:
	_receive_client_hello.rpc_id(1, protocol_version)


func send_join_arena(ticket: String) -> void:
	_join_arena.rpc_id(1, ticket)


func send_leave_arena() -> void:
	_leave_arena.rpc_id(1)


@rpc("authority", "reliable")
func _receive_server_hello_ack(server_protocol_version: int, server_unix_time: int) -> void:
	server_hello_ack_received.emit(server_protocol_version, server_unix_time)


@rpc("any_peer", "reliable")
func _receive_client_hello(_client_protocol_version: int) -> void:
	push_warning("[client][session] unexpected RPC: _receive_client_hello")


@rpc("any_peer", "reliable")
func _join_arena(_ticket: String) -> void:
	push_warning("[client][session] unexpected RPC: _join_arena")


@rpc("any_peer", "reliable")
func _leave_arena() -> void:
	push_warning("[client][session] unexpected RPC: _leave_arena")


@rpc("authority", "reliable")
func _join_arena_ack(
	success: bool, message: String, spawn_position: Vector2, spawn_rotation: float
) -> void:
	join_arena_ack_received.emit(success, message, spawn_position, spawn_rotation)


@rpc("authority", "reliable")
func _leave_arena_ack(success: bool, message: String) -> void:
	leave_arena_ack_received.emit(success, message)
