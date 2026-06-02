extends Control

signal mark_as_archived_clicked(list : Dictionary)

@onready var label := $VBoxContainer/HBoxContainer7/Label
@onready var mark_as_archived_button := $VBoxContainer/HBoxContainer7/MarginContainer/MarkAsArchivedButton
@onready var url_input := $VBoxContainer/HBoxContainer3/MarginContainer/UrlInput
@onready var download_path_input := $VBoxContainer/HBoxContainer4/MarginContainer/DownloadPathInput
@onready var backup_upload_path_input := $VBoxContainer/HBoxContainer/MarginContainer/BackupPathInput
@onready var remote_upload_path_input := $VBoxContainer/HBoxContainer2/MarginContainer/RemotePathInput
@onready var download_archive_file_name_input := $VBoxContainer/HBoxContainer5/MarginContainer/DownloadArchiveFilePathInput
@onready var cookies_from_browser_input := $VBoxContainer/HBoxContainer6/MarginContainer/CookiesFromBrowserInput
@onready var queued_videos_container := $VBoxContainer/ScrollContainer/QueuedVideosContainer
@onready var download_scene := load("res://scenes/download.tscn")

var playlist : Dictionary:
	set(value):
		playlist = value
		label.text = playlist.name
		channel = playlist.channel
		url = playlist.url
		download_path = playlist.download_path
		backup_upload_path = playlist.backup_upload_path
		remote_upload_path = playlist.remote_upload_path
		download_archive_file_name = playlist.download_archive_file_name
		cookies_from_browser = playlist.cookies_from_browser

var channel := ""

var url := "":
	set(value):
		url = value
		if url_input:
			url_input.text = url

var download_path := "":
	set(value):
		download_path = value
		if download_path_input:
			download_path_input.text = download_path

var backup_upload_path := "":
	set(value):
		backup_upload_path = value
		if backup_upload_path_input:
			backup_upload_path_input.text = backup_upload_path

var remote_upload_path := "":
	set(value):
		remote_upload_path = value
		if remote_upload_path_input:
			remote_upload_path_input.text = remote_upload_path

var download_archive_file_name := "":
	set(value):
		download_archive_file_name = value
		if download_archive_file_name_input:
			download_archive_file_name_input.text = download_archive_file_name

var cookies_from_browser := "":
	set(value):
		cookies_from_browser = value
		if cookies_from_browser_input:
			cookies_from_browser_input.text = cookies_from_browser

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


func populate_download_queue() -> void:
	pass


func _on_mark_as_archived_button_button_up():
	mark_as_archived_clicked.emit(playlist)
