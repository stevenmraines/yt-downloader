extends Control

@export var video_name := "":
	set(value):
		video_name = value
		name_label.text = video_name

@export var url := "":
	set(value):
		url = value
		url_label.text = url

@export var delete_after_upload := true:
	set(value):
		delete_after_upload = value
		if delete_after_upload_input:
			delete_after_upload_input.button_pressed = delete_after_upload

@export var no_playlist := false:
	set(value):
		no_playlist = value
		if no_playlist_input:
			no_playlist_input.button_pressed = no_playlist

@export var restrict_filename := true:
	set(value):
		restrict_filename = value
		if restrict_filename_input:
			restrict_filename_input.button_pressed = restrict_filename

@export var cookies_from_browser := "firefox":
	set(value):
		cookies_from_browser = value
		if cookies_from_browser_input:
			cookies_from_browser_input.text = cookies_from_browser

@export var upload_to_backup := true:
	set(value):
		upload_to_backup = value
		if upload_to_backup_input:
			upload_to_backup_input.button_pressed = upload_to_backup

@export var upload_to_remote := true:
	set(value):
		upload_to_remote = value
		if upload_to_remote_input:
			upload_to_remote_input.button_pressed = upload_to_remote

@onready var download_panel_stylebox := load("res://styles/download_panel.tres")


@onready var name_label := $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var url_label := $Panel/MarginContainer/VBoxContainer/UrlLabel
@onready var cookies_from_browser_input := $Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/CookiesFromBrowserInput
@onready var delete_after_upload_input := $Panel/MarginContainer/VBoxContainer/HBoxContainer2/MarginContainer/DeleteAfterUploadInput
@onready var no_playlist_input := $Panel/MarginContainer/VBoxContainer/HBoxContainer3/MarginContainer/NoPlaylistInput
@onready var restrict_filename_input := $Panel/MarginContainer/VBoxContainer/HBoxContainer4/MarginContainer/RestrictFilenameInput
@onready var upload_to_backup_input := $Panel/MarginContainer/VBoxContainer/HBoxContainer5/MarginContainer/UploadToBackupInput
@onready var upload_to_remote_input := $Panel/MarginContainer/VBoxContainer/HBoxContainer6/MarginContainer/UploadToRemoteInput


func _ready() -> void:
	name_label.text = video_name
	url_label.text = url
	add_theme_stylebox_override("panel", download_panel_stylebox)
