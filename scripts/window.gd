extends Control

@export var yt_dlp_path := ""

@onready var yt_dlp_path_input := $Panel/MarginContainer/VSplitContainer/YtDlpConfig/HBoxContainer/MarginContainer/LineEdit
@onready var yt_dlp_input_timer := $YtDlpInputTimer
@onready var channel_container := $Panel/MarginContainer/VSplitContainer/HBoxContainer/ChannelContainer
@onready var console_text_input := $Panel/MarginContainer/VSplitContainer/MarginContainer/Console/MarginContainer/ConsoleText

var typing := false


func _ready() -> void:
	var config = ConfigLoader.config
	var x = "fdsa"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		get_viewport().set_input_as_handled()
		get_tree().quit(0)
	
	
	if event is InputEventKey:
		if yt_dlp_path_input.has_focus():
			yt_dlp_path = yt_dlp_path_input.text
			get_viewport().set_input_as_handled()
			typing = true
			yt_dlp_input_timer.start()
			return
		
		for channel in channel_container.get_children():
			for playlist in channel.playlist_container.get_children():
				if playlist.backup_path_input.has_focus():
					write_to_console(playlist.backup_path_input.text)
					get_viewport().set_input_as_handled()
				elif playlist.remote_path_input.has_focus():
					write_to_console(playlist.remote_path_input.text)
					get_viewport().set_input_as_handled()


func _on_yt_dlp_input_timer_timeout() -> void:
	write_to_console("write to file " + yt_dlp_path)


func write_to_console(text : String) -> void:
	console_text_input.text = console_text_input.text + text + "\n"
	var total_lines = console_text_input.get_line_count()
	console_text_input.set_caret_line(total_lines - 1)
	console_text_input.set_caret_column(console_text_input.get_line_width(total_lines - 1))
