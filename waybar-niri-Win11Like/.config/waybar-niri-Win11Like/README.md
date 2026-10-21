# waybar-niri-Win11Like

主 waybar 的**备选样式**：Windows 11 风格，状态栏在屏幕底部，模块更偏向「任务栏」。

部署到 `~/.config/waybar-niri-Win11Like`，与主 `waybar` 包相互独立，不会互相覆盖。

和主配置一起由 stow 部署，装完即可用 `Mod+F2` / `Mod+F3` 在两套样式间切换。

## 与主状态栏的区别

| | waybar | waybar-niri-Win11Like |
|---|---|---|
| 位置 | 顶部 | **底部** |
| 左侧 | 启动器 + 工作区 + 任务栏 + 网络 + 截图录屏 + 剪贴板 | 工作区 + 媒体 + 截图录屏 + 剪贴板 + 操作菜单 + 取色器 + 当前窗口标题 |
| 中间 | 时钟 + 通知 | 应用启动按钮 + **niri 任务栏**（`cffi/niri-taskbar`） |
| 右侧 | 隐私、性能、电量、托盘、电源 | 托盘、DDC 亮度组、音频组、蓝牙、网络、防休眠、电量、性能、时钟、电源菜单组 |

## 文件

| 文件 | 说明 |
|---|---|
| `config.jsonc` | 布局，`include` 了本包的 `modules.jsonc` **和主 waybar 的** `modules.jsonc` |
| `modules.jsonc` | 本样式专用的模块：`cffi/niri-taskbar`、`custom/applauncher`、`custom/actions`、`custom/colorpicker`、`group/ddcutil`、`group/powermenu` 等 |
| `style.css` | 独立样式，`style.css.backup` 是改动前的备份 |
| `colors.css` | 由 matugen 生成（`~/.config/waybar-niri-Win11Like/colors.css`） |
| `logo/` | 蓝牙等模块用的图标 |
| `scripts/` | `cava.sh`、`check-updates.sh`、`command-center.sh`、`toggle-bluetooth.sh`、录屏截图脚本组 |

## 切换

`Mod+F2` / `Mod+F3` 在 niri 里已绑定：

```bash
# F2 → 主样式
pkill waybar; waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css

# F3 → Win11 样式
pkill waybar; waybar -c ~/.config/waybar-niri-Win11Like/config.jsonc -s ~/.config/waybar-niri-Win11Like/style.css
```

## 注意

- 它 `include` 了主 waybar 的 `modules.jsonc`，所以**主 `waybar` 包必须一起部署**，否则本包启动会因找不到模块配置而报错。
- 用到的 `cffi/niri-taskbar` 需要 waybar 带 CFFI 支持并安装 `niri-taskbar` 插件；`group/ddcutil` 需要 `ddcutil`。这两个在核心包清单里没有，缺了会把对应模块显示成空。
- `custom/updates`（更新检查）在配置里是注释状态。
