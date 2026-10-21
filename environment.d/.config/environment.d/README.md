# environment.d

会话级环境变量。由 systemd 用户会话读取，对**图形会话里启动的所有程序**生效——不管你用哪个 shell。

部署到 `~/.config/environment.d`。

## 文件

| 文件 | 内容 |
|---|---|
| `90-desktop.conf` | `XDG_CURRENT_DESKTOP=wlroots` |
| `im.conf` | 输入法环境变量 + GTK 渲染后端 |

## 90-desktop.conf

```ini
XDG_CURRENT_DESKTOP=wlroots
```

告诉各程序「当前桌面是 wlroots 系」。niri 本身不会设置这个变量（它以 `niri` 作为 `XDG_CURRENT_DESKTOP`），这里补一个 `wlroots` 是为了让 Electron、Qt 等程序走 Wayland 分支而不是 X11 分支。

`local-bin` 包里还有个 `niri-session-wlroots` 包装脚本，做的是同一件事，两种方式任选。

## im.conf

```ini
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=fcitx

GSK_RENDERER=ngl
```

| 变量 | 作用 |
|---|---|
| `GTK_IM_MODULE` / `QT_IM_MODULE` | GTK / Qt 程序使用 fcitx 输入法 |
| `XMODIFIERS` | X11 程序的输入法标识 |
| `SDL_IM_MODULE` / `GLFW_IM_MODULE` | 游戏与 GLFW 程序（Minecraft 等）的输入法 |
| `GSK_RENDERER=ngl` | GTK4 用 NGL 渲染器，解决部分 AMD 显卡下的闪烁 |

文件里还留了一段注释掉的 `ibus` 配置，想换回 ibus 时把 fcitx 那几行注释、ibus 那几行取消注释。

## 生效

```bash
systemctl --user daemon-reload     # 让 systemd 重读
# 注销后重新登录（或者重启）才会应用到整个会话
```

临时验证（只对当前 shell 生效，不推荐长期这么做）：

```bash
set -a; . ~/.config/environment.d/im.conf; set +a
```

## 注意

- 这里的变量**优先级低于** shell 里的 `export`。如果 `.zshrc` 里也设了 `GTK_IM_MODULE`，以 `.zshrc` 为准（对它启动的程序而言）。
- `environment.d` 是 systemd 的功能，需要 `systemd` 会话（Arch 默认就是）。
- 改完不重新登录的话，只有新启动的 systemd 用户服务能读到新值，已经跑着的 GUI 程序不会变。
