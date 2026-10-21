# waypaper

图形化壁纸切换器，前端是 awww（`awww` 守护进程），换完壁纸会触发 matugen 重新配色。

部署到 `~/.config/waypaper`。

## 文件

| 文件 | 说明 |
|---|---|
| `config.ini` | 壁纸目录、后端、填充方式、排序、随机策略 |

## 关键配置

| 项 | 值 | 含义 |
|---|---|---|
| `folder` | `~/Pictures/Wallpapers` | 壁纸目录（安装器会把这个目录链到仓库的 `wallpaper/`） |
| `backend` | `awww` | 用 awww 而不是 swaybg / feh |
| `monitors` | `All` | 所有显示器同一张 |
| `fill` | `fill` | 填充模式（不裁边） |
| `sort` | `daterev` | 按修改时间倒序 |
| `color` | `#ffffff` | 背景色（图片不满屏时露出的颜色） |
| `subfolders` | `False` | 不递归子目录 |
| `show_hidden` | `False` | 不显示隐藏文件 |
| `show_gifs_only` | `False` | 不过滤成只显示动图 |
| `language` | `en` | 界面语言 |
| `zen_mode` | `True` | 隐藏多余界面元素，只看图 |
| `number_of_columns` | 3 | 缩略图三列 |
| `swww_transition_*` | `any` / 63 / 0 / 3s / 60fps | 过渡效果：类型、步进、角度、时长、帧率 |

### post_command：换壁纸后自动换色

```ini
post_command = $HOME/.config/scripts/matugen-update.sh $wallpaper && sleep 0.8 && $HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh $wallpaper
```

选完壁纸会依次做三件事：

1. `matugen-update.sh` 按新壁纸重新生成全部应用配色
2. `sleep 0.8` 等 awww 真正把图刷上去
3. `niri_set_overview_blur_dark_bg.sh` 生成 overview 用的模糊背景

想把「换壁纸」和「换配色」解绑，把 `post_command` 清空即可。

## 用法

```bash
waypaper                 # 打开图形界面选壁纸
waypaper --random        # 随机换一张（Mod+F10）
waypaper --wallpaper ~/Pictures/Wallpapers/xxx.jpg   # 直接指定
```

niri 的 `Mod+Alt+W` 打开界面，`Mod+F10` 随机换，开机时 `autostart.kdl` 里还会 `sleep 1 && waypaper --random`。

## 和 matugen 的关系

waypaper 本身只换壁纸，**不生成配色**。配色由 `matugen` 做，通过上面的 `post_command` 串联：

```
waypaper 选图 → matugen-update.sh → matugen image → 各应用重载
```

单独手动换色：

```bash
matugen image ~/Pictures/Wallpapers/xxx.jpg
```

## 注意

- `folder` 是 `~/Pictures/Wallpapers`，这个目录在安装时被链到仓库的 `wallpaper/Pictures/Wallpapers`。如果手动 `rm` 了它，waypaper 会打开一个空目录。
- `stylesheet = /home/shorin/.config/waypaper/style.css` 是配置里**残留的第三方路径**，安装器部署时会自动替换成你的家目录；手动部署要自己改，否则 waypaper 界面样式不生效（不影响功能）。
- 仓库里 `wallpaper/` 有 9 张图，`wallpapers/` 有 20 张（含模糊版本），后者不部署、不参与壁纸选择。
- 多显示器想各用各的：`monitors` 改成具体输出名（`niri msg outputs` 查看），再对每个屏单独设置。
- `backend` 写的是 `awww`，对应 `awww-daemon` 必须已经在跑；`autostart.kdl` 里已经启动了两个实例（普通 + overview）。
