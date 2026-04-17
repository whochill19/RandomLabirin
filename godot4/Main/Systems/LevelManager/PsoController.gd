extends Node

@export var generator_path : NodePath

var iterasi_maksimal := 10
var jumlah_partikel := 5

var iterasi_sekarang := 0
var skor_terbaik_global := -999.0
var seed_terbaik_global := 0
var musuh_terbaik_global := 0.0
var kesulitan_sekarang: Global.TingkatKesulitan

# Variabel khusus Testing
var nomor_skenario_uji := 1
var ukuran_grid_sekarang : Vector2

var kawanan_partikel = []
var data_log_csv := ""
var folder_sesi_ini : String = ""

var seluruh_dungeon_data := {} # Dictionary untuk menyimpan {seed: path_koordinat}

signal pso_selesai

@onready var generator = get_node(generator_path)

func _ready():
	# Dikosongkan karena PsoTester akan dikendalikan manual oleh TestWorld.gd
	siapkan_folder_pengujian()
	pass

# ==========================================
# PENGATURAN 12 SKENARIO UJI
# ==========================================
func atur_parameter_pso():
	jumlah_partikel = 5
	iterasi_maksimal = 10

	match nomor_skenario_uji:
		1: kesulitan_sekarang = Global.TingkatKesulitan.EASY; ukuran_grid_sekarang = Vector2(5, 5)
		2: kesulitan_sekarang = Global.TingkatKesulitan.EASY; ukuran_grid_sekarang = Vector2(8, 6)
		3: kesulitan_sekarang = Global.TingkatKesulitan.EASY; ukuran_grid_sekarang = Vector2(12, 10)
		4: kesulitan_sekarang = Global.TingkatKesulitan.EASY; ukuran_grid_sekarang = Vector2(16, 14)
		5: kesulitan_sekarang = Global.TingkatKesulitan.MEDIUM; ukuran_grid_sekarang = Vector2(5, 5)
		6: kesulitan_sekarang = Global.TingkatKesulitan.MEDIUM; ukuran_grid_sekarang = Vector2(8, 6)
		7: kesulitan_sekarang = Global.TingkatKesulitan.MEDIUM; ukuran_grid_sekarang = Vector2(12, 10)
		8: kesulitan_sekarang = Global.TingkatKesulitan.MEDIUM; ukuran_grid_sekarang = Vector2(16, 14)
		9: kesulitan_sekarang = Global.TingkatKesulitan.HARD; ukuran_grid_sekarang = Vector2(5, 5)
		10: kesulitan_sekarang = Global.TingkatKesulitan.HARD; ukuran_grid_sekarang = Vector2(8, 6)
		11: kesulitan_sekarang = Global.TingkatKesulitan.HARD; ukuran_grid_sekarang = Vector2(12, 10)
		12: kesulitan_sekarang = Global.TingkatKesulitan.HARD; ukuran_grid_sekarang = Vector2(16, 14)

	generator.grid_size = ukuran_grid_sekarang

func inisialisasi_partikel():
	kawanan_partikel.clear()
	skor_terbaik_global = -999.0
	seed_terbaik_global = 0
	musuh_terbaik_global = 0.0

	# Header CSV ditambahkan Kolom Skenario dan Ukuran Grid
	data_log_csv = "Skenario,Grid_X,Grid_Y,Kesulitan,Iterasi,Partikel_ID,Seed,Peluang_Musuh,Skor_Fitness,Global_Best,Solvable\n"

	for i in range(jumlah_partikel):
		var partikel = {
			"id": i + 1,
			"seed": randi() % 100000,
			"v_seed": 0.0,
			"pbest_seed": 0,
			"peluang_musuh": randf(),
			"v_musuh": 0.0,
			"pbest_musuh": 0.0,
			"pbest_skor": -999.0
		}
		kawanan_partikel.append(partikel)

