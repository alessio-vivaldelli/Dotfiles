return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
        close_on_exit = true, -- Chiude il terminale quando il processo termina
        persist_mode = false, -- Non mantiene aperti i terminali quando Neovim viene chiuso
      })
    end,
  },
}
