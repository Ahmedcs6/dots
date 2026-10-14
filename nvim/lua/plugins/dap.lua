-- Debug adapters for C++ (codelldb) and .NET (netcoredbg).
-- LazyVim's `dap.core` + `lang.clangd` extras provide nvim-dap, dap-ui,
-- and the codelldb adapter. This file adds the .NET side (kept separate
-- from `lang.dotnet` to avoid pulling in omnisharp, since this config
-- uses roslyn.nvim for C# LSP) and ensures the Mason binaries exist.
return {
    -- Ensure the debuggers / formatters are installed by Mason.
    {
        "mason-org/mason.nvim",
        optional = true,
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            for _, tool in ipairs({ "codelldb", "netcoredbg", "csharpier" }) do
                if not vim.tbl_contains(opts.ensure_installed, tool) then
                    table.insert(opts.ensure_installed, tool)
                end
            end
        end,
    },

    -- C# treesitter (dotnet extra does this; we do it here without omnisharp).
    {
        "nvim-treesitter/nvim-treesitter",
        optional = true,
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            for _, lang in ipairs({ "c_sharp" }) do
                if not vim.tbl_contains(opts.ensure_installed, lang) then
                    table.insert(opts.ensure_installed, lang)
                end
            end
        end,
    },

    -- .NET adapter (mirrors lazyvim.plugins.extras.lang.dotnet).
    {
        "mfussenegger/nvim-dap",
        optional = true,
        opts = function()
            local dap = require("dap")
            if not dap.adapters["netcoredbg"] then
                dap.adapters["netcoredbg"] = {
                    type = "executable",
                    command = vim.fn.exepath("netcoredbg"),
                    args = { "--interpreter=vscode" },
                    options = { detached = false },
                }
            end
            -- Alias so VS Code-style launch.json files with "type": "coreclr"
            -- work with the netcoredbg adapter.
            if not dap.adapters["coreclr"] then
                dap.adapters["coreclr"] = dap.adapters["netcoredbg"]
            end
            for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
                if not dap.configurations[lang] then
                    dap.configurations[lang] = {
                        {
                            type = "netcoredbg",
                            name = "Launch file",
                            request = "launch",
                            ---@diagnostic disable-next-line: redundant-parameter
                            program = function()
                                return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
                            end,
                            cwd = "${workspaceFolder}",
                        },
                    }
                end
            end
        end,
    },
}
