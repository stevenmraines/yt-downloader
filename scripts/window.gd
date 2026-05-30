extends Control

@export var yt_dlp_path := ""

@onready var yt_dlp_path_input := $Panel/MarginContainer/VSplitContainer/YtDlpConfig/HBoxContainer/MarginContainer/LineEdit
@onready var yt_dlp_input_timer := $YtDlpInputTimer

var typing := false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		get_viewport().set_input_as_handled()
		get_tree().quit(0)
	
	if yt_dlp_path_input.has_focus():
		yt_dlp_path = yt_dlp_path_input.text
		get_viewport().set_input_as_handled()
		typing = true
		yt_dlp_input_timer.start()


func _on_yt_dlp_input_timer_timeout() -> void:
	print("write to file ", yt_dlp_path)
