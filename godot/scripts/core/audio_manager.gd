extends Node
## Autoloaded as "AudioManager". Procedural SFX for all game events.
## Generates simple waveform sounds at startup — no external audio files needed.

const SAMPLE_RATE := 22050
const POOL_SIZE := 10

var _players: Array[AudioStreamPlayer] = []
var _player_idx: int = 0
var _sfx: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	_generate_sounds()
	_connect_signals()

# ---- Signal wiring ----

func _connect_signals() -> void:
	GameEvents.damage_dealt.connect(_on_damage)
	GameEvents.enemy_killed.connect(func(_e): play("kill"))
	GameEvents.xp_gained.connect(func(_a): play("xp"))
	GameEvents.level_up.connect(func(_l): play("level_up"))
	GameEvents.item_acquired.connect(_on_item_acquired)
	GameEvents.wave_started.connect(func(_w): play("wave_start"))
	GameEvents.wave_completed.connect(func(_w): play("wave_complete"))
	GameEvents.boss_spawned.connect(func(_b): play("boss"))
	GameEvents.game_over.connect(func(): play("game_over"))
	GameEvents.game_started.connect(func(): play("game_start"))
	GameEvents.kill_streak_changed.connect(_on_streak)

func play(sfx_name: String, vol_db: float = 0.0) -> void:
	if not _sfx.has(sfx_name):
		return
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
