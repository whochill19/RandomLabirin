extends Node

@export var iterasi_maksimal := 5
@export var jumlah_partikel := 5
@export var generator_path : NodePath

var iterasi_sekarang := 0
var skor_terbaik_global := -999.0
var seed_terbaik_global := 0
var musuh_terbaik_global := 0.0
var kesulitan_sekarang: Global.TingkatKesulitan

var kawanan_partikel = []
var data_log_csv := ""

signal pso_mulai
signal pso_selesai
signal pso_diupdate(iterasi, iter_maks, skor_sekarang, skor_terbaik, seed_aktif)

@onready var generator = get_node(generator_path)


func _ready():
	add_to_group("mandor_pso")

	kesulitan_sekarang = Global.kesulitan_terpilih

	if generator_path.is_empty() or generator == null: return
	if not generator.is_node_ready(): await generator.ready

	#await get_tree().create_timer(0.5).timeout
	await generator.get_node("Timer").timeout
	mulai_pencarian()

# # ==========================================
# MENGATUR JUMLAH PARTIKEL & ITERASI SESUAI KESULITAN
# ==========================================
func atur_parameter_pso():
	match kesulitan_sekarang:
		Global.TingkatKesulitan.EASY:
			iterasi_maksimal = 3
			jumlah_partikel = 3 # Ingat, minimal 3 agar seed bisa bergerak
			generator.grid_size = Vector2(5, 5) # Map kecil

		Global.TingkatKesulitan.MEDIUM:
			iterasi_maksimal = 5
			jumlah_partikel = 5
			generator.grid_size = Vector2(8, 6) # Map sedang

		Global.TingkatKesulitan.HARD:
			iterasi_maksimal = 7
			jumlah_partikel = 8
			generator.grid_size = Vector2(12, 10) # Map besar

		Global.TingkatKesulitan.EXTREME:
			iterasi_maksimal = 10
			jumlah_partikel = 10
			generator.grid_size = Vector2(16, 14) # Map raksasa (Labirin sejati!)

func inisialisasi_partikel():
	kawanan_partikel.clear()
	skor_terbaik_global = -999.0
	seed_terbaik_global = 0
	musuh_terbaik_global = 0.0

	# Tambahkan Kolom Kesulitan di Log CSV
	data_log_csv = "Kesulitan,Iterasi,Partikel_ID,Seed,Peluang_Musuh,Skor_Fitness,Global_Best\n"

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

#func mulai_pencarian():
	## 1. Atur parameter partikel dan iterasi berdasarkan kesulitan saat ini
	#atur_parameter_pso()
#
	## Cetak informasi ke console
	#var nama_kesulitan = Global.TingkatKesulitan.keys()[kesulitan_sekarang]
	#print("=== MEMULAI PSO 2D | KESULITAN: ", nama_kesulitan, " ===")
	#print("Target: ", iterasi_maksimal, " Iterasi x ", jumlah_partikel, " Partikel")
#
	## 2. Inisialisasi partikel sesuai jumlah yang baru diatur
	#inisialisasi_partikel()
#
	#var w = 0.5
	#var c1 = 1.5
	#var c2 = 1.5
#
	#for iter in range(iterasi_maksimal):
		#iterasi_sekarang = iter + 1
#
		#for partikel in kawanan_partikel:
			#generator.enemy_spawn_chance = partikel.peluang_musuh
			#generator.generate_level(partikel.seed)
			#await generator.level_completed
#
			#var data_map = generator.get_path_data()
			#var skor = hitung_fitness_berdasarkan_kesulitan(data_map, partikel.peluang_musuh)
#
			#if skor > partikel.pbest_skor:
				#partikel.pbest_skor = skor
				#partikel.pbest_seed = partikel.seed
				#partikel.pbest_musuh = partikel.peluang_musuh
#
			#if skor > skor_terbaik_global:
				#skor_terbaik_global = skor
				#seed_terbaik_global = partikel.seed
				#musuh_terbaik_global = partikel.peluang_musuh
#
			#data_log_csv += "%s,%d,%d,%d,%.2f,%.1f,%.1f\n" % [nama_kesulitan, iterasi_sekarang, partikel.id, partikel.seed, partikel.peluang_musuh, skor, skor_terbaik_global]
#
			#pso_diupdate.emit(iterasi_sekarang, iterasi_maksimal, skor, skor_terbaik_global, partikel.seed)
#
			#await get_tree().create_timer(0.001).timeout
			#generator.clear_map()
			#await get_tree().create_timer(0.15).timeout
#
		## Update Posisi PSO
		#for partikel in kawanan_partikel:
			#var r1 = randf()
			#var r2 = randf()
#
			#var kognitif_seed = c1 * r1 * (partikel.pbest_seed - partikel.seed)
			#var sosial_seed = c2 * r2 * (seed_terbaik_global - partikel.seed)
			#partikel.v_seed = (w * partikel.v_seed) + kognitif_seed + sosial_seed
			#partikel.seed = partikel.seed + int(partikel.v_seed)
			#if partikel.seed < 0: partikel.seed *= -1
