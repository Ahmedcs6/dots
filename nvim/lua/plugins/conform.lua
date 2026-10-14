-- Formatter overrides for LazyVim's conform.nvim spec.
-- Uses the modern conform API (`formatters_by_ft`).
-- Install the backing tools you need: stylua, black, prettier, clang-format.
return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "black" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                cpp = { "clang-format" },
                cs = { "csharpier" },
            },
            formatters = {
                clang_format = {
                    prepend_args = {
                        "--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}",
                    },
                },
            },
        },
    },
}
