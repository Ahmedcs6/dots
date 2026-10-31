return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                roslyn_ls = {
                    enabled = false,
                },
            },
        },
    },
}
