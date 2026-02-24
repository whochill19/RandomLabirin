# Procedural level generator based checked tilemaps and a random walker algorithm. It uses chunks or
# rooms designed by hand. See [Rooms.gd].
#
# The generator walks semi-randomly around a grid to draw an unobstructed path from the level's
# start to its end. It then fills up the remaining cells with random rooms. It also randomizes the
# rooms.
extends Node2D

signal path_completed
signal side_rooms_completed # Signal baru
signal level_completed(player_position)
signal player_reached_finish # Tambahkan signal ini di baris atas

# Array of directions towards which the algorithm can move. Controls the base frequency of
# directions, although some rules may override that. See [_update_next_position].
const STEP := [Vector2.LEFT, Vector2.LEFT, Vector2.RIGHT, Vector2.RIGHT, Vector2.DOWN]

@export var Rooms : PackedScene = preload("res://Main/Systems/LevelChunk/RoomTemplates.tscn")
@export var grid_size := Vector2(16, 14)
#@export var max_steps: int = 10
#@export var room_density: float = 0.5

@export var enemy_spawn_chance: float = 0.6

var _rng := RandomNumberGenerator.new()
var _rooms: Node2D = null
var _player: CharacterBody2D = null
var _state := {}
var _horizontal_chance := 0.0
var _camera_limits := {}
var _resolution := DisplayServer.window_get_size()
var current_seed : int = 0

@onready var scene_tree: SceneTree = get_tree()
@onready var camera: Camera2D = $Camera2D
@onready var level_main: TileMap = $Level/TileMapMain
@onready var level_danger: TileMap = $Level/TileMapDanger
@onready var level_extra: Node2D = $Level/Extra
@onready var level_finish: TileMap = $Level/TileMapFinish
@onready var timer: Timer = $Timer
@onready var background: ParallaxBackground = $ParallaxBackground


func _ready() -> void:
	print("--- Memulai Inisialisasi Generator ---")
	_rooms = Rooms.instantiate()
	_horizontal_chance = 1.0 - STEP.count(Vector2.DOWN) / float(STEP.size())

	print("Horizontal Chance: ", _horizontal_chance)

	_camera_limits = {
		"min": level_main.map_to_local(-Vector2.ONE),
		"max": level_main.map_to_local(_grid_to_map(grid_size) + Vector2.ONE)
	}
	camera.setup(_resolution, _grid_to_world(grid_size))
	background.offset = _resolution / 2

	# === HAPUS 4 BARIS INI AGAR PSO BISA MENGAMBIL ALIH KONTROL PENUH ===
	# scene_tree.paused = true
	# generate_level()
	# await self.level_completed
	# scene_tree.paused = false


func _on_Camera2D_zoom_changed(zoom: Vector2) -> void:
	for n in background.get_children():
		n.modulate.a = zoom.x


func _on_Tween_tween_all_completed() -> void:
	# CEK DULU: Apakah player masih valid dan belum dihapus oleh PSO?
	if is_instance_valid(_player):
		_player.get_node("RemoteTransform2D").remote_path = camera.get_path()

	camera.limit_left = _camera_limits.min.x
	camera.limit_top = _camera_limits.min.y
	camera.limit_right = _camera_limits.max.x
	camera.limit_bottom = _camera_limits.max.y

# Generates a new level.
func generate_level(custom_seed: int = -1) -> void:
	# --- Atur Seed ---
	if custom_seed != -1:
		_rng.seed = custom_seed
	else:
		_rng.randomize()
	current_seed = _rng.seed

	# --- Reset dan Gambar ---
	_reset()
	_update_start_position()

	var safety_break = 0

	while _state.offset.y < grid_size.y:
		_update_room_type()
		_update_next_position()
		_update_down_counter()

		# --- REM DARURAT ---
		safety_break += 1
		if safety_break > 500: # Jika sudah jalan 500 langkah tapi belum sampai bawah
			push_error("ERROR: Walker terjebak dalam Infinite Loop! Memaksa berhenti.")
			break # Paksa keluar dari loop agar game tidak crash

	_place_walls()

	# Tunggu animasi menggambar selesai
	await _place_path_rooms()
	_place_side_rooms()

	# Letakkan pintu terakhir
	_place_door()

	# KUNCI UTAMA: Teriakkan signal "SELESAI" dan kirimkan posisi Player ke Kamera!
	if _player != null:
		level_completed.emit(_player.position)
	else:
		# Jaga-jaga agar tidak crash kalau player belum ter-spawn
		level_completed.emit(Vector2.ZERO)

