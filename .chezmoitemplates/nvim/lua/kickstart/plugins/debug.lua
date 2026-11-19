vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/jay-babu/mason-nvim-dap.nvim',
  'https://github.com/TheLeoP/powershell.nvim',
  'https://github.com/jbyuki/one-small-step-for-vimkind',
}

local dap = require 'dap'
local dapui = require 'dapui'
local rpc = require 'dap.rpc'

vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', function() dap.step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', function() dap.step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', function() dap.step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', function() dap.toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Breakpoint' })
-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
vim.keymap.set('n', '<F7>', function() dapui.toggle() end, { desc = 'Debug: See last session result.' })

dapui.setup {}

require('mason-nvim-dap').setup {
  automatic_installation = true,
  handlers = nil,
  ensure_installed = {},
}

vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
local breakpoint_icons = { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
for type, icon in pairs(breakpoint_icons) do
  local tp = 'Dap' .. type
  local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
  vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
end

dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

-- Need to have dap set up prior to this set up. This also handles lsp, etc
require('powershell').setup {
  bundle_path = vim.fn.expand '$MASON/packages/powershell-editor-services',
}

dap.adapters.nlua = function(callback, config)
  callback {
    type = 'server',
    host = config.host or '127.0.0.1',
    port = config.port or 8086,
  }
end
dap.configurations.lua = {
  {
    type = 'nlua',
    request = 'attach',
    name = 'Attach to running Neovim instance',
  },
}

local function create_signer_script(signer_path)
  local content = string.format(
    [[
        try {
            const signerModule = require('%s');
            const signer = new signerModule.signer();

            // Get payload from arguments
            const payload = process.argv[2];
            if (!payload) process.exit(1);

            // Sign and output
            process.stdout.write(signer.sign(payload));
        } catch (e) {
            console.error("Signer error:", e);
            process.exit(1);
        }
    ]],
    vim.fs.abspath(signer_path)
  )

  local script_path = vim.fn.stdpath 'cache' .. '/handshake_signer.js'
  local f = io.open(script_path, 'w')
  if f then
    f:write(content)
    f:close()
    return script_path
  end
  return nil
end
local signer_script = create_signer_script '~/scoop/apps/vscode/current/69047191fc/resources/app/node_modules.asar.unpacked/vsda/build/Release/vsda.node'

local function RunHandshake(self, request_payload)
  local cmd = 'node ' .. signer_script .. ' ' .. request_payload.arguments.value
  local handle = io.popen(cmd)
  if not handle then return end

  local signature = handle:read '*a'
  handle:close()

  if signature then
    local response = {
      type = 'response',
      seq = 0,
      command = 'handshake',
      request_seq = request_payload.seq,
      success = true,
      body = { signature = signature },
    }
    self.client.write(rpc.msg_with_content_length(vim.json.encode(response)))
  end
end

dap.adapters.vscoreclr = {
  -- id required for vsdb-ui to initialize otherwise default is `nvim-dap`
  id = 'coreclr',
  type = 'executable',
  command = vim.fs.abspath '~/scoop/persist/vscode/data/extensions/ms-dotnettools.csharp-11.7.18-win32-x64/.debugger/x86_64/vsdbg-ui.exe',
  args = {
    '--interpreter=vscode',
  },
  options = {
    detached = false -- Required for internal console to work properly and not pop up a conhost.exe
  },
  console = 'internalConsole',
  reverse_request_handlers = {
    handshake = RunHandshake
  }
}
local function get_dll()
  return coroutine.create(function(dap_run_co)
    local items = vim.fn.globpath(vim.fn.getcwd(), '**/bin/Debug/**/*.dll', 0, 1)
    local opts = {
      format_item = function(path) return 'Vsdbg-Ui: Launch ' .. vim.fn.fnamemodify(path, ':t') end,
    }
    local function cont(choice)
      if choice == nil then
        return nil
      else
        coroutine.resume(dap_run_co, choice)
      end
    end

    vim.ui.select(items, opts, cont)
  end)
end
dap.configurations.cs = {
  {
    type = 'vscoreclr',
    name = 'Vsdbg-Ui: Launch Dll',
    request = 'launch',
    cwd = '${fileDirname}',
    program = get_dll,
  },
}

vim.keymap.set('n', '<leader>dl', function() require('osv').launch { port = 8086 } end, { desc = '[D]ebug [L]aunch' })
vim.keymap.set('n', '<leader>dw', function() require('dap.ui.widgets').hover() end, { desc = '[D]ebug [W]idget Hover' })
vim.keymap.set('n', '<leader>df', function()
  local widgets = require 'dap.ui.widgets'
  widgets.centered_float(widgets.frames)
end, { desc = '[D]ebug Widget [F]loat' })
