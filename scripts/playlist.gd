extends Control

@export var channel := ""

@export var playlist := "":
	set(value):
		playlist = value
		if label:
			label.text = playlist

@export var url := "":
	set(value):
		url = value
		if url_input:
			url_input.text = url

@export var download_path := "":
	set(value):
		download_path = value
		if download_path_input:
			download_path_input.text = download_path

@export var backup_upload_path := "":
	set(value):
		backup_upload_path = value
		if backup_upload_path_input:
			backup_upload_path_input.text = backup_upload_path

@export var remote_upload_path := "":
	set(value):
		remote_upload_path = value
		if remote_upload_path_input:
			remote_upload_path_input.text = remote_upload_path

@export var download_archive_file_name := "":
	set(value):
		download_archive_file_name = value
		if download_archive_file_name_input:
			download_archive_file_name_input.text = download_archive_file_name

@export var cookies_from_browser := "":
	set(value):
		cookies_from_browser = value
		if cookies_from_browser_input:
			cookies_from_browser_input.text = cookies_from_browser

@onready var label := $VBoxContainer/Label
@onready var url_input := $VBoxContainer/HBoxContainer3/MarginContainer/UrlInput
@onready var download_path_input := $VBoxContainer/HBoxContainer4/MarginContainer/DownloadPathInput
@onready var backup_upload_path_input := $VBoxContainer/HBoxContainer/MarginContainer/BackupPathInput
@onready var remote_upload_path_input := $VBoxContainer/HBoxContainer2/MarginContainer/RemotePathInput
@onready var download_archive_file_name_input := $VBoxContainer/HBoxContainer5/MarginContainer/DownloadArchiveFilePathInput
@onready var cookies_from_browser_input := $VBoxContainer/HBoxContainer6/MarginContainer/CookiesFromBrowserInput
@onready var queued_videos_container := $VBoxContainer/ScrollContainer/QueuedVideosContainer
@onready var download_scene := load("res://scenes/download.tscn")

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


func populate_download_queue(channel_name : String, playlist_name : String) -> void:
	channel = channel_name
	playlist = playlist_name
	#for video in queued_videos:
		#var scene = download_scene.instantiate()
		#queued_videos_container.add_child(scene)
		#scene.video_name = video.name
		#scene.url = video.url
