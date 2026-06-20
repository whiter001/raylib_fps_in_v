# raylib_fps_in_v

> Raylib [First Person Maze 示例](https://github.com/raysan5/raylib/blob/master/examples/models/models_first_person_maze.c) 的 [V 语言](https://github.com/vlang/v) 移植版。

感谢 [@raysan5](https://github.com/raysan5) 带来优秀的 Raylib，以及 [@irishgreencitrus](https://github.com/irishgreencitrus) 提供的 V 语言绑定。

![ScreenShot](screenshot.png)

---

## 当前功能

- **窗口**: 初始化一个 800×450 的 OpenGL 窗口，标题为 `raylib [models] example - first person maze`，帧率限制 60 FPS。
- **第一人称相机**: 透视投影、视场角 45°，支持 WASD 移动、Shift 加速、Space 上升、Ctrl 下降、鼠标转向。
- **3D 迷宫**:
  - 读取灰度地图 `cubicmap.png`，按 1×1×1 的立方体自动生成网格。
  - 白色像素视为墙体，其他颜色为可通行区域。
  - 加载 `cubicmap_atlas.png` 作为地面 / 墙体的漫反射贴图。
- **碰撞检测**:
  - 把玩家简化为 XZ 平面上半径 0.1 的圆柱。
  - 每帧逐像素扫描地图像素，与白墙做圆-矩形相交检测，撞墙时回退相机到本帧开始时的位置。
- **HUD**:
  - 左上角显示实时 FPS。
  - 右上角绘制放大 4 倍的 2D 小地图，用红色方块标示玩家当前位置，用绿色边框勾勒小地图。
- **资源管理**: 退出时按顺序释放像素数组、贴图、模型与 OpenGL 上下文。

源码中的每一段功能都配有详细的中文注释（见 `raylib_fps.v` 文件顶部说明）。

---

## 运行环境

- [V 编译器](https://vlang.zikesong.cn/) `0.5.x` 或更高
- Raylib 模块（通过 `v.mod` 自动声明）

## 构建与运行

```bash
# 1. 拉取依赖（首次运行必需）
v install

# 2. 编译并运行
v run .
```

也可单独编译为目标二进制：

```bash
v .
./raylib_fps_in_v
```

## 资源文件

| 文件 | 用途 |
|---|---|
| `cubicmap.png` | 灰度地图：白像素=墙，其余可通行；同时用作 3D 网格生成和 2D 小地图纹理 |
| `cubicmap_atlas.png` | 立方体的漫反射贴图集 |
| `screenshot.png` | 运行截图 |

## 分支

- `master`: 原始上游版本
- `main`: 在 master 基础上为源码添加了中文功能注释

## 操作说明

- `W` / `A` / `S` / `D` — 前后左右移动
- `Shift` — 加速
- `Space` / `Ctrl` — 上升 / 下降
- 鼠标 — 视角转向
- `ESC` — 退出

## License

MIT，详见 [LICENSE](LICENSE) 文件。
