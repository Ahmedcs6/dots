-- C# / .NET support via roslyn.nvim
-- See https://github.com/seblyng/roslyn.nvim for `choose_target`,
-- `ignore_target`, `broad_search`, `lock_target`, and `extensions` options.
return {
    {
        "seblyng/roslyn.nvim",
        ft = { "cs", "razor" },
        ---@module "roslyn.config"
        ---@type RoslynNvimConfig
        opts = {},
        init = function()
            -- Workaround for roslyn_ls + Nvim 0.12:
            -- server sends out-of-range inlay hints
            -- ("Invalid 'col': out of range" at inlay_hint.lua:362).
            -- LazyVim re-enables hints per-buffer via
            -- Snacks.util.lsp.on(method="textDocument/inlayHint"),
            -- which runs after a plain LspAttach autocmd, so just
            -- disabling is not enough: strip the capability so the
            -- method-based trigger never fires for roslyn.
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("RoslynNoInlayHint", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and (client.name == "roslyn" or client.name == "roslyn_ls") then
                        client.server_capabilities.inlayHintProvider = false
                        pcall(vim.lsp.inlay_hint.enable, false, { bufnr = args.buf })
                    end
                end,
            })
        end,
    },
    {
        -- LazyVim-supported part of the workaround: never auto-enable
        -- inlay hints for C#/Razor buffers.
        "neovim/nvim-lspconfig",
        optional = true,
        opts = function(_, opts)
            opts.inlay_hints = opts.inlay_hints or {}
            opts.inlay_hints.exclude = opts.inlay_hints.exclude or {}
            for _, ft in ipairs({ "cs", "razor" }) do
                if not vim.tbl_contains(opts.inlay_hints.exclude, ft) then
                    table.insert(opts.inlay_hints.exclude, ft)
                end
            end
        end,
    },
}
