return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false, -- Load immediately
        priority = 1000,
        config = function()
            require("catppuccin").setup {
                flavour = "mocha", -- Options: latte, frappe, macchiato, mocha
                transparent_background = false, -- Set to true for a transparent look
                term_colors = true,
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    treesitter = true,
                    telescope = true,
                    lsp_saga = true,
                    mason = true,
                    nvimtree = true,
                    dashboard = true,
                    neotree = true,
                    which_key = true,
                    fidget = true,
                    indent_blankline = {
                        enabled = true,
                        scope_color = "lavender", -- Highlight current scope
                    },
                },
            }

            -- Set the colorscheme
            vim.cmd("colorscheme catppuccin")
        end,
    },
}

