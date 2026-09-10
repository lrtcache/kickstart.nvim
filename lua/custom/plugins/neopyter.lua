return {
  'SUSTech-data/neopyter',
  -- Save-only synchronization below depends on this revision's internal API.
  commit = 'ede156ea0fbfc7ec0920302f624f7b6c27735cfc',
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
      local function map_command(key, command, desc)
        vim.keymap.set('n', '<leader>r' .. key, '<cmd>Neopyter ' .. command .. '<CR>', {
          buffer = buf,
          desc = desc,
        })
      end

      local function map_cursor_run(key, method, desc, all_cells)
        vim.keymap.set('n', '<leader>r' .. key, function()
          require('neopyter.async').run(function()
            local jupyter = require 'neopyter.jupyter'
            local notebook = jupyter.jupyterlab and jupyter.jupyterlab:get_notebook(buf)
            if not notebook or not notebook:safe_sync() then
              vim.notify('Neopyter is not connected to this notebook', vim.log.levels.ERROR)
              return
            end

            -- Execution in JupyterLab is relative to its active cell. Neopyter
            -- normally updates that cell from CursorMoved only when scrolling is
            -- enabled, so select it explicitly while keeping the browser still.
            notebook:parse()
            local index = notebook:get_cursor_cell_pos()
            if not all_cells and index == 0 then
              vim.notify('Cursor is not inside a notebook cell', vim.log.levels.WARN)
              return
            end

            notebook:full_sync()
            notebook:activate()
            if not all_cells then
              notebook:activate_cell(index - 1)
            end
            notebook[method](notebook)
          end)
        end, { buffer = buf, desc = desc })
      end

      -- Buffer-local mappings override Quarto's mappings only in connected notebooks.
      map_cursor_run('c', 'run_selected_cell', 'Run current notebook cell')
      map_cursor_run('a', 'run_all', 'Run all notebook cells', true)
      map_cursor_run('u', 'run_all_above', 'Run cells above')
      map_cursor_run('d', 'run_all_below', 'Run current cell and below')
      map_cursor_run('n', 'run_cell_and_select_next', 'Run cell and select next')
      map_command('s', 'sync current', 'Sync current notebook')
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
