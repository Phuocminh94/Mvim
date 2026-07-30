local theme_path = vim.fn.stdpath("config") .. "/lua/minh/theme.lua"
local loop = vim.uv or vim.loop
local stat = loop.fs_stat(theme_path)

local extra_plugins = {}

if stat then
	local success, result = pcall(dofile, theme_path)
	if success and type(result) == "table" then
		extra_plugins = result
	end
end

local has_custom_theme = #extra_plugins > 0

local plugins = {
	{
		"projekt0n/github-nvim-theme",
		name = "github-theme",
		enabled = not has_custom_theme,
		priority = 1000,
		config = function()
			require("github-theme").setup({
				options = {
					styles = {
						comments = "NONE",
						keywords = "bold",
					},
				},
			})

			vim.cmd.colorscheme("github_dark_high_contrast")

			vim.keymap.set("n", "<leader>tt", function()
				if vim.g.colors_name == "github_dark_high_contrast" then
					vim.cmd.colorscheme("github_light")
					print("Switch to light mode (GitHub Light)")
				else
					vim.cmd.colorscheme("github_dark_high_contrast")
					print("Switch to dark mode (GitHub Dark High Contrast)")
				end
			end, { desc = "Toggle Dark/Light High Contrast" })
		end,
	},
}

for _, plugin in ipairs(extra_plugins) do
	table.insert(plugins, plugin)
end

return plugins
