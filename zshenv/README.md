# zshenv

一个文件：`~/.zshenv`。作用是让 zsh 知道配置到底放在哪。

部署到 `~/.zshenv`（仓库里的 `zsh` 包也有个 `.config/zsh/.zshenv`，那个是 PATH 补充，两份别搞混）。

## 内容

```zsh
# Zsh config directory
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
```

两步：

1. `ZDOTDIR` 指向 `~/.config/zsh`，之后 zsh 会去那里找 `.zshrc`、`.zprofile` 等，而不是 `~/.zshrc`。
2. 如果 `~/.config/zsh/.zshenv` 存在就 source 它——那份由 `zsh` 包提供，里面是 `~/.local/bin` 的 PATH 补充。

## 为什么必须单独一个包

`~/.zshenv` 必须在 `$HOME` 根目录，不能放进 `.config/zsh`（zsh 还没读到 `ZDOTDIR` 之前就要执行它）。所以它作为一个独立 stow 包存在，包里只有一个位于顶层 `.zshenv` 的文件。

## 验证

```bash
echo $ZDOTDIR          # 应该是 /home/<你的用户名>/.config/zsh
zsh -c 'echo $ZDOTDIR' # 非交互也要正确
```

## 注意

- 这个文件不能删。删了之后 zsh 会去读 `~/.zshrc`（不存在），配置全部失效，等于裸 shell。
- 换用户名后 `$HOME` 是动态的，不需要改；但如果手工写过绝对路径就要改。
- 安装器的 `03-dotfiles.sh` 在部署前会备份已有的 `~/.zshenv` 到 `~/.config-backup-<时间戳>`。
