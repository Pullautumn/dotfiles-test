# mpv

视频播放器配置。niri / Wayland 原生，GPU 渲染，modernz 界面。

部署到 `~/.config/mpv`。

## 目录结构

```
.config/mpv/
├── mpv.conf                    # 主配置
├── input.conf                  # 只写偏离 mpv 默认的按键
├── fonts/                      # modernz 的图标字体
│   ├── fluent-system-icons.ttf
│   └── material-design-icons.ttf
├── scripts/
│   ├── modernz.lua             # OSC 界面（替代内置 OSC）
│   ├── thumbfast.lua           # 进度条悬停缩略图
│   ├── playlistmanager.lua     # 播放列表（F8）
│   └── autoload.lua            # 自动加载同目录同类型文件
└── script-opts/
    ├── modernz.conf
    ├── playlistmanager.conf
    └── autoload.conf
```

`shaders/`（Anime4K 着色器）不在仓库里，由 `install.sh` 询问后下载到
`~/.config/mpv/shaders/`，已加入 `.gitignore`。

## ⚠️ 改配置前必读：两个解析器规则不同

mpv 有两套配置文件解析器，对「注释」的处理**完全相反**：

| 文件 | 解析器 | 行尾 `#` 注释 |
|---|---|---|
| `mpv.conf` | C（`options/parse_configfile.c`） | **有效**，`#` 后面整段被切掉 |
| `script-opts/*.conf` | Lua（`player/lua/options.lua`） | **无效**，`#` 连同后面文字一起变成选项值 |

Lua 那边只认「行首 `#`」：

```lua
if string.find(line, "#") ~= 1 then     -- # 不在第 1 位就不当注释
    local val = string.sub(line, eqpos+1)   -- 一直取到行尾
```

后果分类型：

- `number` / `boolean` 转换失败 → 报错并**回退默认值**（静默失效）
- `string` → 直接把 `en    # 英文界面` 这种脏字符串吃下去

所以本仓库的规矩是：**所有注释独占一行，不许写在 `=` 后面。**
`mpv.conf` 本来允许行尾注释，也一并遵守这条，保持统一。

另一个坑：`mpv.conf` 里值本身含 `#` 时必须加引号，否则会被当成注释截断。
`sub-color='#FFFFFF'` 是对的，`sub-color=#FFFFFF` 会变成空值。

## 快捷键

mpv 的默认键位已经很合理，`input.conf` 只补必要的：

| 快捷键 | 功能 | 来源 |
|---|---|---|
| `Tab` | 切换 OSC 显示模式（自动 / 常显 / 常隐） | modernz |
| `Ctrl+1` ~ `Ctrl+6` | Anime4K 六种画质模式 | 需先下载 shaders |
| `Ctrl+0` | 清除所有着色器 | 同上 |
| `F8` | 显示播放列表 | playlistmanager |

保持 mpv 默认、没有覆盖的常用键：

| 快捷键 | 功能 |
|---|---|
| `空格` | 暂停 |
| `←` / `→` | 快退 / 快进 5 秒 |
| `↑` / `↓` | 快退 / 快进 60 秒 |
| `滚轮` | 音量 ±2 |
| `f` | 全屏 |
| `j` / `J` | 切换主字幕轨道 |
| `s` / `S` | 截图（含 / 不含字幕） |
| `[` `]` `{` `}` | 减速 / 加速 / 半速 / 双速 |
| `BS` | 速度归 1.0 |
| 右键 | 上下文菜单（mpv 0.38+ 内置） |

想改成「双击左键暂停」，在 `input.conf` 里加一行（默认双击是全屏，只能二选一）：

```
MBTN_LEFT_DBL cycle pause
```

## 依赖

| 项 | 说明 |
|---|---|
| `mpv >= 0.40` | `secondary-sid=auto` 双字幕需要；Arch 仓库版本已满足 |
| `noto-fonts-cjk` | `sub-font` 指定的中文字幕字体，已在 `PKG_GROUPS[fonts]` |
| 图标字体 | 已在 `fonts/` 里，modernz 的 `icon_theme=fluent` 依赖它 |

## 几处刻意的选择

**`vo=gpu-next` 而不是 `vo=gpu`**

`gpu-next` 走 libplacebo，画质上限更高：HDR 色调映射、film grain 合成、更新的缩放器。
真显卡环境下没有理由用老管线，所以默认 `gpu-next`。

唯一例外：libplacebo 检测到 OpenGL 是**软件光栅化**（llvmpipe）时会以
`allow_software=false` 直接拒绝初始化，报 `Failed initializing opengl context` /
`Video: no video`。所以**在没开 3D 加速的 virtio-gpu 虚拟机里测这套配置时**，
mpv 会起不来画面——把 `mpv.conf` 里 `vo=gpu-next` 临时换成 `vo=gpu`（老管线只
警告不拒绝）并注释掉插值三行即可，测完改回来。物理机上不要留 `vo=gpu`。

**`hwdec=auto-copy` 而不是 `vaapi`**

copy-back 模式兼容性最好，NVIDIA 也能用，且内存里保留 CPU 侧帧（将来接 SVP 补帧不用改）。
代价是每帧多一次 GPU→CPU 拷贝。只装 AMD / Intel 且追求极致性能可以换 `vaapi`。

**开了 `interpolation`**

把片源帧率补到屏幕刷新率，配 `video-sync=display-resample` 和 `tscale=mitchell`。
不想要「肥皂剧效应」或 GPU 吃紧，把这三行一起注释掉。
（虚拟机软件渲染下这三行必须注释，否则每帧都在 CPU 上重算，直接卡成幻灯片。）

**`no-resume-playback` 没抄**

mpv 默认 `--save-position-on-quit=no`，本来就不记忆播放进度，上游那一行是多余的。
真想要断点续播，取消 `mpv.conf` 里 `save-position-on-quit=yes` 的注释。

**`input.conf` 只有 8 条绑定**

上游 jswysnemc 用了 51 行，其中滚轮、左右键、`[ ] { } BS`、`s/S`、`j/J`、`f`
等十余条与 mpv 默认值**逐字相同**，等于没写。这里全删，让默认值生效。
另外它把 `MBTN_RIGHT` 设成 `ignore`，屏蔽了内置右键菜单，这里恢复默认。

**`autoload.lua` 修了拼写**

上游文件名是 `auoload.lua`（少个 t）。脚本用 `read_options(o, nil)` 取配置，
identifier 会回退成文件名，于是它去找 `script-opts/auoload.conf` —— 永远找不到，
提供的 `autoload.conf` 从未生效。这里改回正确文件名。

## 用法

```bash
mpv video.mkv
mpv --no-config video.mkv     # 跳过本配置，排查问题用
mpv --input-test --force-window --idle   # 交互式查当前按键绑定
```

## 改完怎么生效

mpv 每次启动重新读配置，不需要重载。改了 `mpv.conf` 直接重开一个窗口即可。
`script-opts` 的修改同样在下次启动生效。
