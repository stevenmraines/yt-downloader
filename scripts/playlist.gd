extends MarginContainer

signal mark_as_archived_clicked(list : Dictionary)
signal download_unarchived_videos_button_clicked(list : Dictionary)
signal download_single_video_button_clicked(url : String, list : Dictionary, delete_download : bool)

@export var folded_minimum_height := 50.0
@export var unfolded_minimum_height := 450.0

@onready var label := %Label
@onready var settings_container := %SettingsContainer
@onready var url_input := %UrlInput
# TODO These should all have browse buttons
@onready var download_path_input := %DownloadPathInput
@onready var backup_upload_path_input := %BackupPathInput
@onready var remote_upload_path_input := %RemotePathInput
@onready var download_archive_file_name_input := %DownloadArchiveFileNameInput
@onready var cookies_from_browser_input := %CookiesFromBrowserInput
@onready var delete_download_input := %DeleteDownloadInput
@onready var preview_unarchived_on_startup_input := %PreviewUnarchivedOnStartupInput
@onready var preview_parent_container := %PreviewParentContainer
@onready var preview_container := %PreviewContainer
@onready var archive_confirmation_dialog := $ArchiveConfirmationDialog
@onready var download_unarchived_videos_button := %DownloadUnarchivedVideosButton
@onready var download_unarchived_videos_confirmation_dialog := %DownloadUnarchivedVideosConfirmationDialog
@onready var download_single_video_window := %DownloadSingleVideoWindow
@onready var single_video_url_input := %SingleVideoUrlInput
@onready var delete_single_download_input := %DeleteSingleDownloadInput
@onready var download_path_dialog := $DownloadPathDialog
@onready var backup_upload_path_dialog := $BackupUploadPathDialog
@onready var remote_upload_path_dialog := $RemoteUploadPathDialog
@onready var preview_scene := load("res://scenes/preview.tscn")

var playlist : Dictionary:
	set(value):
		playlist = value
		
		# Set all the playlist vars
		playlist_name = playlist.name
		channel = playlist.channel
		url = playlist.url
		download_path = playlist.download_path
		backup_upload_path = playlist.backup_upload_path
		remote_upload_path = playlist.remote_upload_path
		download_archive_file_name = playlist.download_archive_file_name
		cookies_from_browser = playlist.cookies_from_browser
		delete_download = playlist.delete_download
		preview_unarchived_on_startup = playlist.preview_unarchived_on_startup
		
		# Set labels and inputs
		label.text = playlist_name
		url_input.text = url
		download_path_input.text = download_path
		backup_upload_path_input.text = backup_upload_path
		remote_upload_path_input.text = remote_upload_path
		download_archive_file_name_input.text = download_archive_file_name
		cookies_from_browser_input.text = cookies_from_browser
		delete_download_input.button_pressed = delete_download
		preview_unarchived_on_startup_input.button_pressed = preview_unarchived_on_startup
		preview_parent_container.visible = preview_unarchived_on_startup
		
		# Need to connect this here rather than in _ready because
		# playlist won't be set yet when _ready is fired.
		download_unarchived_videos_button.connect("button_up", _on_download_unarchived_videos_button_button_up.bind(playlist))

var channel := ""
var playlist_name := ""
var url := ""
var download_path := ""
var backup_upload_path := ""
var remote_upload_path := ""
var download_archive_file_name := ""
var cookies_from_browser := ""
var delete_download := false
var preview_unarchived_on_startup := false

var downloaded_videos := []
var queued_videos := [
	{
		"name": "The Comment 'Shop - Episode 102",
		"url": "https://www.youtube.com/watch?v=Ih3JDtDJAfE&t=4480s&pp=0gcJCQ0LAYcqIYzv"
	},
	{
		"name": "The Comment 'Shop - Episode 103",
		"url": "https://www.youtube.com/watch?v=Ih3JDtDJAfE&t=4480s&pp=0gcJCQ0LAYcqIYzv"
	}
]

