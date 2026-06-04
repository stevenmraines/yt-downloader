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


func mark_playlist_as_archived(playlist : Dictionary) -> void:
	console_signal_bus.add_line("Marking playlist " + playlist.name + " for channel " + playlist.channel + " as archived")
	
	var archive_file = _get_archive_file_path(playlist)
	var video_ids = []
	
	# TODO See if there's a way to actually show the output in the terminal window
	# FIXME This returns an exit code, not a pid...that could be a problem
	OS.execute(yt_dlp_path, [
		playlist.url,
		opts.archive, archive_file,
		opts.cookies, playlist.cookies_from_browser,
		opts.simulate,
		opts.get_id
	], video_ids, false, true)
	
	video_ids = video_ids[0].split("\n")
	var file = FileAccess.open(archive_file, FileAccess.WRITE)
	
	for video_id in video_ids:
		if video_id != "":
			console_signal_bus.add_line("Video archived: " + video_id)
			file.store_string("youtube " + video_id + "\n")
	
	file.close()


func download_playlist(playlist : Dictionary) -> int:
	# TODO Remove this after playlists have been marked as archived and we can kill processes
	return -1
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