func mulai_pencarian():
	atur_parameter_pso()
	var nama_kesulitan = Global.TingkatKesulitan.keys()[kesulitan_sekarang]

	print("\n==================================================")
	print("🚀 MEMULAI UJI SKENARIO ", nomor_skenario_uji, " | KESULITAN: ", nama_kesulitan, " | GRID: ", ukuran_grid_sekarang)
	print("==================================================")

	inisialisasi_partikel()

	var w = Global.pso_w
	var c1 = Global.pso_c1
	var c2 = Global.pso_c2

	# PERCEPAT ANIMASI GENERATOR AGAR TESTING CEPAT SELESAI
	generator.get_node("Timer").wait_time = 0.001

	for iter in range(iterasi_maksimal):
		iterasi_sekarang = iter + 1

		for partikel in kawanan_partikel:
			generator.enemy_spawn_chance = partikel.peluang_musuh
			generator.generate_level(partikel.seed)
			await generator.level_completed

			var data_map = generator.get_path_data()
			var skor = hitung_fitness_berdasarkan_kesulitan(data_map, partikel.peluang_musuh)

			# ==========================================
			# CEK STATUS SOLVABLE (Apakah jalan sampai finish?)
			# ==========================================
			#var is_solvable = false
			#if data_map.size() > 0:
				#var ruangan_terakhir = data_map.back()
				## Cek apakah posisi Y ruangan terakhir mencapai baris paling bawah grid
				#if ruangan_terakhir.offset.y >= (ukuran_grid_sekarang.y - 1):
					#is_solvable = true
#
			#var is_solvable_end = "TRUE" if is_solvable else "FALSE"

			var is_solvable = await generator.generate_level(partikel.seed)
			if data_map.size() > 0:
				var ruangan_terakhir = data_map.back()

				# 1. Cek apakah mencapai dasar (Logic lama)
				var mencapai_finish = ruangan_terakhir.offset.y >= (ukuran_grid_sekarang.y - 1)

				# 2. Cek apakah jumlah ruangan logis (contoh: minimal ada 3 ruangan untuk bisa sampai bawah)
				var jumlah_ruangan_cukup = data_map.size() >= ukuran_grid_sekarang.y

				# Gabungkan logika
				if mencapai_finish and jumlah_ruangan_cukup and skor >= 30:
					is_solvable = true

			var is_solvable_end = "TRUE" if is_solvable else "FALSE"

			# --- UPDATE PBEST & GBEST ---
			if skor > partikel.pbest_skor:
				partikel.pbest_skor = skor
				partikel.pbest_seed = partikel.seed
				partikel.pbest_musuh = partikel.peluang_musuh

			if skor > skor_terbaik_global:
				skor_terbaik_global = skor
				seed_terbaik_global = partikel.seed
				musuh_terbaik_global = partikel.peluang_musuh

			# Rekam Data ke CSV (Tambahkan parameter is_solvable di akhir)
			var grid_x = ukuran_grid_sekarang.x
			var grid_y = ukuran_grid_sekarang.y

			# Tambahkan %s di akhir format string, dan is_solvable di dalam array
			data_log_csv += "Uji_%d,%d,%d,%s,%d,%d,%d,%.2f,%.1f,%.1f,%s\n" % [
				nomor_skenario_uji, grid_x, grid_y, nama_kesulitan,
				iterasi_sekarang, partikel.id, partikel.seed,
				partikel.peluang_musuh, skor, skor_terbaik_global, is_solvable_end
			]

			var koordinat_sederhana = []
			for ruangan in data_map:
				koordinat_sederhana.append({"x": ruangan.offset.x, "y": ruangan.offset.y})

			seluruh_dungeon_data[str(partikel.seed)] = {
				"skenario": nomor_skenario_uji,
				"kesulitan": nama_kesulitan,
				"grid_size": {"x": grid_x, "y": grid_y},
				"path": koordinat_sederhana,
				"fitness": skor
			}

			await generator.get_node("Timer").timeout
			generator.clear_map()

		# --- UPDATE PSO POSITION & VELOCITY ---
		for partikel in kawanan_partikel:
			var r1 = randf()
			var r2 = randf()
			# Update Seed
			partikel.v_seed = (w * partikel.v_seed) + (c1 * r1 * (partikel.pbest_seed - partikel.seed)) + (c2 * r2 * (seed_terbaik_global - partikel.seed))
			partikel.seed = abs(partikel.seed + int(partikel.v_seed))

			# Update Musuh
			partikel.v_musuh = (w * partikel.v_musuh) + (c1 * r1 * (partikel.pbest_musuh - partikel.peluang_musuh)) + (c2 * r2 * (musuh_terbaik_global - partikel.peluang_musuh))
			partikel.peluang_musuh = clamp(partikel.peluang_musuh + partikel.v_musuh, 0.0, 1.0)

	simpan_log_ke_file()
	simpan_koleksi_dungeon()

	# Visualisasi hasil terbaik
	generator.get_node("Timer").wait_time = 0.001
	generator.enemy_spawn_chance = musuh_terbaik_global
	generator.generate_level(seed_terbaik_global)
	await generator.level_completed
	pso_selesai.emit()

#func hitung_fitness_berdasarkan_kesulitan(path_data: Array, peluang_musuh: float) -> float:
	#var target_panjang := 0
	#var target_musuh := 0.0
	#var skor = 100.0
