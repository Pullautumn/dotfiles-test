# tlpui

`tlpui` 是 TLP（笔记本电源管理）的图形前端。这里只保存了窗口状态：尺寸、位置、上次停留的页面、界面语言。

部署到 `~/.config/tlpui`。

> **注意**：这个包**不在**安装器的 `STOW_PACKAGES` 里，`install.sh` 不会自动部署。要用得手动 stow。

## 文件

| 文件 | 说明 |
|---|---|
| `tlpui.cfg` | 界面状态：语言 `zh_CN`、窗口尺寸 2033×1387、上次选中的分类与位置 |

## 要不要用它

先看有没有 TLP：

```bash
pacman -Q tlp tlpui
```

没有的话：

```bash
paru -S tlp tlpui
sudo systemctl enable --now tlp
```

## 手动部署

```bash
cd ~/dotfiles
stow -d ~/dotfiles -t ~ tlpui
# 撤销
stow -d ~/dotfiles -t ~ -D tlpui
```

## 说明

- 这个配置文件没有实质性的电源策略内容，**所有 TLP 参数都在 `/etc/tlp.conf`**，由 `tlpui` 读写。换机器后窗口位置之类会自己重建，没什么保留价值。
- 窗口尺寸是 `2033×1387`，小屏幕上打开会自动缩小，不会超出屏幕。
- 如果只是想省电又不想装 GUI，直接编辑 `/etc/tlp.conf` 更轻量。

## 建议

仓库里保留这个包主要是记录「曾经用过 tlpui」。如果确定不用 TLP，可以整个目录删掉，`README` 也不用留。
