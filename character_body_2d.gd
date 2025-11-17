extends CharacterBody2D

@export var move_speed: float = 200.0
@export var acceleration: float = 15.0
@export var dash_speed: float = 600.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.5

var _velocity: Vector2 = Vector2.ZERO
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _is_dashing: bool = false
var _last_move_dir: Vector2 = Vector2.DOWN

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("left", "right", "up", "down")

	# Track last direction
	if input_vector != Vector2.ZERO:
		_last_move_dir = input_vector.normalized()

	# Cooldown
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

	# Dash trigger
	if Input.is_action_just_pressed("dash") and _cooldown_timer <= 0 and not _is_dashing:
		_is_dashing = true
		_dash_timer = dash_time
		_cooldown_timer = dash_cooldown

		var dash_dir := input_vector if input_vector != Vector2.ZERO else _last_move_dir
		_velocity = dash_dir.normalized() * dash_speed

	# Dash behavior
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0:
			_is_dashing = false

		velocity = _velocity
		move_and_slide()
		_update_animation(input_vector, true)
		return

	# Normal movement with smoothing
	var target_vel := input_vector * move_speed
	_velocity = _velocity.lerp(target_vel, acceleration * delta)

	# Stop tiny drift
	if input_vector == Vector2.ZERO and _velocity.length() < 5:
		_velocity = Vector2.ZERO

	velocity = _velocity
	move_and_slide()

	_update_animation(input_vector, false)



# ─────────────────────────────────────────
# ANIMATION CONTROLLER (FULL 4-DIRECTION)
# ─────────────────────────────────────────
func _update_animation(input_vector: Vector2, is_dashing: bool) -> void:
	# DASH animations
	if is_dashing:
		if _last_move_dir.y < 0:
			anim.play("walk_up")      # change to "dash_up" if you add it
		elif _last_move_dir.y > 0:
			anim.play("walk_forward") # change to "dash_forward"
		elif abs(_last_move_dir.x) > 0:
			anim.play("walk_side")    # change to "dash_side"
		_flip_sprite(_last_move_dir)
		return

	# IDLE animations
	if input_vector == Vector2.ZERO:
		if _last_move_dir.y < 0:
			anim.play("idle_up")
		else:
			anim.play("idle")
		return

	# WALK animations
	if input_vector.y < 0:
		anim.play("walk_up")
	elif input_vector.y > 0:
		anim.play("walk_forward")
	elif abs(input_vector.x) > 0:
		anim.play("walk_side")

	_flip_sprite(input_vector)



# ─────────────────────────────────────────
# LEFT-RIGHT FLIPPING
# ─────────────────────────────────────────
func _flip_sprite(dir: Vector2) -> void:
	if dir.x != 0:
		anim.flip_h = dir.x < 0
