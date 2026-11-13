# 安装器说明

`setup/` 是安装器的实现。架构沿用 [jswysnemc/dotfiles](https://github.com/jswysnemc/dotfiles) 的模块化设计，
内容适配 Pullautumn 的 niri + waybar 配置。

## 目录结构

```
install.sh              引导层：校验环境 → 定位仓库 → 转交 setup/main.sh
setup/
  main.sh               编排层：解析参数 → 按顺序调用各阶段函数
  lib/
    config.sh           仓库地址、stow 包清单、必需软件包、AUR 包
    ui.sh               banner、section、print_*、confirm、dashboard
    exec.sh             exe / exe_live（带 spinner、写日志）
    state.sh            mark_done / is_done（断点续跑）
    flatpak.sh          按需装 flatpak、加 flathub 源、选国内镜像
    network.sh          GitHub 真实 GET 探测、/etc/hosts 修复（带备份回滚）、gh_clone / gh_retry 下载重试
  steps/
    01-preflight.sh     系统检查、基础工具、paru、定位仓库
    02-packages.sh      必需软件分组安装、AUR、可选软件 fzf 勾选（装包带转圈进度）
    03-dotfiles.sh      备份旧配置、stow 部署、壁纸链接（仅作者）、GTK 书签生成
    04-apps.sh          nvim / zsh / mpv / yazi
    05-system.sh        locale、PATH、PAM、matugen、系统服务、SDDM、用户目录
    99-completion.sh    完成提示与重启
  common-applist.txt    可选软件清单：安装时用 fzf 勾选，改这里就能增删
  resources/            安装器素材区：不走 stow，运行时复制到家目录
    必看-pullautumn-Niri使用方法.txt   部署后复制到 ~/
```

## 执行阶段

| 阶段函数 | 所在文件 | 作用 |
|---|---|---|
| `check_system` | 01 | 校验 Arch、非 root、pacman、网络；真实 GET 探测 GitHub 直连（含 Releases 下载域与吞吐记录），不通则用 `/etc/hosts` 修（`lib/network.sh`），写后仍不通自动回滚 |
| `install_base` | 01 | `pacman -Syu`，装 git / stow / base-devel |
| `install_aur_helper` | 01 | 添加 archlinuxcn 源，装 paru |
| `clone_dotfiles` | 01 | 本地运行直接用当前仓库，否则克隆到 `~/.dotfiles` |
| `install_packages` | 02 | 按 `PKG_GROUPS` 分组装必需包（已装的组直接记 OK），再逐包装必需的 AUR 包，全程不询问；失败包名上屏并写 `~/pullautumn-missing-packages.txt`，末尾用 `pacman -T` 复核（包组先展开，避免组名误报） |
| `install_optional_packages` | 02 | 读 `common-applist.txt`，fzf 勾选后按 repo / AUR / flatpak 分类安装（`--yes` 则全装） |
| `apply_dotfiles` | 03 | 备份 → stow → 壁纸链接（仅作者，其他人只建空目录） → 权限 → 生成 GTK 书签 → flatpak 覆盖。已部署过时 stow 跳过，但**执行位仍会补修一次**（x 位易丢，重跑即可修，不必 `--reset`） |
| `setup_nvim` | 04 | 装 neovim，同步 LazyVim 插件 |
| `setup_zsh` | 04 | 装 zsh，改默认 shell（配置由 zshenv/zsh 包提供） |
| `setup_mpv` | 04 | 装 mpv，可选下载 Anime4K（`gh_clone` 带 3 次重试） |
| `setup_yazi` | 04 | 装 yazi 与预览依赖，装插件（`gh_retry` 带 3 次重试） |
| `setup_locale` | 05 | 生成 en_US.UTF-8 与 zh_CN.UTF-8 |
| `setup_bash_path` | 05 | 把 `~/.local/bin` 加进 PATH |
| `setup_local_bin` | 05 | 本地脚本可执行权限 |
| `setup_qs_lock_pam` | 05 | 创建 `/etc/pam.d/qs-lock`（缺 howdy 时**询问是否安装**人脸识别，有 howdy 再加 `qs-lock-face` 并自动探测 `pam_howdy.so` / `pam_python.so`）。**每次运行都检查，不受 `is_done` 短路**，补装 howdy 后重跑即可 |
| `setup_quickshell` | 05 | 兜底 `Theme.js`、`uv sync`、注册 `qs-notifications.service` |
| `setup_matugen` | 05 | 用当前壁纸生成 Material You 配色 |
| `setup_desktop_tweaks` | 05 | 默认终端（kitty）、Nautilus 右键终端、窗口按钮、i2c 权限 |
| `enable_services` | 05 | NetworkManager / bluetooth / swayosd。蓝牙走「enable → 单独 start → 自检」三步，不用 `enable --now`：bluez 的 unit 带 `ConditionPathIsDirectory=/sys/class/bluetooth`，内核模块没加载时启动会被静默跳过却仍返回 0。未运行则置 `BT_SELFCHECK_FAILED`，由完成页提示补救命令 |
| `setup_sddm` | 05 | 装 SDDM + lunar-glass 主题，写 `/etc/sddm.conf.d/` drop-in，最后做只读自检（主题 / greeter / qt5-svg / drop-in / 自启），不通过则不标记完成 |
| `setup_user_dirs` | 05 | 建 `~/Pictures/Wallpapers` 等目录 |
| `show_completion` | 99 | 收尾提示（含待补装清单路径、SDDM 自检结果）与重启倒计时 |

## 常用命令

```bash
bash install.sh                 # 全量安装
bash install.sh --minimal       # 只装核心，跳过可选软件
bash install.sh --no-stow       # 只装软件，不动配置
bash install.sh --yes           # 全程自动确认（可选软件按清单全装），且不自动重启
bash install.sh --no-reboot     # 装完不自动重启
bash install.sh --reset         # 清空进度，重新开始
bash install.sh --mirror        # 跳过询问，直接启用 GitHub 镜像加速
bash install.sh --no-mirror     # 跳过询问，不用镜像
```

## 断点续跑

每完成一个阶段就写入 `~/.pullautumn_install_progress`，重跑时自动跳过已完成阶段。
日志写在 `~/.local/state/pullautumn/install-*.log`。

## 装失败的包怎么补

没装上的包会同时：在终端逐条列出包名、写入 `~/pullautumn-missing-packages.txt`、
并在完成页给出路径。文件里**只有一行是命令**，其余都是 `#` 注释，重启联网后
把整个文件内容复制粘贴到终端执行即可，不会多执行任何东西：

```bash
paru -S --needed --skipreview --noconfirm ttf-lxgw-wenkai-screen ...
```

文件末尾还附一段 `gh-mirror` 用法提示：补装时若又出现 `curl: (7)` / `git clone` 超时，
可以 `gh-mirror on` → 执行补装命令 → `gh-mirror off`（镜像只读不写，留着会让 `git push` 失败）。

> `/etc/hosts` 修复只能解决域名解析与建连。Releases 大文件下载到一半被断开
> （`curl: (35) Recv failure`）属于传输层问题，hosts 修不了，只能等网络稳定后补装。

## GitHub 镜像加速（可选）

安装脚本开头会**无条件问一次**要不要启用（回车不算回答，必须敲 `y` 或 `n`）。
问句上方会打印探测结果：

```
   [i] GitHub 连通性检测（最长约 7 秒）
   [i] github.com          : 直连不可达
   [i] gh-proxy.com        : 镜像可达 (3947B / 1.1s)
   [i] ghfast.top          : 镜像可达 (3947B / 0.8s)
```

探测做的是**真实 GET 取一段字节**，不是只看 HTTP 状态码 —— 上一个版本的
hosts 修复就是因为只看状态码而假阳性失效的。

### 它治的是哪种病

| 症状 | 病因 | 药 |
|---|---|---|
| `curl: (6) Could not resolve host` | DNS 污染 | `/etc/hosts`（`lib/network.sh`） |
| `curl: (7) Failed to connect ... after 21062 ms` | TCP/TLS 被阻断 | **镜像**（本节） |
| `curl: (35) Recv failure` | 传输中途被重置 | 镜像 + 重试；仍失败则进补装清单 |

hosts 只能决定「域名解析到哪个 IP」，改不了「这个 IP 连不上」。
所以两者互不替代：镜像开着时脚本会**跳过** hosts 修补。

### 它改了哪两处

| 文件 | 内容 |
|---|---|
| `~/.makepkg.conf` | 追加一段带标记的 `DLAGENTS`，`https::` 指向 `~/.local/share/pullautumn/gh-mirror/github-dl` |
| `~/.gitconfig` | 追加一段 `[include]`，指向 `~/.local/share/pullautumn/gh-mirror/gitconfig`（里面是 `url.insteadOf`） |

两处都**不需要 sudo**（`makepkg.conf` 的用户级配置优先级高于 `/etc/makepkg.conf`），
且都带 `# >>> pullautumn gh-mirror >>>` 标记，清除时按标记精确删除，
不会动你在标记之外写的任何配置。

> `~/.makepkg.conf` 如果原本是坏的，脚本会先备份成 `~/.makepkg.conf.pullautumn-bak`，
> `gh-mirror off` 时原样 `mv` 回来。

### 什么时候清除

- **正常装完**：完成页会再问一次「是否清除」，选 `y` 立即还原，选 `n` 保留。
  这一步在 `systemctl reboot` **之前**同步执行，不依赖 EXIT trap。
- **中途 Ctrl+C / 报错退出**：`cleanup()` 兜底还原。
- **断电 / `kill -9`**：文件会残留，下次跑 `install.sh` 时预检会发现并自动清除。
- **`--yes` 或非交互环境**：不问，按「不启用」进、按「清除」出。

### 手动操作

```bash
gh-mirror status     # 看当前状态、改了哪些文件
gh-mirror on         # 临时启用（补装失败的包时用）
gh-mirror off        # 清除，paru / git 恢复直连
gh-mirror probe      # 只探测连通性，不写文件
```

`gh-mirror` 随 `local-bin` 这个 stow 包部署到 `~/.local/bin`，装完就能直接敲。
安装之前它还不存在，用完整路径调用：

```bash
bash ~/.dotfiles/local-bin/.local/bin/gh-mirror on
```

### 两个必须知道的副作用

1. **镜像开着时 `git push` 会失败。** `insteadOf` 对 push 同样生效，而这类镜像
   只代理读取、不代写。要推送先 `gh-mirror off`。
2. **`-git` 类 AUR 包没有 `sha256sums` 校验。** release 资产 makepkg 会比对校验和，
   但 VCS 包直接 clone 最新提交，走第三方镜像理论上存在被投毒的可能。
   介意的话装完对一下 AUR 页面记录的 HEAD commit。

### 彻底手删（`gh-mirror` 已经不可用时）

```bash
rm -f ~/.makepkg.conf
# 再删掉 ~/.gitconfig 里这两行所在的三行块：
#   # >>> pullautumn gh-mirror >>>
#   [include]
#       path = ~/.local/share/pullautumn/gh-mirror/gitconfig
#   # <<< pullautumn gh-mirror <<<
rm -rf ~/.local/share/pullautumn/gh-mirror
```

## 要改什么，去哪里改

| 需求 | 位置 |
|---|---|
| 换仓库地址 | `lib/config.sh` 的 `DOTFILES_REPO` |
| 增删 stow 包 | `lib/config.sh` 的 `STOW_PACKAGES`（`uv` 是条件包，在数组之后按 `LEGACY_USER` 追加） |
| 增删**必需**软件 | `lib/config.sh` 的 `PKG_GROUPS` / `AUR_PACKAGES` |
| 增删**可选**软件 | `setup/common-applist.txt`（改这个文件即可，不用动脚本） |
| 改某个阶段的逻辑 | 对应的 `steps/*.sh` |
| 调整阶段顺序 | `main.sh` 的 `main()` |
| 新增阶段 | 在 `steps/` 里加函数，然后在 `main()` 里加一行调用 |

## 配置部署的几个特殊处理

- **mimeapps** 用绝对路径链接，因为桌面环境会直接写这个文件，避免写穿 stow 链接。
- **wallpaper/** 不走 stow，单独链接到 `~/Pictures/Wallpapers`。图片不进 git（9 张 35 MB），
  所以这条只在作者机器上成立：`TARGET_USER` 不等于 `LEGACY_USER`（默认 `pullautumn`）时，
  安装器会清空仓库里残留的图、只建一个空的 `~/Pictures/Wallpapers`。细则见
  `wallpaper/Pictures/Wallpapers/README.md`。
- **家目录路径**：配置里能自解析的都写成了 `~` / `$HOME` / `vim.fn.expand`，不再做批量替换。
  仅 GTK 书签由 `_dotfiles_generate_bookmarks` 按 `$HOME` 现生成；niri 的 `screenshot-path`
  写成 `~`，由 niri 自己展开并在缺失时自动创建目录。
  > 书签就是 **Nautilus 侧边栏的固定目录清单**（实测 51.1 不会自动列出标准 XDG 目录）。
  > 标准目录由首次登录的 `xdg-user-dirs-update` 创建，而书签在 Phase 3 就生成 ——
  > 所以生成函数先用 `xdg-user-dir` 查路径再 `mkdir -p` 补建，只判 `[[ -d ]]` 的老写法
  > 会只剩安装途中顺带建出来的 `~/Pictures` 一项。该函数也挂在 `apply_dotfiles` 的
  > is_done 短路里，重跑安装器能把半截书签补齐。
  > 早先版本用 `sed` 替换 `readlink -f` 解析出的文件，那实际是在改仓库（stow 会把
  > `~/.config/*` 折叠成指向仓库的软链），会把 `~/dotfiles` 改写成别人的用户名，已移除。
- **备份**：`~/.config/*` 下的同名配置会先移到 `~/.config-backup-<时间戳>`。
- **waybar-niri-Win11Like** 部署到独立目录 `~/.config/waybar-niri-Win11Like`，与主 waybar 不冲突；
  和主配置一起部署，用 `Mod+F2` / `Mod+F3` 切换两套样式。

## 只有作者机器才生效的配置

三处都拿 `TARGET_USER`（`id -un`）与 `LEGACY_USER`（默认 `pullautumn`，可用环境变量
`LEGACY_USER=xxx ./install.sh` 覆盖）比较，两边都小写化 —— 因为 MSYS 下 `id -un` 首字母
可能大写。这是唯一按用户名分流的地方，别的配置不做任何「作者 / 别人」区分。

| 位置 | 作者本人 | 其他人 |
|---|---|---|
| `_dotfiles_link_wallpapers` | 把仓库壁纸链到 `~/Pictures/Wallpapers` | 清空仓库里残留的图，只建一个空目录 |
| `STOW_PACKAGES` 末尾的 `uv` 追加 | 多一份 `~/.config/uv/uv.toml`（清华 PyPI 源） | 不部署这个包 |
| `_dotfiles_generate_bookmarks` | 侧栏多 `.config`、`.local` 两项 | 只有 6 项 |

`uv` 的**二进制**不在条件里：它在 `AUR_PACKAGES` 中，所有人都会装（`setup_quickshell`
的 `uv sync` 要用）；只有镜像配置是作者专属 —— 清华源跟地理位置绑定，对海外用户是减分项。

## 与上游的区别

- 配置内容全部来自 Pullautumn：niri + waybar + swaync + fuzzel/rofi + awww/waypaper + quickshell 锁屏。
- 移除了上游的 tmux / fish / ghostty 相关步骤。
- 显示管理器与上游一致用 SDDM（lunar-glass 主题），配置写进 `/etc/sddm.conf.d/` 的 drop-in。
- 新增 `--yes` / `--no-reboot` 参数。
- 蓝牙服务改成「enable → 单独 start → 自检」：上游用 `enable --now`，而 bluez 的 `ConditionPathIsDirectory` 不满足时启动会被静默跳过、命令仍返回 0，日志显示成功但实际没有守护进程。未运行时完成页会给出 `sudo systemctl restart bluetooth`。
- 可选软件改为独立清单 `common-applist.txt` + fzf 勾选，不再写在脚本里。
- 新增 Nautilus 右键终端：上游没有。Nautilus 43 之后原生「在终端中打开」不可配置，改由
  `nautilus-open-any-terminal`（AUR，靠 repo 的 `nautilus-python` 加载）注册菜单项，
  `setup_nautilus_terminal` 用 gsettings 把终端设为 kitty；纯 TTY 装机会话没有 dconf 连接，
  失败时自动套 `dbus-run-session` 重试。同时补装 `xdg-terminal-exec`，否则之前只写
  `~/.config/xdg-terminals.list` 却没有程序读取它。
  这一步单独成函数、且排在 `setup_desktop_tweaks` 的 `is_done` 短路之前，因为它坑过一次：
  AUR 包已经装好，但那一刻 `gschemas.compiled` 还没把它的 schema 编进去，`gsettings list-schemas`
  查不到 → 整段被判成「包没装上」，只打印一句 WARN 就跳过，右键菜单于是停在默认的 `gnome-terminal`
  （这台机器根本没装它，点了毫无反应）。现在每次运行都会「查不到 schema 就先
  `glib-compile-schemas` 再查 → 重设 → `gsettings get` 读回校验」，重跑安装器即可自愈。
