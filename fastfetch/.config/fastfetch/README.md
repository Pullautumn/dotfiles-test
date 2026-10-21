# fastfetch

系统信息展示，开终端时的「欢迎页」。比 neofetch 快很多，配置也更细。

部署到 `~/.config/fastfetch`。

## 文件

| 文件 | 说明 |
|---|---|
| `config.jsonc` | 主配置：logo 与模块列表 |
| `gpu.jsonc` | GPU 专用信息（可单独 `fastfetch -c gpu.jsonc` 查看） |
| `config.jsonc.bak` | 旧备份 |
| `logo/` | 一组 ASCII / 图标 logo 文件 |

## logo

当前用的是文件型 logo：

```jsonc
"logo": {
    "type": "file",
    "source": "~/.config/fastfetch/logo/laffey.txt"
}
```

`logo/` 里还有多个可换的：

| 文件 | 说明 |
|---|---|
| `laffey.txt` | 当前使用（文字型） |
| `arch.icon` | Arch 图标 |
| `hyprland.icon` | Hyprland 图标 |
| `agk_clan.icon` / `aisaka.icon` / `geass.icon` | 动漫主题图标 |
| `loli.icon` / `pochita.icon` / `ryuzaki.icon` | 动漫主题图标 |

换 logo 只改 `source` 那一行。

## 显示模块

`config.jsonc` 里依次是：

```
file(发行版) · kernel · custom(分隔线) · host · memory · cpu · gpu · disk
· custom(分隔线) · shell · lm(登录管理器) · wm · terminal · de
· packages · gpu · display · custom(分隔线) · wifi · battery · disk · uptime
```

其中 `custom` 类型在本配置里只是**分隔线**（`>-----------<+>-----`），用来把信息分成几块，不调用外部脚本。

## 用法

```bash
fastfetch                # 用主配置
fastfetch -c gpu.jsonc   # 只看 GPU
fastfetch --gen-config   # 生成一份默认配置（会覆盖，慎用）
fastfetch -l arch        # 临时换 logo
```

## 注意

- matugen 会重写 `config.jsonc`（模板 `templates/fastfetch-config.jsonc`），也就是说**手工改的内容会在换壁纸后被覆盖**。想保留自定义就改模板，或者把本文件复制成 `my.jsonc` 用 `-c my.jsonc`。
- 想看某一项的耗时：`fastfetch --format json` 与 `time fastfetch`。
