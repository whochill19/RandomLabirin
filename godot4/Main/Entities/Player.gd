extends "Actor.gd"


const TIME_DEATH := 0.2

@onready var danger_detector: Area2D = $DangerDetector
@onready var finish_detector: Area2D = $FinishDetector

func _on_DangerDetector_body_entered(_body: Node) -> void:
	set_physics_process(false)

	# 1. Panggil HUD Game Over langsung saat kena musuh
	var hud = get_tree().get_root().find_child("GameHud", true, false)
	if hud:
		hud.tampilkan_game_over()

	# 2. Jalankan animasi mati seperti biasa
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, TIME_DEATH)
	tween.tween_callback(queue_free)

func _on_finish_detector_body_entered(body: Node2D) -> void:
	var is_entering_door := false
	# Cek apakah yang ditabrak adalah pintu DAN pastikan animasi belum berjalan
	if body.name == "TileMapFinish" and not is_entering_door:
		is_entering_door = true # Kunci agar trigger tidak terpanggil berkali-kali
		print("Player mendeteksi pintu finish! Memulai animasi masuk...")

		# 1. Hentikan input dan gravitasi Player agar tidak bisa jalan-jalan saat animasi
		set_physics_process(false)

		# (Opsional) Jika kamu punya animasi lari/jalan, ubah ke animasi "idle" di sini
		# $AnimationPlayer.play("idle") atau $AnimatedSprite2D.play("idle")

		# 2. Buat objek Tween baru
		var tween = create_tween()

		# 3. Animasi 1: Menyusut menjadi debu (Scale X dan Y menjadi 0) dalam 0.5 detik
		# set_trans(Tween.TRANS_BACK) dan set_ease(Tween.EASE_IN) memberi efek tersedot ke dalam
		tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

		# 4. Animasi 2: Memudar (Alpha / Transparansi menjadi 0) berjalan bersamaan (parallel)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)

		# 5. TUNGGU sampai animasi Tween ini benar-benar selesai!
		await tween.finished

		# 6. Gunakan fitur "Group" Godot untuk berteriak ke PSOSearch
		get_tree().call_group("mandor_pso", "level_berhasil_diselesaikan")

		# 7. Terakhir, hapus player dengan tenang
		queue_free()

func _physics_process(_delta: float) -> void:
	if not is_on_floor():
		velocity.y += 3500 * _delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -speed.y

	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed.x
	else:
		velocity.x = move_toward(velocity.x, 0, speed.x)
	move_and_slide()

	#if Input.is_action_just_pressed("ui_cancel"):
		#get_tree().quit()
