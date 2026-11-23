-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
	theme = "catppuccin",

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },

	statusline = {
		modules = {
			file = function()
				local stbufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
				local path = vim.api.nvim_buf_get_name(stbufnr)
				if path == "" then
					return "%#St_file# 󰈚 Empty %#St_file_sep#"
						.. (vim.g.statusline_sep_style == "round" and "" or "")
				end

				local icon = "󰈚"
				local name = vim.fn.fnamemodify(path, ":~:.")
				local ok, devicons = pcall(require, "nvim-web-devicons")
				if ok then
					local ft_icon = devicons.get_icon(vim.fn.fnamemodify(path, ":t"))
					icon = ft_icon or icon
				end

				local sep_style = vim.g.statusline_sep_style or "default"
				local sep_r = (sep_style == "round" and "") or ""

				return "%#St_file# " .. icon .. " " .. name .. " %#St_file_sep#" .. sep_r
			end,
		},
	},
}

return M
