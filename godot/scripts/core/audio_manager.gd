extends Node
## Autoloaded as "AudioManager". Procedural SFX for all game events.
## Generates simple waveform sounds at startup — no external audio files needed.

const SAMPLE_RATE := 22050
const POOL_SIZE := 10

var _players: Array[AudioStreamPlayer] = []
var _player_idx: int = 0
var _sfx: Dictionary = {}
var _music_player: AudioStreamPlayer
var _music_layers: Array[AudioStreamPlayer] = []  # [calm, mid, intense]
var _current_intensity: int = 0
var sfx_volume_db: float = 0.0
var music_volume_db: float = -24.0

func set_sfx_volume(db: float) -> void:
	sfx_volume_db = db

func set_music_volume(db: float) -> void:
	music_volume_db = db
	if _music_layers.size() > 0:
		_music_layers[_current_intensity].volume_db = db

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -24.0
	add_child(_music_player)

	_generate_sounds()
	_generate_music()
	_connect_signals()

# ---- Signal wiring ----

func _connect_signals() -> void:
	GameEvents.damage_dealt.connect(_on_damage)
	GameEvents.enemy_killed.connect(func(_e): play("kill"))
	GameEvents.xp_gained.connect(func(_a): play("xp"))
	GameEvents.level_up.connect(func(_l): play("level_up"))
	GameEvents.item_acquired.connect(_on_item_acquired)
	GameEvents.wave_started.connect(_on_wave_started)
	GameEvents.wave_completed.connect(func(_w): play("wave_complete"))
	GameEvents.boss_spawned.connect(func(_b): play("boss"))
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.game_started.connect(_on_game_started)
	GameEvents.kill_streak_changed.connect(_on_streak)
	GameEvents.wave_milestone.connect(func(_w): play("milestone"))

func play(sfx_name: String, vol_db: float = 0.0) -> void:
	if not _sfx.has(sfx_name):
		return
	vol_db += sfx_volume_db
	var p = _players[_player_idx]
	_player_idx = (_player_idx + 1) % POOL_SIZE
	p.stream = _sfx[sfx_name]
	p.volume_db = vol_db
	p.play()

# ---- Event handlers ----

func _on_damage(_target: Node2D, _amount: float, is_crit: bool, _type: String = "") -> void:
	play("crit" if is_crit else "hit")

func _on_item_acquired(item: Resource) -> void:
	var rarity: int = item.rarity if item.get("rarity") != null else 0
	match rarity:
		Rarity.Type.COMMON: play("item_common")
		Rarity.Type.UNCOMMON: play("item_uncommon")
		Rarity.Type.RARE: play("item_rare")
		Rarity.Type.EPIC: play("item_epic")
		Rarity.Type.LEGENDARY: play("item_legendary")

func _on_streak(streak: int) -> void:
	if streak > 0 and streak % 5 == 0:
		play("streak")

func _on_wave_started(wave: int) -> void:
	play("wave_start")
	# Crossfade music intensity based on wave
	var target: int
	if wave < 15:
		target = 0  # calm
	elif wave < 30:
		target = 1  # mid
	else:
		target = 2  # intense
	if target != _current_intensity and _music_layers.size() == 3:
		_crossfade_music(target)

func _crossfade_music(target: int) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	for i in range(_music_layers.size()):
		var vol = music_volume_db if i == target else -60.0
		tween.tween_property(_music_layers[i], "volume_db", vol, 2.0)
	_current_intensity = target

func _on_game_started() -> void:
	play("game_start")
	_current_intensity = 0
	for i in range(_music_layers.size()):
		_music_layers[i].volume_db = music_volume_db if i == 0 else -60.0
		_music_layers[i].play()

func _on_game_over() -> void:
	play("game_over")
	for layer in _music_layers:
		layer.stop()

# ---- Sound generation ----

