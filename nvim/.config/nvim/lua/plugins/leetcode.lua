return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
    dependencies = {
      "nvim-telescope/telescope.nvim",
      -- "ibhagwan/fzf-lua",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      -- Abilita supporto immagini se configurato
      image_support = true,

      -- Configurazione degli import automatici
      injector = {
        ["cpp"] = {
          before = { "#include <bits/stdc++.h>", "#include <vector>", "using namespace std;" },
          after = "int main() {}",
        },
      },
    },
  },
}