# Pastikan fungsi ini ada untuk memberikan data ke PSO
func get_path_data() -> Array:
	return _state.path

# Resets the _state variable to its default values, and populates its `empty_cells` key with rooms
# to use.
func _reset() -> void:
	# Pastikan layar bersih sebelum mereset logika
	clear_map()

	_state = {
		"random_index": -1,
		"offset": Vector2.ZERO,
		"delta": Vector2.ZERO,
		"down_counter": 0,
		"path": [],
		"empty_cells": {}
	}
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			_state.empty_cells[Vector2(x, y)] = 0

# Fungsi khusus untuk menghapus semua visual di layar
func clear_map() -> void:
	if level_main != null: level_main.clear()
	if level_danger != null: level_danger.clear()
	if level_finish != null: level_finish.clear()

	if level_extra != null:
		for child in level_extra.get_children():
			child.queue_free()

	print("Layar dibersihkan!")

# Picks a random start position on the first row of the generation grid.
func _update_start_position() -> void:
	# warning-ignore:narrowing_conversion
	var x := _rng.randi_range(0, grid_size.x - 1)
	_state.offset = Vector2(x, 0)


# Picks the direction in which the generator should move to place the next room. This is
# semi-random: we pick a random direction only if that doesn't risk generating a broken path, and in
# such a way we prevent backtracking.
func _update_next_position() -> void:
	var old_pos = _state.offset
	# ... (logika pemilihan random_index tetap sama)
	_state.random_index = (
		_rng.randi_range(0, STEP.size() - 1)
		if _state.random_index < 0
		else _state.random_index
	)
	_state.delta = STEP[_state.random_index]

	var horizontal_chance := _rng.randf()
	if _state.delta.is_equal_approx(Vector2.LEFT):
		_state.random_index = (
			0
			if _state.offset.x > 1 and horizontal_chance < _horizontal_chance
			else 4
		)
	elif _state.delta.is_equal_approx(Vector2.RIGHT):
		_state.random_index = (
			2
			if _state.offset.x < grid_size.x - 1 and horizontal_chance < _horizontal_chance
			else 4
		)
	else:
		if _state.offset.x > 0 and _state.offset.x < grid_size.x - 1:
			_state.random_index = _rng.randi_range(0, 4)
		elif _state.offset.x == 0:
			_state.random_index = 2 if horizontal_chance < _horizontal_chance else 4
		elif _state.offset.x == grid_size.x - 1:
			_state.random_index = 0 if horizontal_chance < _horizontal_chance else 4

	_state.delta = STEP[_state.random_index]
	_state.offset += _state.delta
	print("Walker bergerak: ", old_pos, " -> ", _state.offset, " (Arah: ", _state.delta, ")")


# Increments the `down_counter` every time the random walker moves downward.
func _update_down_counter() -> void:
	_state.down_counter = (
		_state.down_counter + 1
		if _state.delta.is_equal_approx(Vector2.DOWN)
		else 0
	)


# Picks a room type to use on the cell the algorithm is currently visiting.
# Uses some rules to prevent the room from blocking the player.
#func _update_room_type() -> void:
	#if not _state.path.is_empty():
		#var last: Dictionary = _state.path.back()
		#if last.type in _rooms.BOTTOM_CLOSED and _state.delta.is_equal_approx(Vector2.DOWN):
			#print("Koreksi: Ruangan sebelumnya tertutup bawah, membuka akses ke bawah di pos: ", last.offset)
			## ... (logika koreksi tetap sama)
			#var index := _rng.randi_range(0, _rooms.BOTTOM_OPENED.size() - 1)
			#var type: int = (
				#_rooms.BOTTOM_OPENED[index]
				#if _state.down_counter < 2
				#else _rooms.Type.LRTB
			#)
			#_state.path[-1].type = type
