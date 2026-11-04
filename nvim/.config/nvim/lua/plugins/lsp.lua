-- ~/.config/nvim/lua/plugins/lsp.lua
-- LSP 配置（虚拟环境路径运行时展开，不写死用户名 / Python 版本）

-- 虚拟环境根目录：~/Code/Python/.venv 存在就用它，否则退回系统 python3。
-- site-packages 的目录名带 Python 版本（python3.12 / python3.13 …），用 glob 匹配。
local venv_root = vim.fn.expand("~/Code/Python/.venv")
local venv_bin = venv_root .. "/bin/python"
if vim.fn.executable(venv_bin) == 0 then
  venv_bin = "python3"
end
local venv_site = vim.fn.glob(venv_root .. "/lib/python*/site-packages", false, true)[1]
local py_extra_paths = { ".", "./src" }
if venv_site then
  table.insert(py_extra_paths, venv_site)
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              pythonPath = venv_bin,  -- 运行时展开，装到任何用户名下都成立
              analysis = {
                extraPaths = py_extra_paths,
                typeCheckingMode = "off",  -- 完全关闭类型检查
                -- diagnosticMode = "none",  -- 禁用所有诊断
                -- 禁用所有可能导致问题的检查
                diagnosticSeverityOverrides = {
                  reportMissingImports = "none",
                  reportMissingModuleSource = "none",
                  reportUnknownMemberType = "none",
                  reportUnknownVariableType = "none",
                  reportUnknownArgumentType = "none",
                  reportGeneralTypeIssues = "none",
                  reportOptionalMemberAccess = "none",  -- 不报告可选成员访问（解决 match.group 问题）
                  reportOptionalSubscript = "none",
                  reportOptionalIterable = "none",
                  reportOptionalCall = "none",
                  reportOptionalOperand = "none",
                  reportOptionalContextManager = "none",
                  reportOptionalAttributeAccess = "none",
                },
              },
            },
          },
        },
      },
    },
  },

  -- TypeScript 支持
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- JSON 支持
  { import = "lazyvim.plugins.extras.lang.json" },

  -- 可选：如果您想用更强大的 Python 扩展（推荐，补全更好）
  { import = "lazyvim.plugins.extras.lang.python" },
}