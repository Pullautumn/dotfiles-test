# starship

跨 shell 提示符，Rust 写的，启动很快。zsh 里由 `.zshrc` 加载，显示目录、git 分支、命令耗时、语言版本等。

部署到 `~/.config/starship.toml`。

## 安装与启用

```bash
# 1. 装 starship（核心包清单里已有）
paru -S starship

# 2. 字体（Nerd Font 图标必需）
paru -S ttf-jetbrains-mono-nerd noto-fonts-cjk

# 3. 用安装器部署，或手动
cd ~/dotfiles && stow starship

# 4. 在 shell 里启用（zsh 配置已经包含这一行）
eval "$(starship init zsh)"
```

Bash 用 `eval "$(starship init bash)"`，Fish 用 `starship init fish | source`。

## 结构

| 项 | 说明 |
|---|---|
| `format` | 提示符顺序：shell → os → 用户名 → 主机名 → 目录 → 容器 → 各模块 → 字符 |
| `add_newline` | `false`，提示符之间不插空行 |
| `[character]` | 成功 `➜` 绿、失败 `➜` 红；vim 模式另有 `󰰒` / `󰬝` / `󰬙` |
| `[shell]` | 各 shell 的图标，当前 `disabled = true` |
| `[cmd_duration]` | 上条命令耗时 |
| `[git_branch]` / `[directory]` | 分支与目录 |
| `[custom.zsh_startup]` | 显示 zsh 启动耗时，数据由 `.zshrc` 的计时器写入 `STARSHIP_STARTUP_TIME` |
| `[os.symbols]` | 各发行版图标 |

另外声明了一批语言模块（`python` `nodejs` `rust` `golang` `java` `php` `ruby` `lua` `conda` `docker_context` `nix_shell` `memory_usage` 等），基本是 `disabled = true`，用到哪个把 `disabled` 改成 `false`。

## 用法

```bash
starship explain      # 逐段解释当前提示符每一段从哪来
starship timings      # 各模块耗时，排查「提示符卡顿」
starship config       # 打开配置文件
starship preset       # 内置预设列表
```

## 配色与 matugen

`matugen` 有模板 `templates/starship-colors.toml`，可以从壁纸生成一整套配色。当前没有接进自动注入流程，需要手动把生成结果合并进本文件。

## 注意

- `[shell]` 段 `disabled = true`，所以提示符开头不显示 zsh 图标；想显示就删掉那行。
- 提示符卡顿基本都出在 `git_branch` 和 `cmd_duration` 上，`starship timings` 能看到具体数字。
- 图标显示成方块说明 Nerd Font 没装或没生效，`fc-cache -fv` 之后重开终端。
