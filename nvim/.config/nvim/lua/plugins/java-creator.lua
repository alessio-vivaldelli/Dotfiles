-- ~/.config/nvim/lua/plugins/java-creator.lua
return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/java-creator",
    name = "java-creator",
    config = function()
      require("java-creator").setup({
        options = {
          java_version = 17,
          auto_open = true,
          use_notify = true,
          custom_src_path = "backend/src/main/java", -- Specifica il tuo percorso custom
          src_patterns = { "src/main/java", "src/test/java", "src" },
          project_markers = { "pom.xml", "build.gradle", "settings.gradle", ".project", "backend" },
          package_selection_style = "hybrid", -- "auto", "menu" o "hybrid"
        },
        keymaps = {
          java_new = "<leader>jn",
          java_class = "<leader>jc",
          java_interface = "<leader>ji",
          java_enum = "<leader>je",
          java_record = "<leader>jr",
        },
        templates = {
          -- Puoi sovrascrivere i template predefiniti qui
          -- Esempio per Spring Boot:
          -- class = [[package %s;
          --
          -- import org.springframework.stereotype.*;
          --
          -- @Service
          -- public class %s {
          --
          -- }]],
        },
        default_imports = {
          -- Puoi aggiungere import di default per tipo
          class = {},
          interface = {},
          enum = {},
          record = { "java.util.*" },
          abstract_class = {},
        },
      })

      -- Mappa extra per l'autocompletamento
      vim.api.nvim_set_keymap("i", "<C-space>", 'pumvisible() ? "\\<C-n>" : "\\<C-x>\\<C-u>"', {
        expr = true,
        noremap = true,
        desc = "Attiva completamento package Java",
      })
    end,
    ft = "java", -- Carica solo per file Java
    event = "VeryLazy", -- Carica quando NVIM è pronto
    dependencies = {
      "nvim-telescope/telescope.nvim", -- Opzionale: per una migliore UI
      "rcarriga/nvim-notify", -- Opzionale: per notifiche più belle
    },
  },
}
