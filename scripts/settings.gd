extends Window

signal settings_saved(settings : Dictionary)
signal settings_reset

@onready var path_settings_container := %PathSettingsContainer
@onready var server_settings_container := %ServerSettingsContainer
@onready var channel_settings_container := %ChannelSettingsContainer
@onready var save_changes_confirmation_dialog := %SaveChangesConfirmationDialog
@onready var undo_changes_confirmation_dialog := %UndoChangesConfirmationDialog
@onready var path_settings_scene := load("res://scenes/path_settings.tscn")
@onready var server_settings_scene := load("res://scenes/server_settings.tscn")
@onready var channel_settings_scene := load("res://scenes/channel_settings.tscn")

var config_loader : ConfigLoader

var paths : Array[Dictionary]:
	set(value):
		paths = value
		
		for child in path_settings_container.get_children():
			path_settings_container.remove_child(child)
			child.queue_free()
		
		for path in paths:
			var path_node = path_settings_scene.instantiate()
			path_settings_container.add_child(path_node)
			path_node.path = path

var servers : Array[Dictionary]:
	set(value):
		servers = value
		
		for child in server_settings_container.get_children():
			server_settings_container.remove_child(child)
			child.queue_free()
		
		for server in servers:
			var server_node = server_settings_scene.instantiate()
			server_settings_container.add_child(server_node)
			server_node.server = server
			server_node.server_deleted.connect(_on_server_deleted)

var channels : Array[Dictionary]:
	set(value):
		channels = value
		
		for child in channel_settings_container.get_children():
			# queue_free won't happen immediately, and when a channel
			# is deleted the playlists setter will get an error about
			# an unknown key for the deleted channel when it loops over
			# channel_settings_container.get_children.
			# So we need to remove it first, then free it.
			channel_settings_container.remove_child(child)
			child.queue_free()
		
		for channel in channels:
			var channel_node = channel_settings_scene.instantiate()
			channel_settings_container.add_child(channel_node)
			channel_node.channel = channel
			channel_node.channel_deleted.connect(_on_channel_deleted)
			channel_node.playlist_added.connect(_on_playlist_added)
			channel_node.playlist_deleted.connect(_on_playlist_deleted)

var playlists : Array[Dictionary]:
	set(value):
		playlists = value
		
		for child in channel_settings_container.get_children():
			for child2 in child.playlists_container.get_children():
				child.playlists_container.remove_child(child2)
				child2.queue_free()
		
		var channel_playlists := {}
		
		for channel in channels:
			var x : Array[Dictionary]
			channel_playlists[channel.name] = x
		
		for playlist in playlists:
			channel_playlists[playlist.channel].append(playlist)
		
		for child in channel_settings_container.get_children():
			child.playlists = channel_playlists[child.channel.name]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Escape"):
		get_viewport().set_input_as_handled()
		# TODO Add confirm dialog
		visible = false
	elif event.is_action_pressed("Save Settings"):
		get_viewport().set_input_as_handled()
		_on_save_config_button_button_up()


func _get_all_data() -> Dictionary:
	var data = {
		"paths": [],
		"servers": [],
		"channels": [],
		"playlists": [],
	}
	
	for child in path_settings_container.get_children():
		data["paths"].append(child.path)
	
	for child in server_settings_container.get_children():
		data["servers"].append(child.server)
	
	for child in channel_settings_container.get_children():
		data["channels"].append(child.channel)
		for child2 in child.playlists_container.get_children():
			data["playlists"].append(child2.playlist)
	
	return data


func _on_save_config_confirmation_dialog_confirmed() -> void:
	settings_saved.emit(_get_all_data())


func _on_save_config_button_button_up() -> void:
	save_changes_confirmation_dialog.visible = true


func _on_undo_changes_button_button_up() -> void:
	undo_changes_confirmation_dialog.visible = true


func _on_undo_changes_confirmation_dialog_confirmed() -> void:
	settings_reset.emit()


func _on_new_server_button_button_up() -> void:
	var new_servers = servers
	new_servers.append(config_loader.get_empty_server())
	servers = new_servers


func _on_server_deleted(server : Dictionary) -> void:
	var new_servers : Array[Dictionary]
	
	for existing_server in servers:
		if existing_server.id != server.id:
			new_servers.append(existing_server)
	
	servers = new_servers


func _on_new_channel_button_button_up() -> void:
	var new_channels = channels
	new_channels.append(config_loader.get_empty_channel())
	channels = new_channels
	playlists = playlists


func _on_channel_deleted(channel : Dictionary) -> void:
	var new_channels : Array[Dictionary]
	
	for existing_channel in channels:
		if existing_channel.id != channel.id:
			new_channels.append(existing_channel)
	
	channels = new_channels
	
	var new_playlists : Array[Dictionary]

	for existing_playlist in playlists:
		if existing_playlist.channel != channel.name:
			new_playlists.append(existing_playlist)
	
	playlists = new_playlists


func _on_playlist_added(channel : Dictionary) -> void:
	var new_playlists = playlists
	var empty_playlist = config_loader.get_empty_playlist()
	empty_playlist.channel = channel.name
	new_playlists.append(empty_playlist)
	playlists = new_playlists


func _on_playlist_deleted(playlist : Dictionary) -> void:
	var new_playlists : Array[Dictionary]
	
	for existing_playlist in playlists:
		if existing_playlist.id != playlist.id:
			new_playlists.append(existing_playlist)
	
	playlists = new_playlists
