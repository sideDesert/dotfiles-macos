vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<D-s>", "<cmd>w<cr>")
-- need to install undo-tree
-- vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "Y", "yg$")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Delete to oblivion
vim.keymap.set("n", "<leader>d", '"_d')
vim.keymap.set("v", "<leader>d", '"_d')
vim.keymap.set("x", "<leader>d", '"_d')

vim.keymap.set("n", "<leader>x", '"_x')
vim.keymap.set("v", "<leader>x", '"_x')
vim.keymap.set("x", "<leader>x", '"_x')

vim.keymap.set("n", "<leader>cc", '"_cc')
vim.keymap.set("v", "<leader>c", '"_c')
vim.keymap.set("x", "<leader>c", '"_c')
-- Paste from default buffe<D-s><D-s><D-s>
vim.keymap.set("n", "<C-p>", '"+p')
vim.keymap.set("v", "<C-p>", '"+p')
vim.keymap.set("x", "<C-p>", '"+p')

vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("x", "<leader>y", '"+y')
vim.keymap.set("v", "<C-y>", '"+y')
vim.keymap.set("x", "<C-y>", '"+y')
-- Tree Bar
vim.keymap.set("n", "<C-b>", "<leader>e")

-- change window easy
-- vim.keymap.set("n", "<C-h>", "<C-w>h")
-- vim.keymap.set("n", "<C-l>", "<C-w>l")
-- vim.keymap.set("n", "<C-j>", "<C-w>j")
-- vim.keymap.set("n", "<C-k>", "<C-w>k")

vim.keymap.set("n", "<leader>K", "<C-w>K")
vim.keymap.set("n", "<leader>J", "<C-w>J")
vim.keymap.set("n", "<leader>H", "<C-w>H")
vim.keymap.set("n", "<leader>L", "<C-w>L")

-- Buffer Line
vim.keymap.set("n", "<C-t>", ":BufferLinePick<CR>")
vim.keymap.set("n", ":sp", ":vs")

vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
vim.keymap.set("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
-- vim.keymap.set("n", "<leader>bd", LazyVim.ui.bufremove, { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>bD", "<cmd>:bd!<cr>", { desc = "Delete Buffer and Window" })
-- helps with auto pair

vim.keymap.set("i", "<C-e>", "<C-c>A")
vim.keymap.set("i", "<C-a>", "<C-c>I")
vim.keymap.set("i", "<C-l>", "<Right>")
vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-k>", "<Up>")

-- for error reading
vim.keymap.set("n", "<C-e>", function()
  vim.diagnostic.open_float()
end)

-- insert line in normal mode
vim.keymap.set("n", "<C-S-j>", "o<Esc>")
vim.keymap.set("v", "<C-S-j>", "o<Esc>")
vim.keymap.set("x", "<C-S-j>", "o<Esc>")
vim.keymap.set("n", "<C-S-k>", "O<Esc>")
vim.keymap.set("v", "<C-S-k>", "O<Esc>")
vim.keymap.set("x", "<C-S-k>", "O<Esc>")

-- replace whats under there

vim.keymap.set("v", "<C-v>", '"_dP')
vim.keymap.set("x", "<C-v>", '"_dP')

vim.keymap.set("n", "cic", "ci{")

vim.keymap.set("n", "cid", 'ci"')
vim.keymap.set("n", "ciD", "ci'")
vim.keymap.set("n", "cad", 'ca"')
vim.keymap.set("n", "caD", "ca'")
-- lsp- Add any additional keymaps here
