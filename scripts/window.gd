extends PanelContainer

@onready var servers_input := %ServersInput
@onready var channel_container := %ChannelContainer
@onready var process_container := %ProcessContainer
@onready var process_queue_background_panel := %ProcessQueueBackgroundPanel
@onready var pause_status_label := %PauseStatusLabel
@onready var console_text_input := %ConsoleTextInput
@onready var console_signal_bus := $ConsoleSignalBus
@onready var config_loader := $ConfigLoader
@onready var yt_dlp_wrapper := $YtDlpWrapper
@onready var process_queue := $ProcessQueue
@onready var settings := $Settings
@onready var channel_scene := load("res://scenes/channel.tscn")
@onready var process_scene := load("res://scenes/process.tscn")
@onready var process_queue_background_style := load("res://styles/process_queue_background.tres")
@onready var process_queue_background_paused_style := load("res://styles/process_queue_background_paused.tres")
@onready var parent_process_container_style := load("res://styles/parent_process_container.tres")

var yt_dlp_path := "":
	set(value):
		yt_dlp_path = value
		settings.yt_dlp_path = yt_dlp_path
		yt_dlp_wrapper.yt_dlp_path = yt_dlp_path
		console_signal_bus.add_line("yt-dlp path set to " + yt_dlp_path)

var selected_server : Dictionary:
	set(value):
		selected_server = value
		_set_server_vars()


func _ready() -> void:
	for config_path in config_loader.get_paths():
		if config_path.name == "yt-dlp":
			yt_dlp_path = config_path.path
	
	_populate_channels()
	_create_archive_files()
	_populate_servers()
	
	settings.playlists = config_loader.get_playlists()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		# TODO Add a confirm dialog before exiting
		get_viewport().set_input_as_handled()
		get_tree().quit(0)


func _populate_channels() -> void:
	var channels = config_loader.get_channels()
	settings.channels = channels
	
	for channel in channels:
		var channel_node = channel_scene.instantiate()
		channel_container.add_child(channel_node)
		channel_node.yt_dlp_wrapper = yt_dlp_wrapper
		channel_node.channel_name = channel.name
		channel_node.playlists = config_loader.get_playlists()
		channel_node.playlist_marked_as_archived.connect(_on_playlist_marked_as_archived)
		channel_node.playlist_unarchived_videos_downloaded.connect(_on_playlist_unarchived_videos_downloaded)
		channel_node.playlist_single_video_downloaded.connect(_on_playlist_single_video_downloaded)
		channel_node.connect("folding_changed", _on_channel_folding_changed.bind(channel_node))
		if channel.start_collapsed:
			channel_node.fold()


func _create_archive_files() -> void:
	for playlist in config_loader.get_playlists():
		var archive_dir = OS.get_user_data_dir() + "/archived"
		var channel_archive_dir = archive_dir + "/" + playlist.channel
		
		if ! DirAccess.dir_exists_absolute(archive_dir):
			console_signal_bus.add_line("Creating archive directory " + archive_dir)
			DirAccess.make_dir_absolute(archive_dir)
		
		if ! DirAccess.dir_exists_absolute(channel_archive_dir):
			console_signal_bus.add_line("Creating channel archive directory " + channel_archive_dir)
			DirAccess.make_dir_absolute(channel_archive_dir)
		
		var archive_file_path = channel_archive_dir + "/" + playlist.download_archive_file_name
		
		if ! FileAccess.file_exists(archive_file_path):
			console_signal_bus.add_line("Creating archive file " + archive_file_path)
			var archive_file = FileAccess.open(archive_file_path, FileAccess.WRITE)
			archive_file.close()


func _populate_servers() -> void:
	var servers = config_loader.get_servers()
	settings.servers = servers
	var default_server_found = false
	
	for i in servers.size():
		var server = servers[i]
		servers_input.add_item(server.name)
		
		if server.default:
			servers_input.select(i)
			selected_server = server
			default_server_found = true
			console_signal_bus.add_line("Default server %s selected" % selected_server.name)
	
	if ! default_server_found:
		console_signal_bus.add_warning("No default server found")


func _set_server_vars() -> void:
	var server_credentials = config_loader.get_credentials()
	settings.credentials = server_credentials
	var selected_server_credentials = {}
			
	for credentials in server_credentials:
		if credentials.server == selected_server.name:
			selected_server_credentials = credentials
	
	if ! selected_server_credentials:
		console_signal_bus.add_error("No credentials found for default server")
		return
	
	process_queue.remote_ip = selected_server.ip
	process_queue.remote_user = selected_server_credentials.user
	process_queue.ssh_key_path = selected_server_credentials.ssh_key_path


