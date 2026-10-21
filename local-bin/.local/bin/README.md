# local-bin

自定义命令入口，放三个脚本到 `~/.local/bin`。这个目录已经在 PATH 里（`setup_bash_path` 负责），所以脚本名可以直接当命令用。

## 脚本

| 文件 | 作用 |
|---|---|
| `niri-session-wlroots` | 用 `wlroots` 作为 `XDG_CURRENT_DESKTOP` 启动 niri |
| `quicksave` | 创建 Btrfs 快照（存档） |
| `quickload` | 从 Btrfs 快照恢复（读档） |

## niri-session-wlroots

```sh
#!/bin/sh
export XDG_CURRENT_DESKTOP=wlroots
export XDG_SESSION_DESKTOP=niri
exec niri-session "$@"
```

比直接 `niri-session` 多做一件事：把 `XDG_CURRENT_DESKTOP` 设成 `wlroots`。Electron、Qt 之类靠这个变量判断「该走 Wayland 还是 X11」。

`environment.d` 包里也有一条 `XDG_CURRENT_DESKTOP=wlroots`，两者效果相同，任选。

装 ly 的时候，会话项指向哪个都行；想让桌面变量更"标准"（`niri`）就直接 `niri-session`。

## quicksave / quickload

基于 **Btrfs + snapper** 的快照工具，有中英双语界面，普通用户即可运行（权限不够时会请求提权，自动把 wheel 组加进配置）。

依赖：

| 包 | 用途 |
|---|---|
| `snapper` | 快照管理后端 |
| `btrfs-progs` | Btrfs 工具 |
| 根分区是 Btrfs 且配好了 snapper 配置 | 否则 `quicksave -lc` 会提示「未检测到任何 snapper 配置」 |

常用：

```bash
quicksave                      # 用默认描述创建快照
quicksave -c root -d "装驱动前"  # 指定配置与描述
quicksave -l                   # 列出快照
quicksave -lc                  # 列出可用的 snapper 配置
quicksave -del 12              # 删掉 ID 12 的快照

quickload                      # 交互式选快照恢复
quickload -c root -l           # 看 root 配置下有哪些可恢复的快照
quickload -c root -n           # 直接恢复，不再确认
```

niri 里 `Mod+F5` 存档、`Mod+F8` 读档。

## 注意

- `quicksave` / `quickload` 是**强依赖 Btrfs** 的。ext4 上跑会直接报错退出，不是坏了。
- 恢复快照本身是危险操作，`quickload -n` 不给二次确认；不熟悉就先 `-l` 看看，别直接 `-n`。
- 这两个脚本带 `set -euo pipefail`，任何一步失败都会立刻中止——这是有意的，避免半途恢复。
- `~/.local/bin` 是 stow 会合并的共享目录，安装器**不会**备份或整体替换它，只往里加文件。
