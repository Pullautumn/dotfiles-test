# nvim

Neovim 配置，基于 [LazyVim](https://github.com/LazyVim/LazyVim) 发行版。插件由 `lazy.nvim` 管理，首次启动自动拉取。

部署到 `~/.config/nvim`。

## 结构

| 文件 / 目录 | 说明 |
|---|---|
| `init.lua` | 入口，`require("config.lazy")` 交给 LazyVim 引导 |
| `lua/config/lazy.lua` | `lazy.nvim` 引导、LazyVim 本体、插件目录声明 |
| `lua/config/options.lua` | `vim.opt` 设置 |
| `lua/config/keymaps.lua` | 自定义键位 |
| `lua/config/autocmds.lua` | 自动命令 |
| `lua/plugins/*.lua` | 插件规格，按主题拆成 15 个文件 |
| `lazy-lock.json` | 插件版本锁，保证换机器后版本一致 |
| `lazyvim.json` | LazyVim 的 extras 选择记录 |
| `.neoconf.json` | neoconf 的 LSP 数据源配置 |
| `stylua.toml` | Lua 格式化规则 |
| `LICENSE` | LazyVim 模板附带的许可证 |

## 插件分文件

| 文件 | 内容 |
|---|---|
| `lsp.lua` | LSP：nvim-lspconfig、诊断、格式化 |
| `mason.lua` | Mason 安装 LSP / DAP / linter |
| `cmp.lua` | 补全（nvim-cmp 或 blink.cmp） |
| `telescope.lua` | 模糊查找 |
| `fzf.lua` | fzf-lua 查找（与 telescope 二选一或并存） |
| `treesitter.lua` | 语法高亮与缩进 |
| `colorscheme.lua` | 配色方案 |
| `ui.lua` | 界面增强（状态栏、缩进线、bufferline 等） |
| `snacks.lua` | snacks.nvim 的 picker、dashboard、终端等 |
| `which-key.lua` | 键位提示 |
| `comment.lua` | 注释增强 |
| `rainbowbracket.lua` | 彩虹括号 |
| `vim-floaterm.lua` | 浮动终端 |
| `supermaven.lua` | AI 补全 |
| `disabled.lua` | 集中关闭不想要的默认插件 |
| `example.lua.bak` | 官方示例备份，不加载 |

## 依赖

| 包 | 用途 |
|---|---|
| `neovim` | 本体 |
| `nodejs` / `npm` | 大部分 LSP 与 tree-sitter 的运行时 |
| `ripgrep` | telescope / fzf-lua 的搜索后端 |
| `fd` | 文件查找 |
| `tree-sitter-cli` | 编译 tree-sitter 解析器 |
| `clang` | C/C++ 解析器编译 |
| `stylua` / `ruff` / `pyright` / `lua-language-server` | 格式化与 LSP |

后五个属于可选，安装器 Phase 6a 会单独询问；不装也能用，只是对应语言没有 LSP。

## 首次使用

```bash
nvim                  # 首次启动自动 clone lazy.nvim 并安装全部插件
```

安装器里跑的是非交互版本：

```bash
nvim --headless "+Lazy! sync" +qa
```

常用命令：

```bash
:Lazy          # 插件管理界面
:Lazy sync     # 同步 lazy-lock.json 里的版本
:Lazy update   # 升级插件
:Mason         # LSP / DAP / linter 安装界面
:LspInfo       # 当前 buffer 的 LSP 状态
:checkhealth   # 体检
```

## 注意

- `lazy-lock.json` 建议提交，它保证你和作者用的是同一批插件版本；不想要固定版本可以删掉，让 lazy 自己解析。
- `supermaven.lua` 需要联网并登录，离线环境会报连接失败，可以把该文件改名或删掉。
- `example.lua.bak` 不会被加载（后缀不是 `.lua`），可以当模板抄。
- 插件安装失败大多是网络问题，`git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"` 一类的镜像手段能救。
