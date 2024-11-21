local M = {}

-- Store window and buffer IDs
M.win_id = nil
M.buf_id = nil

M.selectable_lines = {} -- Will store line numbers that contain marks

-- Window creation with some nice defaults
function M.create_window()
  -- Create a new buffer for our window
  local buf = vim.api.nvim_create_buf(false, true)

  -- Get editor dimensions
  local width = vim.o.columns
  local height = vim.o.lines

  -- Calculate floating window size
  local win_height = math.min(math.ceil(height * 0.8 - 4), 40)
  local win_width = math.min(math.ceil(width * 0.8), 80)

  -- Calculate starting position to center the window
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- Set some buffer options
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "delete"

  -- Window options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = "rounded",
    title = " MarkStash ",
    title_pos = "center",
  }

  -- Create and store window ID
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Store IDs for later use
  M.win_id = win
  M.buf_id = buf

  -- Set window-local options
  vim.wo[win].cursorline = true
  vim.wo[win].winblend = 10

  return win, buf
end

function M.is_open()
  return M.win_id ~= nil and vim.api.nvim_win_is_valid(M.win_id)
end

function M.close()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_win_close(M.win_id, true)
  end
  M.win_id = nil
  M.buf_id = nil
end

function M.setup_keymaps()
  local opts = { buffer = M.buf_id, silent = true, noremap = true }
  vim.keymap.set("n", "j", function()
    M.move_cursor("down")
  end, opts)
  vim.keymap.set("n", "k", function()
    M.move_cursor("up")
  end, opts)
  vim.keymap.set("n", "<CR>", function()
    M.jump_to_mark()
  end, opts)
end

function M.jump_to_mark()
  local current_line = vim.api.nvim_win_get_cursor(M.win_id)[1]
  -- Get the content of the current line
  local line_content = vim.api.nvim_buf_get_lines(M.buf_id, current_line - 1, current_line, false)[1]

  -- Extract the mark character (first character of the line)
  local mark = line_content:match("^([`'a-zA-Z])")

  if mark then
    -- Close the window
    M.close()
    -- Jump to the mark
    vim.cmd("normal! `" .. mark)
  end
end

function M.update_content(window_marks, global_marks)
  if not M.buf_id or not vim.api.nvim_buf_is_valid(M.buf_id) then
    return
  end

  local lines = {
    "Window Marks",
    "------------",
  }

  M.selectable_lines = {} -- Reset selectable lines
  local current_line = #lines + 1

  -- Add window marks
  for _, mark in ipairs(window_marks) do
    table.insert(lines, string.format("%s  %s:%s", mark.mark, mark.file, mark.line))
    table.insert(M.selectable_lines, current_line)
    current_line = current_line + 1
  end

  -- Add spacing and global marks section
  table.insert(lines, "")
  table.insert(lines, "Global Marks")
  table.insert(lines, "------------")
  current_line = current_line + 3

  -- Add global marks
  for _, mark in ipairs(global_marks) do
    table.insert(lines, string.format("%s  %s:%s", mark.mark, mark.file, mark.line))
    table.insert(M.selectable_lines, current_line)
    current_line = current_line + 1
  end

  -- Update buffer content
  vim.bo[M.buf_id].modifiable = true
  vim.api.nvim_buf_set_lines(M.buf_id, 0, -1, false, lines)
  vim.bo[M.buf_id].modifiable = false

  -- Setup keymaps after content is updated
  M.setup_keymaps()

  -- Move cursor to first selectable line if it exists
  if M.selectable_lines[1] then
    vim.api.nvim_win_set_cursor(M.win_id, { M.selectable_lines[1], 0 })
  end
end

function M.move_cursor(direction)
  local current_line = vim.api.nvim_win_get_cursor(M.win_id)[1]
  local next_line

  if direction == "down" then
    -- Find next selectable line after current position
    for _, line_num in ipairs(M.selectable_lines) do
      if line_num > current_line then
        next_line = line_num
        break
      end
    end
    -- If no next line found, wrap to first
    next_line = next_line or M.selectable_lines[1]
  else
    -- Find previous selectable line before current position
    for i = #M.selectable_lines, 1, -1 do
      if M.selectable_lines[i] < current_line then
        next_line = M.selectable_lines[i]
        break
      end
    end
    -- If no previous line found, wrap to last
    next_line = next_line or M.selectable_lines[#M.selectable_lines]
  end

  if next_line then
    vim.api.nvim_win_set_cursor(M.win_id, { next_line, 0 })
  end
end

return M
