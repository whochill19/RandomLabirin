extends Control

# Sinyal untuk melapor ke MainHub
signal kembali_ke_menu

# Sambungkan node KembalIButton ke fungsi ini via panel Signals di Godot!
func _on_kembali_button_pressed() -> void:
	kembali_ke_menu.emit()
