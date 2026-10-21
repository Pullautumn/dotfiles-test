# yazi

终端文件管理器，`Mod+Y` 在 kitty 里打开。Rust 写的，异步 IO，图片 / 视频 / PDF 预览都是真的预览。

部署到 `~/.config/yazi`。

## 文件

| 文件 | 说明 |
|---|---|
| `yazi.toml` | 行为：布局比例、排序、预览规则、打开方式（opener）、任务并发、自定义 fetcher |
| `keymap.toml` | 各模式的按键：`[mgr]` `[tasks]` `[spot]` `[pick]` `[input]` `[confirm]` `[completion]` `[help]` |
| `theme.toml` | 配色（`[flavor]` `[mgr]` `[status]` `[select]` `[input]` `[completion]` `[tasks]` `[which]` `[help]` `[notify]`） |
| `init.lua` | 启动钩子 |
| `package.toml` | 插件依赖声明，`ya pkg install` 读它 |
| `plugins/` | 9 个插件，见下表 |

## 插件

| 插件 | 作用 |
|---|---|
| `chmod.yazi` | 可视化改文件权限 |
| `diff.yazi` | 文件对比 |
| `git.yazi` | 显示 git 状态、暂存、提交 |
| `mount.yazi` | 挂载 / 卸载磁盘 |
| `ouch.yazi` | 压缩解压（ouch 提供） |
| `skim.yazi` | 用 skim 做模糊搜索 |
| `skim-rg.yazi` | skim + ripgrep 全目录搜索 |
| `smart-enter.yazi` | 回车智能判断：文件用 opener 打开、目录进入 |
| `sudo.yazi` | 提权操作 |

安装 / 更新插件：

```bash
cd ~/.config/yazi && ya pkg install
```

安装器的 Phase 6d 会自动跑这一步。

## 关键行为

| 项 | 值 | 含义 |
|---|---|---|
| `[manager] folder_actions` | `["enter"]` | 回车直接进入目录 |
| `[manager] show_reveal` | `true` | 右键菜单显示「在文件管理器中显示」 |
| `[mgr] ratio` | `[1, 4, 3]` | 父目录 : 当前 : 预览 的宽度比例 |
| `[mgr] sort_by` | `natural` | 自然排序（`file2` 在 `file10` 前） |

## 依赖

| 包 | 用途 |
|---|---|
| `yazi` | 本体 |
| `ffmpeg` / `ffmpegthumbnailer` | 视频缩略图 |
| `poppler` | PDF 预览 |
| `imagemagick` | 图片处理 |
| `p7zip` | 压缩包预览与解压 |
| `fd` `ripgrep` `fzf` | 搜索 |
| `jq` | 处理 JSON 预览 |

安装器的 Phase 6d 会一并装齐（`--minimal` 之外）。

## 用法

```bash
yazi              # 在当前目录打开
yazi /path        # 指定目录
ya pkg list       # 已装插件
ya pkg upgrade    # 升级插件
```

`q` 退出、`~` 回 home、`.` 显示隐藏文件、`空格` 多选、`/` 搜索。

## 注意

- `theme.toml` 会被 matugen 覆盖（模板 `templates/yazi-theme.toml`），想保留自定义配色就把它挪到别处再 include。
- 插件是 git 子仓库形式提交在 `plugins/` 下的，`ya pkg install` 会重写这个目录；如果你改过插件源码，记得先备份。
- 预览大文件会卡：`yazi.toml` 的 `[preview]` 段可以按 MIME 类型关掉对应预览。
