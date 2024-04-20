class_name LevelSelect extends Room

@export var camera_dynamics: DynamicsResource
@export var level_resources: Array[LevelResource]
@export var select_circle_gap = Vector2(150.0, 25.0)
@export var dotted_line_padding = 30.0
@export var stars_parallax = 0.8
@export var stars_amount = 50
@export var stars_box: Vector2 = Vector2(1920, 540)

@onready var camera: Camera = $Camera
@onready var stars: Node2D = $Stars
@onready var camera_dynamics_solver := Globals.create_dynamics_vector(camera_dynamics)

var index = 0
var camera_target_position = Vector2.ZERO
var level_select_circles: Array[LevelSelectCircle] = []
var level_select_circle_scene = preload("res://scenes/ui/level_select_circle.tscn")
var dotted_line_scene = preload("res://scenes/dotted_line.tscn")
var star_scene = preload("res://scenes/star.tscn")

func _ready() -> void:
	# Adding the circles
	var level = RoomManager.load_level()
	index = level - 1
	for i in range(len(level_resources)):
		var level_select_circle = level_select_circle_scene.instantiate() as LevelSelectCircle
		var x = i * select_circle_gap.x
		var y = select_circle_gap.y if i % 2 == 0 else -select_circle_gap.y

		level_select_circle.position = Vector2(x, y)
		level_select_circle.level_resource = level_resources[i]
		level_select_circle.num = i + 1

		if i < level:
			level_select_circle.completed = true
		elif i > level:
			level_select_circle.locked = true

		level_select_circles.push_back(level_select_circle)

		add_child(level_select_circle)

		if i == 0:
			camera_target_position = level_select_circle.position
			level_select_circle.selected = true

	# Adding dotted lines
	for x in range(len(level_select_circles)):
		if x == len(level_resources) - 1: break

		var circle = level_select_circles[x]
		var next_circle = level_select_circles[x + 1]
		var normal = (circle.position - next_circle.position).normalized()

		var dotted_line = dotted_line_scene.instantiate() as Line2D
		var offset = normal * dotted_line_padding
		dotted_line.add_point(circle.position - offset, 0)
		dotted_line.add_point(next_circle.position + offset, 1)
		dotted_line.self_modulate = Color.RED
		add_child(dotted_line)

	# Adding the stars
	for j in range(stars_amount):
		var star = star_scene.instantiate() as Sprite2D
		var x = randf_range(0, stars_box.x)
		var y = randf_range(-stars_box.y / 2, stars_box.y / 2)
		star.position = Vector2(x - 240, y)
		stars.add_child(star)

	update_selection()

func update_selection(value: int = 0):
	level_select_circles[index].selected = false
	index = clampi(index + value, 0, len(level_select_circles) - 1)
	level_select_circles[index].selected = true
	camera_target_position = level_select_circles[index].position
	color_palette = level_resources[index].color_palette
	ColorPalette.update_color_palette()

func _process(_delta: float) -> void:
	camera.position = camera_dynamics_solver.update(camera_target_position)
	stars.position = -camera.position * stars_parallax

	var input = 0
	if Input.is_action_just_pressed("left"): input -= 1
	if Input.is_action_just_pressed("right"): input += 1

	if input: update_selection(input)

	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
		if level_select_circles[index].locked:
			camera.shake(0.1, 2)
		else:
			RoomManager.play_level(level_resources[index])
