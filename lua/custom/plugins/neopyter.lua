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
}
