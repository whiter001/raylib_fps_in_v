// =============================================================================
//  文件: raylib_fps.v
//  说明: Raylib 第一人称迷宫示例的 V 语言移植版
//  原版: https://github.com/raysan5/raylib/blob/master/examples/models/models_first_person_maze.c
//
//  当前功能:
//    1. 创建一个 800x450 的 OpenGL 窗口,标题为 "raylib [models] example - first person maze"
//    2. 加载一张灰度立方地图图片 (cubicmap.png) 作为迷宫关卡:
//         - 用该图片构建一个 3D 立方体网格 (立方体的存在与否由像素灰度决定)
//         - 同时把同一张图作为右上角 2D 小地图纹理
//    3. 加载一张纹理图集 (cubicmap_atlas.png) 作为 3D 迷宫地面的材质贴图
//    4. 初始化一个第一人称相机 (CAMERA_FIRST_PERSON),隐藏鼠标光标
//    5. 进入主循环:
//         - 处理玩家输入并更新相机 (WASD 移动, 鼠标转向)
//         - 把玩家简化为一个 2D 圆,逐像素检测与白墙的碰撞,撞墙时回退位置
//         - 绘制 3D 迷宫、2D 小地图、玩家在雷达中的红色方块以及 FPS 计数
//    6. 程序退出时按顺序释放颜色数组、贴图、模型,最后关闭窗口
// =============================================================================

import os
import raylib as r

