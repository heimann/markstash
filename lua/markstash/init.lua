local ui = require("markstash.ui")

local M = {}

local function parse_marks()
  local marks = vim.api.nvim_exec2("marks", { output = true }).output
  local window_marks = {}
  local global_marks = {}

  -- Split the output into lines and process each mark
  for line in marks:gmatch("[^\r\n]+") do
    -- Skip the header line
    if not line:match("^%s*mark line") then
      local mark, line_nr, col, file_or_text = line:match("%s*([`'a-zA-Z])%s+(%d+)%s+(%d+)%s+(.*)")
      if mark then
        -- Global marks are uppercase
        if mark:match("[A-Z]") then
          table.insert(global_marks, {
            mark = mark,
            line = line_nr,
            file = file_or_text,
          })
        else
          table.insert(window_marks, {
            mark = mark,
            line = line_nr,
            file = file_or_text,
          })
        end
      end
    end
  end

  return window_marks, global_marks
end

M.setup = function(_opts)
  -- We'll add configuration options here later
  print("MarkStash initialized!")
end

M.toggle = function()
  if ui.is_open() then
    ui.close()
  else
    local win_marks, global_marks = parse_marks()
    ui.create_window()
    ui.update_content(win_marks, global_marks)
  end
end

return M
