extends MarginContainer

signal mark_as_archived_clicked(list : Dictionary)
signal download_single_video_button_clicked(url : String, list : Dictionary)

@onready var label := $VBoxContainer/HBoxContainer7/Label
@onready var url_input := $VBoxContainer/HBoxContainer3/MarginContainer/UrlInput
@onready var download_path_input := $VBoxContainer/HBoxContainer4/MarginContainer/DownloadPathInput
@onready var backup_upload_path_input := $VBoxContainer/HBoxContainer/MarginContainer/BackupPathInput
@onready var remote_upload_path_input := $VBoxContainer/HBoxContainer2/MarginContainer/RemotePathInput
@onready var download_archive_file_name_input := $VBoxContainer/HBoxContainer5/MarginContainer/DownloadArchiveFileNameInput
@onready var cookies_from_browser_input := $VBoxContainer/HBoxContainer6/MarginContainer/CookiesFromBrowserInput
@onready var queued_videos_container := $VBoxContainer/ScrollContainer/QueuedVideosContainer
@onready var archive_confirmation_dialog := $ArchiveConfirmationDialog
@onready var download_single_video_window := $DownloadSingleVideoWindow
@onready var single_video_url_input := $DownloadSingleVideoWindow/Control/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/SingleVideoUrlInput
@onready var download_scene := load("res://scenes/download.tscn")

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
		
		# Set labels and inputs
		label.text = playlist_name
		url_input.text = url
		download_path_input.text = download_path
		backup_upload_path_input.text = backup_upload_path
		remote_upload_path_input.text = remote_upload_path
		download_archive_file_name_input.text = download_archive_file_name
		cookies_from_browser_input.text = cookies_from_browser

var channel := ""
var playlist_name := ""
var url := ""
var download_path := ""
var backup_upload_path := ""
var remote_upload_path := ""
var download_archive_file_name := ""
var cookies_from_browser := ""

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


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func populate_download_queue() -> void:
	pass


func _on_mark_as_archived_button_button_up():
	archive_confirmation_dialog.dialog_text = "Are you sure you want to mark the " \
		+ playlist.name + " playlist as archived? This will overwrite the archive file."
	archive_confirmation_dialog.visible = true


func _on_download_single_video_button_pressed():
	single_video_url_input.text = ""
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
	download_single_video_button_clicked.emit(single_video_url_input.text, playlist)
	download_single_video_window.visible = false


func _on_url_input_text_changed(new_text):
	url = new_text


func _on_download_path_input_text_changed(new_text):
	download_path = new_text


func _on_backup_path_input_text_changed(new_text):
	backup_upload_path = new_text


func _on_remote_path_input_text_changed(new_text):
	remote_upload_path = new_text


func _on_download_archive_file_path_input_text_changed(new_text):
	download_archive_file_name = new_text


func _on_cookies_from_browser_input_text_changed(new_text):
	cookies_from_browser = new_text
