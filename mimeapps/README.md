# mimeapps

默认打开方式。双击一个 `.png` 或点一个链接时，到底开哪个程序由这里决定。

部署到 `~/.config/mimeapps.list`。

> **特殊处理**：安装器不用 stow，而是 `ln -sfn` 建**绝对路径**链接。原因是桌面环境（Thunar、Chrome）会直接往里写内容，stow 的软链会被写穿成真实文件，之后 `stow -D` 删不掉。

## 结构

```ini
[Default Applications]     # 默认程序（28 条）
[Added Associations]       # 候选程序列表
```

## 典型映射

| MIME / 协议 | 默认程序 |
|---|---|
| `text/html`、`x-scheme-handler/http(s)` | `google-chrome.desktop` |
| `inode/directory` | `org.gnome.Nautilus.desktop` |
| `image/jpeg`、`image/png` | `org.kde.gwenview.desktop` |
| `x-scheme-handler/clash` | `mihomo-party.desktop` |
| `x-scheme-handler/clash-verge` | `clash-verge.desktop` |
| `text/plain` | `org.gnome.TextEditor.desktop` |

## 查与改

```bash
# 看某个类型当前用什么打开
xdg-mime query default image/png

# 看某个文件会用什么打开
xdg-mime query filetype photo.png
xdg-mime query default $(xdg-mime query filetype photo.png)

# 改
xdg-mime default org.gnome.Loupe.desktop image/png

# 看 desktop 文件是否存在（名字对不上是最常见的问题）
ls /usr/share/applications | grep -i loupe
```

`xdg-mime default` 会直接改这个文件，比手写安全。

## 注意

- `inode/directory` 指向 `org.gnome.Nautilus.desktop`，但**仓库的默认文件管理器是 Thunar**。想用 Thunar 就执行：
  ```bash
  xdg-mime default thunar.desktop inode/directory
  ```
- `org.kde.gwenview.desktop` 属于 KDE 的图片查看器，没装的话图片会打不开。替代品是 `imv`（核心包里有）：
  ```bash
  xdg-mime default imv.desktop image/png image/jpeg
  ```
- 桌面条目名必须和 `/usr/share/applications` 或 `~/.local/share/applications` 里的文件名**完全一致**，差一个 `.desktop` 后缀都会静默失效。
- 本仓库的 `local-share-applications` 包提供了一批自定义 `.desktop`（微信、QQ、WPS、IDEA 等），这里的映射依赖它们已经部署。
