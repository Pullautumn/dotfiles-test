# obs-studio

OBS 的配置快照：场景、编码器、输出路径、WebSocket 设置。装好 `obs-studio` 包后放进去就是作者当时的工作状态。

部署到 `~/.config/obs-studio`。

## 目录

| 路径 | 说明 |
|---|---|
| `global.ini` | 全局设置：渲染器（OpenGL）、日志数量、自动更新、浏览器硬件加速 |
| `basic/profiles/未命名/basic.ini` | 配置档「未命名」：输出模式、编码器、码率、录制路径 |
| `basic/profiles/未命名/recordEncoder.json` | 录制编码器参数 |
| `basic/scenes/未命名.json` | 场景与源的完整定义 |
| `plugin_config/obs-websocket/config.json` | WebSocket 服务配置（供手机遥控 / 第三方控制） |
| `plugin_config/rtmp-services/` | 直播平台推流地址表 |
| `plugin_manager/modules.json` | 插件模块记录 |
| `profiler_data/*.csv.gz` | 性能采样数据，纯历史记录 |

`.bak` 结尾的是改动前的备份。

## 注意

- **配置档和场景都叫「未命名」**，里面很可能指向作者机器上的路径、摄像头设备名、显示器编号。换机器后大概率要重新选设备、改录制目录，别指望开箱即用。
- `Renderer=OpenGL` 是 Linux 下的默认选择；NVIDIA 遇到卡顿可以换成 `Vulkan`。
- `obs-websocket` 默认可能开了密码，密码在 `plugin_config/obs-websocket/config.json` 的 `server_password` 里，公开仓库里这份配置建议清空或改掉。
- `profiler_data/` 会随时间越来越大，可以定期删。
- 想从干净状态开始，删掉 `basic/profiles/未命名/` 与 `basic/scenes/未命名.json`，OBS 会重建默认配置。
