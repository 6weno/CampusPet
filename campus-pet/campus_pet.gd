
extends Node2D
# --- 变量声明 ---
# 使用 @onready 确保在节点进入场景树后才获取引用
@onready var pet_sprite = $PetSprite
@onready var animation_player = $AnimationPlayer

# 桌宠的状态
var current_state = "idle" 
# 行走速度（像素/秒）
var walk_speed = 8
# 移动方向：1 代表向右，-1 代表向左
var direction = 1
# 计时器，用于控制状态切换
var state_timer = 0.0
# 状态持续时间（秒）
var idle_duration = 3.0
var walk_duration = 5.0

const DEBUG_MODE = true
# --- 函数 ---
func _ready():
	# 初始化随机数种子
	randomize()
	var win = get_window()
	if DEBUG_MODE:
		win.set_flag(Window.FLAG_BORDERLESS, false)   # 显示边框
		win.set_flag(Window.FLAG_TRANSPARENT, false)  # 关闭透明

	var screen = DisplayServer.screen_get_size()
	
	# 设置窗口大小（略大于宠物）
	win.size = Vector2i(300, 300)
	
	# 设置窗口初始位置：放在屏幕左下区域
	var win_x = win.size.x
	var win_y = screen.y  # 距离底部 50px
	win.position=Vector2i(win_x,win_y)-win.size
	# ===== 宠物在窗口内的初始位置：底部居中 =====
	self.position = Vector2i(win.size/2)  # 窗口内坐标
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
	#update_window_position()

func move_and_constrain(delta):
	var win = get_window()
	
	# 1. 计算宠物在窗口内的新位置（假设窗口不动）
	var new_pet_x = position.x + walk_speed * delta * direction
	
	# 2. 预测：如果宠物移到 new_pet_x，窗口会放在哪里？
	#    （假设窗口始终以宠物为中心）
	var window_offset = win.size.x / 2.0
	var predicted_window_x = (win.position.x + new_pet_x) - window_offset  # 推导见下方说明
	
	# 3. 获取主屏幕的工作区（排除任务栏等）
	var screen_rect = DisplayServer.get_display_safe_area()
	
	# 4. 检查预测的窗口是否超出屏幕左右边界
	var min_window_x = screen_rect.position.x                    # 屏幕最左
	var max_window_x = screen_rect.position.x + screen_rect.size.x - win.size.x  # 屏幕最右（窗口右边缘不能超）
	
	if predicted_window_x < min_window_x:
		# 窗口会从左边出去 → 强制窗口贴左，宠物转向右
		predicted_window_x = min_window_x
		direction = 1
		new_pet_x = window_offset  # 宠物在窗口中心（x = win.size/2）
		
	elif predicted_window_x > max_window_x:
		# 窗口会从右边出去 → 强制窗口贴右，宠物转向左
		predicted_window_x = max_window_x
		direction = -1
		new_pet_x = window_offset
	
	# 5. 应用宠物新位置
	position.x = new_pet_x
	
	# 6. 更新窗口位置（让宠物保持在窗口中心）
	win.position.x = predicted_window_x
	win.position.y = win.position.y  # Y 不变（或按需处理）

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
	var win_pos=win.position
	var new_window_pos = Vector2i(global_position.x+win_pos.x,win_pos.y)  # 宠物在屏幕上的绝对位置
	
	# 计算窗口应放置的位置：让宠物在窗口中心
	
	# 设置窗口位置
	win.position = new_window_pos
	if Engine.get_frames_drawn() % 600 == 0:  # 每秒一次（60fps）
		print("📍 宠物位置:", global_position)
		print("🖥️ 窗口位置:", win.position)
		print("📏 窗口尺寸:", win.size)
		print("---")
