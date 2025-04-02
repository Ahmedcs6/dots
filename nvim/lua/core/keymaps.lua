
-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Map Esc to kk
keymap('i', 'kk', '<Esc>')

-- Navigate between windows
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-l>", "<C-w>l", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)

-- Resize windows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Move lines up and down
keymap("n", "<A-j>", ":m .+1<CR>==", opts)
keymap("n", "<A-k>", ":m .-2<CR>==", opts)
keymap("i", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
keymap("i", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

-- Save file quickly
keymap("n", "<leader>w", ":w<CR>", opts)

-- Close current window
keymap("n", "<leader>q", ":q<CR>", opts)

-- Reload configuration without restart nvim
keymap('n', '<leader>r', ':so %<CR>')

-- Close all windows and save changes
keymap("n", "<leader>Q", ":qa!<CR>", opts)

-- Telescope bindings for searching files
keymap("n", "<leader>ff", ":Telescope find_files<CR>", opts)
keymap("n", "<leader>fg", ":Telescope live_grep<CR>", opts)
keymap("n", "<leader>fb", ":Telescope buffers<CR>", opts)
keymap("n", "<leader>fh", ":Telescope help_tags<CR>", opts)

-- Toggle NvimTree file explorer
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- LSP Keybindings
keymap("n", "gd", ":lua vim.lsp.buf.definition()<CR>", opts)
keymap("n", "K", ":lua vim.lsp.buf.hover()<CR>", opts)
keymap("n", "gr", ":lua vim.lsp.buf.references()<CR>", opts)
keymap("n", "gD", ":lua vim.lsp.buf.declaration()<CR>", opts)

-- Navigate between buffers
keymap("n", "<Tab>", ":bnext<CR>", opts)
keymap("n", "<S-Tab>", ":bprevious<CR>", opts)

-- Remove search highlighting
keymap("n", "<leader>h", ":nohlsearch<CR>", opts)

-- Terminal mappings
keymap("n", "<leader>t", function()
  local file_dir = vim.fn.expand("%:p:h")              -- Get current file's directory
  vim.cmd("lcd " .. file_dir)                          -- Change local working directory
  vim.cmd("split | resize 10 | terminal")
end, { noremap = true, silent = true })                -- open
keymap('t', '<Esc>', '<C-\\><C-n>')                    -- exit

-- open lazy
keymap("n", "<leader>l", ":Lazy<CR>", { noremap = true, silent = true })
