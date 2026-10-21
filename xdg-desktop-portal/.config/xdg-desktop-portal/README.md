# xdg-desktop-portal

桌面门户配置。决定「截图、录屏、文件选择框、密码存储」这些跨应用能力由谁提供。

部署到 `~/.config/xdg-desktop-portal`。

## 文件

| 文件 | 说明 |
|---|---|
| `niri-portals.conf` | 各门户能力的后端选择 |

## 内容

```ini
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.FileChooser=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.ScreenCast=gnome
org.freedesktop.impl.portal.Screenshot=gnome
```

| 能力 | 后端 | 为什么 |
|---|---|---|
| 默认 | `gnome` → `gtk` | niri 没有专用门户，先试 gnome 再退 gtk |
| 访问确认 | `gtk` | 轻量，够用 |
| 通知 | `gtk` | 走系统通知 |
| 文件选择框 | `gtk` | 文件对话框 |
| 密码 / 密钥 | `gnome-keyring` | 存密码、浏览器密码库 |
| 屏幕录制 | `gnome` | **niri 下唯一能用的 ScreenCast 实现** |
| 截图 | `gnome` | 同上 |

## 因此这三个包不能删

| 包 | 原因 |
|---|---|
| `xdg-desktop-portal-gnome` | 提供 ScreenCast / Screenshot 实现，OBS 录屏、Chrome 共享屏幕全靠它 |
| `gnome-keyring` | 提供 Secret 服务，Chrome、VS Code 存密码要用 |
| `polkit-gnome` | 不是门户，但 `niri/conf.d/autostart.kdl` 会 spawn 它的认证代理，没有它弹不出提权窗口 |

## 生效

```bash
systemctl --user restart xdg-desktop-portal
systemctl --user restart xdg-desktop-portal-gnome
```

改完必须重启这两个服务，不然还是老后端。

## 排查

```bash
# 看当前注册了哪些门户
busctl --user list | grep portal

# 看日志（截图失败时最有用）
journalctl --user -u xdg-desktop-portal -n 50
journalctl --user -u xdg-desktop-portal-gnome -n 50
```

## 注意

- `ScreenCast` 与 `Screenshot` 两行结尾**没有分号**，其余行有。这是从上游抄下来的原样，实际不影响解析，但保持原样以免和别人的笔记对不上。
- 门户服务由 systemd 用户会话按需拉起，`niri/conf.d/autostart.kdl` 里已经显式 spawn 了一次 `xdg-desktop-portal-gnome`。
- 装了 `xdg-desktop-portal-gtk` 但没装 gnome 那个时，截图能用、录屏会失败。
