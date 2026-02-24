extends Node

enum TingkatKesulitan { EASY, MEDIUM, HARD, EXTREME }
var kesulitan_terpilih: TingkatKesulitan = TingkatKesulitan.EASY

# ==========================================
# PARAMETER PSO (Bisa diatur bebas di Settings)
# ==========================================
var pso_w: float = 0.5
var pso_c1: float = 1.5
var pso_c2: float = 1.5

# Default Partikel & Iterasi (misal 5)
var pso_partikel: int = 5
var pso_iterasi: int = 5
