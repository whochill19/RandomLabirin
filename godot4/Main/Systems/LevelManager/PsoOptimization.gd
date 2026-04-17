extends Node
class_name PSOManager

# Parameter PSO
@export var swarm_size := 5 # Berapa banyak alternatif level yang dibuat per iterasi
@export var iterations := 3 # Berapa kali swarm memperbaiki diri

var best_level_data = null
var best_global_score = -999.0

# Fungsi untuk mengevaluasi kualitas satu level utuh
func evaluate_level_fitness(path_data: Array) -> float:
	var score = 0.0

	# KRITERIA 1: Panjang Jalur (Misal: Kita ingin jalur yang panjangnya ideal, tidak terlalu pendek)
	var path_length = path_data.size()
	score += path_length * 2.0

	# KRITERIA 2: Kompleksitas (Berapa kali jalur berbelok)
	var turns = 0
	for i in range(1, path_data.size() - 1):
		if path_data[i].offset.x != path_data[i-1].offset.x:
			turns += 1
	score += turns * 5.0 # Semakin banyak belokan, skor makin tinggi (level menarik)

	return score

func get_best_iteration(generator_node) -> Dictionary:
	best_global_score = self.best_global_score
	var final_best_path = []

	for iter in range(iterations):
		print("PSO Iterasi ke-", iter)
		var local_best_path = []
		var local_best_score = -999.0

		for s in range(swarm_size):
			# Minta Random Walker buat satu draf jalur
			var current_path = generator_node.create_path_draft()
			var current_score = evaluate_level_fitness(current_path)

			if current_score > local_best_score:
				local_best_score = current_score
				local_best_path = current_path

		# Update Global Best
		if local_best_score > best_global_score:
			best_global_score = local_best_score
			final_best_path = local_best_path

	return {"path": final_best_path, "score": best_global_score}
