-- claude-code.nvim
-- Neovim plugin for Claude Code integration

local M = {}

-- Configuration defaults
M.config = {
  keymap = "<leader>fc",
  claude_cmd = "claude",
  log_file = vim.fn.stdpath("cache") .. "/claude-code.log",
  debug = true,  -- Set to false to disable logging
}

-- Namespace for virtual text and extmarks
M.ns_id = vim.api.nvim_create_namespace("claude_code_spinner")

-- Active tasks tracking
M.tasks = {}
M.task_counter = 0

-- 3x3 dot matrix spinner frames (braille patterns)
M.spinner_frames = {
  "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"
}

-- Logging function
function M.log(level, msg)
  if not M.config.debug then return end

  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_line = string.format("[%s] [%s] %s\n", timestamp, level, msg)

  local f = io.open(M.config.log_file, "a")
  if f then
    f:write(log_line)
    f:close()
  end

  -- Also show errors in nvim
  if level == "ERROR" then
    vim.notify("Claude: " .. msg, vim.log.levels.ERROR)
  end
end

-- Command to view log file
function M.view_log()
  vim.cmd("edit " .. M.config.log_file)
end

-- Command to clear log file
function M.clear_log()
  local f = io.open(M.config.log_file, "w")
  if f then
    f:write("")
    f:close()
    vim.notify("Claude log cleared", vim.log.levels.INFO)
  end
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  M.log("INFO", "Claude Code plugin initialized")
  M.log("INFO", "Log file: " .. M.config.log_file)

  -- Visual mode keymap
  vim.keymap.set("v", M.config.keymap, function()
    -- Exit visual mode and call our function
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    vim.schedule(function()
      M.open_prompt()
    end)
  end, { desc = "Claude Code: Edit selection with AI" })

  -- Commands for log management
  vim.api.nvim_create_user_command("ClaudeLog", function() M.view_log() end, {})
  vim.api.nvim_create_user_command("ClaudeLogClear", function() M.clear_log() end, {})
  vim.api.nvim_create_user_command("ClaudeCancel", function() M.cancel_all() end, {})
end

-- Cancel all running tasks
function M.cancel_all()
  for task_id, task in pairs(M.tasks) do
    M.stop_spinner(task_id)
    if task.job_id then
      pcall(vim.fn.jobstop, task.job_id)
    end
    -- Clean up temp files
    if task.prompt_file then pcall(os.remove, task.prompt_file) end
    if task.output_file then pcall(os.remove, task.output_file) end
    if task.error_file then pcall(os.remove, task.error_file) end
  end
  M.tasks = {}
  vim.notify("All Claude tasks cancelled", vim.log.levels.INFO)
  M.log("INFO", "All tasks cancelled by user")
end

-- Get visual selection info
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  if #lines == 0 then
    return nil
  end

  -- Handle visual mode selection (adjust for partial lines)
  local mode = vim.fn.visualmode()
  if mode == "v" then
    -- Character-wise visual mode
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col, end_col)
    else
      lines[1] = string.sub(lines[1], start_col)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end
  -- For line-wise (V) and block-wise (Ctrl-V), we take full lines

  return {
    bufnr = bufnr,
    start_line = start_line,
    end_line = end_line,
    start_col = start_col,
    end_col = end_col,
    lines = lines,
    text = table.concat(lines, "\n"),
    mode = mode,
  }
end

