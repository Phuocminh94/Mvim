-- Molten: run Python in a Jupyter kernel from the buffer; each run becomes a
-- cell whose output (value of the last line, prints, tracebacks, plots) shows
-- as virtual lines under it. Plots are drawn by snacks.image.
--
-- Needs (outside this repo):
--   * a venv for nvim's Python host with pynvim + jupyter_client:
--       python3 -m venv ~/.local/share/nvim/molten-venv
--       ~/.local/share/nvim/molten-venv/bin/pip install pynvim jupyter_client nbformat pillow
--   * a kernel per project env (the env needs ipykernel):
--       <env python> -m ipykernel install --user --name <env name>
local VENV_PYTHON = vim.fs.joinpath(vim.fn.stdpath("data"), "molten-venv", "bin", "python")

--- Start the kernel named after the active conda env or venv, or pick one.
local function init_kernel()
  local env = vim.env.CONDA_PREFIX or vim.env.VIRTUAL_ENV
  local name = env and vim.fs.basename(env)
  if name and vim.tbl_contains(vim.fn.MoltenAvailableKernels(), name) then
    vim.cmd.MoltenInit(name)
  else
    vim.cmd.MoltenInit()
  end
end

--- Run the `# %%` cell around the cursor (the same cells iron's <leader>rb sends).
local function run_block()
  local here = vim.fn.line(".")
  local first = vim.fn.search([[^\s*#\s*%%]], "bcnW")
  local last = vim.fn.search([[^\s*#\s*%%]], "nW")
  first = first == 0 and 1 or (first == here and here or first + 1)
  last = last == 0 and vim.fn.line("$") or last - 1
  if last >= first then
    vim.fn.MoltenEvaluateRange(first, last)
  end
end

return {
  "benlubas/molten-nvim",
  -- Pinned to a commit that was read through; review the diff before moving it.
  commit = "bedea63819c618e007e7c40059fc6e72d598c8df",
  -- A remote (Python) plugin: its commands come from the rplugin manifest that
  -- :UpdateRemotePlugins writes, and it loads its own Lua modules when they
  -- run, so it is not lazy-loaded.
  lazy = false,
  build = ":UpdateRemotePlugins",
  init = function()
    if vim.uv.fs_stat(VENV_PYTHON) then
      vim.g.python3_host_prog = VENV_PYTHON
    end
    vim.g.molten_image_provider = "snacks.nvim"
    -- Output as virtual lines under the cell, always in view; the float only
    -- on <leader>jo.
    vim.g.molten_virt_text_output = true
    vim.g.molten_auto_open_output = false
    vim.g.molten_output_win_max_height = 20
    vim.g.molten_wrap_output = true
  end,
  keys = {
    { "<leader>ji", init_kernel, desc = "Molten: start kernel" },
    { "<leader>jj", "<cmd>MoltenEvaluateLine<cr>", desc = "Molten: run line" },
    { "<leader>jj", ":<C-u>MoltenEvaluateVisual<cr>gv<Esc>", mode = "x", desc = "Molten: run selection" },
    { "<leader>jb", run_block, desc = "Molten: run # %% cell" },
    { "<leader>jc", "<cmd>MoltenReevaluateCell<cr>", desc = "Molten: rerun cell" },
    { "<leader>jo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Molten: open output" },
    { "<leader>jh", "<cmd>MoltenHideOutput<cr>", desc = "Molten: hide output" },
    { "<leader>jd", "<cmd>MoltenDelete<cr>", desc = "Molten: delete cell" },
    { "<leader>jD", "<cmd>MoltenDelete!<cr>", desc = "Molten: delete all outputs (keep kernel)" },
    { "<leader>jr", "<cmd>MoltenRestart!<cr>", desc = "Molten: restart kernel + delete all outputs" },
    { "<leader>jx", "<cmd>MoltenInterrupt<cr>", desc = "Molten: interrupt kernel" },
  },
}
