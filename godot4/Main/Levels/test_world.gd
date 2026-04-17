extends Node2D

@onready var pso_tester = $PsoTesterNode

var skenario_sekarang = 1
var maksimal_skenario = 12

func _ready():
	print("==================================================")
	print("🛠️ MEMULAI PENGUJIAN OTOMATIS (12 SKENARIO)")
	print("==================================================")

	pso_tester.pso_selesai.connect(_on_pso_selesai)

	await get_tree().create_timer(1.0).timeout
	jalankan_skenario()

func jalankan_skenario():
	if skenario_sekarang > maksimal_skenario:
		print("\n==================================================")
		print("🎉 SEMUA 12 SKENARIO PENGUJIAN TELAH SELESAI! 🎉")
		print("📁 Silakan cek folder Documents/hasil pso/")
		print("==================================================")
		return

	# Setel nomor skenario
	pso_tester.nomor_skenario_uji = skenario_sekarang
	# Jalankan PSO khusus testing
	pso_tester.mulai_pencarian()

func _on_pso_selesai():
	print("✅ Uji Skenario ", skenario_sekarang, " Selesai didata!")
	skenario_sekarang += 1

	# Beri jeda 2 detik untuk bernapas & lihat hasil sebelum lanjut
	await get_tree().create_timer(2.0).timeout
	jalankan_skenario()
