# swaync

通知中心 + 控制中心。`Mod+N` 开关，右上角滑出。

部署到 `~/.config/swaync`。

## 文件

| 文件 | 说明 |
|---|---|
| `config.json` | 行为配置：位置、宽度、超时、组件列表、按钮网格 |
| `style.css` | 结构与字阶（Material You 风格），首行 `@import url("colors.css")` |
| `colors.css` | **生成物**，不入库：matugen 按壁纸写的 `@define-color` 变量 |
| `refresh.sh` | 重启 swaync |

## 样式分两层

| 层 | 内容 | 谁改 |
|---|---|---|
| `colors.css` | 颜色变量（`surface` / `on_surface` / `primary` …） | matugen 换壁纸时重写 |
| `style.css` | 圆角、间距、字阶、滑块、按钮网格 | 手改，入库 |

兜底配色在 `matugen/.config/matugen/custom/swaync/colors.css`（Catppuccin Mocha），
`matugen-restore.sh` 会把它复制成 `~/.config/swaync/colors.css`。所以：

- 没跑过 matugen 也有颜色，不会退成默认灰白
- 换壁纸后 matugen 直接覆盖，`Mod+F12` 还原回 Mocha

配色模板复用 `matugen/templates/colors.css`（和 swayosd 同一份）。**GTK4 只认
`@define-color`，不认 Web 的 `--var`** —— 仓库里原来那份 `swaync-colors.css` 用的是
`:root { --name: value }`，等于从没生效过，已删除。

## 关键参数

| 项 | 值 |
|---|---|
| `positionX` / `positionY` | `right` / `top` |
| `control-center-width` | 380 |
| `notification-window-width` | 340 |
| `notification-icon-size` | 40 |
| `control-center-margin-*` | 四边 12（浮起，配合圆角） |
| `timeout` | 4 秒（低优先级 6 秒，紧急 1 秒） |
| `widgets` | `mpris` · `title` · `notifications` · `volume` · `backlight` · `buttons-grid` |
| `notification-grouping` / `relative-timestamps` | `true` |

## 圆角对齐（改样式必须遵守）

niri 的 `layer-rule` 按 `geometry-corner-radius` 裁 surface 物理角，**必须比 CSS
圆角大 2px**，否则圆角会被切成直角：

| 窗口 | layer namespace | niri 裁 | CSS 圆角 |
|---|---|---|---|
| 浮动通知 | `swaync-notification-window` | 20 | 18 |
| 控制中心 | `swaync-control-center` | 24 | 22 |

这两条 layer-rule **不加 `background-effect`**，只看圆角。原因：swaync 的两个
surface 都锚 top+bottom，实际尺寸是「右侧整列、接近全高」的透明层，卡片只占顶部
一小块。而 niri 的 `blur` 按 **surface 矩形**生效、不看逐像素 alpha —— 一旦挂上，
通知一弹出右侧整片壁纸就被糊掉，视觉上像蒙了层毛玻璃遮住半屏。

卡片背景是 `alpha(@sn_1, 0.94)`、控制中心是 0.96，本身足够实，不依赖背景模糊。
确实想要磨砂感时，在对应 rule 里补：

```kdl
background-effect {
    xray false
    blur true
}
```

规则写在 `niri/conf.d/window-rules.kdl` 末尾。

## 倒计时条（通知还剩多久）

卡片底部那条随超时收缩的色条。

swaync **没有**「剩余时间」节点 —— 模板里那个 `progressbar` 只反映应用自己上报的
进度（`notify-send -h int:value:50` 那种），跟自动消失无关。所以这条是用 GTK4 的
`background-size` 动画画的：`100% 3px` → `0% 3px`，GTK4 会平滑插值（实测有效）。

```css
@keyframes sn-countdown {
    from { background-size: 100% 3px; }
    to   { background-size: 0% 3px; }
}

.notification {
    background-image: linear-gradient(to right, @primary 0%, @primary 100%);
    background-size: 100% 3px;
    background-position: bottom left;
    background-repeat: no-repeat;
    animation: sn-countdown 4s linear;
}
```

颜色用 `@primary`（matugen 按壁纸生成），换壁纸自动跟着变。

### 时长必须和 `config.json` 对齐

| 配置项 | 值 | 对应 CSS |
|---|---|---|
| `timeout` | 4 | `.notification` 的 `animation: sn-countdown 4s` |
| `timeout-low` | 6 | `.notification.low { animation-duration: 6s }` |
| `timeout-critical` | 1 | `.notification.critical { animation-duration: 1s }` |

**改任何一个超时都要同步改上面这三处秒数**，否则条走完的时间对不上。

### 三个已知局限

1. **悬停暂停**：鼠标停在卡片上时 swaync 会暂停超时计时，但 CSS 动画不会停
   （GTK4 没有可靠的 `animation-play-state` 联动钩子），色条会先走完。
2. **无 `animation-fill-mode`**：GTK4 不支持这个属性，动画结束后属性回落到基础值。
   通知如果活得比动画久，色条会「弹回」满宽。默认(4s)/紧急(1s)与动画时长一致，
   不会看到；只有低优先级(6s)在 `.low` 类没命中时才可能遇到。
3. **应用自定 `-t`**：`notify-send -t 10000` 这类自定义超时，色条仍按固定时长走。

控制中心里的通知条目**关掉了**这条（`background-image: none; animation: none`）——
那里不会自动消失，进度条没有意义。

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
| 锁定 | `qs-lock` |
| 重启 / 关机 | `reboot` / `shutdown now` |

其中 `missioncenter`、`gnome-network-displays` 属于可选软件，没装的话点了没反应；
`Docs` / `Settings` 是 shell 别名，需要 zsh 配置里定义过。

## 用法

```bash
swaync-client -t          # 开关控制中心
swaync-client -d          # 切换免打扰
swaync-client -C          # 清空全部通知
swaync-client -R          # 重载配置（config.json）
swaync-client -rs         # 重载样式（改 style.css / colors.css 后）
```

改完 `style.css` 直接 `swaync-client -rs` 就能看到效果，不用重启 swaync。

## 注意

- 和 `mako` 抢同一个 D-Bus 名，只能二选一。
- `title` 组件里 `button-text` 用的是 Nerd Font 私有区字符，字体没装全时显示成方块。
- 别给 `.notification` 加 `text-align: right` —— 旧样式就是这么写的，正文全挤在右边，
  是当时「丑」的主要原因。
