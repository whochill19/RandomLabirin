extends Node

@export var total_iterations := 5 # Berapa kali mau coba generate ulang
var current_iteration := 0
var best_score := -1.0
var best_path_data := []

@onready var generator = get_parent() # Asumsi PSO ini anak dari RandomWalker

func start_optimization():
	print("--- Memulai Optimasi PSO ---")
	current_iteration = 0
	best_score = -1.0
	_run_next_cycle()

func _run_next_cycle():
	if current_iteration < total_iterations:
		current_iteration += 1
		print("\n>>> Memulai Iterasi Ke-", current_iteration)

		# Perintahkan generator untuk reset dan buat baru
		generator.generate_level()
	else:
		print("\n--- OPTIMASI SELESAI ---")
		print("Skor Terbaik yang Ditemukan: ", best_score)
		# Di sini kamu bisa memanggil fungsi untuk mengunci level terbaik
