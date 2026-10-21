# scripts

一组和壁纸、配色、截图相关的胶水脚本，放在 `~/.config/scripts`。

它们被 waypaper 的 `post_command`、niri 的快捷键、随机壁纸脚本互相调用，是「换壁纸 → 整套换色」这条链路的中间层。

部署到 `~/.config/scripts`。安装器 Phase 5 会给这里的 `*.sh` / `*.py` 统一加执行权限。

## 脚本

| 脚本 | 作用 | 谁调用 |
|---|---|---|
| `matugen-update.sh` | 总入口：读壁纸 → 调 `matugen image` → 处理策略与明暗 → 触发重载 | waypaper 的 `post_command`、`matugen-select-type.sh`、`random-anime-wallpaper.sh` |
| `matugen-select-type.sh` | 交互式切换配色策略，结果缓存在 `~/.cache/matugen-strategy/type` | `Mod+Alt+M` / `Mod+Alt+T` |
| `matugen-restore.sh` | 系统级还原：清图标缓存、按缓存重新生成整套配色 | 手动 |
| `niri_set_overview_blur_dark_bg.sh` | 生成 overview 用的模糊 + 变暗背景 | waypaper 的 `post_command`（紧跟在 matugen-update 后） |
| `niri_auto_blur_bg.sh` | 自动跟随当前壁纸生成模糊背景 | `niri/conf.d/autostart.kdl` 开机启动 |
| `generate_hyprlock_wallpaper.sh` | 为 hyprlock 生成带模糊的锁屏背景 | 手动 / 配合锁屏配置 |
| `random-anime-wallpaper.sh` | 从在线 API 随机下载动漫壁纸并设为壁纸 | `Mod+Shift+F10` |

## matugen-update.sh

```bash
~/.config/scripts/matugen-update.sh                       # 用当前壁纸
~/.config/scripts/matugen-update.sh /path/to/wall.jpg     # 指定图片
~/.config/scripts/matugen-update.sh -t scheme-content -m dark
```

支持 `-t` 配色方案、`-m` 明暗模式，以及 `--source-color-index` 指定从图片里取第几个主色。

## matugen-select-type.sh

```bash
~/.config/scripts/matugen-select-type.sh
```

弹出选择界面挑配色策略，选中后写进 `~/.cache/matugen-strategy/type` 并立即用当前壁纸重跑一次。

## random-anime-wallpaper.sh

```bash
~/.config/scripts/random-anime-wallpaper.sh
```

从 `https://t.alcy.cc/pc/` 拉一张随机动漫图，存到壁纸目录后设为壁纸，再调 `matugen-update.sh` 换色。

## 和 waypaper 的关系

`waypaper/.config/waypaper/config.ini` 里这一行串起了全部：

```ini
post_command = $HOME/.config/scripts/matugen-update.sh $wallpaper && sleep 0.8 && $HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh $wallpaper
```

所以「在 waypaper 里点一张壁纸」= 换壁纸 + 换整套配色 + 重做 overview 背景，中间那条 `sleep 0.8` 是等 awww 把壁纸真正画上去。

## 注意

- 这些脚本都**不是 POSIX sh**，用的是 bash 特性（数组、`[[ ]]`），别把 shebang 改成 `sh`。
- `random-anime-wallpaper.sh` 依赖外网，API 挂了脚本会静默退出，不会破坏当前壁纸。
- `matugen-restore.sh` 会清 `~/.cache` 下的图标缓存并重建，跑一次要几十秒，别频繁用。
- 脚本里的路径基本都是 `$HOME/...` 相对写法，换用户名不用改。
