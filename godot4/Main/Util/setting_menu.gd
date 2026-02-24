extends Control

signal kembali_ke_menu

# Referensi Slider PSO
@onready var slider_w = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/SliderW
@onready var label_w = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/LabelW

@onready var slider_c1 = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/SliderC1
@onready var label_c1 = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/LabelC1

@onready var slider_c2 = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/SliderC2
@onready var label_c2 = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/LabelC2

# Referensi Slider Partikel & Iterasi
@onready var slider_partikel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/SliderPartikel
@onready var label_partikel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/LabelPartikel

@onready var slider_iterasi = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/SliderIterasi
@onready var label_iterasi = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ParameterPSO/LabelIterasi

func _ready() -> void:
	# Sinkronisasi nilai slider dengan data di Global
	slider_w.value = Global.pso_w
	slider_c1.value = Global.pso_c1
	slider_c2.value = Global.pso_c2
	slider_partikel.value = Global.pso_partikel
	slider_iterasi.value = Global.pso_iterasi

	_update_labels()

func _update_labels() -> void:
	label_w.text = "Bobot Inersia (w): " + str(slider_w.value)
	label_c1.text = "Kognitif (c1): " + str(slider_c1.value)
	label_c2.text = "Sosial (c2): " + str(slider_c2.value)
	label_partikel.text = "Jumlah Partikel: " + str(slider_partikel.value)
	label_iterasi.text = "Jumlah Iterasi: " + str(slider_iterasi.value)

# ==========================================
# SINYAL DARI SLIDER (Pastikan sudah di-connect di Godot!)
# ==========================================
func _on_slider_w_value_changed(value: float) -> void:
	Global.pso_w = value; _update_labels()

func _on_slider_c1_value_changed(value: float) -> void:
	Global.pso_c1 = value; _update_labels()

func _on_slider_c2_value_changed(value: float) -> void:
	Global.pso_c2 = value; _update_labels()

func _on_slider_partikel_value_changed(value: float) -> void:
	Global.pso_partikel = int(value); _update_labels()

func _on_slider_iterasi_value_changed(value: float) -> void:
	Global.pso_iterasi = int(value); _update_labels()

# ==========================================
# TOMBOL LAINNYA
# ==========================================
func _on_kembali_button_pressed() -> void:
	kembali_ke_menu.emit()

func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
