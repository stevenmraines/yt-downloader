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
@onready var exit_confirmation_dialog := $ExitConfirmationDialog
@onready var settings := $Settings
@onready var channel_scene := load("res://scenes/channel.tscn")
@onready var process_scene := load("res://scenes/process.tscn")
@onready var process_queue_background_style := load("res://styles/process_queue_background.tres")
@onready var process_queue_background_paused_style := load("res://styles/process_queue_background_paused.tres")
@onready var parent_process_container_style := load("res://styles/parent_process_container.tres")

var yt_dlp_path := "":
	set(value):
		yt_dlp_path = value
		yt_dlp_wrapper.yt_dlp_path = yt_dlp_path
		console_signal_bus.add_line("yt-dlp path set to " + yt_dlp_path)

var selected_server : Dictionary:
	set(value):
		selected_server = value
		process_queue.selected_server = selected_server
		console_signal_bus.add_line("Server credentials set to %s@%s" % [selected_server.user, selected_server.ip])
		console_signal_bus.add_line("SSH Key Path set to %s" % selected_server.ssh_key_path)


func _ready() -> void:
	_initialize()


func _initialize() -> void:
	for config_path in config_loader.get_paths():
		if config_path.name == "yt-dlp":
			yt_dlp_path = config_path.path
	
	_populate_channels()
	_create_archive_files()
	_populate_servers()
	_setup_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		get_viewport().set_input_as_handled()
		exit_confirmation_dialog.visible = true
	elif event.is_action_pressed("Settings"):
		get_viewport().set_input_as_handled()
		settings.visible = true
	elif event.is_action_released("Toggle Pause"):
		get_viewport().set_input_as_handled()
		_toggle_pause_process_queue()


func _populate_channels() -> void:
	for child in channel_container.get_children():
		channel_container.remove_child(child)
		child.queue_free()
	
	var channels = config_loader.get_channels()
	
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
	var default_server_found = false
	servers_input.clear()
	
	for i in servers.size():
		var server = servers[i]
		servers_input.add_item(server.name)
		
		if server.is_default:
			servers_input.select(i)
			selected_server = server
			default_server_found = true
			console_signal_bus.add_line("Default server %s selected" % selected_server.name)
	
	if ! default_server_found:
		console_signal_bus.add_warning("No default server found")
	elif selected_server.ip == "" or selected_server.user == "":
		console_signal_bus.add_warning("Missing server ip or user name")


func _setup_settings() -> void:
	settings.config_loader = config_loader
	# Use duplicate so we don't pass by ref, otherwise any unsaved changes to
	# settings will be persisted here even when undo changes is clicked.
	settings.paths = config_loader.get_paths().duplicate(true)
	settings.servers = config_loader.get_servers().duplicate(true)
	settings.channels = config_loader.get_channels().duplicate(true)
	settings.playlists = config_loader.get_playlists().duplicate(true)


func _toggle_pause_process_queue() -> void:
	var paused = process_queue.process_mode == Node.PROCESS_MODE_DISABLED
	_pause_process_queue(! paused)


func _pause_process_queue(pause := true) -> void:
	if pause:
		process_queue.process_mode = Node.PROCESS_MODE_DISABLED
		console_signal_bus.add_line("Process queue paused")
		process_queue_background_panel.add_theme_stylebox_override("panel", process_queue_background_paused_style)
		pause_status_label.visible = true
	else:
		process_queue.process_mode = Node.PROCESS_MODE_INHERIT
		console_signal_bus.add_line("Process queue resumed")
		process_queue_background_panel.add_theme_stylebox_override("panel", process_queue_background_style)
		pause_status_label.visible = false


func _on_playlist_marked_as_archived(playlist : Dictionary) -> void:
	process_queue.queue_mark_playlist_as_archived(playlist)


func _on_playlist_unarchived_videos_downloaded(playlist : Dictionary, start_index : String, end_index : String) -> void:
	# TODO Also add custom filename formatting string option
	# TODO Add download range option
	process_queue.queue_download_playlist(playlist, start_index, end_index)


func _on_playlist_single_video_downloaded(url : String, playlist : Dictionary, copy_to_backup : bool, copy_to_remote : bool, delete_download : bool) -> void:
	process_queue.queue_download_single_video(url, playlist, copy_to_backup, copy_to_remote, delete_download)


func _on_channel_folding_changed(is_folded : bool, container : FoldableContainer):
	if is_folded:
		container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	else:
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL


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
	_pause_process_queue()


func _on_play_button_button_up():
	_pause_process_queue(false)


func _on_file_menu_index_pressed(index: int) -> void:
	if index == 0:
		OS.shell_open(OS.get_user_data_dir())
	elif index == 1:
		settings.visible = true


func _on_yt_dlp_menu_index_pressed(_index: int) -> void:
	# Again, there's only one yt-dlp menu item
	process_queue.queue_update()


func _on_settings_close_requested() -> void:
	settings.visible = false


func _on_settings_settings_saved(new_settings: Dictionary) -> void:
	console_signal_bus.add_line("Saving changes to settings")
	config_loader.save_changes(new_settings)
	_initialize()


func _on_settings_settings_reset() -> void:
	console_signal_bus.add_line("Undoing changes to settings")
	_setup_settings()


func _on_servers_input_item_selected(index):
	for server in config_loader.get_servers():
		if server.name == servers_input.get_item_text(index):
			selected_server = server
			break


func _on_confirmation_dialog_confirmed() -> void:
	get_tree().quit(0)
