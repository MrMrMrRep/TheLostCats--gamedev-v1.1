extends Node
## Music crossfade (calm world map <-> tense level) and one-shot SFX.
## Registered as the `Audio` autoload. Buses: Master > Music, SFX.
## music(&"map_calm") / sfx(&"jump") play the files in audio/music and
## audio/sfx (placeholders from tools/make_audio.py) by name.

const SILENT_DB := -40.0
const MUSIC_DB := -8.0                      # music sits under the effects
const SFX_DB := -4.0

var _cache := {}

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
	tween.tween_property(new, "volume_db", MUSIC_DB, fade_time)
	tween.tween_property(old, "volume_db", SILENT_DB, fade_time)
	tween.chain().tween_callback(old.stop)


## Play audio/music/<name>.wav on a loop (crossfading from what played before).
func music(name: StringName, fade_time: float = 1.5) -> void:
	var s := _load("res://audio/music/%s.wav" % name)
	if s is AudioStreamWAV and s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	if s:
		play_music(s, fade_time)


## Play audio/sfx/<name>.wav once.
func sfx(name: StringName, pitch_jitter: float = 0.06) -> void:
	var s := _load("res://audio/sfx/%s.wav" % name)
	if s:
		play_sfx(s, pitch_jitter)


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func play_sfx(stream: AudioStream, pitch_jitter: float = 0.05) -> void:
	var player := AudioStreamPlayer.new()
	player.volume_db = SFX_DB
	player.bus = &"SFX"
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
