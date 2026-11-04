# Zsh Shell 配置

> **本仓库中的位置**：stow 包 `zsh`，部署到 `~/.config/zsh`；配套的 `zshenv` 包提供 `~/.zshenv`（设置 `ZDOTDIR`）。
> 用安装器跑的话，Phase 4 装好所有依赖、Phase 5 完成 stow、Phase 6b 询问是否 `chsh`，本文档的「从零开始安装」只需在手动部署时参考。
>
> **加载顺序**：`.zshrc` → `preload.zsh`（初始化 Zi，并 `source plugins.zsh` 装插件）→ `conf.d/*.zsh`（按文件名排序）→ `lastload.zsh`（Starship）。
>
> **`conf.d/` 下的模块**（共 10 个，全量列出）：
>
> | 文件 | 作用 |
> |---|---|
> | `00-functions.zsh` | 通用函数：代理开关/状态/测试、`y`（yazi 切目录）、`export_from_file`、`cv` |
> | `01-environment.zsh` | PATH（`~/.custom/bin`、pnpm、`~/.local/bin`）、Maven/JDK 变量、`fnm` 初始化 |
> | `02-optins.zsh` | `setopt` 选项、`^V` 编辑命令、补全与 fzf-tab 的 `zstyle`、`FZF_DEFAULT_OPTS` |
> | `04-grml.zsh` | grml 风格 `...` / `....` 上跳、`any` 函数、`Alt+S` 加 sudo |
> | `05-aliases.zsh` | 基础别名（**当前整份被注释，0 行生效**） |
> | `100-eza-aliases.zsh` | `eza` 别名（**当前整份被注释，0 行生效**） |
> | `101-archive-helper.plugin.zsh` | `arkh` 压缩解压命令提示（只打印不执行） |
> | `103-conda.zsh` | conda 懒加载（首次调用 `conda` 才 source） |
> | `104-expend-alias.zsh` | `Ctrl+X` 递归展开别名 |
> | `106-cmdh-expand.zsh` | `Ctrl+G` 调 `cmdh` 展开命令 |
>
> 插件由 `~/.config/zsh/plugins.zsh` 声明（不在 `conf.d/` 里，由 `preload.zsh` 末尾 `source`），
> 全部走 Zi；`preload.zsh` 在 Zi 目录不存在时会自动 `git clone` 一份，无需手动装。

Zsh (Z Shell) 是一个功能强大的交互式 shell，提供了丰富的配置选项和插件支持。此配置使用 Zi 作为插件管理器，集成了众多实用工具。

## 目录

