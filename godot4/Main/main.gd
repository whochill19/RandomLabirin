extends Control

# Referensi ke semua anak-anak menu
@onready var menu_utama = $MainMenu
@onready var leaderboard = $Leaderboard
@onready var setting_menu = $SettingMenu

func _ready() -> void:
	# Saat game baru dibuka, pastikan hanya Menu Utama yang terlihat
	tampilkan_menu_utama()

# ==========================================
# FUNGSI-FUNGSI TRANSISI MENU
# ==========================================
func sembunyikan_semua() -> void:
	menu_utama.hide()
	leaderboard.hide()
	setting_menu.hide()

func tampilkan_menu_utama() -> void:
	sembunyikan_semua()
	menu_utama.show()

func tampilkan_leaderboard() -> void:
	sembunyikan_semua()
	leaderboard.show()

func tampilkan_setting() -> void:
	sembunyikan_semua()
	setting_menu.show()
