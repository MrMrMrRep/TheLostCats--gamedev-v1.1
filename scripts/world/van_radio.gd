class_name VanRadio
extends Node
## The band van's radio. Channels belong to a region ("NL", "DE"): only the
## local ones come in, so the dial switches to German stations in Germany.
## Until there is real music every song is a little procedural tune (drums,
## bass, chords, a melody), rendered once into a looping WAV by
## tools/make_radio.py (audio/radio/radio_<channel>_<song>.wav): playing a file
## costs nothing per frame and never stutters (it used to be synthesised live,
## sample by sample). Changing channel crackles (static.wav).
## Give a song a "stream" to play a real track instead.

signal tuned(text: String)

const SONG_SECONDS := 50.0
const STATIC_SECONDS := 0.35
const VOLUME_DB := -9.0
const DIR := "res://audio/radio/"
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
var _crackle: AudioStreamPlayer
var _song: Dictionary = {}
var _song_time := 0.0
var _static := 0.0                          # seconds of crackle left before the song comes in
var _rng := RandomNumberGenerator.new()
var _streams := {}


func _ready() -> void:
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = VOLUME_DB
		add_child(p)
		if i == 0:
			_player = p
		else:
			_crackle = p
			p.stream = load(DIR + "static.wav") if ResourceLoader.exists(DIR + "static.wav") else null
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
		_start_song(song, true)
	else:
		_player.stop()
		_crackle.stop()
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


## The song's looping stream: its own "stream", or the rendered loop.
func _stream_for(ch: int, index: int) -> AudioStream:
	var key := "%d_%d" % [ch, index]
	if not _streams.has(key):
		var s: AudioStream = CHANNELS[ch].songs[index].get("stream")
		var path := DIR + "radio_%s.wav" % key
		if s == null and ResourceLoader.exists(path):
			s = load(path)
		if s is AudioStreamWAV and s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		_streams[key] = s
	return _streams[key]


func _start_song(index: int, with_static: bool) -> void:
	var songs: Array = CHANNELS[channel].songs
	song = index % songs.size()
	_song = songs[song]
	_song_time = 0.0
	_player.stop()
	_player.stream = _stream_for(channel, song)
	_static = STATIC_SECONDS if with_static and _crackle.stream else 0.0
	if _static > 0.0:
		_crackle.play()
	elif _player.stream:
		_player.play()
	tuned.emit(now_playing())


func _process(delta: float) -> void:
	if _static > 0.0:
		_static -= delta
		if _static <= 0.0 and _player.stream:
			_player.play()
	_song_time += delta
	if _song_time >= SONG_SECONDS:
		_start_song(song + 1, false)
