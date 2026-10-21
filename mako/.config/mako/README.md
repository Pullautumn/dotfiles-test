# mako

轻量通知守护进程。**本配置里默认不用它**，实际通知由 `swaync` 负责；这份是备用方案，想换回 mako 时装上 `mako` 包并把 `swaync` 从 autostart 里替换掉即可。

部署到 `~/.config/mako`。

## 文件

| 文件 | 说明 |
|---|---|
| `config` | 通知行为：位置、超时、边框、圆角、字体、历史记录 |
| `colors.conf` | **由 matugen 生成**，`include` 进主配置 |

## 关键参数

| 项 | 值 | 含义 |
|---|---|---|
| `anchor` | `top-right` | 出现在右上角 |
| `default-timeout` | `8000` | 默认 8 秒消失 |
| `border-size` / `border-radius` | 2 / 8 | 边框与圆角 |
| `icons` | 1 | 显示应用图标 |
| `max-visible` | 20 | 最多同屏 20 条 |
| `max-history` | 100 | 保留 100 条历史 |
| `margin` / `padding` | 10 / `10,0` | 外边距与内边距 |
| `font` | `adwaita sans regular 11` | 字体 |
| `history` | 1 | 开启历史浏览 |

## 用法

```bash
makoctl reload      # 改完配置重载
makoctl history     # 查看历史通知
makoctl dismiss     # 关掉当前通知
makoctl dismiss -a  # 全部关掉
makoctl mode        # 查看当前模式
```

## 注意

- 和 `swaync` **不能同时运行**，两者都抢 D-Bus 的通知服务名，后启动的那个会失败。
- 配置里没有开 `group-by`，同类通知不会合并；需要合并就加 `group-by=app-name`。
