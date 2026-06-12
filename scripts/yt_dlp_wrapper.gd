class_name YtDlpWrapper extends Node

var yt_dlp_path : String
var console_signal_bus : ConsoleSignalBus

const OPTS := {
	"archive" : "--download-archive",
	"cookies" : "--cookies-from-browser",
	"flat" : "--flat-playlist",
	"format" : "--format",
	"get_id" : "--get-id",
	"no_playlist" : "--no-playlist",
	"output" : "--output",
	"output_format" : "--merge-output-format",
	"print" : "--print",
	"restrict" : "--restrict-filenames",
	"simulate" : "--simulate",
	"skip" : "--skip-download",
	"update" : "--update",
	"watched" : "--mark-watched",
}

const FORMAT_STRING := "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]"


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
		OPTS.get_id,
		OPTS.flat,
		OPTS.cookies, playlist.cookies_from_browser,
		">", temp_file
	]
	
	var pid = OS.create_process("cmd.exe", args, true)
	
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
		OPTS.archive, archive_file,
		OPTS.cookies, playlist.cookies_from_browser,
		OPTS.restrict,
		OPTS.output, output,
		OPTS.output_format, "mp4",
		OPTS.format, FORMAT_STRING
	])


# FIXME If video is already in archive file, terminal closes immediately and process remains in queue
func download_single_video(playlist : Dictionary) -> int:
	console_signal_bus.add_line("Downloading single video")
	var archive_file = _get_archive_file_path(playlist)
	var output = playlist.download_path + "/%(upload_date>%Y-%m-%d)s %(title)s.%(ext)s"
	var temp_file = OS.get_user_data_dir() + "/download_single_video_temp.txt"
	console_signal_bus.add_line("Writing output to temp file: %s" % temp_file)
	
	# Pass our args as one big string so that we don't have to escape a bunch of stuff for cmd.exe
	var command_str = ("\"%s\" \"%s\" %s \"%s\" %s %s %s \"%s\" \"%s\" %s \"mp4\" %s \"%s\" %s > \"%s\"" % [
		yt_dlp_path,
		playlist.url,
		OPTS.archive, archive_file,
		OPTS.cookies, playlist.cookies_from_browser,
		OPTS.restrict,
		OPTS.output, output,
		OPTS.output_format,
		OPTS.format, FORMAT_STRING,
		OPTS.no_playlist,
		temp_file
	])
	
	var pid = OS.create_process("cmd.exe", ["/c", command_str], true)
	
	_watch_download_single_video_job(pid, temp_file)
	
	return pid


func _watch_download_single_video_job(pid : int, temp_file : String) -> void:
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
			#console_signal_bus.add_warning("download_single_video process terminated, removing temp file: %s" % temp_file)
			#DirAccess.remove_absolute(temp_file)
			return
		# TODO Get downloaded video filename
		# [Merger] Merging formats into "C:\Users\steve\Videos\Astrogoblin\other\2025-05-19 I_Spent_24_Hours_at_Dollywood.mp4"
		# TODO Notify child processes of that filename somehow
		print("yee")
		#_write_archive_from_temp(archive_file, temp_file)
	)
	
	timer.start()


func get_unarchived_video_details(playlist : Dictionary) -> Array:
	var archive_file = _get_archive_file_path(playlist)
	var output = []
	
	console_signal_bus.add_line("Getting unarchived video details for playlist %s" % playlist.name)
	
	OS.execute(yt_dlp_path, [
		playlist.url,
		OPTS.archive, archive_file,
		OPTS.cookies, playlist.cookies_from_browser,
		OPTS.simulate,
		OPTS.print, "upload_date,title"
	], output)
	
	output = output[0].split("\n")
	var details = []
	var date = ""
	var title = ""
	
	for line in output:
		if line == "":
			continue
		
		var date_regex = RegEx.new()
		date_regex.compile("(?<year>\\d{4})(?<month>\\d{2})(?<day>\\d{2})")
		var result = date_regex.search(line)
		
		if result:
			var year = result.get_string("year")
			var month = result.get_string("month")
			var day = result.get_string("day")
			date = year + "-" + month + "-" + day
		else:
			title = line
			if date:
				title = date + " - " + title
			details.append(title)
			date = ""
			title = ""
	
	return details


func update() -> int:
	return _run_command([OPTS.update])
