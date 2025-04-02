
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

require("lazy").setup({
    { import = "plugins" },
    { import = "plugins.lsp"}
}, {
    ui = {
        border = "rounded",
    }
})
