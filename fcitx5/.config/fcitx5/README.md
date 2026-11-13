# fcitx5

中文输入法。默认方案是 **Rime（雾凇拼音 rime_ice）**，另外保留了英文键盘与拼音（备用）。

**切换键：左 Shift。** 没有沿用上游的 `Ctrl+Space`，改成单独按左 Shift 一键切中英。
写在 `config` 的 `[Hotkey/TriggerKeys] 0=Shift_L` 里，落盘即生效，装完不需要再手点 configtool。

但**光改这一处不够**：Rime 的 `ascii_composer` 默认也把 Shift 用作切换键
（`Shift_L: inline_ascii` / `Shift_R: commit_text`），会在 fcitx5 判定「单按」之前先把键吃走，
表现成「按 Shift 只是临时英文」而不是切输入法。所以 `local-share-fcitx5` 那份
`rime/default.custom.yaml` 里必须同时把两个 Shift 设成 `noop`。两边都改才算配置完整。

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
| `TriggerKeys` | `Shift_L` | 单按左 Shift 切中英（主触发键），上游默认 `Control+space` |
| `AltTriggerKeys` | `Shift_R` | 单按右 Shift 切中英（备用）。原写法 `Shift+Shift_R` 里的 `Shift+` 是冗余的，fcitx5 会 normalize 掉 |
| `ModifierOnlyKeyTimeout` | `250` | 单按修饰键的判定窗口（毫秒）；按下后 250ms 内没接别的键才算「单按」 |
| `EnumerateGroupForwardKeys` | `Control+space` | 切输入法组。原来是 `Super+space`，但被 niri 的 `Mod+Space`（窗口浮动）先吃掉，fcitx5 收不到；本仓库只有一组，实际不会触发 |
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
- **`ascii_composer/switch_key` 的 `Shift_L` / `Shift_R` 都设成 `noop`** —— 把 Shift 让给
  fcitx5 的 `TriggerKeys` / `AltTriggerKeys`。不设这两行，上面那个左 Shift 切中英就是废的。

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

- **左 Shift 是主触发键，右 Shift 只是备用。** 两者在 fcitx5 里走不同的判定：
  `TriggerKeys`（左 Shift）任何时候都能切；`AltTriggerKeys`（右 Shift）多一层
  `canAltTrigger()`——输入法已经关闭、且上一次不是它自己关的，直接返回 false，按了没反应。
  所以主用左手。判定窗口由 `ModifierOnlyKeyTimeout=250` 控制：`Shift+A` 这类组合不会误触发，
  但「先按住 Shift 停顿超过 250ms 再按字母」会切过去。
- **改完怎么生效。** 手改 `config` 是有效的，不需要 configtool：重启 fcitx5 进程
  （`pkill -x fcitx5 && fcitx5 -d`）后，用 D-Bus 读回来确认过 `TriggerKeys[0]=Shift_L`：
  ```bash
  gdbus call --session --dest org.fcitx.Fcitx5 --object-path /controller \
      --method org.fcitx.Fcitx.Controller1.GetConfig "fcitx://config/global"
  ```
  `fcitx5-remote -r` 只重载 fcitx5 自己的配置，**不会触发 Rime 重新部署**。改了
  `default.custom.yaml` 要先删掉编译产物再重启：
  ```bash
  rm -f ~/.local/share/fcitx5/rime/build/default.yaml
  pkill -x fcitx5; fcitx5 -d
  ```
  重编后 `build/default.yaml` 的 `ascii_composer:` 里应出现 `switch_key: {Shift_L: noop, Shift_R: noop}`。
  （早前版本的本 README 写过「手改无效、必须走 configtool」，那是误判：当时没改 Rime 的
  `switch_key`，Shift 被 `ascii_composer` 截走，看起来才像热键没生效。）
- **切过去之后当前输入法会停在 `keyboard-us`。** 停用态（`keyboard-us`）下再按 Shift 会回到
  `rime`，两者对应 `~/.config/fcitx5/profile` 里的前两项。排查时注意 `fcitx5-remote`
  的返回值是 **`1` = 未激活、`2` = 激活**（不是反过来），别拿它当「中/英」。
- 本目录经 stow 软链到 `~/.config/fcitx5`，**configtool 保存时会把整份运行时配置写回这个文件**
  （等于直接改仓库）。改完记得核对 `[Hotkey/*]` 各段，别把别的键一起带脏。
- `pinyin` 是备用引擎：`DefaultIM=rime` 时不会被选中，只有 rime 加载失败才顶上，
  或者用 `fcitx5-remote -s pinyin` / configtool 手动选才切得到。所以 `input` 组必须装全 —— 缺 `fcitx5-rime` 时
  `DefaultIM=rime` 会静默回落到拼音，能打字但左 Shift 失效。
  `fcitx5-chinese-addons` 也不能卸，`chttrans.conf`（简繁）与 `punctuation.conf`（标点）来自它。
- 全新安装首次启动会编译雾凇词库，可能卡十几秒；没编完就 `fcitx5-remote -r`，或在托盘菜单里点「重新部署」。
- `conf/cached_layouts` 是缓存文件，删掉无影响。
- Wayland 下候选框位置错乱大多是 `ForceWaylandDPI` 与显示器缩放不匹配，试着改成 0 或 192。
