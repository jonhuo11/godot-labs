extends Node2D


@onready var pb_DO: ProgressBar = $pb_DO
@onready var pb_B: ProgressBar = $pb_B
@onready var pb_TAN: ProgressBar = $pb_TAN
@onready var pb_F: ProgressBar = $pb_F

@onready var lbl_ticks: Label = $lbl_ticks
@onready var lbl_sim_time: Label = $lbl_sim_time
@onready var lbl_stats: Label = $lbl_stats

# -----------------------------
# Simulation config
# -----------------------------
const TPS: float = 30.0 # ticks per second (Timer-driven)
const SIM_TIME_SCALE: float = 3600.0 * 24 # each tick = 1 hour of simulated time
const SECONDS_PER_HOUR := 3600.0
const SECONDS_PER_DAY := 86400.0

@onready var tick_timer: Timer = $TickTimer
var tick_count: int = 0
var sim_time_seconds: float = 0.0  # total simulated time in seconds
var recruitment_accumulator: float = 0.0  # fractional shrimp waiting to be born

# -----------------------------
# Tank state (units in comments)
# -----------------------------
var N: int = 400 # shrimp count (indiv)
var W: float = 2.0 # avg weight (g / indiv)
var B: float = N * W # biomass (g)
var F: float = 5000.0 # feed inventory (g)

var TAN: float = 0.10 # total ammonia nitrogen (mg/L)
var DO: float = 6.5 # dissolved oxygen (mg/L)

# -----------------------------
# Controls (can be edited by UI)
# -----------------------------
var A: float = 0.6 # aeration power [0..1]
var feed_cmd: float = 20.0 # feed offered this tick (g) - scaled for daily ticks

# -----------------------------
# Constants / parameters (tune)
# -----------------------------
const V: float = 5000.0 # tank volume (L)

# Growth & feeding (per-day)
const SGR: float = 0.035 # specific growth rate (/day)
const FR: float = 0.025 # max feed intake as fraction of biomass (/day)
const FCR: float = 1.5 # feed conversion ratio (g feed → g biomass)

# Ammonia generation & removal
const y_TAN: float = 0.03 # mg TAN per mg feed eaten (≈3% of feed nitrogen → TAN)
const k_nit: float = 0.10 # nitrification removal rate (/hour), simple lumped

# Oxygen dynamics
const DO_in_per_A: float = 0.8 # mg/L/h at A = 1.0 (aeration input)
const q_O2: float = 0.25 # mg O2 / (g biomass · h) shrimp respiration
const DO_sat: float = 7.5 # mg/L saturation ceiling
const DO_crit: float = 3.0 # mg/L mortality trigger

# Reproduction parameters
const W_maturity: float = 15.0 # weight threshold for reproduction (g) - mature at ~15g
const r_base: float = 0.015 # base recruitment rate (/day) - ~1.5% daily pop growth when optimal
const B_max: float = 20000.0 # max sustainable biomass (g) - ~4kg/m³ stocking density limit

func _ready() -> void:
	print("Tank _ready() called!")
	print("TickTimer found: ", tick_timer)
	# Timer is already a child via the scene; don't add_child() again.
	tick_timer.wait_time = 1.0 / TPS
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()
	print("Timer started with wait_time: ", tick_timer.wait_time)

func _on_tick() -> void:
	#print("tick!")
	# Fixed-step integration using the target wait_time, scaled by SIM_TIME_SCALE
	var dt_s: float = tick_timer.wait_time * SIM_TIME_SCALE
	var dt_hours: float = dt_s / SECONDS_PER_HOUR
	var dt_days: float = dt_s / SECONDS_PER_DAY

	_calc(dt_days, dt_hours)
	tick_count += 1
	sim_time_seconds += dt_s

	# update labels
	lbl_ticks.text = "Ticks: %d" % tick_count
	
	var sim_days: int = int(sim_time_seconds / SECONDS_PER_DAY)
	var sim_hours: int = int((sim_time_seconds - sim_days * SECONDS_PER_DAY) / SECONDS_PER_HOUR)
	lbl_sim_time.text = "Sim Time: %dd %dh" % [sim_days, sim_hours]
	
	# Calculate reproduction factors for display
	var maturity_factor: float = 0.0
	var density_factor: float = 0.0
	var feed_factor: float = 0.0
	if N > 0 and W > 0.0:
		maturity_factor = 1.0 / (1.0 + exp(-0.3 * (W - W_maturity)))
		density_factor = max(0.0, 1.0 - B / B_max)
		feed_factor = clamp(F / 500.0, 0.0, 1.0)
	
	lbl_stats.text = "N: %d\nW: %.2fg\nB: %.1fg\nF: %.1fg\nMat: %.1f%% Den: %.1f%%" % [N, W, B, F, maturity_factor * 100, density_factor * 100]

	# update progress bars
	pb_DO.value = (DO / DO_sat) * 100
	pb_B.value = ((B / 1000) / V) * 10000  # scale: 100% bar = 1% tank volume
	pb_TAN.value = (TAN / 2.0) * 100  # 0-2 mg/L range (safe levels)
	pb_F.value = (F / 5000.0) * 100  # initial feed inventory as max

