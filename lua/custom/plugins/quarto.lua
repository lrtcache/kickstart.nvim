return {
  {
    'jmbuhr/otter.nvim',
    dev = false,
    lazy = false,
    event = { 'LSPAttach' },
    dependencies = {
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
  },

  {
    'quarto-dev/quarto-nvim',
    ft = { 'quarto' },
    dev = false,
    lazy = false,
    event = { 'LSPAttach' },
    opts = {},
    dependencies = {
      'jmbuhr/otter.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('quarto').setup()
      local quarto = require 'quarto'
      vim.keymap.set('n', '<leader>rp', quarto.quartoPreview, { desc = '[r]un [p]review' })
      vim.keymap.set('n', '<leader>rc', function()
        require('quarto.runner').run_cell()
      end, { desc = '[r]un [c]urrent cell' })
      vim.keymap.set('n', '<leader>rl', function()
        require('quarto.runner').run_line()
      end, { desc = '[r]un [l]ine' })
      vim.keymap.set('n', '<leader>ra', function()
        require('quarto.runner').run_all()
      end, { desc = '[r]un [a]ll cells' })
      vim.keymap.set('n', '<leader>ru', function()
        require('quarto.runner').run_above()
      end, { desc = '[r]un above([u]p) cells' })
      vim.keymap.set('n', '<leader>rd', function()
        require('quarto.runner').run_below()
      end, { desc = '[r]un below([d]own) cell' })
    end,
  },

  { -- directly open ipynb files as quarto docuements
    -- and convert back behind the scenes
    'GCBallesteros/jupytext.nvim',
    event = { 'LSPAttach' },
    lazy = false,
    opts = {
      custom_language_formatting = {
        python = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
        r = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
      },
    },
  },

  {
    'jpalardy/vim-slime',
    dev = false,
    init = function()
      vim.b['quarto_is_python_chunk'] = false
      Quarto_is_in_python_chunk = function()
        require('otter.tools.functions').is_otter_language_context 'python'
      end

      vim.g.slime_target = 'neovim'
      vim.g.slime_no_mappings = true
      vim.g.slime_python_ipython = 1
    end,
    config = function()
      vim.g.slime_input_pid = false
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false
      vim.g.slime_neovim_ignore_unlisted = true

      local function mark_terminal()
        local job_id = vim.b.terminal_job_id
        vim.print('job_id: ' .. job_id)
      end
      local function set_terminal()
        vim.fn.call('slime#config', {})
      end

      vim.keymap.set('n', '<leader>cm', mark_terminal, { desc = '[m]ark_terminal' })
      vim.keymap.set('n', '<leader>cs', set_terminal, { desc = '[s]et_terminal' })
    end,
  },
}
