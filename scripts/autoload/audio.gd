extends Node
## Music crossfade (calm world map <-> tense level) and one-shot SFX.
## Registered as the `Audio` autoload. Buses: Master > Music, SFX.

const SILENT_DB := -40.0

var _players: Array[AudioStreamPlayer] = []
var _current: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)


func play_music(stream: AudioStream, fade_time: float = 1.5) -> void:
	var old := _players[_current]
	if old.stream == stream and old.playing:
		return
	_current = 1 - _current
	var new := _players[_current]
	new.stream = stream
	new.volume_db = SILENT_DB
	new.play()
	var tween := create_tween().set_parallel()
	tween.tween_property(new, "volume_db", 0.0, fade_time)
	tween.tween_property(old, "volume_db", SILENT_DB, fade_time)
	tween.chain().tween_callback(old.stop)


func play_sfx(stream: AudioStream, pitch_jitter: float = 0.05) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
