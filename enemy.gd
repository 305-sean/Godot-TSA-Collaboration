extends CharacterBody2D

enum State { SPAWN, IDLE, CHASE, ATTACK, DAMAGE }

@export var move_speed := 60.0
@export var attack_range := 35.0
@export var attack_cooldown := 1.0

var state: State = State.SPAWN
var attack_timer := 0.0
var health := 3

var player: Node2D = null
var player_in_range := false   # <-- Area2D detection flag

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D


func _ready() -> void:
	# Connect Area2D signals (important!)
	detection_area.body_entered.connect(_on_detect_enter)
	detection_area.body_exited.connect(_on_detect_exit)

	play_anim("spawn")

	# Switch to idle after spawn anim
	get_tree().create_timer(1.0).timeout.connect(_start_ai)


func _start_ai() -> void:
	change_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if state == State.IDLE:
		state_idle()
	elif state == State.CHASE:
		state_chase(delta)
	elif state == State.ATTACK:
		state_attack(delta)

	if attack_timer > 0:
		attack_timer -= delta


# ---------------- Detection via Area2D ----------------

func _on_detect_enter(body):
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		change_state(State.CHASE)


func _on_detect_exit(body):
	if body == player:
		player_in_range = false
		player = null
		change_state(State.IDLE)


# ---------------- States ----------------

func state_idle():
	play_anim("idle")

	if player_in_range:
		change_state(State.CHASE)


func state_chase(delta: float):
	play_anim("idle")

	if !player_in_range:
		change_state(State.IDLE)
		return

	if player and global_position.distance_to(player.global_position) <= attack_range:
		change_state(State.ATTACK)
		return

	# Move towards player
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()


func state_attack(delta: float):
	play_anim("attack")

	if attack_timer <= 0:
		attack_timer = attack_cooldown  # Damage player here

	if !player_in_range:
		change_state(State.CHASE)


# ---------------- Helpers ----------------

func change_state(new_state: State):
	state = new_state


func play_anim(name: String):
	anim.play(name)
