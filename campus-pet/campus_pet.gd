@tool # 允许在编辑器中预览随机行为
extends Node2D

# --- 变量声明 ---
# 使用 @onready 确保在节点进入场景树后才获取引用
@onready var pet_sprite = $PetSprite
@onready var animation_player = $AnimationPlayer

# 桌宠的状态
var current_state = "idle" 
# 行走速度（像素/秒）
var walk_speed = 80
# 移动方向：1 代表向右，-1 代表向左
var direction = 1
# 计时器，用于控制状态切换
var state_timer = 0.0
# 状态持续时间（秒）
var idle_duration = 3.0
var walk_duration = 5.0

# --- 函数 ---
func _ready():
	# 初始化随机数种子
	randomize()
	# 设置初始动画
	update_animation()
	# 随机设置初始方向
	var directions = [1, -1]
	direction = directions[randi() % directions.size()]
	# 随机设置初始状态和计时器
	if randf() < 0.5:
		current_state = "idle"
		state_timer = randf_range(1.0, idle_duration)
	else:
		current_state = "walking"
		state_timer = randf_range(1.0, walk_duration)
		# 如果一开始就在行走，确保动画播放
		if pet_sprite.animation == "idle":
			pet_sprite.play("walk")

func _process(delta):
	# 更新状态计时器
	state_timer -= delta
	
	match current_state:
		"idle":
			# 待机状态下，计时器归零后开始行走
			if state_timer <= 0:
				start_walking()
		"walking":
			# 行走状态下，移动角色
			move_and_constrain(delta)
			# 计时器归零后回到待机
			if state_timer <= 0:
				start_idle()
	
	# 每帧都更新动画（处理方向翻转）
	update_animation()
	update_window_position()

func move_and_constrain(delta):
	# 根据方向和速度计算移动量
	var move_x = walk_speed * delta * direction
	position.x += move_x
	
	# 获取当前窗口的大小
	var window_size = get_viewport_rect().size
	# 边界检测：如果超出左右边界，则转向
	if position.x < 0:
		position.x = 0
		direction = 1
	elif position.x > window_size.x:
		position.x = window_size.x
		direction = -1

func update_animation():
	# 根据方向翻转精灵图像
	pet_sprite.flip_h = direction < 0

func start_walking():
	current_state = "walking"
	state_timer = walk_duration
	pet_sprite.play("walk")

func start_idle():
	current_state = "idle"
	state_timer = idle_duration
	pet_sprite.play("idle")

# 可选：添加鼠标点击交互
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 检查点击是否发生在猫精灵的范围内
			if pet_sprite.get_global_rect().has_point(event.position):
				# 点击后，立即进入待机状态（模拟被吓到）
				start_idle()
				# （可选）播放一个音效或短暂的“惊吓”动画
				print("喵！别摸我！")
				
func update_window_position():
	var win = get_window()
	var pet_pos = global_position  # 宠物在屏幕上的绝对位置
	
	# 计算窗口应放置的位置：让宠物在窗口中心
	var window_offset = Vector2i(win.size) / 2
	var new_window_pos = Vector2i(pet_pos - Vector2(window_offset))
	
	# 设置窗口位置
	win.position = new_window_pos
