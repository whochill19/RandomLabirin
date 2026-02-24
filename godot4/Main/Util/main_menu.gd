extends Control

# 1. BUAT SINYAL KUSTOM
signal buka_leaderboard
signal buka_setting

@onready var difficulty_dropdown = $MarginContainer/VBoxContainer/HBoxContainer/DifficultyDropdown

func _ready() -> void:
	difficulty_dropdown.clear()
	difficulty_dropdown.add_item("Easy (Pemula)")
	difficulty_dropdown.add_item("Medium (Standar)")
	difficulty_dropdown.add_item("Hard (Menantang)")
	difficulty_dropdown.add_item("Extreme (Neraka)")
	difficulty_dropdown.selected = Global.kesulitan_terpilih

# ==========================================
# FUNGSI TOMBOL
# ==========================================
func _on_play_button_pressed() -> void:
	Global.kesulitan_terpilih = difficulty_dropdown.selected as Global.TingkatKesulitan

	# PENTING: Karena Main.tscn sekarang adalah Menu, Play button harus
	# diarahkan ke scene gameplay kamu yang asli!
	get_tree().change_scene_to_file("res://Main/Systems/PCG/PCGGenerator.tscn")

func _on_leaderboard_button_pressed() -> void:
	# Teriakkan sinyal agar didengar oleh MainHub
	buka_leaderboard.emit()

func _on_setting_button_pressed() -> void:
	# Teriakkan sinyal agar didengar oleh MainHub
	buka_setting.emit()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
