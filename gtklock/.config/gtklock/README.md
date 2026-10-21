# gtklock

GTK 锁屏，**主锁屏方案**。支持播放控制、电源按钮、用户头像，走 PAM 校验密码。

部署到 `~/.config/gtklock`。

## 文件

| 文件 | 说明 |
|---|---|
| `config.ini` | 模块与各模块参数、样式文件路径、背景图 |
| `style.css` | 时钟、输入框、按钮的外观 |
| `wallpaper-blur.jpg` | 模糊过的锁屏背景 |

## 关键配置

```ini
[main]
modules=playerctl-module;powerbar-module;userinfo-module

[General]
css-file=/home/pullautumn/.config/gtklock/style.css
```

| 模块 | 作用 |
|---|---|
| `playerctl-module` | 显示当前媒体信息的封面与标题，可切歌 |
| `powerbar-module` | 电源按钮：重启 / 关机 / 挂起 / 注销 |
| `userinfo-module` | 用户头像与用户名，圆形裁剪 |

电源按钮命令：`systemctl reboot`、`systemctl -i poweroff`、`systemctl suspend`，注销走 `niri msg action quit -s`。

## 前置条件：PAM 配置

gtklock **必须**有 `/etc/pam.d/gtklock`，否则输入密码会直接失败。安装器的 Phase 7d 会自动创建：

```
auth      include   system-login
account   include   system-login
password  include   system-login
session   include   system-login
```

手动装的话自己写一份，权限 `644`：

```bash
sudo tee /etc/pam.d/gtklock >/dev/null <<'EOF'
auth      include   system-login
account   include   system-login
password  include   system-login
session   include   system-login
EOF
```

## 用法

```bash
gtklock                    # 锁屏
gtklock -d                 # 先 daemon 化（niri 里更稳，避免锁屏瞬间画面残留）
loginctl lock-session      # 走 logind 触发
```

## 注意

- `css-file` 里写的是绝对路径 `/home/pullautumn/...`。用别的用户名时安装器会自动替换；手动部署需要自己改这一行，否则样式不生效（不报错，只是变成默认外观）。
- `Mod+Alt+L` 在 niri 里绑定的是 `hyprlock`，不是 gtklock。想用 gtklock 就把 `binds.kdl` 第 66 行的命令换回来。
- 没有配 `idle` 时不会自动锁屏，自动锁屏由 `niri/scripts/swayidle.sh` 负责。
