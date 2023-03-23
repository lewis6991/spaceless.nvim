
local group = vim.api.nvim_create_augroup('spaceless', {})

local function au(event, callback)
  vim.api.nvim_create_autocmd(event, { group = group, callback = callback })
end

---@module 'spaceless'
local spaceless = setmetatable({}, {
  __index = function(_, name)
    return function()
      require('spaceless')[name]()
    end
  end
})

au('InsertEnter' , spaceless.onInsertEnter)
au('InsertLeave' , spaceless.onInsertLeave)
au('TextChangedI', spaceless.onTextChangedI)
au('TextChanged' , spaceless.onTextChanged)

-- The user may move between buffers in insert mode
-- (for example, with the mouse), so handle this appropriately.
au('BufEnter', spaceless.onBufEnter)
au('BufLeave', spaceless.onBufLeave)
