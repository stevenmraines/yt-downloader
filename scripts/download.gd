extends Control

@export var video_name := "":
	set(value):
		video_name = value
		name_label.text = video_name

@export var url := "":
	set(value):
		url = value
		url_label.text = url

@export var delete_after_upload := true
# TODO How will this work when we want to download a whole playlist vs single video? Maybe instead of video it should be called download?
@export var no_playlist := false
@export var strip_characters := true
@export var cookies_from_browser := "firefox"

@onready var name_label := $VBoxContainer/NameLabel
@onready var url_label := $VBoxContainer/UrlLabel


func _ready() -> void:
	name_label.text = video_name
	url_label.text = url
