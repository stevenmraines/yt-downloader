extends PanelContainer

@export var yt_dlp_path := "":
	set(value):
		yt_dlp_path = value
		yt_dlp_path_input.text = yt_dlp_path
		yt_dlp_wrapper.yt_dlp_path = yt_dlp_path
		console_signal_bus.add_line("yt-dlp path set to " + yt_dlp_path)
		# TODO Update config if value there is different

@onready var save_config_confirmation_dialog := $MarginContainer/VBoxContainer/SaveConfigConfirmationDialog
@onready var yt_dlp_path_input := $MarginContainer/VBoxContainer/VSplitContainer/MarginContainer/YtDlpConfig/YtDlpPathInput
@onready var yt_dlp_path_file_dialog := $MarginContainer/VBoxContainer/VSplitContainer/MarginContainer/YtDlpConfig/YtDlpPathFileDialog
@onready var channel_container := $MarginContainer/VBoxContainer/VSplitContainer/ChannelContainer
@onready var console_text_input := $MarginContainer/VBoxContainer/VSplitContainer/Console/MarginContainer/ConsoleTextInput
@onready var console_signal_bus := $ConsoleSignalBus
@onready var config_loader := $ConfigLoader
@onready var yt_dlp_wrapper := $YtDlpWrapper
@onready var channel_scene := load("res://scenes/channel.tscn")


func _ready() -> void:
	for config_path in config_loader.get_paths():
		if config_path.name == "yt-dlp":
			yt_dlp_path = config_path.path
	
	_populate_channels()
	_create_archive_files()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		get_viewport().set_input_as_handled()
		get_tree().quit(0)


func _populate_channels() -> void:
	for channel in config_loader.get_channels():
		var channel_node = channel_scene.instantiate()
		channel_container.add_child(channel_node)
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


func _on_update_yt_dlp_button_button_up():
	yt_dlp_wrapper.update()


func _on_playlist_marked_as_archived(playlist : Dictionary) -> void:
	yt_dlp_wrapper.mark_playlist_as_archived(playlist)


func _on_playlist_unarchived_videos_downloaded(playlist : Dictionary) -> void:
	yt_dlp_wrapper.download_playlist(playlist)


func _on_playlist_single_video_downloaded(url : String, playlist : Dictionary) -> void:
	yt_dlp_wrapper.download_single_video(url, playlist)


func _on_yt_dlp_browse_files_button_button_up() -> void:
	yt_dlp_path_file_dialog.visible = true


func _on_yt_dlp_path_file_dialog_file_selected(path: String) -> void:
	yt_dlp_path = path


func _on_channel_folding_changed(is_folded : bool, container : FoldableContainer):
	if is_folded:
		container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	else:
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _on_save_config_button_button_up():
	save_config_confirmation_dialog.visible = true


func _on_save_config_confirmation_dialog_confirmed():
	# There aren't really going to be any changes to look out for in channels rn
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
						or config_playlist.cookies_from_browser != playlist_node.cookies_from_browser:
					config_playlist.url = playlist_node.url
					config_playlist.download_path = playlist_node.download_path
					config_playlist.backup_upload_path = playlist_node.backup_upload_path
					config_playlist.remote_upload_path = playlist_node.remote_upload_path
					config_playlist.download_archive_file_name = playlist_node.download_archive_file_name
					config_playlist.cookies_from_browser = playlist_node.cookies_from_browser
					changes["playlists"].append(config_playlist)
	
	config_loader.save_changes(changes)
