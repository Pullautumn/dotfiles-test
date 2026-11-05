# waybar

状态栏配置，分「布局」与「样式」两部分，配色由 matugen 从壁纸生成。

部署到 `~/.config/waybar`。

## 文件

| 文件 | 说明 |
|---|---|
| `config.jsonc` | 布局：把模块分到 left / center / right 三个区域，含间距、高度、层 |
| `modules.jsonc` | 每个模块的具体配置（命令、格式、点击行为、图标） |
| `style.css` | 样式（650 行），配色变量从 `colors.css` 读 |
| `colors.css` | **由 matugen 生成**，不要手改 |
| `scripts/` | 各模块的辅助脚本 |

## 当前布局

```
左侧   launcher · niri/workspaces · wlr/taskbar · network · 截图 · 录屏
       · swayidle 开关 · mpris
中间   clock · notification
右侧   privacy · clipboard · cpu · memory · temperature · wireplumber
       · backlight · battery · power-profiles · tray · power
```

`config.jsonc` 里注释掉了一些备用模块（`idle_inhibitor`、`group/misc`、`custom/vkeyboard`、`custom/battery`），想用取消注释并加进对应数组即可。

## 脚本

| 脚本 | 作用 |
|---|---|
| `battery-status.sh` / `battery-tooltip.sh` | 电池状态文字与悬浮提示 |
| `cliphist-fuzzel-img` | 带图片预览的剪贴板选择器（`Mod+Shift+V`） |
| `screenshot.sh` | 选区截图，直接进剪贴板（`wayfreeze` 由 niri 键位负责，这里只 `grim`+`slurp`） |
| `wf-recorder.sh` | 录屏主控：`waybar` 出状态 JSON、`start`/`stop`/`pause-toggle`/`settings` |
| `switch-perf-mode.sh` | 切换性能模式（`power-profiles-daemon`） |

截图模块三个鼠标键：左键调 `screenshot.sh`，中键调 `wayscrollshot`（滚动长截图），
右键开 `qs-popup screenshot-toolbox`。录屏模块左键开关、中键暂停、右键开录制设置。

## 改完怎么生效

```bash
killall -SIGUSR2 waybar    # 重载配置与样式
# 或者整体重启
pkill waybar && waybar &
```

`waybar` 在 `style.css` 里开了 `reload_style_on_change`，改 CSS 会自动重载，改 `config.jsonc` / `modules.jsonc` 需要上面的信号。

## 注意

- `style.css` 里大量使用 `@define-color` 引用 `colors.css` 的变量，直接把 `colors.css` 删了会整条状态栏变黑底白字。
- 换样式（`Mod+F3`）时切换到的是 `waybar-niri-Win11Like` 包，那个包 include 了本包的 `modules.jsonc`，所以删本包会连带影响备选样式。
- `wlr/taskbar` 依赖 `niri` 的 foreign-toplevel 支持，窗口列表为空时先确认 niri 版本。
