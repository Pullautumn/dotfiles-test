# local-share-fcitx5

fcitx5 的**用户级数据**，目前只有一份 Rime 定制补丁。

部署到 `~/.local/share/fcitx5`。

## 文件

| 文件 | 说明 |
|---|---|
| `rime/default.custom.yaml` | 对 Rime 默认方案的补丁：锁定输入方案、改选词键位、改翻页键 |

## default.custom.yaml 做了什么

```yaml
patch:
  ascii_composer:
    good_old_caps_lock: true      # Caps Lock 仍是大小写切换，不切成英文输入
    switch_key:                   # 把 Shift 让给 fcitx5 的 TriggerKeys
      Shift_L: noop               # 不设这两行，左 Shift 切中英会被 Rime 先截走
      Shift_R: noop
  schema_list:
    - schema: rime_ice            # 只用雾凇拼音
  "menu/page_size": 9             # 每页 9 个候选
```

`switch_key` 只写了两个 Shift，没列出的 `Control_L` / `Control_R` / `Caps_Lock` 保持 librime
内置默认（`noop` / `noop` / `clear`），不受影响。

选词与翻页键位：

| 操作 | 键 |
|---|---|
| 选第 1-9 个候选 | 数字键 `1`–`9` |
| 上下选词 | `←` / `→` |
| 下移一条 | `Tab` |
| 翻页 | `↑` / `↓`，或 `,` / `.` |
| 翻页（备选，已注释） | `[` / `]` |

## 生效

Rime 的补丁文件改完必须重新部署。`fcitx5-remote -r` **不够**：它只重载 fcitx5 自己的配置，
不会让 Rime 重新编译（实测删掉编译产物后它也没有重建）。要删掉编译产物再重启进程：

```bash
rm -f ~/.local/share/fcitx5/rime/build/default.yaml
pkill -x fcitx5; fcitx5 -d
```

也可以不做上面这步，直接在托盘图标右键 →「重新部署」。

验证是否编进去了：重编后 `~/.local/share/fcitx5/rime/build/default.yaml` 的 `ascii_composer:`
段里应该能看到 `switch_key: {Shift_L: noop, Shift_R: noop}`。

## 前置条件

`default.custom.yaml` 里的 `rime_ice` 方案来自**雾凇拼音**，对应两个包：

| 包 | 提供的内容 |
|---|---|
| `fcitx5-rime` | Rime 引擎本身 |
| `rime-ice-git` | 雾凇拼音方案（`rime_ice` schema + 词库，AUR） |

两个都在核心包清单的 `input` 组里，一键安装会一起装上。方案文件由 `rime-ice-git` 装到系统共享
数据目录（`/usr/share/rime-data/`），Rime 直接从那里加载，**不需要**手工往 `~/.local/share/fcitx5/rime/`
里拷任何东西 —— 这个用户目录只放你自己的补丁和 `*.custom.yaml`。

首次启动会自动编译词库，可能要十几秒；没编完就 `fcitx5-remote -r`，或在托盘菜单里点「重新部署」。

## 注意

- `schema_list` 里只留了 `rime_ice`。如果你装的是别的方案（比如明月拼音），把这里改成对应 schema 名，否则输入法会回落到默认方案。
- Rime 的自定义文件命名规则是「原名 + `.custom`」：想改 `luna_pinyin` 的配置就建 `luna_pinyin.custom.yaml`，不是在这里改。
- `rime/default.custom.yaml` 会和 `~/.local/share/fcitx5/rime/default.yaml` 合并，后者是自动生成的，别手改。
- Rime 报错时看 `~/.local/share/fcitx5/rime/` 下的 `*.log`，比界面提示有用。