#
			#var kognitif_musuh = c1 * r1 * (partikel.pbest_musuh - partikel.peluang_musuh)
			#var sosial_musuh = c2 * r2 * (musuh_terbaik_global - partikel.peluang_musuh)
			#partikel.v_musuh = (w * partikel.v_musuh) + kognitif_musuh + sosial_musuh
			#partikel.peluang_musuh = clamp(partikel.peluang_musuh + partikel.v_musuh, 0.0, 1.0)
#
	#print("\n=== PENCARIAN PSO SELESAI ===")
	#simpan_log_ke_file()
#
	#generator.enemy_spawn_chance = musuh_terbaik_global
	#generator.clear_map()
	#generator.generate_level(seed_terbaik_global)
	#await generator.level_completed
	#pso_selesai.emit()

func mulai_pencarian():
	pso_mulai.emit()
	# 1. Atur parameter partikel dan iterasi berdasarkan kesulitan saat ini
	atur_parameter_pso()

	# Cetak informasi ke console
	var nama_kesulitan = Global.TingkatKesulitan.keys()[kesulitan_sekarang]
	print("\n==================================================")
	print("🚀 MEMULAI PSO 2D | KESULITAN: ", nama_kesulitan)
	print("🎯 Target: ", iterasi_maksimal, " Iterasi x ", jumlah_partikel, " Partikel")
	print("==================================================")

	# 2. Inisialisasi partikel sesuai jumlah yang baru diatur
	inisialisasi_partikel()

	# ==========================================
	# AMBIL RUMUS DARI MENU SETTING (GLOBAL)
	# ==========================================
	var w = Global.pso_w
	var c1 = Global.pso_c1
	var c2 = Global.pso_c2

	for iter in range(iterasi_maksimal):
		iterasi_sekarang = iter + 1
		print("\n--------------------------------------------------")
		print("🔄 MULAI ITERASI ", iterasi_sekarang, " DARI ", iterasi_maksimal)
		print("--------------------------------------------------")

		for partikel in kawanan_partikel:
			# LOG: Partikel mulai bekerja
			print("  ▶ [Partikel ", partikel.id, "] Menguji Seed: ", partikel.seed, " | Musuh: ", round(partikel.peluang_musuh * 100), "%")

			generator.enemy_spawn_chance = partikel.peluang_musuh
			generator.generate_level(partikel.seed)
			await generator.level_completed

			var data_map = generator.get_path_data()
			var skor = hitung_fitness_berdasarkan_kesulitan(data_map, partikel.peluang_musuh)

			# LOG: Hasil dari partikel tersebut
			print("    ↳ Hasil -> Panjang Map: ", data_map.size(), " ruangan | Skor Fitness: ", snapped(skor, 0.1))

			if skor > partikel.pbest_skor:
				partikel.pbest_skor = skor
				partikel.pbest_seed = partikel.seed
				partikel.pbest_musuh = partikel.peluang_musuh

			if skor > skor_terbaik_global:
				skor_terbaik_global = skor
				seed_terbaik_global = partikel.seed
				musuh_terbaik_global = partikel.peluang_musuh
				# LOG: Jika ada pemecahan rekor tertinggi
				print("      🏆 REKOR GLOBAL BARU! Skor Tertinggi Sekarang: ", snapped(skor_terbaik_global, 0.1), " (Oleh Partikel ", partikel.id, ")")

			data_log_csv += "%s,%d,%d,%d,%.2f,%.1f,%.1f\n" % [nama_kesulitan, iterasi_sekarang, partikel.id, partikel.seed, partikel.peluang_musuh, skor, skor_terbaik_global]

			pso_diupdate.emit(iterasi_sekarang, iterasi_maksimal, skor, skor_terbaik_global, partikel.seed)

			await generator.get_node("Timer").timeout
			generator.clear_map()
			await generator.get_node("Timer").timeout

		# LOG: Memberitahu bahwa iterasi selesai dan partikel sedang berdiskusi
		print("  [🧠 Proses Belajar] Mengevaluasi hasil dan mengarahkan partikel untuk iterasi selanjutnya...")

		# Update Posisi PSO
		for partikel in kawanan_partikel:
			var r1 = randf()
			var r2 = randf()

			var kognitif_seed = c1 * r1 * (partikel.pbest_seed - partikel.seed)
			var sosial_seed = c2 * r2 * (seed_terbaik_global - partikel.seed)
			partikel.v_seed = (w * partikel.v_seed) + kognitif_seed + sosial_seed
			partikel.seed = partikel.seed + int(partikel.v_seed)
			if partikel.seed < 0: partikel.seed *= -1

			var kognitif_musuh = c1 * r1 * (partikel.pbest_musuh - partikel.peluang_musuh)
			var sosial_musuh = c2 * r2 * (musuh_terbaik_global - partikel.peluang_musuh)
			partikel.v_musuh = (w * partikel.v_musuh) + kognitif_musuh + sosial_musuh
			partikel.peluang_musuh = clamp(partikel.peluang_musuh + partikel.v_musuh, 0.0, 1.0)

	print("\n==================================================")
	print("✅ PENCARIAN PSO SELESAI")
	print("Membangun map final menggunakan rekor terbaik...")
	print("Seed Final: ", seed_terbaik_global, " | Skor Final: ", snapped(skor_terbaik_global, 0.1))
	print("==================================================")
	simpan_log_ke_file()

	generator.enemy_spawn_chance = musuh_terbaik_global
	generator.clear_map()
	generator.generate_level(seed_terbaik_global)
	await generator.level_completed
	await get_tree().create_timer(1.5).timeout
	pso_selesai.emit()


