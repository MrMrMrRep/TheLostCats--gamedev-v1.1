class_name VanRadio
extends Node
## The band van's radio. Channels belong to a region ("NL", "DE"): only the
## local ones come in, so the dial switches to German stations in Germany.
## Until there is real music every song is a tiny procedural tune (drums, bass,
## chords, a melody) synthesised live into an AudioStreamGenerator, through a
## soft low-pass so it sounds like a van radio. Changing channel crackles.
## Replace a song's dictionary with {"title", "stream"} to play a real track.

signal tuned(text: String)

const MIX_RATE := 22050.0
const SONG_SECONDS := 50.0
const STATIC_SECONDS := 0.35
const VOLUME_DB := -9.0
const MAJOR := [0, 2, 4, 7, 9]
const MINOR := [0, 3, 5, 7, 10]
const CHANNELS := [
	{"name": "Kat FM", "region": "NL", "songs": [
		{"title": "Grachtengordel Groove", "bpm": 112, "root": 57, "prog": [0, 7, 9, 5], "minor": false, "lead": 0, "seed": 11},
		{"title": "Nine Lives", "bpm": 128, "root": 52, "prog": [0, 5, 7, 5], "minor": true, "lead": 1, "seed": 23},
		{"title": "Bikes in the Rain", "bpm": 96, "root": 60, "prog": [0, 9, 5, 7], "minor": false, "lead": 2, "seed": 5}]},
	{"name": "Polder Pop", "region": "NL", "songs": [
		{"title": "Windmolen", "bpm": 120, "root": 55, "prog": [0, 5, 9, 7], "minor": false, "lead": 1, "seed": 31},
		{"title": "Dijk Disco", "bpm": 124, "root": 53, "prog": [0, 0, 5, 7], "minor": false, "lead": 0, "seed": 47},
		{"title": "Koeien Kijken", "bpm": 88, "root": 58, "prog": [0, 7, 5, 5], "minor": false, "lead": 2, "seed": 9}]},
	{"name": "Radio Nachtbus", "region": "NL", "songs": [
		{"title": "Last Ferry", "bpm": 84, "root": 50, "prog": [0, 8, 3, 10], "minor": true, "lead": 2, "seed": 61},
		{"title": "Neon Canal", "bpm": 104, "root": 49, "prog": [0, 3, 8, 7], "minor": true, "lead": 1, "seed": 77}]},
	{"name": "Ruhrwelle", "region": "DE", "songs": [
		{"title": "Zeche Zollverein", "bpm": 132, "root": 52, "prog": [0, 3, 10, 7], "minor": true, "lead": 0, "seed": 83},
		{"title": "Currywurst Blues", "bpm": 92, "root": 55, "prog": [0, 5, 0, 7], "minor": false, "lead": 2, "seed": 97}]},
	{"name": "Autobahn Funk", "region": "DE", "songs": [
		{"title": "Kilometer 412", "bpm": 118, "root": 57, "prog": [0, 0, 8, 10], "minor": true, "lead": 1, "seed": 101}]},
]

var region := "NL":
	set(value):
		region = value
		if is_on and CHANNELS[channel].region != region:
			next_channel()
var channel := 0
var song := 0
var is_on := false

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _song: Dictionary = {}
var _song_time := 0.0
var _static := 0.0
var _t := 0                                 # samples since the song started
var _step := -1
var _rng := RandomNumberGenerator.new()
# Voices: envelope, phase, frequency.
var _kick := 0.0
var _kick_phase := 0.0
var _snare := 0.0
var _hat := 0.0
var _bass := 0.0
var _bass_phase := 0.0
var _bass_freq := 55.0
var _lead := 0.0
var _lead_phase := 0.0
var _lead_freq := 440.0
var _pad := 0.0
var _pad_phase := [0.0, 0.0, 0.0]
var _pad_freq := [220.0, 277.0, 330.0]
var _last_noise := 0.0
var _lp := 0.0


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.25
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.bus = &"Music"
	_player.volume_db = VOLUME_DB
	add_child(_player)
	set_process(false)


## Radio on (last channel) or off.
func power(on: bool) -> void:
	if on == is_on:
		return
	is_on = on
	set_process(on)
	if on:
		if CHANNELS[channel].region != region:
			channel = _channels_here()[0]
		_player.play()
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
		_start_song(song, true)
	else:
		_player.stop()
		_playback = null
		tuned.emit("")


## R in the van: next local channel, then off, then the first one again.
func next_channel() -> void:
	var here := _channels_here()
	var i := here.find(channel)
	if is_on and i == here.size() - 1:
		power(false)
		return
	channel = here[(i + 1) % here.size()] if is_on else here[0]
	if not is_on:
		power(true)
		return
	_start_song(_rng.randi() % CHANNELS[channel].songs.size(), true)


