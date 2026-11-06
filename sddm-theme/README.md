# Lunar Glass

一款融合中式美学与现代设计的 SDDM 登录主题。农历日历 + 毛玻璃质感，为你的 Linux 桌面带来独特的登录体验。

## 预览

![Preview](background.png)

## 特性

- 🌙 农历日期显示（天干地支、生肖年）
- 🕐 实时时钟
- 👤 用户头像自动加载
- 🔐 密码登录 + 人脸识别支持
- ⌨️ 内置虚拟键盘
- 🖥️ 桌面环境选择器
- 💤 睡眠/重启/关机快捷操作
- 🎨 毛玻璃风格 UI

## 人脸识别

本主题支持通过 PAM 人脸识别模块实现无密码登录。

### 工作原理

主题通过 SDDM 的 PAM 认证机制实现人脸识别：

1. 用户点击人脸识别按钮（或登录界面加载后自动触发）
2. 主题调用 `sddm.login(username, "", sessionIndex)` 发起空密码认证请求
3. PAM 模块链中的人脸识别模块（如 Howdy）接管认证流程
4. 认证成功后 SDDM 完成登录，失败则显示错误提示

### 配置 Howdy（推荐）

[Howdy](https://github.com/boltgolt/howdy) 是 Linux 上流行的人脸识别方案。

1. 安装 Howdy：

```bash
# Arch Linux
yay -S howdy

# Ubuntu/Debian
sudo add-apt-repository ppa:boltgolt/howdy
sudo apt update && sudo apt install howdy

# Fedora
sudo dnf copr enable principis/howdy
sudo dnf install howdy
```

2. 录入人脸：

```bash
sudo howdy add
```

3. 配置 PAM，编辑 `/etc/pam.d/sddm`，在文件开头添加：

```
auth sufficient pam_python.so /lib/security/howdy/pam.py
```

4. 测试：

```bash
sudo howdy test
```

### 界面交互

- 点击头像旁的人脸图标手动触发识别
- 识别中：头像边框蓝色脉冲动画
- 识别成功：边框变绿
- 识别失败：边框变红 + 抖动动画

### 其他 PAM 人脸识别方案

- [pam-face-authentication](https://github.com/pam-face-authentication/pam-face-authentication)
- [face_recognition](https://github.com/ageitgey/face_recognition) + 自定义 PAM 模块

## 安装

> 本目录**不含上游的 `install.sh`**。安装由仓库根目录的一键安装器负责
> （`setup/steps/05-system.sh` 里的 `setup_sddm`），它会装包、拷主题、
> 写 `/etc/sddm.conf`、启用服务。手动装的话按下面第 2 节的步骤做。

### 通过安装器（推荐）

```bash
cd ~/dotfiles
bash install.sh          # Phase 9b 会问要不要装 SDDM
```

### 手动安装

1. 复制到 SDDM 主题目录：

```bash
sudo cp -r . /usr/share/sddm/themes/lunar-glass
```

2. 编辑 SDDM 配置文件 `/etc/sddm.conf`：

```ini
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --no-global-shortcuts --locale1

[Theme]
Current=lunar-glass
```

3. 装齐 Qt5 QML 依赖和 greeter 用的合成器：

```bash
sudo pacman -S --needed sddm qt5-declarative qt5-quickcontrols \
    qt5-quickcontrols2 qt5-wayland qt6-wayland kwin
```

> `kwin_wayland` 是上游的做法，效果最稳，但会带进一批 KDE 依赖。
> 想省空间可以换成 `CompositorCommand=weston --shell=kiosk`（约 5MB），
> 或者在 `[Wayland]` 段留空让 SDDM 退回 X11 greeter（需要 xorg-server）。

4. 启用服务（**不要 `systemctl start`**，会当场把当前图形会话踢掉）：

```bash
sudo systemctl disable ly@tty1      # 如果之前用的是 ly
sudo systemctl enable sddm
# 重启生效
```

出问题时的救命步骤（TTY: `Ctrl+Alt+F2`）：

```bash
sudo systemctl disable sddm
sudo systemctl enable --now ly@tty1
```

## 配置

编辑 `theme.conf` 自定义主题：

```ini
[General]
background=background.png  # 背景图片
avatar=avatar.jpg          # 登录头像
type=image                 # image 或 color
color=#1d1f21              # 纯色背景色
fontSize=14
fontFamily="Noto Sans"
```

`background` 和 `avatar` 都写**相对文件名**，解析基准是本主题目录（Qt 拿 QML 文件所在目录当
baseUrl）。只有想指向主题目录以外时才需要写 `file:///绝对路径`；裸绝对路径会被当成相对路径
拼到主题目录后面，结果是一张空图。

`avatar` 由 `Main.qml` 的 `source: config.avatar || ...` 读取，后半段保留了原来的
`file:///home/<用户名>/.face` 兜底 —— 把 `theme.conf` 里的 `avatar` 删掉就退回读家目录的 `.face`。

## 换头像 / 换背景

两者都是**覆盖同名文件**，不需要改配置：

```bash
cd ~/.dotfiles/sddm-theme

# 头像：正方形，建议 288×288 或 512×512（容器 96×96 圆形，自动居中裁圆）
cp 新头像.jpg avatar.jpg

# 背景：不低于屏幕分辨率，体积控制在 2–3MB（greeter 每次登录都要重新解一遍）
cp 新背景.png background.png
```

改完同步到系统 —— `sddm-theme/` 是**拷贝部署**（`setup_sddm` 的 `cp -rf`），不是 stow 软链，
改仓库不会自动落到 `/usr/share`：

```bash
sudo cp theme.conf       /usr/share/sddm/themes/lunar-glass/theme.conf
sudo cp Main.qml         /usr/share/sddm/themes/lunar-glass/Main.qml
sudo cp avatar.jpg       /usr/share/sddm/themes/lunar-glass/avatar.jpg
sudo cp background.png   /usr/share/sddm/themes/lunar-glass/background.png
```

只换图的话前两条可以跳过（文件名没变，配置也没变），`theme.conf` / `Main.qml` 只有第一次要拷。

### 兜底行为

- `avatar.jpg` 缺失或损坏 → `userAvatar.status` 变 `Error` → 自动显示 `default-avatar.svg`。
  所以这个 svg 不能删。
- `background.png` 缺失 → 背景层不渲染，露出 `color=#1d1f21` 的纯色底。上游原版背景留在
  `default-background.png`，想换回去直接 `cp default-background.png background.png`。

### 为什么不用 `~/.face`

`Main.qml` 的兜底路径是 `file:///home/<用户名>/.face`，但 greeter 以 `sddm` 用户运行，读它
要穿过家目录（需要 `x` 位），否则头像永远不显示，而改家目录权限会把整个 home 暴露给所有
本地用户。`theme.conf` 的 `avatar` 指向主题目录自己的文件，`/usr/share` 天然 world-readable，
不存在这个问题。

另外 `usernameInput.text` 在登录框为空时是空串，那时兜底路径直接得到 `""`，头像同样不显示。

## 依赖

- SDDM
- Qt 5.x
- Noto Sans CJK SC 字体（可选，用于中文显示）

## 文件结构

```
├── Main.qml               # 主界面
├── KeyButton.qml          # 虚拟键盘按键组件
├── theme.conf             # 主题配置
├── metadata.desktop       # 主题元数据
├── background.png         # 登录背景（换背景 = 覆盖它）
├── avatar.jpg             # 登录头像（换头像 = 覆盖它）
├── default-background.png # 上游原版背景，未被引用，备查用
├── default-avatar.svg     # 头像加载失败时的兜底
└── icons/                 # 图标资源
```

## 许可证

MIT License
