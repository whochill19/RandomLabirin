extends "Actor.gd"

# Kita jadikan 300.0 sebagai patokan dasar (base speed)
var kecepatan_dasar: float = 300.0
var _inital_speed: float = 300.0
var _direction: float = 1.0

@onready var visibility_enabler: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D

func _ready() -> void:
	# ==========================================
	# 1. ADAPTASI KECEPATAN BERDASARKAN KESULITAN
	# ==========================================
	var pengali_kecepatan := 1.0

	match Global.kesulitan_terpilih:
		Global.TingkatKesulitan.EASY:
			pengali_kecepatan = 0.5 # Kecepatan turun jadi 150.0 (Santai)
		Global.TingkatKesulitan.MEDIUM:
			pengali_kecepatan = 1.0 # Kecepatan normal 300.0 (Standar)
		Global.TingkatKesulitan.HARD:
			pengali_kecepatan = 1.5 # Kecepatan naik jadi 450.0 (Agresif)
		Global.TingkatKesulitan.EXTREME:
			pengali_kecepatan = 2.2 # Kecepatan naik jadi 660.0 (Sangat Cepat!)

	# Timpa nilai _inital_speed dengan hasil perkaliannya
	_inital_speed = kecepatan_dasar * pengali_kecepatan

	# ==========================================
	# 2. KODE BAWAAN ORIGINAL
	# ==========================================
	visibility_enabler.screen_entered.connect(set_physics_process.bind(true))
	visibility_enabler.screen_exited.connect(set_physics_process.bind(false))
	set_physics_process(false)

	# velocity.x sekarang sudah memakai nilai _inital_speed yang baru!
	velocity.x = _inital_speed
	velocity.y = 0.0

func _physics_process(_delta: float) -> void:
	if is_on_wall():
		_direction *= -1

	velocity.x = _inital_speed * _direction

	if not is_on_floor():
		velocity.y += 3500 * _delta

	move_and_slide()
