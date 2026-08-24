local function get_personal_terminal_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == 'terminal' and vim.b[buf].personal_toggle_terminal == true then return buf end
  end
  return nil
end

local terminal_buf = get_personal_terminal_buffer()

local function is_terminal_alive(buf)
  if not buf or not vim.api.nvim_buf_is_loaded(buf) then return false end

  local job_id = vim.bo[buf].channel
  return job_id > 0 and vim.fn.jobwait({ job_id }, 0)[1] == -1
end

local function get_terminal_window(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then return win end
  end
end

local function open_terminal(buf)
  return vim.api.nvim_open_win(buf, true, {
    split = 'below',
    win = -1,
    height = 12,
  })
end

local function edit_alt_keepalt()
  vim.cmd.normal {
    vim.keycode '<C-^>',
    bang = true,
    mods = { keepalt = true },
  }
end

local function toggle_terminal()
  if is_terminal_alive(terminal_buf) then
    local win = get_terminal_window(terminal_buf)
    if win then
      if #vim.api.nvim_tabpage_list_wins(0) == 1 then
        if vim.api.nvim_get_mode().mode == 't' then vim.cmd.stopinsert() end
        local _, sch_err = vim.schedule(function()
          local ok, err = pcall(edit_alt_keepalt)
          if not ok then vim.notify('Terminal is only window remaining. Could not switch to alternate buffer. ' .. tostring(err), vim.log.levels.WARN) end
        end)
        if sch_err then vim.notify(tostring(sch_err), vim.log.levels.ERROR) end
      else
        vim.api.nvim_win_hide(win)
      end
      return
    end

    open_terminal(terminal_buf)
  else
    local stale_buf = terminal_buf
    terminal_buf = nil
    if stale_buf and vim.api.nvim_buf_is_valid(stale_buf) then vim.api.nvim_buf_delete(stale_buf, { force = true }) end

    local win = open_terminal(0)
    local ok, err = pcall(vim.cmd.terminal)
    if not ok then
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end

      error(err, 0)
    end

    terminal_buf = vim.api.nvim_get_current_buf()
    vim.bo[terminal_buf].buflisted = false
    vim.b[terminal_buf].personal_toggle_terminal = true
    vim.keymap.set('n', '<C-^>', edit_alt_keepalt, {
      buf = terminal_buf,
      desc = 'Invoke alternate file without changing alternate file otherwise the personal terminal marked as buflisted.',
    })
  end

  vim.cmd.startinsert()
end

vim.keymap.set({ 'n', 't' }, [[<C-\><C-\>]], toggle_terminal, {
  desc = 'Toggle terminal',
})

