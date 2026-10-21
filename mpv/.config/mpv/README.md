# mpv

视频播放器配置。追求「画面干净、走 GPU、Wayland 原生」。

部署到 `~/.config/mpv`。

## 文件

| 文件 | 说明 |
|---|---|
| `mpv.conf` | 主配置，只有 5 行，全是关键项 |
| `script-opts/modernx.conf` | modernx 界面脚本的参数（紧凑模式、标题栏、窗口按钮等） |

## mpv.conf 全部内容

```ini
osc=no
no-osc
vo=gpu-next
hwdec=vaapi
gpu-context=wayland
```

| 项 | 作用 |
|---|---|
| `osc=no` / `no-osc` | 关掉内置进度条，界面交给 modernx 脚本 |
| `vo=gpu-next` | 用新一代 GPU 渲染后端（libplacebo） |
| `hwdec=vaapi` | 硬解走 VA-API（Intel / AMD 显卡） |
| `gpu-context=wayland` | 强制 Wayland 上下文，避免走 XWayland |

## modernx 参数

| 项 | 值 |
|---|---|
| `compact_mode` | `no` |
| `title_font_size` | 20 |
| `window_top_bar` | `auto` |
| `window_controls` | `yes` |
| `show_windowed` / `show_fullscreen` | `yes` |
| `idle_screen` | `yes`（暂停时显示 idle 画面） |
| `key_bindings` | `yes`（沿用 modernx 默认键位） |

## 依赖与脚本

modernx 是 mpv 的用户脚本，需要放在 `~/.config/mpv/scripts/modernx.lua`。本仓库**只带 `script-opts` 的参数文件，脚本本体没带**，需要自己下：

```bash
mkdir -p ~/.config/mpv/scripts
git clone https://github.com/cyl0/ModernX /tmp/modernx
cp /tmp/modernx/modernx.lua ~/.config/mpv/scripts/
```

没装脚本也不影响播放，只是没有进度条和控制栏（因为 `osc=no` 已经关掉了内置的）。

## 用法

```bash
mpv video.mkv
mpv --no-config video.mkv    # 跳过本配置排查问题时用
```

## 注意

- `hwdec=vaapi` 是 AMD / Intel 的路子。NVIDIA 用户改成 `hwdec=nvdec-copy`，否则会黑屏。
- 只关了 OSC，没配 `input.conf`，所以键位是 mpv 默认的：`空格`暂停、`←/→` 快退快进、`f` 全屏。
- 想让 mpv 也跟随系统配色可以考虑 matugen，但本仓库没接。