func _calc(dt_days: float, dt_hours: float) -> void:
	# -----------------------------
	# Feeding & Growth
	# -----------------------------
	# Max shrimp can physically eat this tick (g):
	var FI_cap: float = FR * B * dt_days
	# Actual eaten feed (g) — Godot min() takes 2 args, so nest it:
	var FI: float = min(feed_cmd, min(FI_cap, F))
	F -= FI
	if F < 0.0:
		FI += F # reduce FI if we over-subtracted
		F = 0.0

	# Biomass gain limited by FCR and physiology:
	var dB_fcr: float = FI / FCR
	var dB_phys: float = B * SGR * dt_days
	var dB: float = min(dB_fcr, dB_phys)

	B += dB
	if N > 0:
		W = B / N
	else:
		W = 0.0

	# -----------------------------
	# TAN (mg/L)
	# -----------------------------
	# Feed eaten → TAN (convert g → mg with *1000):
	var TAN_gen: float = (y_TAN * 1000.0 * FI) / V # mg/L per tick
	var TAN_rem: float = (k_nit * TAN) * dt_hours # mg/L removed this tick
	TAN = max(TAN + TAN_gen - TAN_rem, 0.0)

	# -----------------------------
	# DO (mg/L)
	# -----------------------------
	var O2_in: float = (DO_in_per_A * A) * dt_hours # mg/L added
	var O2_out: float = (q_O2 * B / V) * dt_hours # mg/L consumed
	DO = clamp(DO + O2_in - O2_out, 0.0, DO_sat)

	# -----------------------------
	# Mortality (simple DO rule)
	# -----------------------------
	if DO < DO_crit and N > 0:
		# 2% per tick when under critical DO (fixed-step). Consider exp(-m*dt_hours) later.
		N = int(round(N * (1.0 - 0.02)))
		# Recompute biomass metrics after mortality? (v0 keeps B; v1 could reduce B by average W)
		# If you want B to drop with deaths, uncomment:
		# var deaths := max(0, N_prev - N)
		# B -= deaths * W
		# B = max(B, 0.0)
		# if N > 0: W = B / N else: W = 0.0
	
	# -----------------------------
	# Reproduction (recruitment)
	# -----------------------------
	if N > 0 and W > 0.0:
		# Maturity factor: sigmoid curve around W_maturity threshold
		# 0% at W=5g, 50% at W=15g, 95% at W=25g
		var maturity_factor: float = 1.0 / (1.0 + exp(-0.3 * (W - W_maturity)))
		
		# Density factor: reproduction slows as biomass approaches max capacity
		# 100% at low density, 0% at B_max
		var density_factor: float = max(0.0, 1.0 - B / B_max)
		
		# Feed availability factor: need adequate feed for reproduction
		# Drops below 50% when feed < 10% of starting inventory
		var feed_factor: float = clamp(F / 500.0, 0.0, 1.0)
		
		# Combined recruitment rate
		var recruitment_rate: float = r_base * maturity_factor * density_factor * feed_factor
		
		# New shrimp added (fractional) - accumulate over time
		var dN: float = N * recruitment_rate * dt_days
		recruitment_accumulator += dN
		
		# Only add whole shrimp when accumulator >= 1
		var new_shrimp: int = int(recruitment_accumulator)
		if new_shrimp > 0:
			N += new_shrimp
			recruitment_accumulator -= new_shrimp
			# Add biomass for new juveniles (0.5g each)
			B += new_shrimp * 0.5
			# Recalculate average weight
			W = B / N