func _on_update_yt_dlp_button_button_up():
	process_queue.queue_update()


func _on_playlist_marked_as_archived(playlist : Dictionary) -> void:
	process_queue.queue_mark_playlist_as_archived(playlist)


func _on_playlist_unarchived_videos_downloaded(playlist : Dictionary) -> void:
	process_queue.queue_download_playlist(playlist)


func _on_playlist_single_video_downloaded(url : String, playlist : Dictionary, delete_download : bool) -> void:
	process_queue.queue_download_single_video(url, playlist, delete_download)


func _on_yt_dlp_path_file_dialog_file_selected(path: String) -> void:
	yt_dlp_path = path


func _on_channel_folding_changed(is_folded : bool, container : FoldableContainer):
	if is_folded:
		container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	else:
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _on_save_config_confirmation_dialog_confirmed():
	# There aren't really going to be any changes to look out for in channels rn
	# TODO Update servers/creds
	var changes = {
		"paths": [],
		"channels": [],
		"playlists": [],
	}
	
	for config_path in config_loader.get_paths():
		if config_path.name == "yt-dlp" and config_path.path != yt_dlp_path:
			config_path.path = yt_dlp_path
			changes["paths"].append(config_path)
	
	for config_playlist in config_loader.get_playlists():
		# Need to find the node matching this playlist
		for channel_node in channel_container.get_children():
			if channel_node.channel_name != config_playlist.channel:
				continue
			
			for playlist_node in channel_node.get_playlist_nodes():
				if playlist_node.playlist_name != config_playlist.name:
					continue
				
				# Everything matches, now overwrite the vars if anything has changed
				if config_playlist.url != playlist_node.url \
						or config_playlist.download_path != playlist_node.download_path \
						or config_playlist.backup_upload_path != playlist_node.backup_upload_path \
						or config_playlist.remote_upload_path != playlist_node.remote_upload_path \
						or config_playlist.download_archive_file_name != playlist_node.download_archive_file_name \
						or config_playlist.cookies_from_browser != playlist_node.cookies_from_browser \
						or config_playlist.delete_download != playlist_node.delete_download:
					config_playlist.url = playlist_node.url
					config_playlist.download_path = playlist_node.download_path
					config_playlist.backup_upload_path = playlist_node.backup_upload_path
					config_playlist.remote_upload_path = playlist_node.remote_upload_path
					config_playlist.download_archive_file_name = playlist_node.download_archive_file_name
					config_playlist.cookies_from_browser = playlist_node.cookies_from_browser
					config_playlist.delete_download = playlist_node.delete_download
					changes["playlists"].append(config_playlist)
	
	config_loader.save_changes(changes)


func _on_process_queue_queue_changed(processes):
	for process_node in process_container.get_children():
		process_node.queue_free()
	
	var parent_process : Process
	var vbox : VBoxContainer
	
	for process in processes:
		var new_process_node = process_scene.instantiate()
		var container = process_container
		
		# If this is a parent
		if process.child_processes.size() > 0:
			parent_process = process
			var parent_container = PanelContainer.new()
			parent_container.add_theme_stylebox_override("panel", parent_process_container_style)
			vbox = VBoxContainer.new()
			parent_container.add_child(vbox)
			process_container.add_child(parent_container)
			container = vbox
		# If this is a child
		elif parent_process and process.parent_process == parent_process:
			container = vbox
		
		container.add_child(new_process_node)
		new_process_node.process = process
		new_process_node.connect("process_killed", _on_process_killed)


func _on_process_killed(process : Process) -> void:
	process_queue.kill_process(process)


func _on_pause_button_button_up():
	process_queue.process_mode = Node.PROCESS_MODE_DISABLED
	console_signal_bus.add_line("Process queue paused")
	process_queue_background_panel.add_theme_stylebox_override("panel", process_queue_background_paused_style)
	pause_status_label.visible = true


func _on_play_button_button_up():
	process_queue.process_mode = Node.PROCESS_MODE_INHERIT
	console_signal_bus.add_line("Process queue resumed")
	process_queue_background_panel.add_theme_stylebox_override("panel", process_queue_background_style)
	pause_status_label.visible = false


func _on_settings_close_requested() -> void:
	settings.visible = false