func now_playing() -> String:
	if not is_on:
		return ""
	return "%s  -  %s" % [CHANNELS[channel].name, _song.get("title", "")]


func _channels_here() -> Array:
	var out := []
	for i in CHANNELS.size():
		if CHANNELS[i].region == region:
			out.append(i)
	return out


func _start_song(index: int, with_static: bool) -> void:
	var songs: Array = CHANNELS[channel].songs
	song = index % songs.size()
	_song = songs[song]
	_song_time = 0.0
	_t = 0
	_step = -1
	if with_static:
		_static = STATIC_SECONDS
	tuned.emit(now_playing())


func _process(delta: float) -> void:
	_song_time += delta
	if _song_time >= SONG_SECONDS:
		_start_song(song + 1, false)
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	for i in frames:
		var v := _sample()
		_playback.push_frame(Vector2(v, v))


func _sample() -> float:
	if _static > 0.0:
		_static -= 1.0 / MIX_RATE
		return _rng.randf_range(-0.35, 0.35) * (0.6 + 0.4 * sin(_static * 90.0))
	var bpm: float = _song.bpm
	var step_len := MIX_RATE * 60.0 / bpm / 4.0
	var step := int(_t / step_len)
	if step != _step:
		_step = step
		_on_step(step)
	_t += 1
	var dt := 1.0 / MIX_RATE
	var out := 0.0
	# Kick: a falling sine.
	if _kick > 0.001:
		_kick_phase += (45.0 + 110.0 * _kick * _kick) * dt
		out += sin(_kick_phase * TAU) * _kick * 0.7
		_kick *= 0.99935
	# Snare and hats: noise (hats high-passed).
	var noise := _rng.randf_range(-1.0, 1.0)
	if _snare > 0.001:
		out += noise * _snare * 0.32
		_snare *= 0.9991
	if _hat > 0.001:
		out += (noise - _last_noise) * _hat * 0.09
		_hat *= 0.9965
	_last_noise = noise
	# Bass: square.
	if _bass > 0.001:
		_bass_phase = fmod(_bass_phase + _bass_freq * dt, 1.0)
		out += (1.0 if _bass_phase < 0.5 else -1.0) * _bass * 0.16
		_bass *= 0.99988
	# Pad: three soft triangles.
	if _pad > 0.001:
		for k in 3:
			_pad_phase[k] = fmod(_pad_phase[k] + _pad_freq[k] * dt, 1.0)
			out += (absf(_pad_phase[k] * 4.0 - 2.0) - 1.0) * _pad * 0.05
		_pad *= 0.99996
	# Lead: pulse, triangle or square-ish depending on the song.
	if _lead > 0.001:
		_lead_phase = fmod(_lead_phase + _lead_freq * dt, 1.0)
		var w := 0.0
		match int(_song.lead):
			0: w = 1.0 if _lead_phase < 0.25 else -1.0
			1: w = absf(_lead_phase * 4.0 - 2.0) - 1.0
			_: w = sin(_lead_phase * TAU) + 0.3 * sin(_lead_phase * TAU * 2.0)
		out += w * _lead * 0.12
		_lead *= 0.99975
	# Van radio: soft low-pass and a gentle clip.
	_lp += (out - _lp) * 0.32
	return clampf(_lp, -0.9, 0.9)


func _on_step(step: int) -> void:
	var pos := step % 16
	var bar := (step / 16) % 4
	var root: int = _song.root
	var chord: int = _song.prog[bar]
	var minor_chord: bool = _song.minor if chord == 0 else chord in [2, 4, 9]
	if pos == 0 or pos == 8:
		_kick = 1.0
		_kick_phase = 0.0
	if pos == 4 or pos == 12:
		_snare = 1.0
	if pos % 2 == 0:
		_hat = 0.8 if pos % 4 == 2 else 0.45
	if pos in [0, 3, 6, 8, 10, 14]:
		_bass = 1.0
		_bass_freq = _freq(root - 24 + chord)
	if pos == 0:
		_pad = 1.0
		var third := 3 if minor_chord else 4
		for k in 3:
			_pad_freq[k] = _freq(root + chord + [0, third, 7][k])
	# Melody: a seeded pentatonic line that repeats every 4 bars.
	var h := hash([int(_song.seed), step % 64])
	if pos % 2 == 0 and h % 100 < 55:
		var scale: Array = MINOR if _song.minor else MAJOR
		var note: int = scale[(h / 100) % 5] + 12 * ((h / 1000) % 2)
		_lead = 1.0
		_lead_freq = _freq(root + 12 + note)


static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)