var console_signal_bus : ConsoleSignalBus
var yt_dlp_wrapper : YtDlpWrapper


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]
	settings_container.fold()


func populate_preview_queue() -> void:
	if ! preview_unarchived_on_startup:
		return
	
	var preview_details = yt_dlp_wrapper.get_unarchived_video_details(playlist)
	for title in preview_details:
		var preview_node = preview_scene.instantiate()
		preview_container.add_child(preview_node)
		preview_node.title = title


func _on_mark_as_archived_button_button_up():
	archive_confirmation_dialog.dialog_text = "Are you sure you want to mark the " \
		+ playlist.name + " playlist as archived? This will overwrite the archive file."
	archive_confirmation_dialog.visible = true


func _on_download_single_video_button_pressed():
	single_video_url_input.text = ""
	download_single_video_window.title = "Download video using " + playlist.name + " options"
	download_single_video_window.visible = true


func _on_download_single_video_window_close_requested():
	download_single_video_window.visible = false
	single_video_url_input.text = ""


func _on_archive_confirmation_dialog_confirmed():
	mark_as_archived_clicked.emit(playlist)


func _on_download_single_video_confirm_button_button_up():
	if ! single_video_url_input.text:
		console_signal_bus.add_error("No video URL provided")
		return
	download_single_video_button_clicked.emit(single_video_url_input.text, playlist, delete_single_download_input.button_pressed)
	download_single_video_window.visible = false


func _on_url_input_text_changed(new_text):
	playlist.url = new_text
	url = new_text


func _on_download_path_input_text_changed(new_text):
	playlist.download_path = new_text
	download_path = new_text


func _on_backup_path_input_text_changed(new_text):
	playlist.backup_upload_path = new_text
	backup_upload_path = new_text


func _on_remote_path_input_text_changed(new_text):
	playlist.remote_upload_path = new_text
	remote_upload_path = new_text


func _on_download_archive_file_path_input_text_changed(new_text):
	playlist.download_archive_file_name = new_text
	download_archive_file_name = new_text


func _on_cookies_from_browser_input_item_selected(index):
	var value = cookies_from_browser_input.get_item_text(index)
	playlist.cookies_from_browser = value
	cookies_from_browser = value


func _on_delete_download_input_toggled(toggled_on: bool) -> void:
	playlist.delete_download = toggled_on
	delete_download = toggled_on


func _on_preview_unarchived_on_startup_input_toggled(toggled_on):
	playlist.preview_unarchived_on_startup = toggled_on
	preview_unarchived_on_startup = toggled_on


func _on_download_unarchived_videos_button_button_up(list : Dictionary):
	# FIXME Changing our text after the fact like this is messing with the window positioning
	download_unarchived_videos_confirmation_dialog.dialog_text = "Are you sure you want to download unarchived videos from the " + list.name + " playlist?"
	download_unarchived_videos_confirmation_dialog.visible = true


func _on_download_unarchived_videos_confirmation_dialog_confirmed():
	download_unarchived_videos_button_clicked.emit(playlist)


func _on_foldable_container_folding_changed(is_folded: bool) -> void:
	custom_minimum_size = Vector2(0, folded_minimum_height) if is_folded \
		else Vector2(0, unfolded_minimum_height)


func _on_download_path_button_button_up():
	download_path_dialog.visible = true


func _on_backup_upload_path_button_button_up():
	backup_upload_path_dialog.visible = true


func _on_remote_upload_path_button_button_up():
	remote_upload_path_dialog.visible = true


func _on_download_path_dialog_dir_selected(dir):
	download_path = dir
	download_path_input.text = dir
	playlist.download_path = dir


func _on_backup_upload_path_dialog_dir_selected(dir):
	backup_upload_path = dir
	backup_upload_path_input.text = dir
	playlist.backup_upload_path = dir


func _on_remote_upload_path_dialog_dir_selected(dir):
	remote_upload_path = dir
	remote_upload_path_input.text = dir
	playlist.remote_upload_path = dir
