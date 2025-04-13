-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })
vim.keymap.set("n", "<leader>tc", ":bdelete<CR>", { noremap = true, silent = true, desc = "Close current buffer" })

vim.keymap.set("n", "<leader>m", ":Maven<CR>", { noremap = true, silent = true, desc = "Open Maven menu" })

vim.keymap.set(
  "n",
  "<leader>p",
  ":NeovimProjectDiscover<CR>",
  { noremap = true, silent = true, desc = "Open Project discovery" }
)

vim.keymap.set("n", "<leader>tt", ":Telescope<CR>", { noremap = true, silent = true, desc = "Telescope" })
-- Database
D = {
  name = "Database",
  u = { "<Cmd>DBUIToggle<Cr>", "Toggle UI" },
  f = { "<Cmd>DBUIFindBuffer<Cr>", "Find buffer" },
  r = { "<Cmd>DBUIRenameBuffer<Cr>", "Rename buffer" },
  q = { "<Cmd>DBUILastQueryInfo<Cr>", "Last query info" },
}