func _generate_sounds() -> void:
	# Combat
	_sfx["hit"] = _tone(350, 0.04, 0.35)
	_sfx["crit"] = _tone(700, 0.06, 0.55, 1)
	_sfx["kill"] = _sweep(500, 200, 0.05, 0.4)

	# Pickups
	_sfx["xp"] = _tone(1400, 0.025, 0.15)

	# Progression
	_sfx["level_up"] = _notes([523, 659, 784], 0.12, 0.5)
	_sfx["streak"] = _sweep(400, 900, 0.08, 0.3)

	# Item rarity fanfares (escalating)
	_sfx["item_common"] = _tone(600, 0.08, 0.25)
	_sfx["item_uncommon"] = _sweep(500, 800, 0.12, 0.35)
	_sfx["item_rare"] = _notes([523, 784], 0.1, 0.45)
	_sfx["item_epic"] = _notes([523, 659, 784, 1047], 0.1, 0.55)
	_sfx["item_legendary"] = _notes([392, 523, 659, 784, 1047], 0.1, 0.65)

	# Waves
	_sfx["wave_start"] = _sweep(200, 400, 0.2, 0.35)
	_sfx["wave_complete"] = _notes([523, 659, 784], 0.1, 0.4)
	_sfx["boss"] = _sweep(120, 60, 0.4, 0.5)

	# War Drummer — dembow kit
	_sfx["drum_kick"] = _sweep(180, 35, 0.2, 0.7)     # Deep reggaeton kick
	_sfx["drum_snare"] = _sweep(900, 200, 0.07, 0.45)  # Sharp snare crack
	_sfx["drum_hat"] = _tone(7000, 0.02, 0.18)         # Metallic hi-hat tick
	_sfx["drum_beat"] = _sweep(180, 35, 0.2, 0.7)      # Alias for legacy calls

	# Milestones
	_sfx["milestone"] = _notes([523, 659, 784, 1047, 1319], 0.12, 0.6)

	# Game state
	_sfx["game_start"] = _notes([523, 659, 784], 0.08, 0.4)
	_sfx["game_over"] = _notes([784, 523, 392, 262], 0.15, 0.45)
	_sfx["click"] = _tone(1000, 0.02, 0.25)

## Generate a single-frequency tone with decay envelope.
func _tone(freq: float, duration: float, vol: float = 0.5, wave: int = 0) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = SAMPLE_RATE
	audio.stereo = false
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - float(i) / n
		env *= env
		var s: float
		if wave == 0:
			s = sin(t * freq * TAU)
		else:
			s = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
		s *= env * vol
		var si := clampi(int(s * 32767), -32768, 32767)
		data[i * 2] = si & 0xFF
		data[i * 2 + 1] = (si >> 8) & 0xFF
	audio.data = data
	return audio

## Generate a frequency sweep (glide from f0 to f1).
func _sweep(f0: float, f1: float, duration: float, vol: float = 0.5) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = SAMPLE_RATE
	audio.stereo = false
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var p := float(i) / n
		var freq := f0 + (f1 - f0) * p
		var env := (1.0 - p) * (1.0 - p)
		phase += freq / SAMPLE_RATE
		var s := sin(phase * TAU) * env * vol
		var si := clampi(int(s * 32767), -32768, 32767)
		data[i * 2] = si & 0xFF
		data[i * 2 + 1] = (si >> 8) & 0xFF
	audio.data = data
	return audio

## Generate a sequence of notes (ascending/descending melodies).
func _notes(freqs: Array, note_dur: float, vol: float = 0.5) -> AudioStreamWAV:
	var total := note_dur * freqs.size()
	var n := int(SAMPLE_RATE * total)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = SAMPLE_RATE
	audio.stereo = false
	var data := PackedByteArray()
	data.resize(n * 2)
	var spn := int(SAMPLE_RATE * note_dur)
	for i in range(n):
		var ni := mini(i / spn, freqs.size() - 1)
		var np := i - ni * spn
		var freq: float = freqs[ni]
		var t := float(np) / SAMPLE_RATE
		var env := 1.0 - float(np) / spn
		env *= env
		var s := sin(t * freq * TAU) * env * vol
		var si := clampi(int(s * 32767), -32768, 32767)
		data[i * 2] = si & 0xFF
		data[i * 2 + 1] = (si >> 8) & 0xFF
	audio.data = data
	return audio

# ---- Procedural emo punk background music (3 intensity layers) ----

func _generate_music() -> void:
	# Generate 3 layers: calm (bass+hats), mid (+ guitar + kick/snare), intense (+ double-time + lead)
	var configs = [
		{"bpm": 140.0, "guitar": 0.0, "bass": 0.16, "kick": 0.0, "snare": 0.0, "hat": 0.08, "lead": 0.0},
		{"bpm": 170.0, "guitar": 0.22, "bass": 0.18, "kick": 0.35, "snare": 0.28, "hat": 0.10, "lead": 0.0},
		{"bpm": 190.0, "guitar": 0.28, "bass": 0.22, "kick": 0.40, "snare": 0.32, "hat": 0.12, "lead": 0.15},
	]

	for cfg in configs:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -60.0
		add_child(player)
		player.stream = _build_music_layer(cfg)
		_music_layers.append(player)

