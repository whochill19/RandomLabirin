extends CanvasLayer

# ==========================================
# REFERENSI NODE UI
# ==========================================
@onready var info_label = $Control/BottomRightMargin/DebugLabel
@onready var loading_screen = $Control/LoadingScreen
@onready var loading_bar = $Control/LoadingScreen/VBoxContainer/LoadingBar

@onready var game_over_screen = $Control/GameOverScreen
@onready var restart_button = $Control/GameOverScreen/VBoxContainer/RestartButton
@onready var menu_button = $Control/GameOverScreen/VBoxContainer/MenuButton

# --- BARU: REFERENSI PAUSE MENU ---
@onready var pause_menu = $Control/PauseMenu

var evaluasi_saat_ini := 0
var pso_manager: Node
var sedang_loading := true

func _ready() -> void:
	# BARIS SAKTI: Membuat HUD tetap berjalan meskipun game sedang di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	game_over_screen.hide()
	pause_menu.hide() # Sembunyikan pause menu di awal
	info_label.hide()

	loading_bar.value = 0
	info_label.text = "Menunggu PSO..."

	await get_tree().process_frame
	pso_manager = get_tree().get_first_node_in_group("mandor_pso")

	if pso_manager:
		pso_manager.pso_mulai.connect(_on_pso_mulai)
		pso_manager.pso_diupdate.connect(_on_pso_diupdate)
		pso_manager.pso_selesai.connect(_on_pso_selesai)

# ==========================================
# DETEKSI INPUT (TOMBOL KEYBOARD)
# ==========================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:

		# 1. TOMBOL 'H' UNTUK TOGGLE INFO HUD
		if event.keycode == KEY_H:
			if not sedang_loading:
				info_label.visible = !info_label.visible

		# 2. TOMBOL 'ESCAPE' UNTUK PAUSE MENU
		if event.keycode == KEY_ESCAPE:
			# Pastikan tidak bisa pause saat layar loading atau saat mati (Game Over)
			if not sedang_loading and not game_over_screen.visible:
				if get_tree().paused:
					lanjutkan_game()
				else:
					pause_game()

# ==========================================
# FUNGSI PAUSE & RESUME
# ==========================================
func pause_game() -> void:
	get_tree().paused = true # Hentikan semua proses di game
	pause_menu.show()        # Tampilkan layar pause

func lanjutkan_game() -> void:
	pause_menu.hide()        # Sembunyikan layar pause
	get_tree().paused = false# Lanjutkan jalannya game

# ==========================================
# SINYAL TOMBOL PAUSE MENU (Sambungkan di Editor!)
# ==========================================
func _on_resume_button_pressed() -> void:
	lanjutkan_game()

func _on_restart_pause_button_pressed() -> void:
	get_tree().paused = false # WAJIB di-unpause dulu sebelum restart!
	get_tree().reload_current_scene()

func _on_menu_pause_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main/Main.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit() # Langsung tutup jendela game (ke Desktop)


# ==========================================
# SAAT PSO MAU MULAI MENCARI (LAYAR LOADING)
# ==========================================
func _on_pso_mulai() -> void:
	sedang_loading = true
	loading_screen.show()
	loading_screen.modulate.a = 1.0

	info_label.show()
	info_label.modulate.a = 1.0
	info_label.get_parent().move_to_front()

	loading_bar.value = 0
	evaluasi_saat_ini = 0
	info_label.text = "Mempersiapkan Generasi Level..."

func _on_pso_diupdate(iterasi: int, iter_maks: int, skor: float, terbaik: float, seed_aktif: int) -> void:
	var max_partikel = pso_manager.jumlah_partikel
	var total_evaluasi_pso = iter_maks * max_partikel

	evaluasi_saat_ini += 1

	var partikel_sekarang = evaluasi_saat_ini % max_partikel
	if partikel_sekarang == 0:
		partikel_sekarang = max_partikel

	var teks = "ITERASI PSO: %d / %d\n" % [iterasi, iter_maks]
	teks += "Partikel: %d / %d\n" % [partikel_sekarang, max_partikel]
	teks += "Skor Partikel Terakhir: %.1f\n" % skor
	teks += "Skor Terbaik: %.1f\n" % terbaik
	teks += "Seed Saat Ini: %d" % seed_aktif
	info_label.text = teks

	var persentase = (float(evaluasi_saat_ini) / float(total_evaluasi_pso)) * 100.0
	var tween = create_tween()
	tween.tween_property(loading_bar, "value", persentase, 0.5).set_trans(Tween.TRANS_SINE)

func _on_pso_selesai() -> void:
	sedang_loading = false

	var tween = create_tween()
	tween.tween_property(loading_screen, "modulate:a", 0.0, 0.5)

	var nama_kesulitan = ""
	var target_jarak = 0

	match Global.kesulitan_terpilih:
		Global.TingkatKesulitan.EASY:
			nama_kesulitan = "EASY (Pemula)"
			target_jarak = 8
		Global.TingkatKesulitan.MEDIUM:
			nama_kesulitan = "MEDIUM (Standar)"
			target_jarak = 14
		Global.TingkatKesulitan.HARD:
			nama_kesulitan = "HARD (Menantang)"
			target_jarak = 20
		Global.TingkatKesulitan.EXTREME:
			nama_kesulitan = "EXTREME (Neraka)"
			target_jarak = 28

	info_label.text = "Kesulitan: " + nama_kesulitan + "\nTarget Jarak: " + str(target_jarak) + " Ruangan\n[Tekan 'H' untuk Sembunyikan]"

	await get_tree().create_timer(1.0).timeout
	loading_screen.hide()


# ==========================================
# GAME OVER SCREEN
# ==========================================
func tampilkan_game_over() -> void:
	game_over_screen.show()
	game_over_screen.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(game_over_screen, "modulate:a", 1.0, 0.5)

func _on_restart_button_pressed() -> void: # Ini untuk Restart di Game Over
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void: # Ini untuk Main Menu di Game Over
	get_tree().change_scene_to_file("res://Main/Main.tscn")
