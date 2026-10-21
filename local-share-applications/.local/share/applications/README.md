# local-share-applications

自定义的 `.desktop` 启动项。放这里可以让应用出现在启动器（fuzzel / rofi）和文件管理器里，还能修掉输入法、Wayland 之类的启动参数问题。

部署到 `~/.local/share/applications`。

## 文件（25 个）

| 类别 | 条目 |
|---|---|
| 中文应用 | `com.qq.weixin.desktop` 微信、`qq.desktop` QQ、`wemeetapp.desktop` 腾讯会议、`wps-office-*.desktop` WPS 文字 / 表格 / 演示 / PDF |
| 开发工具 | `idea.desktop` `pycharm.desktop` `webstorm.desktop` `phpstorm.desktop`、`apifox.desktop`、`charles.desktop`、`cherry-studio.desktop`、`Navicat.Premium.17.desktop`、`install4j_1egslpi-BurpSuitePro.desktop` |
| 网络工具 | `clash-verge-handler.desktop`、`cherrystudio-url-handler.desktop`、`firefox.desktop` |
| 系统 | `org.flameshot.Flameshot.desktop` 截图、`org.gnome.Shell.Extensions.GSConnect*.desktop` 手机互联、`file-converter.desktop` |

## 关键：输入法修复

原生 `.desktop` 里往往没有输入法环境变量，导致这些应用里打不出中文。这里的条目普遍在前面加了 `env`：

```ini
Exec=env GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx /bin/bash -c "..."
```

微信那条更彻底：

```ini
Exec=env GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx /bin/bash -c \
    "killall fcitx5 2>/dev/null; fcitx5 & exec /opt/wechat/wechat --ozone-platform=x11"
```

- 先把 fcitx5 杀掉重启，避免微信复用旧的输入上下文
- `--ozone-platform=x11` 强制走 XWayland，微信的 Wayland 支持目前不稳

QQ 用的是 `fcitx5` 作为模块名（部分版本的 Qt 认这个名字）。

## 怎么改

桌面条目就是文本文件，改完 `update-desktop-database` 或重新登录即可：

```bash
update-desktop-database ~/.local/share/applications
# 或者
gio set ~/.local/share/applications/xxx.desktop metadata::trusted true
```

新增条目最省事的办法：从 `/usr/share/applications/` 复制一份过来再改 `Exec`。

## 注意

- 这里的 `Exec` 全是**绝对路径**（`/opt/wechat/wechat`、`/usr/bin/linuxqq`）。换了安装方式（比如从 AppImage 换成仓库包）就要跟着改，否则点击无反应。
- `wechat` 用 `/opt/wechat/wechat`，说明它是按官方 `linuxqq-appimage` 那种解包到 `/opt` 的方式装的；如果装在别处，图标能显示但点了不启动。
- `.desktop` 文件必须有可执行位吗？不需要，但在某些文件管理器里需要 `chmod +x` 才显示为「可信」。
- `mimeapps.list` 里的映射依赖这里的文件名，重命名会让默认打开方式失效。
