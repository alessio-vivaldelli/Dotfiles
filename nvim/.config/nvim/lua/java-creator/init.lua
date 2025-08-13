-- lua/java-creator/init.lua
local M = {}

-- Configurazione di default
M.config = {
  templates = {
    class = [[package %s;

public class %s {
    
}]],
    interface = [[package %s;

public interface %s {
    
}]],
    enum = [[package %s;

public enum %s {
    
}]],
    record = [[package %s;

public record %s() {
    
}]],
    abstract_class = [[package %s;

public abstract class %s {
    
}]],
  },

  default_imports = {
    class = {},
    interface = {},
    enum = {},
    record = { "java.util.*" },
    abstract_class = {},
  },

  keymaps = {
    java_new = "<leader>jn",
    java_class = "<leader>jc",
    java_interface = "<leader>ji",
    java_enum = "<leader>je",
    java_record = "<leader>jr",
  },

  options = {
    auto_open = true,
    use_notify = true,
    java_version = 17,
    src_patterns = { "src/main/java", "src/test/java", "src" },
    project_markers = { "pom.xml", "build.gradle", "settings.gradle", ".project", "backend" },
    custom_src_path = nil,
    package_selection_style = "hybrid", -- "auto", "menu" or "hybrid"
  },
}

local utils = {}

function utils.notify(msg, level)
  level = level or vim.log.levels.INFO
  if M.config.options.use_notify then
    local ok, notify = pcall(require, "notify")
    if ok then
      notify(msg, level, { title = "Java Creator" })
      return
    end
  end
  vim.notify(msg, level)
end

function utils.error(msg)
  utils.notify(msg, vim.log.levels.ERROR)
end
function utils.info(msg)
  utils.notify(msg, vim.log.levels.INFO)
end
function utils.warn(msg)
  utils.notify(msg, vim.log.levels.WARN)
end

function utils.validate_java_name(name)
  if not name or name == "" then
    return false, "Il nome non può essere vuoto"
  end
  if not name:match("^[a-zA-Z_]") then
    return false, "Il nome deve iniziare con una lettera o underscore"
  end
  if not name:match("^[a-zA-Z0-9_]*$") then
    return false, "Il nome può contenere solo lettere, numeri e underscore"
  end

  local java_keywords = {
    "abstract",
    "assert",
    "boolean",
    "break",
    "byte",
    "case",
    "catch",
    "char",
    "class",
    "const",
    "continue",
    "default",
    "do",
    "double",
    "else",
    "enum",
    "extends",
    "final",
    "finally",
    "float",
    "for",
    "goto",
    "if",
    "implements",
    "import",
    "instanceof",
    "int",
    "interface",
    "long",
    "native",
    "new",
    "null",
    "package",
    "private",
    "protected",
    "public",
    "return",
    "short",
    "static",
    "strictfp",
    "super",
    "switch",
    "synchronized",
    "this",
    "throw",
    "throws",
    "transient",
    "try",
    "void",
    "volatile",
    "while",
    "true",
    "false",
  }

  for _, keyword in ipairs(java_keywords) do
    if name:lower() == keyword then
      return false, "Il nome non può essere una keyword Java: " .. keyword
    end
  end

  return true
end

function utils.validate_package_name(package)
  if not package or package == "" then
    return true
  end
  for part in package:gmatch("[^%.]+") do
    local valid, err = utils.validate_java_name(part)
    if not valid then
      return false, "Package non valido: " .. err
    end
  end
  return true
end

function utils.find_java_project_root(start_dir)
  start_dir = start_dir or vim.fn.getcwd()
  local current_dir = start_dir

  while current_dir ~= "/" and current_dir ~= "" do
    for _, marker in ipairs(M.config.options.project_markers) do
      local marker_path = current_dir .. "/" .. marker
      if marker == "backend" then
        if vim.fn.isdirectory(marker_path) == 1 and vim.fn.isdirectory(marker_path .. "/src") == 1 then
          return current_dir
        end
      elseif vim.fn.filereadable(marker_path) == 1 or vim.fn.isdirectory(marker_path) == 1 then
        return current_dir
      end
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end
  return nil
end

function utils.find_java_src_dir(project_root)
  if not project_root then
    return nil
  end

  if M.config.options.custom_src_path then
    local custom_path = project_root .. "/" .. M.config.options.custom_src_path
    if vim.fn.isdirectory(custom_path) == 1 then
      return custom_path
    end
  end

  local nested_paths = {
    "",
    "backend",
    "src",
    "src/main/java",
  }

  for _, nested_path in ipairs(nested_paths) do
    local base_path = project_root
    if nested_path ~= "" then
      base_path = base_path .. "/" .. nested_path
    end

    for _, pattern in ipairs(M.config.options.src_patterns) do
      local src_candidate = base_path .. "/" .. pattern
      if vim.fn.isdirectory(src_candidate) == 1 then
        return src_candidate
      end
    end
  end

  return nil
end

