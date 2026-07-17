class_name YtDlpWrapper extends Node

var yt_dlp_path : String
var console_signal_bus : ConsoleSignalBus

const OPTS := {
	"archive" : "--download-archive",
	"cookies" : "--cookies-from-browser",
	"flat" : "--flat-playlist",
	"format" : "--format",
	"get_id" : "--get-id",
	"items" : "--playlist-items",
	"no_playlist" : "--no-playlist",
	"output" : "--output",
	"output_format" : "--merge-output-format",
	"print" : "--print",
	"restrict" : "--restrict-filenames",
	"simulate" : "--simulate",
	"skip" : "--skip-download",
	"update" : "--update",
	"update_to" : "--update-to",
	"watched" : "--mark-watched",
}

const FORMAT_STRING := "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]"


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func _run_command(args : PackedStringArray) -> int:
	return OS.create_process(yt_dlp_path, args, true)


func mark_playlist_as_archived(process : Process) -> int:
	console_signal_bus.add_line("Marking playlist " + process.playlist.name + " for channel " + process.playlist.channel + " as archived")
	var temp_file = process.data.temp_file
	console_signal_bus.add_line("Writing video IDs to temp file: %s" % temp_file)
	
	# Pipe yt-dlp output to a temp file via cmd
	var args = [
		"/c", yt_dlp_path,
		process.playlist.url,
		OPTS.get_id,
		OPTS.flat,
		OPTS.cookies, process.playlist.cookies_from_browser,
		">", temp_file
	]
	
	return OS.create_process("cmd.exe", args, true)


func download_playlist(process : Process) -> int:
	var start_index = process.data.start_index
	var end_index = process.data.end_index
	var use_archive_file = process.data.use_archive_file
	var output = process.playlist.download_path + "/%(upload_date>%Y-%m-%d)s %(title)s.%(ext)s"
	
	console_signal_bus.add_line("Downloading playlist %s (%s)" % [process.playlist.name, process.playlist.channel])
	
	# Pass our args as one big string so that we don't have to escape a bunch of stuff for cmd.exe
	var interp_str = "\"%s\" \"%s\" %s %s %s \"%s\" \"%s\" %s \"mp4\" %s \"%s\""
	var interp_str_values = [
		yt_dlp_path,
		process.playlist.url,
		OPTS.cookies, process.playlist.cookies_from_browser,
		OPTS.restrict,
		OPTS.output, output,
		OPTS.output_format,
		OPTS.format, FORMAT_STRING
	]
	
	if start_index != "" and end_index != "":
		interp_str += " %s %d:%d"
		interp_str_values.append(OPTS.items)
		interp_str_values.append(start_index.to_int())
		interp_str_values.append(end_index.to_int())
		console_signal_bus.add_line("Restricting playlist items from %d to %d" % [start_index, end_index])
	
	if use_archive_file:
		var archive_file = Util.get_archive_file_path(process.playlist)
		interp_str += " %s \"%s\""
		interp_str_values.append(OPTS.archive)
		interp_str_values.append(archive_file)
		console_signal_bus.add_line("Using archive file: %s" % archive_file)
	
	var temp_file = process.data.temp_file
	interp_str += " > \"%s\""
	interp_str_values.append(temp_file)
	console_signal_bus.add_line("Writing output to temp file: %s" % temp_file)
	
	var command_str = (interp_str % interp_str_values)
	return OS.create_process("cmd.exe", ["/c", command_str], true)


# FIXME If video is already in archive file, terminal closes immediately and process remains in queue
func download_single_video(process : Process) -> int:
	console_signal_bus.add_line("Downloading single video using %s (%s) playlist settings" % [process.playlist.name, process.playlist.channel])
	var use_archive_file = process.data.use_archive_file
	var output = process.playlist.download_path + "/%(upload_date>%Y-%m-%d)s %(title)s.%(ext)s"
	
	# Pass our args as one big string so that we don't have to escape a bunch of stuff for cmd.exe
	var interp_str = "\"%s\" \"%s\" %s %s %s \"%s\" \"%s\" %s \"mp4\" %s \"%s\" %s"
	var interp_str_values = [
		yt_dlp_path,
		process.data.url,
		OPTS.cookies, process.playlist.cookies_from_browser,
		OPTS.restrict,
		OPTS.output, output,
		OPTS.output_format,
		OPTS.format, FORMAT_STRING,
		OPTS.no_playlist
	]
	
	if use_archive_file:
		var archive_file = Util.get_archive_file_path(process.playlist)
		interp_str += " %s \"%s\""
		interp_str_values.append(OPTS.archive)
		interp_str_values.append(archive_file)
		console_signal_bus.add_line("Using archive file: %s" % archive_file)
	
	var temp_file = process.data.temp_file
	interp_str += " > \"%s\""
	interp_str_values.append(temp_file)
	console_signal_bus.add_line("Writing output to temp file: %s" % temp_file)
	
	var progress_timer = Timer.new()
	add_child(progress_timer)
	progress_timer.wait_time = 0.5
	progress_timer.connect("timeout", _on_progress_timer_timeout.bind(progress_timer, process, temp_file))
	progress_timer.start()
	
	# TODO Probably will have to do something like "terminal" instead of cmd.exe for Mac, if that's something I care about
	var command_str = (interp_str % interp_str_values)
	return OS.create_process("cmd.exe", ["/c", command_str], true)


func _on_progress_timer_timeout(timer : Timer, process : Process, file : String) -> void:
	var progress = 0.0
	
	if ! process.data.has("progress"):
		process.data.progress = progress
	
	var file_handle = FileAccess.open(file, FileAccess.READ)
	var last_download_line = ""
	
	while ! file_handle.eof_reached():
		var line = file_handle.get_line()
		if line.begins_with("[download]") and "Destination:" in line and line.ends_with(".m4a"):
			# The file will output progress for the video and audio separately,
			# so we need to make sure we don't go recording both.
			break
		if line.begins_with("[download]") and "%" in line and "ETA" in line:
			# TODO How will this work with multiple downloads?
			last_download_line = line
	
	file_handle.close()
	
	if last_download_line == "":
		return
	
	var regex = RegEx.new()
	regex.compile("(?<percentage>\\d+\\.\\d+)%")
	var result = regex.search(last_download_line)
	
	if result:
		var percentage = result.get_string("percentage")
		if percentage.is_valid_float():
			progress = percentage.to_float()
		else:
			console_signal_bus.add_warning("Could not parse %s for download percentage (%s found)" % [file, percentage])
			return
	
	process.data.progress = progress
	
	if progress == 100.0 or process.status != Process.ProcessState.IN_PROGRESS:
		timer.stop()
		timer.queue_free()


func get_unarchived_video_details(playlist : Dictionary) -> Array:
	var archive_file = Util.get_archive_file_path(playlist)
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
	return _run_command([OPTS.update_to, "nightly@latest"])
