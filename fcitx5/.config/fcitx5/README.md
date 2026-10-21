# fcitx5

中文输入法。默认方案是 **Rime（雾凇拼音 rime_ice）**，另外保留了拼音与英文键盘。

部署到 `~/.config/fcitx5`。皮肤与词库在 `local-share-fcitx5` 包里（`~/.local/share/fcitx5`）。

## 文件

| 文件 | 说明 |
|---|---|
| `profile` | 输入法组与顺序：`keyboard-us` → `rime` → `pinyin`，默认 `rime` |
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
| `fcitx5-chinese-addons` | 拼音、双拼、五笔等 |
| `fcitx5-rime` | Rime 引擎（可选清单外，需单独装） |

注意：核心包清单里是 `fcitx5-chinese-addons`，**没有** `fcitx5-rime`。用雾凇拼音要额外装：

```bash
paru -S fcitx5-rime
```

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

- 没装 `fcitx5-rime` 时 `DefaultIM=rime` 会回落到拼音，能打字但不是雾凇的键位。
- `conf/cached_layouts` 是缓存文件，删掉无影响。
- Wayland 下候选框位置错乱大多是 `ForceWaylandDPI` 与显示器缩放不匹配，试着改成 0 或 192。
