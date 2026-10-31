return {
    {
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