-- Create floating prompt window
function M.open_prompt()
  local selection = M.get_visual_selection()
  if not selection then
    vim.notify("No selection found", vim.log.levels.WARN)
    M.log("WARN", "open_prompt called but no selection found")
    return
  end

  M.log("INFO", string.format("Selection: lines %d-%d, %d chars",
    selection.start_line, selection.end_line, #selection.text))

  -- Store selection for later use
  M.current_selection = selection

  -- Get filetype and file path
  M.current_filetype = vim.bo[selection.bufnr].filetype
  M.current_filepath = vim.api.nvim_buf_get_name(selection.bufnr)
  M.current_file_content = table.concat(
    vim.api.nvim_buf_get_lines(selection.bufnr, 0, -1, false),
    "\n"
  )

  -- Create buffer for input
  local prompt_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[prompt_buf].buftype = "nofile"
  vim.bo[prompt_buf].filetype = "markdown"

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * 0.6)
  local height = 3
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create floating window
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Claude: What should I do? ",
    title_pos = "center",
  }

  local prompt_win = vim.api.nvim_open_win(prompt_buf, true, win_opts)

  -- Set window options
  vim.wo[prompt_win].winblend = 10
  vim.wo[prompt_win].cursorline = true

  -- Enter insert mode
  vim.cmd("startinsert")

  -- Keymaps for the prompt buffer
  local close_prompt = function()
    if vim.api.nvim_win_is_valid(prompt_win) then
      vim.api.nvim_win_close(prompt_win, true)
    end
    if vim.api.nvim_buf_is_valid(prompt_buf) then
      vim.api.nvim_buf_delete(prompt_buf, { force = true })
    end
  end

  -- Submit on Enter
  vim.keymap.set("i", "<CR>", function()
    local prompt_lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
    local prompt_text = table.concat(prompt_lines, "\n")

    if prompt_text:match("^%s*$") then
      vim.notify("Prompt cannot be empty", vim.log.levels.WARN)
      return
    end

    close_prompt()
    vim.cmd("stopinsert")

    M.log("INFO", "User prompt: " .. prompt_text)

    -- Submit the task
    M.submit_task(prompt_text, selection)
  end, { buffer = prompt_buf, noremap = true })

  -- Cancel on Escape
  vim.keymap.set("i", "<Esc>", function()
    close_prompt()
    vim.cmd("stopinsert")
    M.log("INFO", "Prompt cancelled by user")
  end, { buffer = prompt_buf, noremap = true })

  vim.keymap.set("n", "<Esc>", function()
    close_prompt()
    M.log("INFO", "Prompt cancelled by user")
  end, { buffer = prompt_buf, noremap = true })

  vim.keymap.set("n", "q", function()
    close_prompt()
    M.log("INFO", "Prompt cancelled by user")
  end, { buffer = prompt_buf, noremap = true })
end