#
	#var type: int = (
		#_rooms.Type.LRT
		#if _state.delta.is_equal_approx(Vector2.DOWN)
		#else _rng.randi_range(1, _rooms.Type.size() - 1)
	#)
#
	#_state.empty_cells.erase(_state.offset)
	#_state.path.push_back({"offset": _state.offset, "type": type, "start": _state.path.is_empty()})

func _update_room_type() -> void:
	# 1. KOREKSI JALUR KE BAWAH (Agar tidak buntu)
	if not _state.path.is_empty():
		var last: Dictionary = _state.path.back()
		if last.type in _rooms.BOTTOM_CLOSED and _state.delta.is_equal_approx(Vector2.DOWN):
			print("Koreksi: Membuka akses lantai ke bawah di pos: ", last.offset)
			var index := _rng.randi_range(0, _rooms.BOTTOM_OPENED.size() - 1)
			var corrected_type: int = (
				_rooms.BOTTOM_OPENED[index]
				if _state.down_counter < 2
				else _rooms.Type.LRTB
			)
			_state.path[-1].type = corrected_type

	# 2. PENENTUAN TIPE RUANGAN SAAT INI (Termasuk Ruangan EXIT)
	var is_last_row = (_state.offset.y >= grid_size.y - 1)
	var current_type: int

	if is_last_row:
		# Paksa menggunakan tipe EXIT yang sudah kamu buat di template
		current_type = _rooms.Type.EXIT
		print("LOG: Walker sampai di baris terakhir, menaruh Ruangan EXIT.")
	else:
		# Logika normal untuk ruangan di tengah path
		current_type = (
			_rooms.Type.LRT
			if _state.delta.is_equal_approx(Vector2.DOWN)
			else _rng.randi_range(1, _rooms.Type.size() - 2)
		)

	_state.empty_cells.erase(_state.offset)
	_state.path.push_back({
		"offset": _state.offset,
		"type": current_type,
		"start": _state.path.is_empty()
	})


func _place_walls(type: int = 0) -> void:
	var cell_grid_size := _grid_to_map(grid_size)

	for x in [-2, -1, cell_grid_size.x, cell_grid_size.x + 1]:
		for y in range(-2, cell_grid_size.y + 2):
			# need to add the atlas coords or nothing will happen
			level_main.set_cell(0, Vector2i(x, y), type, Vector2i(0,0))

	for x in range(-1, cell_grid_size.x + 2):
		for y in [-2, -1, cell_grid_size.y, cell_grid_size.y + 1]:
			level_main.set_cell(0, Vector2i(x, y), type, Vector2i.ZERO)


func _place_path_rooms() -> void:
	for path in _state.path:
		await timer.timeout
		print("Menggambar path room di: ", path.offset, " Tipe: ", path.type)
		_copy_room(path.offset, path.type, path.start)
	path_completed.emit()

func _place_side_rooms() -> void:
	#await self.path_completed
	print("Mengisi side rooms untuk ", _state.empty_cells.size(), " sel kosong.")
	for key in _state.empty_cells:
		var type := _rng.randi_range(0, _rooms.Type.size() - 1)
		_copy_room(key, type, false)

	var all_cells = level_main.get_used_cells(0)
	var terrain_cells = []
	for tc in all_cells:
		var cell_source_id = level_main.get_cell_source_id(0, tc)
		if cell_source_id == 0 or cell_source_id == 3:
			terrain_cells.push_back(tc)
	print("Menghubungkan terrain auto-tiling...")
	level_main.set_cells_terrain_connect(0, terrain_cells , 0, 0)
	side_rooms_completed.emit()

	# HAPUS BARIS DI BAWAH INI:
	 #level_completed.emit(_player.position)