func _build_music_layer(cfg: Dictionary) -> AudioStreamWAV:
	var bpm: float = cfg["bpm"]
	var beat_dur := 60.0 / bpm
	var beats := 32
	var spb := int(SAMPLE_RATE * beat_dur)
	var total_samples := spb * beats
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var chord_roots := [220.0, 261.63, 196.0, 174.61]
	var beats_per_chord := 8
	var guitar_phase := 0.0
	var guitar_phase2 := 0.0
	var guitar_phase3 := 0.0
	var bass_phase := 0.0
	var lead_phase := 0.0

	# Lead melody pattern (scale degrees over chord, one per beat)
	var lead_intervals := [0.0, 4.0/3.0, 5.0/4.0, 3.0/2.0, 4.0/3.0, 5.0/4.0, 1.0, 3.0/2.0]

	for i in range(total_samples):
		var beat_idx := i / spb
		var chord_idx := (beat_idx / beats_per_chord) % chord_roots.size()
		var root: float = chord_roots[chord_idx]
		var fifth: float = root * 1.5
		var sample_in_beat := i % spb
		var beat_frac := float(sample_in_beat) / spb
		var mix := 0.0

		# -- Distorted power chord guitar --
		if cfg["guitar"] > 0.0:
			guitar_phase += root / SAMPLE_RATE
			guitar_phase2 += fifth / SAMPLE_RATE
			guitar_phase3 += (root * 1.003) / SAMPLE_RATE
			var gtr := 0.0
			gtr += 1.0 if fmod(guitar_phase, 1.0) < 0.5 else -1.0
			gtr += 0.7 * (1.0 if fmod(guitar_phase2, 1.0) < 0.5 else -1.0)
			gtr += 0.3 * (1.0 if fmod(guitar_phase3, 1.0) < 0.5 else -1.0)
			gtr = clampf(gtr * 0.8, -1.0, 1.0)
			var eighth := fmod(beat_frac * 2.0, 1.0)
			var strum_env := 1.0 - eighth * 0.6
			if fmod(beat_frac * 2.0, 2.0) >= 1.0:
				strum_env *= 0.7
			mix += gtr * strum_env * cfg["guitar"]

		# -- Bass --
		if cfg["bass"] > 0.0:
			bass_phase += (root * 0.5) / SAMPLE_RATE
			var bass := 1.0 if fmod(bass_phase, 1.0) < 0.35 else -1.0
			var eighth_b := fmod(beat_frac * 2.0, 1.0)
			var bass_env := 1.0 - eighth_b * 0.4
			mix += bass * bass_env * cfg["bass"]

		# -- Kick --
		if cfg["kick"] > 0.0 and beat_idx % 2 == 0:
			var kick_t := float(sample_in_beat) / SAMPLE_RATE
			if kick_t < 0.15:
				var kick_freq := 150.0 - kick_t * 700.0
				var kick_env := (1.0 - kick_t / 0.15)
				kick_env *= kick_env
				mix += sin(kick_t * kick_freq * TAU) * kick_env * cfg["kick"]

		# -- Snare --
		if cfg["snare"] > 0.0 and beat_idx % 2 == 1:
			var snare_t := float(sample_in_beat) / SAMPLE_RATE
			if snare_t < 0.1:
				var snare_env := (1.0 - snare_t / 0.1)
				snare_env *= snare_env
				var noise := fmod(sin(snare_t * 13003.1 + snare_t * snare_t * 400000.0) * 43758.5453, 2.0) - 1.0
				mix += (noise * 0.6 + sin(snare_t * 200.0 * TAU) * 0.4) * snare_env * cfg["snare"]

		# -- Hi-hat --
		if cfg["hat"] > 0.0:
			for h in range(2):
				var hat_start := int(h * spb * 0.5)
				var hat_sample := sample_in_beat - hat_start
				if hat_sample >= 0 and hat_sample < int(SAMPLE_RATE * 0.03):
					var hat_t := float(hat_sample) / SAMPLE_RATE
					var hat_env := (1.0 - hat_t / 0.03) * (1.0 - hat_t / 0.03)
					var hat_noise := fmod(sin(hat_t * 29101.7 + hat_t * hat_t * 900000.0) * 43758.5453, 2.0) - 1.0
					var hat_vol: float = cfg["hat"] if h == 0 else cfg["hat"] * 0.6
					mix += hat_noise * hat_env * hat_vol

		# -- Lead melody (intense layer only) --
		if cfg["lead"] > 0.0:
			var melody_idx := beat_idx % lead_intervals.size()
			var lead_freq: float = root * 2.0 * float(lead_intervals[melody_idx])
			lead_phase += lead_freq / SAMPLE_RATE
			var lead_env := 1.0 - beat_frac
			lead_env *= lead_env
			var lead_s: float = sin(lead_phase * TAU) * lead_env * float(cfg["lead"])
			mix += lead_s

		mix = clampf(mix, -0.95, 0.95)
		var si := clampi(int(mix * 32767), -32768, 32767)
		data[i * 2] = si & 0xFF
		data[i * 2 + 1] = (si >> 8) & 0xFF

	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = SAMPLE_RATE
	audio.stereo = false
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.loop_begin = 0
	audio.loop_end = total_samples
	audio.data = data
	return audio
