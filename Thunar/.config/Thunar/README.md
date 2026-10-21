# Thunar

Xfce 的文件管理器，`Mod+Alt+E` 打开。轻量、启动快，比 nautilus 适合平铺环境。

部署到 `~/.config/Thunar`。

## 文件

| 文件 | 说明 |
|---|---|
| `accels.scm` | 快捷键绑定表（GTK accel 格式） |
| `uca.xml` | 自定义动作（Custom Actions），右键菜单里多出来的条目 |

## 自定义动作

当前只配置了一个：

| 动作 | 说明 |
|---|---|
| `Open Terminal Here` | 在当前目录打开终端 |

它调用 `kitty`，依赖 `kitty` 在 PATH 里。

## 快捷键

`accels.scm` 是 GTK 的快捷键表，每行形如：

```scheme
(gtk_accel_path "<Actions>/ThunarWindow/open-parent" "<Primary>Up")
```

改完需要重启 Thunar 生效：

```bash
thunar -q          # 退出后台进程
thunar             # 重新启动
```

## 依赖

| 包 | 用途 |
|---|---|
| `thunar` | 本体 |
| `thunar-volman` | 可移动设备自动挂载 |
| `thunar-archive-plugin` | 右键压缩 / 解压 |
| `tumbler` | 缩略图服务 |
| `gvfs` `gvfs-mtp` `gvfs-smb` | 挂载手机 MTP、SMB 共享 |
| `ffmpegthumbnailer` | 视频缩略图 |
| `poppler-glib` | PDF 缩略图 |
| `file-roller` | 压缩包管理器 |
| `webp-pixbuf-loader` | WebP 缩略图 |

以上都在核心包清单的 `files` 组里，安装器会自动装齐。

## 注意

- Thunar 是 Xfce 的组件，在纯 Wayland 下借 XWayland 跑；niri 需要 `xwayland-satellite` 才能启动它（核心包清单里已有）。
- 想加右键动作，用图形界面更省事：`thunar-settings` → 「自定义动作」，改完会直接写回 `uca.xml`。
- `nautilus` 装了的话 `Mod+E` 会优先开 nautilus，`Mod+Alt+E` 才固定走 Thunar。
