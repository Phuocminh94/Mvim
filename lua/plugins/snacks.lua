return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		dashboard = {
			enabled = true, 
			width = 60,
			row = nil,
			col = nil,
			pane_gap = 4,
			autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
			preset = {
				pick = nil,
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep')",
					},
					{
						icon = " ",
						key = "o",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{
						icon = "󰒲 ",
						key = "L",
						desc = "Lazy",
						action = ":Lazy",
						enabled = package.loaded.lazy ~= nil,
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = [[
          ███╗   ███╗██╗   ██╗██╗███╗   ███╗          Z
          ████╗ ████║██║   ██║██║████╗ ████║       Z   
          ██╔████╔██║██║   ██║██║██╔████╔██║     z     
          ██║╚██╔╝██║╚██╗ ██╔╝██║██║╚██╔╝██║   z       
          ██║ ╚═╝ ██║ ╚████╔╝ ██║██║ ╚═╝ ██║           
          ╚═╝     ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝           
        ]],
			},
			formats = {
				icon = function(item)
					if item.file and item.icon == "file" or item.icon == "directory" then
						return Snacks.dashboard.icon(item.file, item.icon)
					end
					return { item.icon, width = 2, hl = "icon" }
				end,
				footer = { "%s", align = "center" },
				header = { "%s", align = "center" },
				file = function(item, ctx)
					local fname = vim.fn.fnamemodify(item.file, ":~")
					fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
					if #fname > ctx.width then
						local dir = vim.fn.fnamemodify(fname, ":h")
						local file = vim.fn.fnamemodify(fname, ":t")
						if dir and file then
							file = file:sub(-(ctx.width - #dir - 2))
							fname = dir .. "/…" .. file
						end
					end
					local dir, file = fname:match("^(.*)/(.+)$")
					return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
				end,
			},
			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1, padding = 1 },
				{ section = "startup" },
			},
		},

		picker = {
			win = {
        input = {
          keys = {
            ["<C-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
            ["<C-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
          },
        },
				list = {
					keys = {
						["<C-d>"] = "preview_scroll_down",
						["<C-u>"] = "preview_scroll_up",
					},
				},
			},
		},

    -- https://www.reddit.com/r/neovim/comments/1kuvckk/how_to_hide_all_indent_lines_except_the_current/
    indent = {
      indent = {
        enabled = false,
      },
      chunk = {
        enabled = true,
        char = {
          horizontal = '─',
          vertical = '│',
          corner_top = '╭',
          corner_bottom = '╰',
          arrow = '─',
        },
      },
    },
		explorer = { enabled = false },
		input = { enabled = false },
		lazygit = { enabled = false },
		quickfile = { enabled = false },
		scope = { enabled = false },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = false },
		gh = { enabled = true },
		git = { enabled = false },
		gitbrowse = { enabled = false },
		rename = { enabled = false },
	},
}
