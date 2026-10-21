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
  steps/
    01-preflight.sh     系统检查、基础工具、paru、定位仓库
    02-packages.sh      必需软件分组安装、AUR、可选软件逐项询问
    03-dotfiles.sh      备份旧配置、stow 部署、壁纸链接、路径替换
    04-apps.sh          nvim / zsh / mpv / yazi
    05-system.sh        locale、PATH、PAM、matugen、系统服务、ly、用户目录
    99-completion.sh    完成提示与重启
  common-applist.txt    可选软件清单：安装时逐项询问，改这里就能增删
  resources/            安装器素材区：不走 stow，运行时复制到家目录
    必看-pullautumn-Niri使用方法.txt   部署后复制到 ~/
```

## 执行阶段

| 阶段函数 | 所在文件 | 作用 |
|---|---|---|
| `check_system` | 01 | 校验 Arch、非 root、pacman、网络 |
| `install_base` | 01 | `pacman -Syu`，装 git / stow / base-devel |
| `install_aur_helper` | 01 | 添加 archlinuxcn 源，装 paru |
| `clone_dotfiles` | 01 | 本地运行直接用当前仓库，否则克隆到 `~/.dotfiles` |
| `install_packages` | 02 | 按 `PKG_GROUPS` 分组装必需包，再装必需的 AUR 包 |
| `install_optional_packages` | 02 | 读 `common-applist.txt`，逐项询问后按 repo / AUR / flatpak 分类安装（`--yes` 则全装） |
| `apply_dotfiles` | 03 | 备份 → stow → 壁纸链接 → 权限 → 用户名替换 → flatpak 覆盖 |
| `setup_nvim` | 04 | 装 neovim，同步 LazyVim 插件 |
| `setup_zsh` | 04 | 装 zsh，改默认 shell（配置由 zshenv/zsh 包提供） |
| `setup_mpv` | 04 | 装 mpv，可选下载 Anime4K |
| `setup_yazi` | 04 | 装 yazi 与预览依赖，装插件 |
| `setup_locale` | 05 | 生成 en_US.UTF-8 与 zh_CN.UTF-8 |
| `setup_bash_path` | 05 | 把 `~/.local/bin` 加进 PATH |
| `setup_local_bin` | 05 | 本地脚本可执行权限 |
| `setup_gtklock_pam` | 05 | 创建 `/etc/pam.d/gtklock` |
| `setup_matugen` | 05 | 用当前壁纸生成 Material You 配色 |
| `setup_desktop_tweaks` | 05 | 默认终端、窗口按钮、i2c 权限 |
| `enable_services` | 05 | NetworkManager / bluetooth / swayosd |
| `setup_ly` | 05 | 装 ly 并启用 `ly@tty1` |
| `setup_user_dirs` | 05 | 建 `~/Pictures/Wallpapers` 等目录 |
| `show_completion` | 99 | 收尾提示与重启倒计时 |

## 常用命令

```bash
bash install.sh                 # 全量安装
bash install.sh --minimal       # 只装核心，跳过可选软件
bash install.sh --no-aur        # 不装 paru（AUR 包会被跳过）
bash install.sh --no-stow       # 只装软件，不动配置
bash install.sh --yes           # 全程自动确认（可选软件按清单全装）
bash install.sh --no-reboot     # 装完不自动重启
bash install.sh --reset         # 清空进度，重新开始
```

## 断点续跑

每完成一个阶段就写入 `~/.pullautumn_install_progress`，重跑时自动跳过已完成阶段。
日志写在 `~/.local/state/pullautumn/install-*.log`。

## 要改什么，去哪里改

| 需求 | 位置 |
|---|---|
| 换仓库地址 | `lib/config.sh` 的 `DOTFILES_REPO` |
| 增删 stow 包 | `lib/config.sh` 的 `STOW_PACKAGES` |
| 增删**必需**软件 | `lib/config.sh` 的 `PKG_GROUPS` / `AUR_PACKAGES` |
| 增删**可选**软件 | `setup/common-applist.txt`（改这个文件即可，不用动脚本） |
| 改某个阶段的逻辑 | 对应的 `steps/*.sh` |
| 调整阶段顺序 | `main.sh` 的 `main()` |
| 新增阶段 | 在 `steps/` 里加函数，然后在 `main()` 里加一行调用 |

## 配置部署的几个特殊处理

- **mimeapps** 用绝对路径链接，因为桌面环境会直接写这个文件，避免写穿 stow 链接。
- **wallpaper/** 不走 stow，单独链接到 `~/Pictures/Wallpapers`。
- **路径替换**：配置里硬编码了 `/home/pullautumn`，部署时会替换成当前用户的家目录；
  同时会修掉 waypaper 里残留的 `/home/shorin`。当前用户就是 pullautumn 时自动跳过。
- **备份**：`~/.config/*` 下的同名配置会先移到 `~/.config-backup-<时间戳>`。
- **waybar-niri-Win11Like** 部署到独立目录 `~/.config/waybar-niri-Win11Like`，与主 waybar 不冲突；
  和主配置一起部署，用 `Mod+F2` / `Mod+F3` 切换两套样式。

## 与上游的区别

- 配置内容全部来自 Pullautumn：niri + waybar + swaync + fuzzel/rofi + awww/waypaper + gtklock。
- 移除了上游的 quickshell / tmux / fish / ghostty / SDDM 相关步骤。
- 显示管理器使用 ly（`ly@tty1`），不再使用 SDDM。
- 新增 `--yes` / `--no-reboot` 参数。
- 可选软件改为独立清单 `common-applist.txt` + 逐项询问，不再写在脚本里。
