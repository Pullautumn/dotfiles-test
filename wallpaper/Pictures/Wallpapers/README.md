# Wallpapers

这个目录是 `~/Pictures/Wallpapers` 的链接目标（由 `_dotfiles_link_wallpapers` 建立）。
**图片本身不进 git**：9 张约 35 MB，而 git 只能整仓下载，提交进去就等于让每个
clone 的人都付这份体积，没法按用户分流。

## 安装器怎么处理它

| 安装者 | 行为 |
| --- | --- |
| `pullautumn`（`LEGACY_USER`） | 目录里有图 → 链接到 `~/Pictures/Wallpapers` |
| 其他人 | 先清空本目录（只留这份 `README.md`），再建一个空的 `~/Pictures/Wallpapers` |

其他人想用自己的壁纸，直接把图丢进 `~/Pictures/Wallpapers` 即可，跟本仓库无关。

清空只针对**仓库里的这个目录**：`git pull` 不会删掉已经在工作副本里的图，所以老 clone
或手工拷贝进来的 35 MB 会在这一步被清掉。`~/Pictures/Wallpapers` 属于用户自己，安装器
不删它（作者链接时若已存在实体目录，也只改名备份成 `Wallpapers.bak.<时间戳>`）。

## 作者换机器时

壁纸不在 git 里，所以新机器 clone 下来这个目录是空的（只剩这份 README）。把备份
（网盘 / 移动硬盘）里的图放回本目录，再跑一次 `./install.sh` 即可建立链接。

如果换了个用户名安装，想让新账号也算「作者」，装的时候覆盖一下：

```bash
LEGACY_USER=<新用户名> ./install.sh
```

## 注意

`.gitignore` 只对**未跟踪**文件生效。这 9 张图如果之前已经提交过，加 ignore 不会让它们
退出仓库，需要手动执行一次：

```bash
git rm --cached wallpaper/Pictures/Wallpapers/*.jpg
git commit -m "wallpapers: 不再跟踪图片"
```
