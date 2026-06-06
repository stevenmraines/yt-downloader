class_name YtDlpWrapper extends Node

var yt_dlp_path : String
var console_signal_bus : ConsoleSignalBus

const opts := {
	"archive" : "--download-archive",
	"cookies" : "--cookies-from-browser",
	"flat" : "--flat-playlist",
	"format" : "--format",
	"get_id" : "--get-id",
	"no_playlist" : "--no-playlist",
	"output" : "--output",
	"output_format" : "--merge-output-format",
	"restrict" : "--restrict-filenames",
	"simulate" : "--simulate",
	"skip" : "--skip-download",
	"update" : "--update",
	"watched" : "--mark-watched",
}


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func _run_command(args : PackedStringArray) -> int:
	if yt_dlp_path == "":
		console_signal_bus.add_error("yt-dlp executable path not provided")
		return -1
	print(" ".join(args))
	return OS.create_process(yt_dlp_path, args, true)


func _get_archive_file_path(playlist : Dictionary) -> String:
	return OS.get_user_data_dir() + "/archived/" + playlist.channel \
		+ "/" + playlist.download_archive_file_name


func mark_playlist_as_archived(playlist : Dictionary) -> int:
	console_signal_bus.add_line("Marking playlist " + playlist.name + " for channel " + playlist.channel + " as archived")
	
	var archive_file = _get_archive_file_path(playlist)
	var temp_file = OS.get_user_data_dir() + "/mark_playlist_as_archived_temp.txt"
	
	console_signal_bus.add_line("Writing video IDs to temp file: %s" % temp_file)
	
	# Pipe yt-dlp output to a temp file via cmd
	var args = [
		"/c", yt_dlp_path,
		playlist.url,
		opts.get_id,
		opts.flat,
		opts.cookies, playlist.cookies_from_browser,
		">", temp_file
	]
	var pid = OS.create_process("cmd.exe", args, true)
	print(" ".join(args))
	
	_watch_archive_job(pid, archive_file, temp_file)
	
	return pid


func _watch_archive_job(pid : int, archive_file : String, temp_file : String) -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	
	timer.timeout.connect(func():
		if OS.is_process_running(pid):
			return
		timer.stop()
		timer.queue_free()
		var exit_code = OS.get_process_exit_code(pid)
		if exit_code != 0:
			# Exit code will be some non-zero value if the user killed the process
			# or there was an error, either way we don't want to write to the archive file.
			console_signal_bus.add_warning("mark_playlist_as_archived process terminated, removing temp file: %s" % temp_file)
			DirAccess.remove_absolute(temp_file)
			return
		_write_archive_from_temp(archive_file, temp_file)
	)
	
	timer.start()


func _write_archive_from_temp(archive_file : String, temp_file : String) -> void:
	var file = FileAccess.open(temp_file, FileAccess.READ)
	
	if not file:
		console_signal_bus.add_error("Failed to read temp file: %s" % temp_file)
		return
	
	var content = file.get_as_text()
	file.close()
	DirAccess.remove_absolute(temp_file)
	
	var out = FileAccess.open(archive_file, FileAccess.WRITE)
	
	if not out:
		console_signal_bus.add_error("Failed to write archive file: %s" % archive_file)
		return
	
	for video_id in content.split("\n"):
		var id = video_id.strip_edges()
		
		if id != "":
			out.store_string("youtube " + id + "\n")
	
	out.close()


func download_playlist(playlist : Dictionary) -> int:
	var archive_file = _get_archive_file_path(playlist)
	var output = playlist.download_path + "/%(upload_date>%Y-%m-%d)s %(title)s.%(ext)s\""
	
	console_signal_bus.add_line("Downloading playlist " + playlist.name + " for channel " + playlist.channel)
	
	return _run_command([
		playlist.url,
		opts.archive, archive_file,
		opts.cookies, playlist.cookies_from_browser,
		opts.restrict,
		opts.output, output,
		opts.output_format, "mp4",
		opts.format, "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]"
	])


# FIXME If video is already in archive file, terminal closes immediately and process remains in queue
func download_single_video(url : String, playlist : Dictionary) -> int:
	var archive_file = _get_archive_file_path(playlist)
	var output = playlist.download_path + "/%(upload_date>%Y-%m-%d)s %(title)s.%(ext)s\""
	
	console_signal_bus.add_line("Downloading single video")
	
	# TODO Try to find a way to keep the terminal window open
	return _run_command([
		url,
		opts.archive, archive_file,
		opts.cookies, playlist.cookies_from_browser,
		opts.restrict,
		opts.output, output,
		opts.output_format, "mp4",
		opts.format, "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]",
		opts.no_playlist
	])


func update() -> int:
	return _run_command([opts.update])
