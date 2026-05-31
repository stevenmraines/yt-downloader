extends Control

@export var playlist_name := "":
	set(value):
		playlist_name = value
		if label:
			label.text = playlist_name

@export var playlist_url := ""
@export var download_path := ""
@export var upload_backup_path := ""
@export var upload_remote_path := ""
@export var downloaded_videos_file_path := ""

@onready var label := $VBoxContainer/Label
@onready var backup_path_input := $VBoxContainer/HBoxContainer/MarginContainer/BackupPathInput
@onready var remote_path_input := $VBoxContainer/HBoxContainer2/MarginContainer/RemotePathInput
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


func _ready() -> void:
	label.text = playlist_name
	for video in queued_videos:
		var scene = download_scene.instantiate()
		queued_videos_container.add_child(scene)
		scene.video_name = video.name
		scene.url = video.url