func _copy_room(offset: Vector2, type: int, start: bool) -> void:
	var world_offset := _grid_to_world(offset)
	var map_offset := _grid_to_map(offset)
	var data: Dictionary = _rooms.get_room_data(type)
	for object in data.objects:
		if (not start and object.is_in_group("player")) or (start and object.is_in_group("enemy")):
			continue

		var new_object: Node2D = object.duplicate()
		new_object.position += world_offset
		level_extra.add_child(new_object)

		if start and new_object.is_in_group("player"):
			_player = new_object

	for d in data.tilemap:
		#if d.cell == _rooms.Cell.MAYBE_SPIKES:
			#continue # Lewati/Jangan gambar jika itu duri
		var tilemap := level_main if d.cell != _rooms.Cell.MAYBE_SPIKES else level_danger
		tilemap.set_cell(0, Vector2i(map_offset) + d.offset, d.target_id, d.atlas_coords)

func _place_door() -> void:
	if _state.path.is_empty(): return

	# 1. Ambil data ruangan terakhir
	var last_room = _state.path.back()

	# 2. Konversi posisi grid ruangan terakhir ke koordinat TileMap
	var map_offset = _grid_to_map(last_room.offset)

	# 3. Hitung posisi pintu secara manual di dalam ruangan tersebut
	# Kita ambil titik tengah (X) dan agak ke bawah (Y) supaya menempel di lantai
	var center_x = int(_rooms.room_size.x / 2)
	var floor_y = int(_rooms.room_size.y - 3) # -2 supaya tidak tertanam di tanah

	var door_tile_pos = Vector2i(map_offset) + Vector2i(center_x, floor_y)

	# 4. Gambar pintu merah di TileMapFinish
	level_finish.clear()
	level_finish.z_index = 5
	level_finish.set_cell(0, door_tile_pos, 11, Vector2i(0, 0)) # Sesuaikan atlas pintu merahmu

	# ==========================================
	# MEMBUAT AREA TRIGGER UNTUK PINDAH LEVEL
	# ==========================================
	var door_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()

	# Atur ukuran kotak tabrakan sama dengan ukuran 1 tile
	rect.size = _rooms.cell_size
	collision.shape = rect
	door_area.add_child(collision)

	# --- TAMBAHKAN DUA BARIS INI ---
	door_area.collision_layer = 0 # Pintu tidak perlu terdeteksi oleh musuh
	door_area.collision_mask = 1  # 1 adalah default layer Player. (Ubah jika layer playermu beda)

	# Letakkan Area2D persis di koordinat pintu (konversi dari map ke local pixel)
	door_area.position = level_finish.map_to_local(door_tile_pos)

	# Masukkan ke level_extra agar ikut bersih saat clear_map() dipanggil
	level_extra.add_child(door_area)

	# Hubungkan signal saat player menyentuh area ini
	door_area.body_entered.connect(_on_door_entered)

	print("LOG: Pintu merah & Area Trigger diletakkan di koordinat tile: ", door_tile_pos)

# Fungsi yang dipanggil saat ada benda yang masuk ke Area pintu
func _on_door_entered(body: Node2D) -> void:
	# BARIS INI WAJIB DITAMBAHKAN UNTUK CEK:
	print("LOG TRIGGER: Ada yang menyentuh pintu! Nama objek: ", body.name)

	# Pastikan tulisan "player" ini sama persis dengan yang ada di tab Groups
	if body.is_in_group("player"):
		print("Player mencapai garis finish!")
		body.queue_free()
		player_reached_finish.emit()
	else:
		print("Tapi objek ini BUKAN player (atau belum masuk group 'player').")

func _grid_to_map(vector: Vector2) -> Vector2:
	return _rooms.room_size * vector


func _grid_to_world(vector: Vector2) -> Vector2:
	return _rooms.cell_size * _rooms.room_size * vector
