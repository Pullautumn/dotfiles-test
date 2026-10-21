# swaync

通知中心 + 控制中心。`Mod+N` 开关，右上角滑出。

部署到 `~/.config/swaync`。

## 文件

| 文件 | 说明 |
|---|---|
| `config.json` | 行为配置：位置、宽度、超时、组件列表、按钮网格 |
| `style.css` | 样式（通知卡片、控制中心面板、按钮网格） |
| `colors.css` | 由 matugen 生成（`~/.config/swaync/colors.css`） |
| `refresh.sh` | 重载辅助脚本 |
| `config (副本).json` / `style (副本).css` / `style.css.bak` | 改动前的备份，不参与加载，可以删 |

## 关键参数

| 项 | 值 |
|---|---|
| `positionX` / `positionY` | `right` / `top` |
| `control-center-width` | 350 |
| `notification-window-width` | 280 |
| `timeout` | 4 秒（低优先级 4 秒、紧急常驻由 `timeout-critical` 控制） |
| `widgets` | `mpris` · `title` · `notifications` · `volume` · `backlight` · `buttons-grid` |
| `hide-on-clear` / `hide-on-action` | 清空或点击后自动收起 |

## 控制中心按钮网格

`widget-config.buttons-grid.actions` 里定义了 12 个按钮：

| 按钮 | 动作 |
|---|---|
| 静音扬声器 | `pactl set-sink-mute @DEFAULT_SINK@ toggle` |
| 静音麦克风 | `pactl set-source-mute @DEFAULT_SOURCE@ toggle` |
| WiFi | `kitty nmtui` |
| 蓝牙 | `blueman-manager` |
| 免打扰 | `swaync-client -d` |
| 投屏 | `gnome-network-displays` |
| 文档 / 设置 | `kitty bash -i -c 'Docs'` / `'Settings'` |
| 系统监视器 | `missioncenter` |
| 锁定 | `gtklock` |
| 重启 / 关机 | `reboot` / `shutdown now` |

其中 `missioncenter`、`gnome-network-displays` 属于可选软件，没装的话点了没反应；`Docs` / `Settings` 是 shell 别名，需要 zsh 配置里定义过。

## 用法

```bash
swaync-client -t          # 开关控制中心
swaync-client -d          # 切换免打扰
swaync-client -C          # 清空全部通知
swaync-client -R          # 重载配置
swaync-client -rs         # 重载样式
```

## 注意

- 和 `mako` 抢同一个 D-Bus 名，只能二选一。
- `config (副本).json` 和 `style (副本).css` 文件名带空格与括号，纯粹是手工备份留下的，`swaync` 不会读它们。
- `title` 组件里 `button-text` 用的是 Nerd Font 私有区字符，字体没装全时显示成方块。
