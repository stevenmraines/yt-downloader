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
	"update_to" : "--update-to",
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
	console_signal_bus.add_line("Downloading playlist %s (%s)" % [process.playlist.name, process.playlist.channel])
	var archive_file = Util.get_archive_file_path(process.playlist)
	var output = process.playlist.download_path + "/%(upload_date>%Y-%m-%d)s %(title)s.%(ext)s"
	var temp_file = process.data.temp_file
	console_signal_bus.add_line("Writing output to temp file: %s" % temp_file)
	
	# Pass our args as one big string so that we don't have to escape a bunch of stuff for cmd.exe
	var command_str = ("\"%s\" \"%s\" %s \"%s\" %s %s %s \"%s\" \"%s\" %s \"mp4\" %s \"%s\" > \"%s\"" % [
		yt_dlp_path,
		process.playlist.url,
		OPTS.archive, archive_file,
		OPTS.cookies, process.playlist.cookies_from_browser,
		OPTS.restrict,
		OPTS.output, output,
		OPTS.output_format,
		OPTS.format, FORMAT_STRING,
		temp_file
	])
	print(command_str)
	
	return OS.create_process("cmd.exe", ["/c", command_str], true)


# FIXME If video is already in archive file, terminal closes immediately and process remains in queue
func download_single_video(process : Process) -> int:
	console_signal_bus.add_line("Downloading single video using %s (%s) playlist settings" % [process.playlist.name, process.playlist.channel])
	var archive_file = Util.get_archive_file_path(process.playlist)
	var output = process.playlist.download_path + "/%(upload_date>%Y-%m-%d)s %(title)s.%(ext)s"
	var temp_file = process.data.temp_file
	console_signal_bus.add_line("Writing output to temp file: %s" % temp_file)
	
	# Pass our args as one big string so that we don't have to escape a bunch of stuff for cmd.exe
	var command_str = ("\"%s\" \"%s\" %s \"%s\" %s %s %s \"%s\" \"%s\" %s \"mp4\" %s \"%s\" %s > \"%s\"" % [
		yt_dlp_path,
		process.playlist.url,
		OPTS.archive, archive_file,
		OPTS.cookies, process.playlist.cookies_from_browser,
		OPTS.restrict,
		OPTS.output, output,
		OPTS.output_format,
		OPTS.format, FORMAT_STRING,
		OPTS.no_playlist,
		temp_file
	])
	
	return OS.create_process("cmd.exe", ["/c", command_str], true)


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
