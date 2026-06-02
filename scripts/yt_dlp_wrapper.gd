class_name YtDlpWrapper extends Node

var yt_dlp_path : String
var console_signal_bus : ConsoleSignalBus

const opts := {
	"archive" : "--download-archive",
	"cookies" : "--cookies-from-browser",
	"skip" : "--skip-download",
	"update" : "--update",
}


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func _run_command(args : PackedStringArray) -> void:
	if yt_dlp_path == "":
		console_signal_bus.add_error("yt-dlp executable path not provided")
		return
	
	OS.create_process(yt_dlp_path, args, true)


func mark_playlist_as_archived(playlist : Dictionary) -> void:
	var archive_file = OS.get_user_data_dir() + "/archived/" + playlist.channel \
		+ "/" + playlist.download_archive_file_name
	_run_command([playlist.url, opts.archive + " " + archive_file])


func update() -> void:
	_run_command([opts.update])
