return {
    -- Remove Snacks Explorer keymaps
    {
        "folke/snacks.nvim",
        keys = {
            { "<leader>e", false },
        },
    },

    -- Use Neo-tree instead
    {
        "nvim-neo-tree/neo-tree.nvim",
        keys = {
            {
                "<leader>e",
                "<cmd>Neotree toggle<cr>",
                desc = "Toggle Neo-tree",
            },
        },

        opts = function(_, opts)
            opts.filesystem = opts.filesystem or {}
            opts.filesystem.window = opts.filesystem.window or {}
            opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}

            opts.commands = opts.commands or {}

            opts.commands.easy = function(state)
                local node = state.tree:get_node()
                if not node then
                    return
                end

                local path = node.path or node:get_id()
                if node.type ~= "directory" then
                    path = vim.fs.dirname(path)
                end

                require("easy-dotnet").create_item(path)
            end

            opts.filesystem.window.mappings["R"] = {
                "easy",
                desc = "Create .NET item",
            }

            return opts
        end,
    },
}
