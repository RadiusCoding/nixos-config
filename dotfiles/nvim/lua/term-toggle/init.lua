local M = {}

local state = {
  buf = nil,
  win = nil,
}

local function is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

local function close()
  if is_open() then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

local function open()
  -- Get the directory of the current file before opening the split
  local file_dir = vim.fn.expand("%:p:h")
  if file_dir == "" or vim.fn.isdirectory(file_dir) == 0 then
    file_dir = vim.fn.getcwd()
  end

  -- Calculate ~1/3 of total height
  local height = math.floor(vim.o.lines / 3)

  -- Create horizontal split at the bottom
  vim.cmd("botright " .. height .. "split")
  state.win = vim.api.nvim_get_current_win()

  -- Open terminal in the file's directory
  vim.cmd("terminal")
  state.buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_chan_send(vim.b.terminal_job_id, "cd " .. vim.fn.shellescape(file_dir) .. " && clear\n")

  -- Enter insert mode so you can type immediately
  vim.cmd("startinsert")

  -- Wipe buffer fully when the terminal process exits
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = state.buf,
    once = true,
    callback = function()
      vim.schedule(close)
    end,
  })
end

local function toggle()
  if is_open() then
    close()
  else
    open()
  end
end

function M.setup(opts)
  opts = opts or {}
  local keymap = opts.keymap or "<leader>ft"

  vim.keymap.set("n", keymap, toggle, { desc = "Toggle terminal", silent = true })
  vim.keymap.set("t", keymap, function()
    close()
  end, { desc = "Close terminal", silent = true })
end

return M
