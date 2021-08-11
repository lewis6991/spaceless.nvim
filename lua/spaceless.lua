local api = vim.api

local M = {}

function M.onInsertEnter()
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
  -- Only do this on whitelisted filetypes and if the buffer is modifiable
  -- and modified and we are at the tip of an undo tree
  if not vim.bo.modifiable
    and not vim.bo.modified
    and not atTipOfUndo() then
    return
  end

  if not top then return end

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

  vim.cmd("silent exe "..top.." ',' "..vim.b.bottom.. " 's/\\v\\s+$//e'")

  vim.fn.setpos("']", last_changed)
  vim.fn.setpos("'[", first_changed)
  vim.fn.setpos('.', original_cursor)
end

function M.onTextChanged()
  -- Text was modified in non-Insert mode.  Use the '[ and '] marks to find
  -- what was edited and remove its whitespace.
  stripWhitespace(vim.fn.line("'["), vim.fn.line("']"))
end

function M.onTextChangedI()
  -- Handle motion this way (rather than checking if
  -- b:insert_bottom < curline) to catch the case where the user presses
  -- Enter, types whitespace, moves up, and presses Enter again.
  local curline = api.nvim_win_get_cursor(0)[1]

  if vim.b.whitespace_lastline < curline then
      -- User inserted lines below whitespace_lastline
      vim.b.insert_bottom = vim.b.insert_bottom + (curline - vim.b.whitespace_lastline)
  elseif vim.b.whitespace_lastline > curline then
      -- User inserted lines above whitespace_lastline
      vim.b.insert_top = vim.b.insert_top - (vim.b.whitespace_lastline - curline)
  end

  vim.b.whitespace_lastline = curline
end

function M.onInsertLeave()
  stripWhitespace(vim.b.insert_top, vim.b.insert_bottom)
end

function M.onBufLeave()
  if api.nvim_get_mode().mode == 'i' then
    stripWhitespace(vim.b.insert_top, vim.b.insert_bottom)
  end
end

function M.onBufEnter()
  if api.nvim_get_mode().mode == 'i' then
    M.onInsertEnter()
  end
end

function M.setup()
  vim.cmd[[
  augroup Spaceless
    autocmd!
    autocmd InsertEnter  * lua require('spaceless').onInsertEnter()
    autocmd InsertLeave  * lua require('spaceless').onInsertLeave()
    autocmd TextChangedI * lua require('spaceless').onTextChangedI()
    autocmd TextChanged  * lua require('spaceless').onTextChanged()

    " The user may move between buffers in insert mode
    " (for example, with the mouse), so handle this appropriately.
    autocmd BufEnter * lua require('spaceless').onBufEnter()
    autocmd BufLeave * lua require('spaceless').onBufLeave()
  augroup END
  ]]
end

return M
