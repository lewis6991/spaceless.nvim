local api = vim.api

local function onInsertEnter()
  local curline = api.nvim_win_get_cursor(0)[1]
  vim.b.insert_top = curline
  vim.b.insert_bottom = curline
  vim.b.whitespace_lastline = curline
end

local function atTipOfUndo()
  local tree = vim.fn.undotree()
  return tree.seq_last == tree.seq_cur
end

local function stripWhitespace(top, bottom)
  -- Only do if the buffer is modifiable
  -- and modified and we are at the tip of an undo tree
  if not (vim.bo.modifiable and vim.bo.modified and atTipOfUndo()) then
    return
  end

  if not top or top < 1 then return end

  -- All conditions passed, go ahead and strip
  -- Handle the user deleting lines at the bottom
  local file_bottom = vim.fn.line('$')

  if top > file_bottom then
    -- The user deleted all the lines; there is nothing to do
    return
  end

  vim.b.bottom = math.min(file_bottom, bottom)

  -- Keep the cursor position and these marks:
  local original_cursor = vim.fn.getcurpos()
  local first_changed = vim.fn.getpos("'[")
  local last_changed = vim.fn.getpos("']")

  local sourced_text = api.nvim_buf_get_lines(0, top-1, bottom, false)
  local replaced_text = {}
  for index, line in ipairs(sourced_text) do
    local l, _ = string.gsub(line, '%s+$', '')
    table.insert(replaced_text, index, l)
  end
  api.nvim_buf_set_lines(0, top-1, bottom, false, replaced_text)

  vim.fn.setpos("']", last_changed)
  vim.fn.setpos("'[", first_changed)
  vim.fn.setpos('.', original_cursor)
end

local function onTextChanged()
  -- Text was modified in non-Insert mode.  Use the '[ and '] marks to find
  -- what was edited and remove its whitespace.
  stripWhitespace(vim.fn.line("'["), vim.fn.line("']"))
end

local function onTextChangedI()
  -- Handle motion this way (rather than checking if
  -- b:insert_bottom < curline) to catch the case where the user presses
  -- Enter, types whitespace, moves up, and presses Enter again.
  local curline = api.nvim_win_get_cursor(0)[1]

  if vim.b.whitespace_lastline < curline then
      -- User inserted lines below whitespace_lastline
      vim.b.insert_bottom = vim.b.insert_bottom + (curline - vim.b.whitespace_lastline)
  elseif vim.b.whitespace_lastline > curline then
      -- User inserted lines above whitespace_lastline
      vim.b.insert_top = math.max(1, vim.b.insert_top - (vim.b.whitespace_lastline - curline))
  end

  vim.b.whitespace_lastline = curline
end

local function onInsertLeave()
  stripWhitespace(vim.b.insert_top, vim.b.insert_bottom)
end

local function onBufLeave()
  if api.nvim_get_mode().mode == 'i' then
    stripWhitespace(vim.b.insert_top, vim.b.insert_bottom)
  end
end

local function onBufEnter()
  if api.nvim_get_mode().mode == 'i' then
    onInsertEnter()
  end
end

local M = {}

function M.setup()
  local group = api.nvim_create_augroup('spaceless', {})

  local function au(event, callback)
    api.nvim_create_autocmd(event, { group = group, callback = callback })
  end

  au('InsertEnter' , onInsertEnter)
  au('InsertLeave' , onInsertLeave)
  au('TextChangedI', onTextChangedI)
  au('TextChanged' , onTextChanged)

  -- The user may move between buffers in insert mode
  -- (for example, with the mouse), so handle this appropriately.
  au('BufEnter', onBufEnter)
  au('BufLeave', onBufLeave)
end

return M