-- Start spinner animation on a line
function M.start_spinner(task_id, bufnr, line)
  local task = M.tasks[task_id]
  if not task then return end

  task.spinner_idx = 1
  task.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, line - 1, 0, {
    virt_text = { { " " .. M.spinner_frames[1] .. " Claude thinking...", "DiagnosticInfo" } },
    virt_text_pos = "eol",
  })

  -- Animate spinner
  task.timer = vim.uv.new_timer()
  task.timer:start(0, 80, vim.schedule_wrap(function()
    if not M.tasks[task_id] then
      return
    end

    task.spinner_idx = (task.spinner_idx % #M.spinner_frames) + 1

    if vim.api.nvim_buf_is_valid(bufnr) and task.extmark_id then
      pcall(vim.api.nvim_buf_set_extmark, bufnr, M.ns_id, line - 1, 0, {
        id = task.extmark_id,
        virt_text = { { " " .. M.spinner_frames[task.spinner_idx] .. " Claude thinking...", "DiagnosticInfo" } },
        virt_text_pos = "eol",
      })
    end
  end))
end

-- Stop spinner animation
function M.stop_spinner(task_id)
  local task = M.tasks[task_id]
  if not task then return end

  if task.timer then
    task.timer:stop()
    task.timer:close()
    task.timer = nil
  end

  if task.extmark_id and vim.api.nvim_buf_is_valid(task.bufnr) then
    pcall(vim.api.nvim_buf_del_extmark, task.bufnr, M.ns_id, task.extmark_id)
  end
end

-- Submit task to Claude
function M.submit_task(prompt, selection)
  M.task_counter = M.task_counter + 1
  local task_id = M.task_counter

  M.log("INFO", string.format("Starting task %d", task_id))

  local task = {
    id = task_id,
    bufnr = selection.bufnr,
    start_line = selection.start_line,
    end_line = selection.end_line,
    start_col = selection.start_col,
    end_col = selection.end_col,
    mode = selection.mode,
    original_text = selection.text,
    stdout_data = {},
    stderr_data = {},
    job_id = nil,
  }
  M.tasks[task_id] = task

  -- Start spinner on the line above the selection (or on the first line if at top)
  local spinner_line = math.max(1, selection.start_line)
  M.start_spinner(task_id, selection.bufnr, spinner_line)

  -- Build the prompt for Claude
  local filetype = M.current_filetype or "text"
  local filepath = M.current_filepath or "unknown"
  local file_content = M.current_file_content or ""

  local claude_prompt = string.format([[You are a code-only replacement engine. You MUST follow these rules strictly:

1. Output ONLY the replacement code. Nothing else.
2. Do NOT add any comments, explanations, or annotations.
3. Do NOT wrap the output in markdown code fences or backticks.
4. Do NOT add any text before or after the code.
5. Do NOT attempt to modify any files. Do NOT use any tools.
6. Preserve the original indentation style exactly.

File type: %s
File path: %s

Full file for context:

```%s
%s
```

Selected code (lines %d-%d):

```%s
%s
```

Instruction: %s

Remember: Output ONLY the raw replacement code. No commentary. No code fences. No tool usage.]],
    filetype,
    filepath,
    filetype,
    file_content,
    selection.start_line,
    selection.end_line,
    filetype,
    selection.text,
    prompt
  )

  -- Write prompt to temp file to avoid shell escaping issues
  local prompt_file = os.tmpname()
  local f = io.open(prompt_file, "w")
  if f then
    f:write(claude_prompt)
    f:close()
    M.log("INFO", "Prompt written to: " .. prompt_file)
  else
    M.log("ERROR", "Failed to write prompt file: " .. prompt_file)
    M.stop_spinner(task_id)
    M.tasks[task_id] = nil
    return
  end

  -- Build claude command - write output to temp file for reliable capture
  local output_file = os.tmpname()
  local error_file = os.tmpname()

  -- Use cat to pipe prompt file to claude stdin
  local cmd = string.format(
    'cat "%s" | %s -p --allowedTools "" > "%s" 2> "%s"',
    prompt_file,
    M.config.claude_cmd,
    output_file,
    error_file
  )

  M.log("INFO", "Running command: " .. cmd)
  M.log("INFO", "Output file: " .. output_file)

  -- Check if claude command exists
  local claude_check = vim.fn.executable(M.config.claude_cmd)
  if claude_check ~= 1 then
    M.log("ERROR", "Claude command not found: " .. M.config.claude_cmd)
    M.stop_spinner(task_id)
    M.tasks[task_id] = nil
    os.remove(prompt_file)
    return
  end

  -- Store file paths for cleanup
  task.prompt_file = prompt_file
  task.output_file = output_file
  task.error_file = error_file

  -- Run asynchronously using shell
  local job_id = vim.fn.jobstart({ "sh", "-c", cmd }, {
    on_exit = function(_, exit_code, _)
      vim.schedule(function()
        M.log("INFO", string.format("Task %d exited with code: %d", task_id, exit_code))

        -- Read output file
        local out_f = io.open(output_file, "r")
        if out_f then
          local content = out_f:read("*all")
          out_f:close()
          if content and content ~= "" then
            task.stdout_data = vim.split(content, "\n", { plain = true })
            M.log("INFO", string.format("Read %d bytes from output file", #content))
          end
        end

        -- Read error file
        local err_f = io.open(error_file, "r")
        if err_f then
          local err_content = err_f:read("*all")
          err_f:close()
          if err_content and err_content ~= "" then
            task.stderr_data = vim.split(err_content, "\n", { plain = true })
            M.log("STDERR", err_content)
          end
        end

        -- Clean up temp files
        os.remove(prompt_file)
        os.remove(output_file)
        os.remove(error_file)
        M.log("INFO", "Cleaned up temp files")

        if exit_code ~= 0 then
          M.stop_spinner(task_id)
          local err_msg = task.stderr_data and #task.stderr_data > 0
            and table.concat(task.stderr_data, "\n")
            or "Unknown error"
          M.log("ERROR", string.format("Task %d failed: %s", task_id, err_msg))
          vim.notify("Claude error (see :ClaudeLog): exit code " .. exit_code, vim.log.levels.ERROR)
          M.tasks[task_id] = nil
        else
          M.handle_response(task_id)
        end
      end)
    end,
  })

  if job_id <= 0 then
    M.log("ERROR", "Failed to start job, job_id: " .. tostring(job_id))
    M.stop_spinner(task_id)
    M.tasks[task_id] = nil
    os.remove(prompt_file)
    os.remove(output_file)
    os.remove(error_file)
    return
  end

  task.job_id = job_id
  M.log("INFO", string.format("Job started with id: %d", job_id))
end

-- Handle Claude's response
function M.handle_response(task_id)
  local task = M.tasks[task_id]
  if not task then
    M.log("WARN", "handle_response called but task not found: " .. task_id)
    return
  end

  M.stop_spinner(task_id)

  local data = task.stdout_data or {}

  if #data == 0 then
    M.log("WARN", "Empty response from Claude")
    vim.notify("Empty response from Claude", vim.log.levels.WARN)
    M.tasks[task_id] = nil
    return
  end

  -- Join response lines and clean up
  local response = table.concat(data, "\n")
  M.log("INFO", "Raw response length: " .. #response)
  M.log("DEBUG", "Raw response:\n" .. response:sub(1, 500) .. (response:len() > 500 and "..." or ""))

  -- Remove leading/trailing whitespace
  response = response:gsub("^%s+", "")
  response = response:gsub("%s+$", "")

  -- Remove any markdown code fences if Claude added them despite instructions
  -- Handle ```lang\n...\n``` pattern
  local fenced = response:match("^```[%w]*\n(.-)\n```$")
  if fenced then
    response = fenced
  else
    -- Fallback: strip fences line by line
    response = response:gsub("^```[%w]*\n", "")
    response = response:gsub("\n```$", "")
    response = response:gsub("^```[%w]*$", "")
    response = response:gsub("^```$", "")
  end

  -- Strip common preamble patterns like "Here is the code:" or "Here's the fixed version:"
  response = response:gsub("^[Hh]ere.-:\n", "")
  response = response:gsub("^[Tt]he.-:\n", "")

  if response == "" then
    M.log("WARN", "Empty response from Claude after cleanup")
    vim.notify("Empty response from Claude after cleanup", vim.log.levels.WARN)
    M.tasks[task_id] = nil
    return
  end

  M.log("INFO", "Cleaned response length: " .. #response)

  -- Split response into lines
  local new_lines = vim.split(response, "\n", { plain = true })
  M.log("INFO", string.format("Applying %d lines to buffer", #new_lines))

  -- Check if buffer is still valid
  if not vim.api.nvim_buf_is_valid(task.bufnr) then
    M.log("WARN", "Buffer no longer valid")
    vim.notify("Buffer no longer valid", vim.log.levels.WARN)
    M.tasks[task_id] = nil
    return
  end

  -- Replace the selected text (this creates an undo point automatically)
  local ok, err = pcall(function()
    vim.api.nvim_buf_set_lines(
      task.bufnr,
      task.start_line - 1,
      task.end_line,
      false,
      new_lines
    )
  end)

  if ok then
    M.log("INFO", "Edit applied successfully")
    vim.notify("Claude edit applied", vim.log.levels.INFO)
  else
    M.log("ERROR", "Failed to apply edit: " .. tostring(err))
    vim.notify("Failed to apply edit: " .. tostring(err), vim.log.levels.ERROR)
  end

  M.tasks[task_id] = nil
end

return M