- [从零开始安装](#从零开始安装)
- [目录结构](#目录结构)
- [配置特性](#配置特性)
- [插件列表](#插件列表)
- [自定义函数](#自定义函数)
- [环境变量](#环境变量)
- [别名](#别名)
- [依赖](#依赖)
- [快捷键](#快捷键)
- [故障排除](#故障排除)
- [配置文件](#配置文件)

## 从零开始安装

### 1. 安装 Zsh 和工具

```bash
# 核心
paru -S zsh

# 提示符
paru -S starship

# 命令行工具
paru -S fzf fd ripgrep bat eza zoxide atuin thefuck fnm unarchiver

# 语法高亮（AUR，非 zi 插件，plugins.zsh 里会直接调这个二进制）
paru -S zsh-patina
```

### 2. 应用配置

```bash
cd ~/.dotfiles
stow zsh
stow starship
```

### 3. 设置 Zsh 为默认 Shell

```bash
chsh -s /bin/zsh
```

### 4. 创建 .zshenv 文件

> **注意**：如果使用 dotfiles 安装脚本 (`install.sh`)，此步骤会自动完成。

Zsh 需要知道配置文件在 `~/.config/zsh/` 目录下，创建 `~/.zshenv`：

```bash
cat > ~/.zshenv << 'ZSHENV'
# Zsh config directory
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
ZSHENV
```

### 5. 安装插件

首次启动 Zsh 时，Zi 插件管理器会自动安装。如果需要手动安装：

```bash
# 删除旧的 Zi 目录（如果存在）
rm -rf ~/.local/share/zi

# 启动新终端，Zi 会自动克隆并安装
zsh
```

### 6. 验证安装

```bash
# 检查 Zsh 版本
zsh --version

# 检查插件是否加载
zi list

# 测试工具
starship --version
fzf --version
zoxide --version
```

## 目录结构

```
~/.config/zsh/
├── .zshrc              # 主配置文件（计时 → preload → conf.d → lastload）
├── .zshenv             # 由 ~/.zshenv 转进来，只补 ~/.local/bin 的 PATH
├── conf.d/             # 配置模块目录（按文件名排序加载）
│   ├── 00-functions.zsh              # 通用函数
│   ├── 01-environment.zsh            # 环境变量
│   ├── 02-optins.zsh                 # Zsh 选项 / 快捷键 / 补全
│   ├── 04-grml.zsh                   # GRML 风格函数
│   ├── 05-aliases.zsh                # 别名定义（当前整份注释）
│   ├── 100-eza-aliases.zsh           # Eza 别名（当前整份注释）
│   ├── 101-archive-helper.plugin.zsh # 压缩解压助手
│   ├── 103-conda.zsh                 # Conda 懒加载
│   ├── 104-expend-alias.zsh          # 别名递归展开
│   └── 106-cmdh-expand.zsh           # cmdh 命令展开
├── preload.zsh         # 预加载配置 (Zi 初始化 → source plugins.zsh)
├── plugins.zsh         # 插件配置（zi light / zi snippet）
├── lastload.zsh        # 最后加载配置 (Starship)
└── zsh-dependencies.txt # 依赖列表
```

## 配置特性

### 模块化配置

配置被拆分为多个模块，按数字顺序加载，便于维护：
- `00-*` ~ `04-*` - 基础函数、环境变量、选项、grml 风格
- `05-*` - 别名
- `100-*` ~ `106-*` - 工具集成（eza / arkh / conda / 别名展开 / cmdh）

### 启动时间优化

- 使用 Zi 异步加载插件
- 延迟加载补全系统
- 启动时间测量与 Starship 集成

### Zsh 启动时间测量

配置包含 Zsh 启动时间测量功能，首次启动时会在 Starship 提示符中显示启动时间。

## 插件列表

使用 [Zi](https://github.com/z-shell/zi) 管理插件：

| 插件 | 说明 |
|------|------|
| `colored-man-pages` | 彩色 man 页面（OMZ snippet） |
| `sudo` | `Esc Esc` 给当前命令补 sudo（OMZ snippet） |
| `zsh-vi-mode` | Vi 模式行编辑，`jj` 退出插入模式 |
| `zsh-completions` | 补全增强，配合 `zicompinit` 初始化 |
| `fzf-tab` | FZF 补全菜单（需要 `fzf`） |
| `atuin` | 历史记录管理，绑定 `Ctrl+R` |
| `zsh-sage` | 自动建议（替代 `zsh-autosuggestions`） |
| `zsh-patina` | 语法高亮（替代 `fast-syntax-highlighting`，**非 zi 插件**，走 `zvm_after_init` 调二进制） |

> `zsh-patina` 是独立的 Rust 二进制，不在 Zi 里，需要单独装：
> `paru -S zsh-patina`（AUR）。**已列进安装器的 `AUR_PACKAGES`**，一键安装会带上；
> 单独补装用上面那条。没装的话 `zvm_after_init` 会报 `command not found`。

### Zoxide 集成

智能目录跳转：

```bash
z foo      # 跳转到包含 foo 的最常用目录
zl         # 交互式选择目录
c          # 选择目录并 cd
```

### Atuin 集成

增强历史记录搜索：

```bash
Ctrl+R     # 搜索历史记录
```

## 自定义函数

### export_from_file

从文件导出环境变量：

```bash
export_from_file VAR_NAME /path/to/file "default_value"
```

### cv

清空文件并用编辑器打开：

```bash
cv <filename>
```

### 代理（`00-functions.zsh`）

端口固定写死 `127.0.0.1:7897`，改代理端口要同时改 5 处：

| 命令 | 作用 |
|---|---|
| `proxy_on` | 开代理 + 立刻用 `curl` 测 Google 连通性 |
| `proxy_off` | 清掉所有大小写代理变量 |
| `proxy_status` | 看当前代理变量 + 端口是否在监听 + 是否真能用 |
| `proxy_test` | 只测连通性 |
| `proxy on\|off\|status` | 上游风格的精简版，不做连通性测试 |
| `is_port_listening <port>` | 底层工具，`ss -tuln` 判断端口 |

### y（`00-functions.zsh`）

`yazi` 的 cd-on-exit 包装，退出 yazi 后当前 shell 会跟着切到最后浏览的目录。

### arkh（`101-archive-helper.plugin.zsh`）

**只打印**压缩/解压命令，不执行：

```bash
arkh c my_stuff.tar.gz file1.txt documents/   # 打印 tar -czvf ...
arkh x my_stuff.tar.gz                        # 打印 tar -xzvf ...
```

## 环境变量

### PATH 配置

```bash
export PATH=$HOME/.custom/bin:$PATH
export PATH=$PATH:$HOME/.local/share/cargo/bin
export PATH=$PATH:$HOME/.local/bin
```

### Maven / JDK（本机专用，换机器要改）

```bash
export MAVEN_HOME="/opt/JetBrains/idea/plugins/maven/lib/maven3/"
export MVND_HOME="/opt/maven-mvnd"
export JAVA_HOME="/opt/java/zulu8.92.0.21-ca-fx-jdk8.0.482"
```

> ⚠️ 这三段是写死的本机路径，安装器**不会**创建 `/opt/JetBrains`、`/opt/java`、`/opt/maven-mvnd`。
> 换台机器用这份配置时，`JAVA_HOME` 会指向不存在的目录，容易让依赖它的工具（构建脚本、IDE 启动器）报错，
> 建议按需删掉或改成条件判断。

### fnm（Node 版本管理）

```bash
eval "$(fnm env --use-on-cd --shell zsh)"
```

`fnm` 由安装器的 `shell` 组安装；手动部署时记得 `paru -S fnm`，否则每次开 shell 都会报 `command not found`。

### pnpm 配置

```bash
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
```

### 编辑器

```bash
export EDITOR=nvim
```

## 别名

### Eza 别名 (ls 替代)

| 别名 | 命令 | 用途 |
|------|------|------|
| `ls` | `eza --git -g` | 干净输出，可管道 |
| `l` | `eza -l --git -g` | 长格式 |
| `la` | `eza -la --git -g` | 含隐藏文件 |
| `lls` | `eza --icons --git -g` | 网格 + 图标 |
| `lla` | `eza --icons --git -g -al` | 网格 + 图标 + 隐藏 |
| `ll` | `eza -la --header --icons --git -g` | 日常主力 |
| `llt` | `ll` + `-s modified` | 按修改时间排 |
| `llS` | `ll` + `-s size` | 按大小排 |
| `tree2` | `eza --tree --level=2 --icons -g` | 两层树 |

> ⚠️ 以上别名在 `conf.d/100-eza-aliases.zsh` 里**目前整份被注释掉**（每行都是 `# # alias ...`），
> 实际生效的 `ls` 仍是系统原生 `ls`。要启用就把 `# # ` 前缀去掉。

### 常用别名

查看 `conf.d/05-aliases.zsh` 获取完整别名列表。

> ⚠️ `05-aliases.zsh` 目前**整份被注释掉**（43 行、0 行生效），
> 也就是说 `v` / `nv` / `vi` / `lg` / `gc` / `ssta` / `s` 这些别名现在都不存在。
> 这份文件里还有 `snap-all`、`ccr`（见 `01-environment.zsh`）等本机专用别名，启用前先按自己环境挑。

## 依赖

### 核心依赖

| 包名 | 用途 |
|------|------|
| `zsh` | Shell |
| `git` | 插件克隆 |

### 推荐工具

| 包名 | 用途 |
|------|------|
| `starship` | 提示符 |
| `fzf` | 模糊查找 |
| `fd` | 文件查找 |
| `ripgrep` | 快速搜索 |
| `bat` | 文件查看 |
| `eza` | 现代 ls |
| `zoxide` | 智能目录跳转 |
| `atuin` | 历史记录管理 |
| `thefuck` | 命令纠错 |
| `fnm` | Node 版本管理（`01-environment.zsh` 里 `eval "$(fnm env ...)"`） |
| `zsh-patina` | 语法高亮（AUR，缺了会在启动时报 `command not found`） |
| `unarchiver` | `101-archive-helper.plugin.zsh` 用到的解包工具 |

### 可选依赖

| 包名 | 用途 |
|------|------|
| `neovim` | 默认编辑器 |
| `curl` | HTTP 客户端 |
| `wget` | 下载工具 |

## 快捷键

| 快捷键 | 功能 | 定义位置 |
|--------|------|----------|
| `jj` | 退出插入模式 (Vi 模式) | `plugins.zsh` |
| `Ctrl+V` | 用 `$EDITOR` 编辑当前命令（等价 `vl`） | `02-optins.zsh` |
| `Ctrl+X` | 递归展开当前行的别名 | `104-expend-alias.zsh` |
| `Ctrl+G` | 用 `cmdh` 展开当前命令 | `106-cmdh-expand.zsh` |
| `Ctrl+←` / `Ctrl+→` | 按单词左右移动 | `02-optins.zsh` |
| `Ctrl+L` | 有建议就接受，没建议就清屏 | `plugins.zsh`（sage） |
| `→` | 接受自动建议 | `plugins.zsh`（sage） |
| `Ctrl+R` | 搜索历史记录 (Atuin) | `plugins.zsh` |
| `Esc Esc` / `Alt+S` | 在命令前添加 sudo | OMZ `sudo` + `04-grml.zsh` |

## 故障排除

### Zi 插件安装失败

```bash
# 删除 Zi 目录重新安装
rm -rf ~/.local/share/zi
zsh
```

### 补全不工作

```bash
# 重建补全缓存
rm -rf ~/.cache/zsh/zcompdump*
compinit
```

### Starship 不显示

确保在终端模拟器中（不是 Linux 控制台）：

```bash
# 检查终端类型
echo $TERM
```

### 启动时报 `zsh-patina: command not found`

`plugins.zsh` 的 `zvm_after_init` 会调这个二进制，但 zi 管不到它：

```bash
paru -S zsh-patina     # AUR（安装器的 AUR_PACKAGES 里已有，重跑安装也会装）
command -v zsh-patina  # 验证
```

> 这一行报错只影响语法高亮，不影响 shell 功能。如果暂时不想装，
> 可以把 `plugins.zsh` 里的 `zvm_after_init` 改成
> `(( $+commands[zsh-patina] )) && eval "$(zsh-patina activate)"` 静默跳过。

### 别名不生效

先确认文件里是不是全被注释了（当前 `05-aliases.zsh` 和 `100-eza-aliases.zsh` 就是全注释状态）：

```bash
grep -cE '^[[:space:]]*[^#[:space:]]' ~/.config/zsh/conf.d/05-aliases.zsh
alias | head
```

### 语法/加载报错排查

`conf.d/` 里任何一个文件解析失败，后面的模块和它自己的 widget 都不会注册。快速定位：

```bash
# 逐个语法检查（zsh 自带的 -n 只解析不执行）
for f in ~/.config/zsh/{preload,plugins,lastload}.zsh ~/.config/zsh/conf.d/*.zsh; do
  zsh -n "$f" || echo "FAIL: $f"
done
```

### 启动慢

```bash
# 启用性能分析
# 取消 .zshrc 中 zmodload zsh/zprof 的注释
# 然后在末尾取消 zprof 的注释
```

## 配置文件

| 文件 | 说明 |
|------|------|
| [`.zshrc`](.zshrc) | 主配置文件 |
| [`.zshenv`](.zshenv) | 环境变量配置 |
| [`preload.zsh`](preload.zsh) | 预加载配置 |
| [`plugins.zsh`](plugins.zsh) | 插件配置 |
| [`lastload.zsh`](lastload.zsh) | 最后加载配置 |
| [`conf.d/`](conf.d/) | 模块化配置目录 |

## 许可

MIT License
