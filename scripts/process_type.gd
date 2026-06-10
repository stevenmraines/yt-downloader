class_name Process extends Node

signal progress_timer_timeout(process : Process)

var status := ProcessState.QUEUED
var exit_code := -1
var pid := -1
var process_name := ""
var playlist := {}
var progress_timer := Timer.new()
var parent_process : Process

const PROGRESS_CHECK_DURATION := 0.5

enum ProcessState { QUEUED, IN_PROGRESS, COMPLETE, ERRORED, KILLED }


func _ready() -> void:
	progress_timer.wait_time = PROGRESS_CHECK_DURATION
	progress_timer.autostart = false
	progress_timer.one_shot = false
	add_child(progress_timer)
	progress_timer.timeout.connect(_on_progress_timer_timeout)


func _on_progress_timer_timeout() -> void:
	progress_timer_timeout.emit(self)
