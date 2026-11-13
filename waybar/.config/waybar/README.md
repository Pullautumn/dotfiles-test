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
| `switch-perf-mode.sh` | 切换性能模式（`power-profiles-daemon`） |

截图和录屏脚本三套状态栏用的是同一份，已移到 `~/.config/scripts/`
（`screenshot.sh`、`wf-recorder.sh`），本目录不再保存副本。
`scripts/` 里只留本样式自己会用的模块脚本。

截图模块三个鼠标键：左键调 `screenshot.sh`，中键调 `wayscrollshot`（滚动长截图），
右键开 `qs-popup screenshot-toolbox`。录屏模块左键开关、中键暂停、右键开录制设置。

## 保持唤醒按钮（`custom/swayidle-toggle`）

本模块自己不判断任何状态，只是一个壳，全部逻辑在
`~/.config/scripts/idle-toggle.sh`（`return-type: json`，返回 `text` / `class` /
`tooltip`）：

- 💤 深色 = 允许休眠；☕ 橘色（`class: paused`）= 保持唤醒
- 左键切换，右键 `loginctl lock-session`（保持唤醒时仍然能立刻锁屏）
- 真实开关是 `$XDG_RUNTIME_DIR/idle-paused`，读它的是 `niri/scripts/swayidle.sh`
  里的 `gate()`；点击后脚本发 `SIGRTMIN+7` 让本模块立刻重跑，`interval: 30` 只是兜底

**不要改回 `systemctl --user start/stop swayidle.service`**：swayidle 由 niri
autostart 直接 spawn，根本没有这个 unit。旧版按钮因此变成「显示已禁用、实际照样
锁屏」——最坏的那种坏法，状态栏在撒谎。

## 改完怎么生效

```bash
killall -SIGUSR2 waybar   # 重载 config + style（原地，PID 不变）
killall -SIGUSR1 waybar   # 显示/隐藏状态栏，不是重载样式！
```

`Mod+Shift+F4` 绑的就是 `killall -SIGUSR1 waybar`。改完样式若个别模块外观没跟上，
重启 waybar 最稳。

`waybar` 在 `style.css` 里开了 `reload_style_on_change`，改 CSS 会自动重载，改 `config.jsonc` / `modules.jsonc` 需要上面的信号。

## 注意

- `style.css` 里大量使用 `@define-color` 引用 `colors.css` 的变量，直接把 `colors.css` 删了会整条状态栏变黑底白字。
- 换样式（`Mod+F3`）时切换到的是 `waybar-niri-Win11Like` 包，那个包 include 了本包的 `modules.jsonc`，所以删本包会连带影响备选样式。
- `wlr/taskbar` 依赖 `niri` 的 foreign-toplevel 支持，窗口列表为空时先确认 niri 版本。
