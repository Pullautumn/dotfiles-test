# fcitx5

中文输入法。默认方案是 **Rime（雾凇拼音 rime_ice）**，另外保留了英文键盘与拼音（备用）。

**切换键：左 Shift。** 本仓库作者没有沿用上游的 `Ctrl+Space`，而是在
`fcitx5-configtool` 的「全局选项 → 切换输入法」里改成了单独按左 Shift，中英文一键切换。
这个改动**没法靠预置配置文件完成**——手改 `config` 即使重启 fcitx5 也不生效（见下方「注意」），
所以装完之后需要自己用 configtool 设一次。

部署到 `~/.config/fcitx5`。皮肤与词库在 `local-share-fcitx5` 包里（`~/.local/share/fcitx5`）。

## 文件

| 文件 | 说明 |
|---|---|
| `profile` | 输入法组与顺序：`keyboard-us` → `rime` → `pinyin`，默认 `rime`；`pinyin` 是备用引擎，日常用不到 |
| `config` | 全局开关：共享输入状态、输入法提示、插件启用列表 |
| `conf/classicui.conf` | 皮肤界面：字体、候选列表方向、托盘图标、DPI |
| `conf/rime.conf` | Rime 引擎参数 |
| `conf/pinyin.conf` | 拼音输入法参数 |
| `conf/chttrans.conf` | 简繁转换 |
| `conf/punctuation.conf` | 标点映射 |
| `conf/notifications.conf` | 输入法状态提示 |
| `conf/cached_layouts` | 布局缓存，可删 |

## 关键设置

| 项 | 值 | 含义 |
|---|---|---|
| `DefaultIM` | `rime` | 默认输入法 |
| `TriggerKeys` | `Shift_L` | 切换输入法（中英互切），上游默认 `Control+space` |
| `AltTriggerKeys` | `Shift+Shift_R` | 备用切换键，保持上游默认，本仓库不使用 |
| `Vertical Candidate List` | `False` | 候选词横向排列 |
| `WheelForPaging` | `True` | 滚轮翻页 |
| `Font` | `Sans Serif 12` | 候选词字体 |
| `Theme` / `DarkTheme` | `default` / `default-dark` | 皮肤 |
| `UseDarkTheme` | `False` | 不强制深色 |
| `UseAccentColor` | `True` | 用强调色着色候选 |
| `ForceWaylandDPI` | `96` | Wayland 下强制 96 DPI，避免候选框过大 |
| `EnableFractionalScale` | `False` | 关分数缩放 |
| `ShareInputState` | `No` | 不跨程序共享输入状态 |

## Rime 定制

`local-share-fcitx5` 里有一份 `rime/default.custom.yaml`：

- 方案锁定 `rime_ice`（雾凇拼音）
- 候选每页 **9 个**
- 数字键 `1-9` 直接选词
- `←/→` 选词，`↑/↓` 翻页，`Tab` 下移一条
- `,` / `.` 翻页

改完要重新部署 Rime：

```bash
fcitx5-remote -r     # 重启输入法
# 或者在 Rime 的菜单里点「重新部署」
```

## 环境变量

输入法要工作，`GTK_IM_MODULE` / `QT_IM_MODULE` / `XMODIFIERS` 必须设上，本仓库在 `environment.d` 包的 `im.conf` 里统一处理，不需要在 `.zshrc` 里再写一遍。

## 依赖

| 包 | 用途 |
|---|---|
| `fcitx5` | 本体 |
| `fcitx5-im` | 集成包（含 GTK/Qt 模块） |
| `fcitx5-chinese-addons` | 简繁转换、标点映射等 addon；拼音引擎留作备用 |
| `fcitx5-rime` | Rime 引擎，`DefaultIM=rime` 靠它加载 |
| `rime-ice-git` | 雾凇拼音词库（AUR），提供 `rime_ice` 方案 |

五个包都在核心包清单的 `input` 组里，一键安装会一起装上，不需要额外操作。
`rime-ice-git` 是 AUR 包，组内统一走 AUR helper（`paru -S` / `yay -S`）。

## 用法

```bash
fcitx5-configtool      # 图形配置界面
fcitx5-remote -o       # 打开输入法
fcitx5-remote -c       # 关闭
fcitx5-remote -t       # 切换中英
fcitx5-remote -r       # 重启
```

`Mod+F1` 在 niri 里绑定了「杀进程 / 重启 fcitx5」，输入法卡住时按它。

## 注意

- **左 Shift 切中英文是 fcitx5 的全局热键**，在 `fcitx5-configtool` 的「全局选项 → 切换输入法」
  里设置，落盘为 `[Hotkey/TriggerKeys]` 的 `0=Shift_L`。上游默认是 `Control+space`。
  （另有 `[Hotkey/AltTriggerKeys]` = 「备用切换输入法」，上游默认 `Shift+Shift_R`，本仓库不动它。）
- **热键不能靠手改 `config` 生效。** 实测：把 `0=Shift+Shift_R` 手动改成 `0=Shift_L`，
  再 `fcitx5-remote -e` 优雅退出、确认 `pgrep fcitx5` 为空后 `fcitx5 -d` 重启，依然无效；
  只有走 configtool 改才立刻生效。原因未深究（疑似热键表在启动时被另一份运行时状态覆盖）。
  **所以新机装完后必须手动设一次，这一步没法脚本化。**
- 本目录经 stow 软链到 `~/.config/fcitx5`，**configtool 保存时会把整份运行时配置写回这个文件**
  （等于直接改仓库）。改完记得核对 `[Hotkey/*]` 各段，别把别的键一起带脏。
- `pinyin` 是备用引擎：`DefaultIM=rime` 时不会被选中，只有 rime 加载失败才顶上，
  或用 `Ctrl+Space` 轮换时才切得到。所以 `input` 组必须装全 —— 缺 `fcitx5-rime` 时
  `DefaultIM=rime` 会静默回落到拼音，能打字但左 Shift 失效。
  `fcitx5-chinese-addons` 也不能卸，`chttrans.conf`（简繁）与 `punctuation.conf`（标点）来自它。
- 全新安装首次启动会编译雾凇词库，可能卡十几秒；没编完就 `fcitx5-remote -r`，或在托盘菜单里点「重新部署」。
- `conf/cached_layouts` 是缓存文件，删掉无影响。
- Wayland 下候选框位置错乱大多是 `ForceWaylandDPI` 与显示器缩放不匹配，试着改成 0 或 192。
