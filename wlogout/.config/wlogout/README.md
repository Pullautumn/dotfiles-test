# wlogout

电源菜单：全屏网格，六个动作各带图标与快捷键。

部署到 `~/.config/wlogout`。

## 文件

| 文件 | 说明 |
|---|---|
| `layout` | 六个按钮的定义：图标、动作命令、文字、快捷键 |
| `style.css` | 全屏布局、图标大小、圆角、悬停效果 |
| `colors.css` | **由 matugen 生成**，不要手改 |
| `assets/` | 六个动作的图标 PNG（lock / hibernate / logout / shutdown / suspend / reboot） |

## 按钮

| 快捷键 | 动作 | 命令 |
|---|---|---|
| `l` | 锁定 | `gtklock` |
| `h` | 休眠 | `systemctl hibernate` |
| `e` | 注销 | `niri msg action quit -s` |
| `s` | 关机 | `systemctl poweroff` |
| `u` | 挂起 | `systemctl suspend` |
| `r` | 重启 | `systemctl reboot` |

## 用法

```bash
wlogout              # 全屏菜单
wlogout -b 3         # 3 列布局
wlogout -p layer-shell   # 作为 layer-shell 层（niri 下更稳）
```

niri 里绑在快捷键上调用，`Esc` 退出。

## 注意

- `assets/` 里是 PNG 图标，换主题色时不会被 matugen 重着色，想换配色得自己替换图片。
- `hibernate` 需要提前配好 swap 分区或 swapfile，否则按下会在终端里报错退出。
