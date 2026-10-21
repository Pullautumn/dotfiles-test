# fuzzel

应用启动器，`Mod+A` 呼出。Wayland 原生、启动快、支持图标与 dmenu 模式。

部署到 `~/.config/fuzzel`。

## 文件

| 文件 | 说明 |
|---|---|
| `fuzzel.ini` | 主配置：字体、尺寸、内边距、按键绑定、dmenu 行为 |
| `colors.ini` | **由 matugen 生成**（`include` 进来），不要手改 |

## 关键参数

| 项 | 值 | 含义 |
|---|---|---|
| `font` | `adwaita sans:size=13` | 字体与字号 |
| `terminal` | `kitty -e` | dmenu 模式下选中终端程序时的启动方式 |
| `lines` | 9 | 一次显示几行 |
| `width` | 35 | 窗口宽度（字符数） |
| `horizontal-pad` / `vertical-pad` / `inner-pad` | 40 / 15 / 5 | 三种内边距 |
| `border.width` / `border.radius` | 2 / 8 | 边框粗细与圆角 |

按键：

| 键 | 作用 |
|---|---|
| `Ctrl+K` / `↑` / `Ctrl+W` | 上一条 |
| `Ctrl+J` / `↓` / `Ctrl+S` | 下一条 |
| `Return` / `KP_Enter` / `Ctrl+L` | 确认 |
| `Ctrl+Return` / `Ctrl+H` | 自定义动作 1 |

## 常见用法

```bash
fuzzel                                    # 启动应用
fuzzel --dmenu                            # 当 dmenu 用（从 stdin 读列表）
printf "关机\n重启\n" | fuzzel --dmenu     # 配合脚本做选择菜单
```

`niri/scripts/niri-quick-switch-fuzzel.py` 就是拿它做 `Alt+Tab` 窗口切换菜单的。

## 注意

- `fuzzel.ini` 第一行 `include = "~/.config/fuzzel/colors.ini"` 依赖 matugen 生成的文件；没跑过 matugen 时启动是默认配色，不会报错。
- 改完直接生效，下次呼出即用新配置。
