return {
  'SUSTech-data/neopyter',
  lazy = false,
  opts = {
    -- Neovim and JupyterLab run on the SSH host; forward only JupyterLab's port.
    mode = 'proxy',
    remote_address = '127.0.0.1:9001',
    file_pattern = { '*.ju.py' },
    filename_mapper = function(path)
      return (path:gsub('%.ju%.py$', '.ipynb'))
    end,
    jupyter = {
      -- Keep the browser still while editing; synchronize explicitly on :write.
      partial_sync = false,
      scroll = { enable = false },
    },
    on_attach = function(buf)
      local function map(key, command, desc)
        vim.keymap.set('n', '<leader>r' .. key, '<cmd>Neopyter ' .. command .. '<CR>', {
          buffer = buf,
          desc = desc,
        })
      end
      -- Buffer-local mappings override Quarto's mappings only in connected notebooks.
      map('c', 'run current', 'Run current notebook cell')
      map('a', 'run all', 'Run all notebook cells')
      map('u', 'run allAbove', 'Run cells above')
      map('d', 'run allBelow', 'Run current cell and below')
      map('n', 'execute notebook:run-cell-and-select-next', 'Run cell and select next')
      map('s', 'sync current', 'Sync current notebook')
    end,
  },
  config = function(_, opts)
    require('neopyter').setup(opts)

    local Notebook = require 'neopyter.jupyter.notebook'
    local attach = Notebook.attach
    local full_sync = Notebook.full_sync
    local save = Notebook.save

    -- Neopyter normally sends an RPC update from its on_lines callback after
    -- every edit. Keep its local cell index current, but defer the browser RPC.
    Notebook.attach = function(self)
      local nvim_buf_attach = vim.api.nvim_buf_attach
      vim.api.nvim_buf_attach = function(buf, send_buffer, attach_opts)
        if buf == self.bufnr and attach_opts.on_lines then
          attach_opts = vim.tbl_extend('force', {}, attach_opts)
          attach_opts.on_lines = function()
            self:parse()
          end
        end
        return nvim_buf_attach(buf, send_buffer, attach_opts)
      end

      local ok, result = pcall(attach, self)
      vim.api.nvim_buf_attach = nvim_buf_attach
      if not ok then
        error(result)
      end
      return result
    end

    -- Neopyter already saves the paired notebook on BufWritePre. Add the
    -- deferred full synchronization immediately before that save request.
    Notebook.save = function(self)
      self:parse()
      full_sync(self)
      return save(self)
    end
  end,
}