#
	#var panjang_jalur = path_data.size()
#
	#match kesulitan_sekarang:
		#Global.TingkatKesulitan.EASY: target_panjang = 4; target_musuh = 0.2
		#Global.TingkatKesulitan.MEDIUM: target_panjang = 8; target_musuh = 0.5
		#Global.TingkatKesulitan.HARD: target_panjang = 14; target_musuh = 1.0
		#Global.TingkatKesulitan.EXTREME: target_panjang = 28; target_musuh = 1.0
#
	#var selisih_panjang = abs(panjang_jalur - target_panjang)
	#skor -= (selisih_panjang * 5.0)
#
	#var selisih_musuh = abs(peluang_musuh - target_musuh)
	#skor -= (selisih_musuh * 50.0)
#
	#var jumlah_belokan = 0
	#if panjang_jalur > 2:
		#for i in range(2, panjang_jalur):
			#var arah_sebelumnya = path_data[i-1].offset - path_data[i-2].offset
			#var arah_sekarang = path_data[i].offset - path_data[i-1].offset
			#if arah_sebelumnya != arah_sekarang:
				#jumlah_belokan += 1
#
	#skor += (jumlah_belokan * 2.0)
	#return clamp(skor, 0.0, 100.0)

func hitung_fitness_berdasarkan_kesulitan(path_data: Array, peluang_musuh: float) -> float:
	var panjang_jalur = path_data.size()
	if panjang_jalur == 0: return 1.0 # Keamanan jika dungeon gagal generate

	# 1. Target Panjang yang Dinamis (PENTING!)
	# Daripada angka statis (4, 8, 14), gunakan keliling grid sebagai acuan
	var dimensi_grid = ukuran_grid_sekarang.x + ukuran_grid_sekarang.y
	var target_panjang := 0.0
	var target_musuh := 0.0

	match kesulitan_sekarang:
		Global.TingkatKesulitan.EASY:
			target_panjang = dimensi_grid * 0.6  # Contoh: Grid 16x14 targetnya ~12 sel
			target_musuh = 0.3
		Global.TingkatKesulitan.MEDIUM:
			target_panjang = dimensi_grid * 1.2
			target_musuh = 0.6
		Global.TingkatKesulitan.HARD:
			target_panjang = dimensi_grid * 1.8
			target_musuh = 0.9

	# 2. Perhitungan Skor Tanpa Penalti "Mematikan"
	# Gunakan sistem persentase (0.0 - 1.0) agar skor tidak langsung drop ke 1.0

	# Skor Progresi Vertikal (30% bobot)
	var y_terjauh = 0
	for titik in path_data:
		if titik.offset.y > y_terjauh: y_terjauh = titik.offset.y
	var skor_progres = (float(y_terjauh) / (ukuran_grid_sekarang.y - 1)) * 30.0

	# Skor Panjang Jalur (40% bobot) - Menggunakan Normalisasi
	# Semakin dekat ke target, semakin dekat ke 40 poin
	var selisih_panjang = abs(panjang_jalur - target_panjang)
	var skor_panjang = max(0, 40.0 - (selisih_panjang * 2.0))

	# Skor Musuh (30% bobot)
	var selisih_musuh = abs(peluang_musuh - target_musuh)
	var skor_musuh = max(0, 30.0 - (selisih_musuh * 100.0))

	var total_skor = skor_progres + skor_panjang + skor_musuh

	return clamp(total_skor, 1.0, 100.0)

func siapkan_folder_pengujian() -> void:
	var waktu_sekarang = Time.get_datetime_string_from_system().replace(":", "-")
	folder_sesi_ini = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("hasil pso").path_join(waktu_sekarang)
	if not DirAccess.dir_exists_absolute(folder_sesi_ini):
		DirAccess.make_dir_recursive_absolute(folder_sesi_ini)

func simpan_log_ke_file() -> void:
	var nama_kesulitan = Global.TingkatKesulitan.keys()[kesulitan_sekarang]
	var path_lengkap = folder_sesi_ini.path_join("uji_%d_%s.csv" % [nomor_skenario_uji, nama_kesulitan])
	var file = FileAccess.open(path_lengkap, FileAccess.WRITE)
	if file:
		file.store_string(data_log_csv)
		file.close()

func simpan_koleksi_dungeon():
	var path_file = folder_sesi_ini.path_join("daftar_dungeon_per_seed.json")
	var file = FileAccess.open(path_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(seluruh_dungeon_data, "\t"))
		file.close()
