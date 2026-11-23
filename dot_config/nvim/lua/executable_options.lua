require "nvchad.options"

-- Ensure true-color is always active even inside nested tmux/SSH
vim.opt.termguicolors = true

local function has_executable(binary)
  return vim.fn.executable(binary) == 1
end

local function is_ssh_session()
  return vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil
end

local function has_native_clipboard_provider()
  return has_executable "pbcopy"
    or has_executable "wl-copy"
    or has_executable "xclip"
    or has_executable "xsel"
    or has_executable "win32yank.exe"
    or has_executable "clip.exe"
    or has_executable "lemonade"
    or has_executable "doitclient"
end

if is_ssh_session() and vim.g.clipboard == nil and not has_native_clipboard_provider() then
  local clipboard_cache = {
    ["+"] = {},
    ["*"] = {},
  }

  local function copy(register)
    return function(lines, regtype)
      local text = table.concat(lines, "\n")

      if regtype == "V" then
        text = text .. "\n"
      end

      clipboard_cache[register] = {
        lines = vim.deepcopy(lines),
        regtype = regtype,
      }

      local encoded = vim.base64.encode(text)
      local sequence = string.format("\x1b]52;c;%s\x07", encoded)

      if vim.env.TMUX then
        sequence = string.format("\x1bPtmux;\x1b\x1b]52;c;%s\x07\x1b\\", encoded)
      end

      vim.api.nvim_chan_send(vim.v.stderr, sequence)
    end
  end

  local function paste(register)
    return function()
      local value = clipboard_cache[register] or {}
      return vim.deepcopy(value.lines or {}), value.regtype or "v"
    end
  end

  vim.g.clipboard = {
    name = "ssh-osc52",
    copy = {
      ["+"] = copy "+",
      ["*"] = copy "*",
    },
    paste = {
      ["+"] = paste "+",
      ["*"] = paste "*",
    },
    cache_enabled = 0,
  }

  vim.opt.clipboard:append "unnamedplus"
end

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- Clipboard: use OSC 52 on Linux only (headless NAS, no X11)
-- macOS (pbcopy) and other OS are unaffected
if vim.fn.has "linux" == 1 then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy "+",
      ["*"] = require("vim.ui.clipboard.osc52").copy "*",
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste "+",
      ["*"] = require("vim.ui.clipboard.osc52").paste "*",
    },
  }
end