function utils.get_package_base()
  local project_root = utils.find_java_project_root()
  if not project_root then
    return nil
  end
  return utils.find_java_src_dir(project_root)
end

function utils.get_current_package_fragment(input)
  if not input or input == "" then
    return ""
  end
  return input:match("([^.]+)$") or ""
end

function utils.get_package_matches(base, fragment)
  local matches = {}
  if not base or not fragment then
    return matches
  end

  local pattern = fragment:gsub("%.", "/")
  local search_path = base .. "/**/" .. pattern .. "*/"
  local dirs = vim.fn.glob(search_path, false, true)

  for _, dir in ipairs(dirs) do
    if dir:sub(1, #base) == base then
      local relative = dir:sub(#base + 2, -2)
      if relative ~= "" then
        local package_name = relative:gsub("/", ".")
        table.insert(matches, package_name)
      end
    end
  end

  return matches
end

function utils.find_available_packages()
  local src_dir = utils.get_package_base()
  if not src_dir then
    return {}
  end

  local packages = {}
  local dirs = vim.fn.glob(src_dir .. "/**/", false, true)

  for _, dir in ipairs(dirs) do
    if dir:sub(1, #src_dir) == src_dir then
      local relative = dir:sub(#src_dir + 2, -2)
      if relative ~= "" then
        local package_name = relative:gsub("/", ".")
        -- Includi tutte le cartelle nella gerarchia dei package
        table.insert(packages, package_name)
      end
    end
  end

  table.sort(packages, function(a, b)
    return #a < #b -- Ordina per lunghezza crescente
  end)

  return packages
end

function utils.find_default_package()
  local src_dir = utils.get_package_base()
  if not src_dir then
    return ""
  end

  local current_dir = vim.fn.getcwd()

  if current_dir:sub(1, #src_dir) == src_dir then
    local relative_path = current_dir:sub(#src_dir + 2)
    return relative_path:gsub("/", ".")
  end

  local java_files = vim.fn.glob(current_dir .. "/*.java", false, true)
  for _, file in ipairs(java_files) do
    local package = utils.extract_package_from_file(file)
    if package then
      return package
    end
  end

  return ""
end

function utils.extract_package_from_file(file)
  local content = utils.read_file(file)
  if content then
    local package_match = content:match("package%s+([^;]+);")
    return package_match
  end
  return nil
end

function utils.read_file(file)
  local f = io.open(file, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

function utils.generate_file_path(package, name, java_type)
  local src_dir = utils.get_package_base() or vim.fn.getcwd()

  if package and package ~= "" then
    local package_path = package:gsub("%.", "/")
    local full_dir = src_dir .. "/" .. package_path
    vim.fn.mkdir(full_dir, "p")
    return full_dir .. "/" .. name .. ".java"
  else
    return src_dir .. "/" .. name .. ".java"
  end
end

function utils.generate_file_content(java_type, package, name)
  local template = M.config.templates[java_type]
  if not template then
    return nil, "Template non trovato per tipo: " .. java_type
  end

  local imports = M.config.default_imports[java_type] or {}
  local import_lines = ""
  if #imports > 0 then
    for _, import in ipairs(imports) do
      import_lines = import_lines .. "import " .. import .. ";\n"
    end
    import_lines = import_lines .. "\n"
  end

  local package_line = package and package ~= "" and string.format("package %s;\n\n", package) or ""

  if java_type == "record" then
    return string.format(
      [[%s%spublic record %s() {
    
}]],
      package_line,
      import_lines,
      name
    )
  end

  return package_line .. import_lines .. string.format(template, package or "", name):gsub("package ;\n\n", "")
end

local input = {}

function input.get_java_type(callback)
  local types = { "class", "interface", "enum", "record", "abstract_class" }
  local type_labels = {
    class = "Class",
    interface = "Interface",
    enum = "Enum",
    record = "Record" .. (M.config.options.java_version < 14 and " (Java 14+)" or ""),
    abstract_class = "Abstract Class",
  }

  vim.ui.select(types, {
    prompt = "Seleziona tipo Java:",
    format_item = function(item)
      return type_labels[item] or item
    end,
  }, callback)
end

function input.get_string(prompt, default, callback)
  vim.ui.input({
    prompt = prompt,
    default = default or "",
  }, callback)
end

function input.get_package_input(prompt, default, callback, src_dir)
  vim.ui.input({
    prompt = prompt,
    default = default or "",
    completion = function(arg_lead)
      if not src_dir then
        return {}
      end
      local fragment = utils.get_current_package_fragment(arg_lead)
      if fragment == "" then
        return {}
      end
      return utils.get_package_matches(src_dir, fragment)
    end,
  }, callback)
end

function input.get_package(prompt, default, callback)
  local src_dir = utils.get_package_base()
  local available_packages = utils.find_available_packages()

  -- Menu principale
  vim.ui.select({ "(nuovo package)", unpack(available_packages) }, {
    prompt = prompt,
    default = default,
    format_item = function(item)
      return item == "(nuovo package)" and "✏️ " .. item or "📦 " .. item
    end,
  }, function(choice)
    -- Gestione ESC nel menu principale
    if not choice then
      return callback(nil) -- Annulla tutto
    end

    if choice == "(nuovo package)" then
      -- Input modificabile con completamento
      vim.ui.select(available_packages, {
        prompt = "Scegli base package:",
        format_item = function(pkg)
          return "✏️ " .. pkg
        end,
      }, function(selected_pkg)
        -- Gestione ESC nel secondo menu
        if not selected_pkg then
          return callback(nil) -- Annulla tutto
        end

        vim.ui.input({
          prompt = "Nuovo package: ",
          default = selected_pkg or "",
          completion = function(arg_lead)
            local matches = {}
            for _, p in ipairs(available_packages) do
              if p:find(arg_lead, 1, true) == 1 then
                table.insert(matches, p)
              end
            end
            return matches
          end,
        }, function(input_text)
          -- Gestione ESC nell'input finale
          if not input_text then
            return callback(nil) -- Annulla tutto
          end
          callback(input_text)
        end)
      end)
    else
      callback(choice)
    end
  end)
end

function M.complete_packages(arg_lead, cmd_line, cursor_pos)
  local src_dir = utils.get_package_base()
  if not src_dir then
    return {}
  end
  local fragment = utils.get_current_package_fragment(arg_lead)
  return utils.get_package_matches(src_dir, fragment)
end

function M.create_java_file(java_type, name, package)
  if java_type == "record" and M.config.options.java_version < 14 then
    utils.error("I Record richiedono Java 14 o superiore. Versione corrente: " .. M.config.options.java_version)
    return
  end

  local valid, err = utils.validate_java_name(name)
  if not valid then
    utils.error("Nome non valido: " .. err)
    return
  end

  valid, err = utils.validate_package_name(package)
  if not valid then
    utils.error("Package non valido: " .. err)
    return
  end

  local file_path = utils.generate_file_path(package, name, java_type)
  if vim.fn.filereadable(file_path) == 1 then
    utils.error("Il file esiste già: " .. file_path)
    return
  end

  local content, err_msg = utils.generate_file_content(java_type, package, name)
  if not content then
    utils.error("Errore generazione contenuto: " .. err_msg)
    return
  end

  local file = io.open(file_path, "w")
  if not file then
    utils.error("Impossibile creare il file: " .. file_path)
    return
  end

  file:write(content)
  file:close()

  if M.config.options.auto_open then
    vim.cmd("edit " .. file_path)
  end

  utils.info(string.format("Creato %s: %s", java_type, file_path))
end

function M.java_new()
  input.get_java_type(function(java_type)
    if not java_type then
      return
    end

    input.get_string("Nome " .. java_type .. ": ", "", function(name)
      if not name or name == "" then
        utils.error("Nome richiesto")
        return
      end

      local default_package = utils.find_default_package()
      input.get_package("Package: ", default_package, function(package)
        M.create_java_file(java_type, name, package)
      end)
    end)
  end)
end

function M.create_java_type_direct(java_type)
  input.get_string("Nome " .. java_type .. ": ", "", function(name)
    if not name or name == "" then
      utils.error("Nome richiesto")
      return
    end

    local default_package = utils.find_default_package()
    input.get_package("Package: ", default_package, function(package)
      M.create_java_file(java_type, name, package)
    end)
  end)
end

function M.java_class()
  M.create_java_type_direct("class")
end
function M.java_interface()
  M.create_java_type_direct("interface")
end
function M.java_enum()
  M.create_java_type_direct("enum")
end
function M.java_record()
  M.create_java_type_direct("record")
end

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  vim.api.nvim_create_user_command("JavaNew", M.java_new, { desc = "Crea nuovo file Java interattivo" })
  vim.api.nvim_create_user_command("JavaClass", M.java_class, { desc = "Crea nuova classe Java" })
  vim.api.nvim_create_user_command("JavaInterface", M.java_interface, { desc = "Crea nuova interfaccia Java" })
  vim.api.nvim_create_user_command("JavaEnum", M.java_enum, { desc = "Crea nuovo enum Java" })
  vim.api.nvim_create_user_command("JavaRecord", M.java_record, { desc = "Crea nuovo record Java" })

  if M.config.keymaps then
    local command_map = {
      java_new = "JavaNew",
      java_class = "JavaClass",
      java_interface = "JavaInterface",
      java_enum = "JavaEnum",
      java_record = "JavaRecord",
    }

    for cmd, keymap in pairs(M.config.keymaps) do
      if keymap and keymap ~= "" and command_map[cmd] then
        vim.keymap.set("n", keymap, "<cmd>" .. command_map[cmd] .. "<cr>", {
          desc = "Java Creator: " .. command_map[cmd],
        })
      end
    end
  end

  utils.info("Java Creator plugin caricato")
end

return M
