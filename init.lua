local o = vim.o         -- глобальные опции
local wo = vim.wo       -- окна
local bo = vim.bo       -- буферы

-- Отступы
o.tabstop = 4          -- ширина таба визуально (кол-во пробелов)
o.shiftwidth = 4       -- сколько сдвигать при автодополнении и >>/<<
o.expandtab = true     -- использовать пробелы вместо табов
o.autoindent = true    -- включить автодовод отступа
o.smartindent = true   -- умная автоиндентация для языков типа C/PHP

-- Поиск
o.incsearch = true     -- инкрементальный поиск
o.hlsearch = true      -- подсвечивать все совпадения

-- Номера строк
wo.relativenumber = true -- относительные номера строк
wo.number = true         -- абсолютный номер для текущей строки

vim.g.mapleader = " "
vim.keymap.set('n', '<C-s>', ':w<CR>', { noremap = true, silent = true })
-- vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>a', { noremap = true, silent = true })

vim.pack.add({
    'https://github.com/windwp/nvim-autopairs',
    'https://github.com/folke/flash.nvim',
    'https://github.com/projekt0n/github-nvim-theme',
    'https://github.com/nvim-mini/mini.files',
})

vim.cmd("colorscheme github_light")

require('nvim-autopairs').setup()

require('mini.files').setup({
    mappings = {
      go_in = "L",
      go_in_plus = "l",
    },
})
vim.keymap.set('n', '<leader>e', ':lua MiniFiles.open()<CR>', { noremap = true, silent = true })

require("flash").setup({
    modes = {
      -- отключаю переопределние f и t, мне больше нравится стандартное поведение
      char = { enabled = false },
      -- включаю jump по поиску
      search = { enabled = true },
    },
})
-- чтобы метки были более контрастные:
vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#ffffff", bg = "#bf005d" })

-- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/intelephense.lua
vim.lsp.config('intelephense', {
    cmd = { 'intelephense', '--stdio' },
    filetypes = { 'php' },
    root_markers = { '.git', 'composer.json' },
    on_attach = function(client, bufnr)
        vim.lsp.completion.enable(true, client.id, bufnr, {
            autotrigger = false,
        })
        -- vim.lsp.inlay_hint.enable(true, {bufnr = bufnr})
    end,
})
vim.cmd[[set completeopt=menuone,popup]]
vim.keymap.set('i', '<C-Space>', '<C-x><C-o>', { noremap = true, silent = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  pattern = '*',
  desc = 'Highlight selection on yank',
  callback = function()
    vim.highlight.on_yank { higroup = 'IncSearch', timeout = 150 }
  end,
})

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}
-- vim.opt.clipboard = "unnamedplus"

vim.lsp.enable('intelephense')
