-- =============================================================================
-- minh.dap — step through a debug session without <leader>d before every step
--
--   step_mode()  n over · i into · o out · c continue; any other key exits (and
--                is swallowed, so it never reaches the buffer). Each step waits
--                for the debugger to stop (or the session to end) before taking
--                the next key, so the code view is current. While `c` runs to the
--                next breakpoint, <C-c> leaves step mode.
--   watch()      add the variable under the cursor to Watches. In the file being
--                debugged (__main__) it is watched as __import__("__main__").x,
--                which works from every frame (stepping inside another module
--                no longer gives NameError); elsewhere, as the plain name.
--   focus_repl() jump to the REPL inside dap-ui (opening dap-ui if closed).
--                dap.repl.open() instead makes a split of its own, and when
--                dap-ui opens later it adds its REPL too: two REPL panes.
-- =============================================================================

local M = {}

local STEP_TIMEOUT_MS = 5000
local CONTINUE_TIMEOUT_MS = 10 * 60 * 1000

local STEPS = {
  n = "step_over",
  i = "step_into",
  o = "step_out",
  c = "continue",
}

local HINT = "-- DAP step: n over  i into  o out  c continue  (other key exits) --"

--- The next key, redrawing while it is awaited. A blocking getcharstr() does not
--- redraw: the variables arrive after the stop, so the values dap-ui and the
--- virtual text drew for it only showed with the next key, one step late (at
--- the `if` of a loop's second pass, `i` still showed the first pass's value).
local function next_key()
  while vim.fn.getchar(1) == 0 do
    local _, why = vim.wait(30) -- runs the callbacks that bring the variables
    if why == -2 then
      return "\3" -- <C-c> was taken by the wait; it still leaves step mode
    end
    vim.cmd.redraw()
  end
  return vim.fn.getcharstr()
end
local RUNNING = "-- DAP step: running to the next breakpoint (<C-c> leaves step mode) --"

function M.step_mode()
  local dap = require("dap")
  if not dap.session() then
    vim.notify("DAP: no active session (<leader>dc to start)", vim.log.levels.WARN)
    return
  end

  local stopped = false
  local function mark()
    stopped = true
  end
  dap.listeners.after.event_stopped.minh_step = mark
  dap.listeners.after.event_terminated.minh_step = mark
  dap.listeners.after.event_exited.minh_step = mark

  while dap.session() do
    vim.cmd.redraw()
    vim.api.nvim_echo({ { HINT, "ModeMsg" } }, false, {})
    local key = next_key()
    local step = STEPS[key]
    -- Focus changes (switching herdr pane or terminal window), mouse and other
    -- special keys arrive here too; they must not end step mode.
    if not step and key:byte(1) ~= 0x80 then
      break
    end
    if not step then
      goto next_key
    end
    stopped = false
    dap[step]()
    if step == "continue" then
      vim.api.nvim_echo({ { RUNNING, "ModeMsg" } }, false, {})
      vim.cmd.redraw()
    end
    -- The stopped event comes before the new frame is fetched: wait for both.
    -- `c` may run for long (to the next breakpoint or the end); <C-c> interrupts
    -- the wait and leaves step mode, the program keeps running.
    local ok = vim.wait(step == "continue" and CONTINUE_TIMEOUT_MS or STEP_TIMEOUT_MS, function()
      local session = dap.session()
      return stopped and (not session or session.current_frame ~= nil)
    end, 20)
    if not ok and step == "continue" then
      break
    end
    ::next_key::
  end

  dap.listeners.after.event_stopped.minh_step = nil
  dap.listeners.after.event_terminated.minh_step = nil
  dap.listeners.after.event_exited.minh_step = nil
  -- Say so: after this, n i o c are plain vim keys again (n = next search match).
  vim.api.nvim_echo({ { "-- DAP step mode off --", "WarningMsg" } }, false, {})
end

-- Python keywords under the cursor are not variables (<cword> on `for`, `in`...).
local KEYWORDS = {}
for _, k in ipairs(vim.split("and as assert async await break class continue def del elif else except "
  .. "finally for from global if import in is lambda nonlocal not or pass raise return try while with yield "
  .. "None True False", " ")) do
  KEYWORDS[k] = true
end

function M.watch()
  local name = vim.fn.expand("<cword>")
  if not name:match("^[%a_][%w_]*$") or KEYWORDS[name] then
    vim.notify("DAP: no variable name under the cursor", vim.log.levels.WARN)
    return
  end
  local session = require("dap").session()
  local program = session and session.config.program
  local here = vim.api.nvim_buf_get_name(0)
  local in_main = type(program) == "string" and vim.fs.normalize(vim.fn.fnamemodify(program, ":p")) == vim.fs.normalize(here)
  local expr = in_main and ('__import__("__main__").' .. name) or name
  require("dapui").elements.watches.add(expr)
  vim.notify("DAP: watching " .. expr, vim.log.levels.INFO)
end

function M.focus_repl()
  local function repl_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "dap-repl" then
        return win
      end
    end
  end
  local win = repl_win()
  if not win then
    require("dapui").open()
    win = repl_win()
  end
  if win then
    vim.api.nvim_set_current_win(win)
  end
end

return M
