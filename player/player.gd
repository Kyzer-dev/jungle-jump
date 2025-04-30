extends CharacterBody2D
signal life_changed
signal died
@export var gravity = 700
@export var run_speed = 180
@export var jump_speed = -350
enum {IDLE, RUN, JUMP, HURT, DEAD}
var state = IDLE
var life = 400: set = set_life
enum {LEFT, RIGHT}
var last_input_dir = RIGHT

func _ready():
	change_state(IDLE)
	
func _physics_process(delta):
	velocity.y += gravity * delta
	get_input()
	move_and_slide()
	if state == HURT:
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("danger"):
			hurt()

func reset(_position):
	life = 400
	self.position = _position
	show()
	change_state(IDLE)

func set_life(value):
	life = value
	life_changed.emit(life)
	if life <= 0:
		change_state(DEAD)
		
func hurt():
	if state != HURT:
		change_state(HURT)
	
func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			$AnimationPlayer.play("idle")
		RUN:
			$AnimationPlayer.play("run")
		HURT:
			$AnimationPlayer.play("hurt")
			velocity.y = -200
			velocity.x = -100 * determine_throw()
			life -= 1
			await get_tree().create_timer(0.5).timeout
			change_state(IDLE)
		JUMP:
			$AnimationPlayer.play("jump")
		DEAD:
			died.emit()
			hide()
			
func determine_throw():
	match last_input_dir:
		LEFT:
			return -1
		RIGHT:
			return 1

func get_input():
	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_just_pressed("jump")
	# movement occurs in all states...
	
	# cancel input during hurt
	if state == HURT:
		return
	
	velocity.x = 0
	if right:
		velocity.x += run_speed
		$Sprite2D.flip_h = false
		last_input_dir = RIGHT
	if left:
		velocity.x -= run_speed
		$Sprite2D.flip_h = true
		last_input_dir = LEFT
	
	# only allow jump while on the ground
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	
	# IDLE transition to RUN while moving
	if state == IDLE and velocity.x != 0:
		change_state(RUN)
	# RUN transition to IDLE
	if state == RUN and velocity.x == 0:
		change_state(IDLE)
	# JUMP transition while in air
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP)
		
	if state == JUMP and is_on_floor():
		change_state(IDLE)
	if state == JUMP and velocity.y < 0:
		$AnimationPlayer.play("jump_up")
	if state == JUMP and velocity.y > 0:
		$AnimationPlayer.play("jump_down")