fn main() {
	// 把 raylib 的日志级别调为 error,只输出错误信息,避免刷屏
	r.vset_trace_log_level(.log_error)

	// 初始化窗口: 宽 800, 高 450, 标题如上
	r.init_window(800, 450, 'raylib [models] example - first person maze')

	// 构造相机: 位置、注视点、上方向、视场角和投影方式
	// CAMERA_PERSPECTIVE = 0,使用透视投影
	mut camera := r.Camera{
		position:   r.Vector3{0.2, 0.4, 0.2} // 相机起始位置 (x, y, z)
		target:     r.Vector3{0.185, 0.4, 0.0} // 相机注视的目标点,基本朝 -Z 方向
		up:         r.Vector3{0.0, 1.0, 0.0} // 上方向为 +Y
		fovy:       45.0 // 视场角 (度)
		projection: 0 // CAMERA_PERSPECTIVE 透视投影
	}

	// -----------------------------------------------------------------------------
	// 加载迷宫资源
	// -----------------------------------------------------------------------------

	// 加载灰度地图图片;白色像素 = 墙,其他颜色 = 可通行区域
	// 用 os.resource_abs_path 解析资源路径,保证在任意工作目录下都能正确找到文件
	immap := r.load_image(os.resource_abs_path('cubicmap.png'))

	// 把同一张图片转成纹理,稍后用于右上角的 2D 小地图
	cubicmap := r.load_texture_from_image(immap)

	// 根据图片生成 3D 立方体网格: 每 1x1 像素生成一个 1x1x1 的立方体
	mesh := r.gen_mesh_cubicmap(immap, r.Vector3{1.0, 1.0, 1.0})
	mut model := r.load_model_from_mesh(mesh)

	// 加载纹理图集,贴到 3D 模型的漫反射 (albedo) 通道上
	texture := r.load_texture(os.resource_abs_path('cubicmap_atlas.png'))
	unsafe {
		model.materials[0].maps[r.MaterialMapIndex.material_map_albedo].texture = texture
	}

	// 把图片像素数据加载到内存,用于碰撞检测
	map_pixels := r.load_image_colors(immap)
	r.unload_image(immap) // CPU 端图片数据已拷到 map_pixels 和 cubicmap,这里释放图片

	// 3D 模型在世界坐标中的偏移: 让迷宫原点对齐到 (-16, 0, -8)
	map_position := r.Vector3{-16.0, 0.0, -8.0}

	// 隐藏并限制鼠标光标到窗口内,使相机可以接收鼠标位移作为视角输入
	r.disable_cursor()

	// 限制帧率为 60 FPS
	r.set_target_fps(60)

	// -----------------------------------------------------------------------------
	// 主循环: 持续检测窗口关闭事件 (例如按下 ESC 或点击关闭按钮)
	// -----------------------------------------------------------------------------
	for !r.window_should_close() {
		// 记录本帧开始时相机的位置,碰撞后用于回退
		old_cam_pos := camera.position

		// 由 raylib 处理键盘 (WASD/Space/Shift) 和鼠标输入,更新相机位置与朝向
		r.update_camera(&camera, C.CAMERA_FIRST_PERSON)

		// ---------------- 玩家与迷宫墙的碰撞检测 (简化为 2D 圆-矩形检测) ----------------

		// 把玩家投影到地面 (XZ 平面),建模为一个半径 0.1 的圆柱
		player_pos := r.Vector2{camera.position.x, camera.position.z}
		player_radius := f32(0.1)

		// 计算玩家当前所在的格子 (像素坐标),用于在小地图上画红色方块
		mut player_cell_x := int(player_pos.x - map_position.x + 0.5)
		mut player_cell_y := int(player_pos.y - map_position.z + 0.5)

		// 越界保护: 把格子坐标限制在 [0, width-1] / [0, height-1] 范围内
		player_cell_x = int_max(0, int_min(cubicmap.width - 1, player_cell_x))
		player_cell_y = int_max(0, int_min(cubicmap.height - 1, player_cell_y))

		// 遍历整张地图的像素: 白色像素视为墙
		// 注: TODO 提到可以只检测玩家周围格子来优化,目前实现是全图扫描
		for y := 0; y < cubicmap.height; y++ {
			for x := 0; x < cubicmap.width; x++ {
				// 碰撞: 白色像素,只比较 R 通道 (r == 255)
				if unsafe { map_pixels[y * cubicmap.width + x].r == 255 } {
					// 构造墙对应的 1x1 矩形,圆与矩形相交则发生碰撞
					if r.check_collision_circle_rec(player_pos, player_radius, r.Rectangle{
						map_position.x - 0.5 + f32(x), map_position.z - 0.5 + f32(y), 1.0, 1.0})
					{
						// 检测到碰撞,回退到本帧开始时的位置
						camera.position = old_cam_pos
					}
				}
			}
		}

		// ---------------- 绘制一帧画面 ----------------

		r.begin_drawing()
		{
			// 用 raywhite (近白色) 清屏
			r.clear_background(r.raywhite)

			// 进入 3D 模式,绘制迷宫模型
			r.begin_mode_3d(camera)
			r.draw_model(model, map_position, 1.0, r.white) // 在 map_position 处按 1:1 缩放绘制
			r.end_mode_3d()

			// 在右上角绘制 2D 小地图 (放大 4 倍)
			r.draw_texture_ex(cubicmap, r.Vector2{r.get_screen_width() - cubicmap.width * 4 - 20, 20.0},
				0.0, 4.0, r.white)
			// 用绿色画小地图的外框
			r.draw_rectangle_lines(r.get_screen_width() - cubicmap.width * 4 - 20, 20,
				cubicmap.width * 4, cubicmap.height * 4, r.green)

			// 在小地图上用红色方块标示玩家当前所在格子
			r.draw_rectangle(r.get_screen_width() - cubicmap.width * 4 - 20 + player_cell_x * 4,
				20 + player_cell_y * 4, 4, 4, r.red)

			// 左上角显示 FPS
			r.draw_fps(10, 10)
		}
		r.end_drawing()
	}

	// -----------------------------------------------------------------------------
	// 资源释放
	// -----------------------------------------------------------------------------

	r.unload_image_colors(map_pixels) // 释放用于碰撞检测的像素数组
	r.unload_texture(cubicmap) // 释放小地图纹理
	r.unload_texture(texture) // 释放 3D 模型纹理
	r.unload_model(model) // 释放 3D 模型

	r.close_window() // 关闭窗口与 OpenGL 上下文
}
