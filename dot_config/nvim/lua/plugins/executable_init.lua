return {
  {
    "stevearc/conform.nvim",
    event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },

  -- {
  --   "neovim/nvim-lspconfig",
  --    config = function()
  --       require "plugins.configs.lspconfig"
  --       require "custom.configs.lspconfig"
  --    end,
  -- },

  -- require('packer').startup(function()
  --   use 'williamboman/nvim-lsp-installer'
  --   use 'neovim/nvim-lspconfig'
  --   -- other plugins...
  -- end)

  -- These are some examples, uncomment them if you want to see them work!
  -- {
  --   "neovim/nvim-lspconfig",
  --   config = function()
  --     require("nvchad.configs.lspconfig").defaults()
  --     require "configs.lspconfig"
  --   end,
  -- },

  {
  	"williamboman/mason.nvim",
  	opts = {
  		ensure_installed = {
  			"lua-language-server", "stylua",
  			"html-lsp", "css-lsp" , "prettier"
  		},
  	},
  },

  -- nvim-treesitter (archived master branch): parser installer only.
  -- Uses the archived `master` branch because it compiles parsers via gcc/cc
  -- directly (no `tree-sitter` CLI required). The active `main` branch needs
  -- the tree-sitter CLI which is unavailable on this Synology NAS (glibc 2.36,
  -- binary needs 2.39; no cargo to build from source).
  --
  -- CRITICAL: do NOT autoload this plugin and do NOT call
  -- require("nvim-treesitter.configs").setup() with highlight/indent opts.
  -- Old runtime queries and duplicate autocmds conflict with Neovim 0.12's
  -- built-in treesitter and can cause both "range nil" errors and invalid
  -- field errors. The plugin is only used when :TSInstall/:TSUpdate is run.
  --
  -- Cross-OS notes:
  --   * Compilation requires a C compiler (cc/gcc) in PATH. macOS has clang,
  --     most Linux distros have gcc, Synology NAS uses Entware's /opt/bin/gcc.
  --   * Parsers land in stdpath("data")/lazy/nvim-treesitter/parser and are
  --     per-machine (not chezmoi-managed), so each OS builds the correct ABI.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSInstallSync! markdown markdown_inline lua vim vimdoc query c bash",
    lazy = true,
    event = false,
    cmd = {
      "TSInstall", "TSInstallSync", "TSInstallFromGrammar",
      "TSUpdate", "TSUpdateSync",
      "TSUninstall", "TSBufEnable", "TSBufDisable",
      "TSEnable", "TSDisable", "TSToggle", "TSModuleInfo",
    },
    config = function()
      -- Do NOT call require("nvim-treesitter.configs").setup() here.
      -- Keep the master-branch installer, but point Neovim's built-in
      -- ftplugin languages at parser revisions compatible with Neovim 0.12's
      -- bundled runtime queries.
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

      parser_config.lua.install_info = {
        url = "https://github.com/tree-sitter-grammars/tree-sitter-lua",
        revision = "10fe0054734eec83049514ea2e718b2a56acd0c9",
        files = { "src/parser.c", "src/scanner.c" },
      }

      parser_config.markdown.install_info = {
        url = "https://github.com/tree-sitter-grammars/tree-sitter-markdown",
        revision = "f969cd3ae3f9fbd4e43205431d0ae286014c05b5",
        location = "tree-sitter-markdown",
        files = { "src/parser.c", "src/scanner.c" },
      }

      parser_config.markdown_inline.install_info = {
        url = "https://github.com/tree-sitter-grammars/tree-sitter-markdown",
        revision = "f969cd3ae3f9fbd4e43205431d0ae286014c05b5",
        location = "tree-sitter-markdown-inline",
        files = { "src/parser.c", "src/scanner.c" },
      }

      parser_config.query.install_info = {
        url = "https://github.com/tree-sitter-grammars/tree-sitter-query",
        revision = "fc5409c6820dd5e02b0b0a309d3da2bfcde2db17",
        files = { "src/parser.c" },
      }

      parser_config.vim.install_info = {
        url = "https://github.com/tree-sitter-grammars/tree-sitter-vim",
        revision = "3092fcd99eb87bbd0fc434aa03650ba58bd5b43b",
        files = { "src/parser.c", "src/scanner.c" },
      }

      parser_config.vimdoc.install_info = {
        url = "https://github.com/neovim/tree-sitter-vimdoc",
        revision = "f061895a0eff1d5b90e4fb60d21d87be3267031a",
        files = { "src/parser.c" },
      }
    end,
  },
}
