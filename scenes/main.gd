extends Node

#Preload the obstacle scenes to generate in the code
var car_scene = preload("res://scenes/car.tscn")

#Array of obstacles (Can add more here)
var obstacle_array := [car_scene]

var obstacles : Array #track the obstacle that have spawned
var last_obstacle #track the last obstacle created

const Dog_Start_Position := Vector2i(960, 920)
const Cam_Start_Position := Vector2i(960, 560)

var player_hp : int = 100
var speed : float
var time : float
const Start_Speed : float = 5.0
const Max_Speed : int = 100
var screen_size : Vector2i

var obstacle_timer : float = 0.0
var obstacle_spawn_interval : float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	new_game()
	
func new_game():
	#Reset everything
	time = 0
	speed = Start_Speed
	$"The Dawg".position = Dog_Start_Position
	$"The Dawg".velocity = Vector2i(0, 0)
	$Camera2D.position = Cam_Start_Position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	time += delta
	obstacle_timer += delta
	
	if speed<Max_Speed && time>=1:
		speed = Start_Speed+( (time-1) * 2 )
	
	
	var distance_traveled : float
	distance_traveled -= speed * delta*1000
		
	generate_obs(delta, distance_traveled)
	
	#เพื่อลบ obs ที่ออกนอก screen ไปแล้ว (for optimizing)
	for obs in obstacles:
		if obs.position.y > ($Camera2D.position.y + screen_size.y):
			remove_obs(obs)
	
	show_hp()
	
	#Move the dawg and the cam
	$"The Dawg".position.y -= speed
	$Camera2D.position.y -= speed
	
func show_hp():
	#เอา property "text" ของ node HPLabel ใน scene HUD มาเปลี่ยน ตาม player_hp
	$HUD.get_node("HPLabel").text = "HP: " + str(player_hp)

func generate_obs(delta, distance_traveled):
	#ถ้าไม่เคยมี obstacles มาก่อน หรือ obstacle timer เกินค่าที่กำหนด (+-นิดหน่อย)
	if obstacles.is_empty() or (obstacle_timer >= obstacle_spawn_interval + randf_range(-0.5,5)):
		#randomly selects 1 obstacle type from the array to generate
		var obs_type = obstacle_array[randi() % obstacle_array.size()]
		
		#instantiate (สร้าง copy ของ scene นั้นๆ) the obstacle into the "obs" variable
		var obs
		obs = obs_type.instantiate()
		# **ตอนนี้เราสามารถเล่นกับพวก position หรือ properties ต่างๆของ scene นี้ได้แล้ว เพราะเรา instantiate แล้ว **
		
		#จัดค่าเริ่มต้นของ obstacle นั้น (ไม่ต้องโค้ดให้มันขยับก็ได้ เพราะว่ากล้องมันขยับขึ้นให้แล้ว)
		var obs_y_level = $Camera2D.position.y - 1500
		var obs_x_level : int = screen_size.x*(randf_range(0.3, 0.7))
		
		add_obstacle(obs, obs_x_level, obs_y_level)
		
		#log it to be the last obstacle being created
		last_obstacle = obs
		
		#reset obstacle timer ให้กลายเป็น timer ของตัวนี้
		obstacle_timer = 0.0
	
		
func add_obstacle(obs, x, y):
	#ตั้ง position เริ่มต้น ให้ obs
	obs.position = Vector2i(x, y)
	
	#connect กับ signal "body_entered" ของ obstacle นั้น เพื่อทำ collision
	#ถ้าเกิด "body_entered" signal ให้มันทำ "hit_obs"
	obs.body_entered.connect(hit_obs)
	
	#add "obs" node as a child to the main scene
	add_child(obs)
	#add to the obstacles tracking
	obstacles.append(obs)
	
func hit_obs(body):
	#ถ้าไอตัวที่เกิด collision กับ obs ชื่อว่า The Dawg ให้มัน ลดเลือด
	if body.name == "The Dawg":
		reduce_HP(10)
		
func reduce_HP(hp):
	player_hp -= hp
	
	if player_hp == 0:
		#รอ 0.1 วิ
		await get_tree().create_timer(0.1).timeout
		#ให้เกมมัน pause
		get_tree().paused = true
		
func remove_obs(obs):
	#ลบ obs node ออกจาก main node scene
	obs.queue_free()
	#ลบ obs จาก obstacles list
	obstacles.erase(obs)

	