# ==========================================
# FUNGSI FITNESS TARGET BASE (BERDASARKAN KESULITAN)
# ==========================================
func hitung_fitness_berdasarkan_kesulitan(path_data: Array, peluang_musuh: float) -> float:
	var target_panjang := 0
	var target_musuh := 0.0
	var skor = 100.0 # Kita mulai dari 100, lalu dikurangi jika meleset dari target

	var panjang_jalur = path_data.size()


	# 1. TENTUKAN TARGET BERDASARKAN KESULITAN DARI GLOBAL
	match kesulitan_sekarang:
		Global.TingkatKesulitan.EASY:
			target_panjang = 4
			target_musuh = 0.2 # 20% Musuh
		Global.TingkatKesulitan.MEDIUM:
			target_panjang = 8
			target_musuh = 0.5 # 50% Musuh
		Global.TingkatKesulitan.HARD:
			target_panjang = 14
			target_musuh = 0.8 # 80% Musuh
		Global.TingkatKesulitan.EXTREME:
			target_panjang = 28
			target_musuh = 1.0 # 100% Musuh

	# 2. HITUNG PENALTI PANJANG JALUR (Meleset 1 ruangan = minus 5 poin)
	var selisih_panjang = abs(panjang_jalur - target_panjang)
	skor -= (selisih_panjang * 5.0)

	# 3. HITUNG PENALTI KEPADATAN MUSUH (Meleset 10% = minus 5 poin)
	var selisih_musuh = abs(peluang_musuh - target_musuh)
	skor -= (selisih_musuh * 50.0) # 0.1 selisih x 50 = 5 poin penalti

	# 4. KRITERIA BONUS KOMPLEKSITAS (Belokan)
	var jumlah_belokan = 0
	if panjang_jalur > 2:
		for i in range(2, panjang_jalur):
			var arah_sebelumnya = path_data[i-1].offset - path_data[i-2].offset
			var arah_sekarang = path_data[i].offset - path_data[i-1].offset
			if arah_sebelumnya != arah_sekarang:
				jumlah_belokan += 1

	# Tambahkan bonus poin untuk map yang berliku
	skor += (jumlah_belokan * 2.0)

	# 5. KUNCI SKOR
	return clamp(skor, 1.0, 100.0)


func simpan_log_ke_file() -> void:
	var folder_documents = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	var folder_pso = folder_documents + "/hasil pso"
	if not DirAccess.dir_exists_absolute(folder_pso):
		DirAccess.make_dir_absolute(folder_pso)

	var waktu_sekarang = Time.get_datetime_string_from_system().replace(":", "-")
	var nama_kesulitan = Global.TingkatKesulitan.keys()[kesulitan_sekarang]
	var nama_file = "hasil_pso_" + nama_kesulitan + "_" + waktu_sekarang + ".csv"
	var path_lengkap = folder_pso + "/" + nama_file
	var file = FileAccess.open(path_lengkap, FileAccess.WRITE)
	if file:
		file.store_string(data_log_csv)
		file.close()

func level_berhasil_diselesaikan() -> void:
	print("\n*** LEVEL SELESAI! Player memicu trigger. ***")

	# Naik level otomatis
	if kesulitan_sekarang == Global.TingkatKesulitan.EASY:
		kesulitan_sekarang = Global.TingkatKesulitan.MEDIUM
	elif kesulitan_sekarang == Global.TingkatKesulitan.MEDIUM:
		kesulitan_sekarang = Global.TingkatKesulitan.HARD
	elif kesulitan_sekarang == Global.TingkatKesulitan.HARD:
		kesulitan_sekarang = Global.TingkatKesulitan.EXTREME

	# Simpan perubahan ini ke Global (biar kalau mati / restart gak balik ke Easy)
	Global.kesulitan_terpilih = kesulitan_sekarang

	#await get_tree().create_timer(0.5).timeout
	mulai_pencarian()
