vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "
vim.g.guifont = "JetbrainsMono Nerd Font"

-- Register locally compiled tree-sitter parsers without loading the
-- nvim-treesitter plugin onto runtimepath. This avoids old plugin queries from
-- conflicting with Neovim 0.12's native treesitter runtime while still letting
-- built-in ftplugins (for example markdown.lua) find parser .so files.
local function register_local_treesitter_parsers()
  local parser_dir = vim.fn.stdpath "data" .. "/lazy/nvim-treesitter/parser"

  if not vim.uv.fs_stat(parser_dir) then
    return
  end

  for name, type in vim.fs.dir(parser_dir) do
    if type == "file" and name:sub(-3) == ".so" then
      local lang = name:sub(1, -4)
      local parser_path = parser_dir .. "/" .. name
      pcall(vim.treesitter.language.add, lang, { path = parser_path })
    end
  end
end

register_local_treesitter_parsers()

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require "options"
    end,
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

-- Auto-save on file change
-- vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
--   pattern = "*",
--   command = "silent write"
-- })

-- Auto-save after a certain number of changes
vim.g.auto_save = 1
vim.g.auto_save_events = {"InsertLeave", "TextChanged"}
vim.g.auto_save_silent = 1

-- Auto-save on focus lost
vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  command = "silent! wall"
})

vim.g.loaded_python3_provider = 1


-- Auto-save on timer
-- vim.o.updatetime = 1000
-- vim.api.nvim_create_autocmd("CursorHold", {
--   pattern = "*",
--   command = "silent! wall"
-- })
--
-- -- Set tab width to 4 spaces
-- vim.opt.tabstop = 4
-- vim.opt.shiftwidth = 4
-- vim.opt.softtabstop = 4
-- vim.opt.expandtab = true
--
-- -- Use spaces instead of tabs
-- vim.opt.smartindent = true
--
-- -- If you're using nvim-tree, set tab width for it
-- vim.g.nvim_tree_tab_open = 1

-- require'lspconfig'.pyright.setup{}
-- require("nvim-lsp-installer").setup({
--     automatic_installation = true, -- automatically detect which servers to install (based on which servers are set up via lspconfig)
--     ui = {
--         icons = {
--             server_installed = "✓",
--             server_pending = "➜",
--             server_uninstalled = "✗"
--         }
--     }
-- })
--
-- vim.o.swapfile = true
-- vim.o.directory = '~/.config/nvim/swap/' -- or any directory where you have write permission
