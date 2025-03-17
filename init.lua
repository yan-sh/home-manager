-- require("packman")

-- vim.cmd [[packadd packer.nvim]]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


require('lazy').setup({
  "ntk148v/komau.vim",
  "pgdouyon/vim-yin-yang",
  "lifepillar/vim-solarized8",
  "neovim/nvim-lspconfig",
  "nvim-lua/lsp-status.nvim",
  "neovimhaskell/haskell-vim",
  "junegunn/fzf",
  "junegunn/fzf.vim",
  "Twinside/vim-hoogle",
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  "ryanoasis/vim-devicons",
  "onsails/lspkind-nvim",
  "nvim-lua/popup.nvim",
  "nvim-telescope/telescope.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "nvim-treesitter/nvim-treesitter",
  "preservim/tagbar",
  "liuchengxu/vista.vim",
  "relastle/bluewery.vim",
  "cocopon/iceberg.vim",
  "jacksonludwig/vim-earl-grey",
  "kkga/vim-envy",
  "casperstorm/sort-hvid.vim",
  "rflban/homecolors.vim",
  "LnL7/vim-nix",
  "romgrk/doom-one.vim",
  "NTBBloodbath/doom-one.nvim",
  "sainnhe/everforest",
  "KeitaNakamura/neodark.vim",
  "adrian5/oceanic-next-vim",
  "mswift42/vim-themes",
  "tobi-wan-kenobi/zengarden",
  "yuttie/sublimetext-spacegray.vim",
  "antonk52/lake.vim",
  "habamax/vim-saturnite",
  "axvr/raider.vim",
  "Softmotions/vim-dark-frost-theme",
  "habamax/vim-habanight",
  "pineapplegiant/spaceduck",
  "sainnhe/edge",
  "mzarnitsa/psql",
  "lifepillar/pgsql.vim",
  "zekzekus/menguless",
  "vim-scripts/bw.vim",
  "vim-scripts/zenesque.vim",
  "chriskempson/base16-vim",
  "mnishz/colorscheme-preview.vim",
  "folke/tokyonight.nvim",
  "rktjmp/lush.nvim",
  "Lokaltog/monotone.nvim",
  "folke/trouble.nvim",
  "cideM/yui",
  "ellisonleao/gruvbox.nvim",
  "arturgoms/moonbow.nvim",
  {"ndmitchell/ghcid", 
    config = function(plugin)
        vim.opt.rtp:append(plugin.dir .. "/plugins/nvim")
    end
  },
  {
    "cuducos/yaml.nvim",
    ft = { "yaml" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    }
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    config = true
  },
  { "rose-pine/neovim", name = "rose-pine" },
  { "haystackandroid/rusticated" },
  { "EdenEast/nightfox.nvim" },
  { "zenbones-theme/zenbones.nvim" },
  { "FrenzyExists/aquarium-vim" },
  { "lunacookies/vim-corvine" },
  { "ashfinal/vim-colors-violet" },
  { "jordwalke/VimCleanColors" },
  { "epszaw/hg.vim" },
  { "p00f/alabaster.nvim" },
  { "jecaro/ghcid-error-file.nvim" },
  {
    "folke/zen-mode.nvim",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }
})
-- packman.get("arkav/lualine-lsp-progress")

--
vim.g.check_on_save = false
vim.diagnostic.config{underline = false}

function show_lsp_quickfix()
  vim.cmd([[
    cclose
    belowright copen
  ]])
  vim.diagnostic.setqflist()
  vim.cmd('wincmd p')
end


-- Trouble
require("trouble").setup
  { 
    mode = "workspace_diagnostics",
    position = "left", 
    signs =
      {
        errors = 'E',
        warnings = 'W',
        information = 'I',
        hint = '?',
        ok = 'Ok'
      }
  }

-- Lsp saga
-- local saga = require 'lspsaga'
-- saga.init_lsp_saga()

vim.wo.number = true
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.termguicolors = true
vim.cmd([[
  colorscheme solarized8_flat
  syntax on
  set hidden
  set background=light
  set guifont=Iosevka:h16
  set clipboard=unnamedplus
  set completeopt=menu,menuone,noselect
  set noswapfile
]])
vim.g.neovide_input_macos_option_key_is_meta = 'both'
-- set colorcolumn=90
--
--

--
--
vim.api.nvim_set_keymap('i', 'jj', '<Esc>', {})
vim.api.nvim_set_keymap('t', 'jj', '<C-\\><C-n>', {})
vim.api.nvim_set_keymap('', '<A-h>', '<C-c><C-w>h', {silent=true})
vim.api.nvim_set_keymap('', '<A-j>', '<C-c><C-w>j', {silent=true})
vim.api.nvim_set_keymap('', '<A-k>', '<C-c><C-w>k', {silent=true})
vim.api.nvim_set_keymap('', '<A-l>', '<C-c><C-w>l', {silent=true})
vim.api.nvim_set_keymap('i', '<A-h>', '<C-c><C-w>h', {silent=true})
vim.api.nvim_set_keymap('i', '<A-j>', '<C-c><C-w>j', {silent=true})
vim.api.nvim_set_keymap('i', '<A-k>', '<C-c><C-w>k', {silent=true})
vim.api.nvim_set_keymap('i', '<A-l>', '<C-c><C-w>l', {silent=true})
vim.api.nvim_set_keymap('', '<A-f>', '<C-c>:FZF<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-b>', '<C-c>:Buffers<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-a>', '<C-c>:Ag<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-s>', '<Cmd>lua vim.cmd("w")<CR>', {silent=true})
-- vim.api.nvim_set_keymap('i', '<A-s>', '<C-c>:w<CR>', {silent=true})

vim.api.nvim_set_keymap('', '<A-w>', '<C-c><C-w>n<CR>', {})
vim.api.nvim_set_keymap('', '<A-v>', '<C-c><C-w>v<CR>', {})

vim.api.nvim_set_keymap('', '<A-,>', '<C-c>:tabprevious<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-.>', '<C-c>:tabnext<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-q>', '<C-c>:q<CR>', {})
vim.api.nvim_set_keymap('', '<A-n>', '<C-c>:tabnew<CR>', {})

vim.api.nvim_set_keymap('', '<F1>', '<C-c>:Hoogle ', {})
vim.api.nvim_set_keymap('i', '<F1>', '<C-c>:Hoogle ', {})

vim.api.nvim_set_keymap('n', ';', ':', {})

vim.api.nvim_set_keymap('', '<A-t>', '<C-c>:Tags<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-g>', '<C-c>:GitBlameToggle<CR>', {silent=true})

-- Lsp save keymaps
-- vim.api.nvim_set_keymap('n', 'ca', [[<Cmd>lua require('lspsaga.codeaction').code_action()<CR>]], {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('v', 'ca', ':<C-U>lua require(\'lspsaga.codeaction\').range_code_action()<CR>', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', 'gh', [[<Cmd>lua require'lspsaga.provider'.lsp_finder()<CR>]], {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', 'K', [[<Cmd>lua require('lspsaga.hover').render_hover_doc()<CR>]], {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', 'gs', [[<Cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>]], {noremap = true, silent = true})
vim.api.nvim_set_keymap('', '<A-[>', '<C-c>:cprevious<CR><C-c>', {silent=true})
vim.api.nvim_set_keymap('', '<A-]>', '<C-c>:cnext<CR><C-c>', {silent=true})
vim.api.nvim_set_keymap('', '<F5>', '<C-c>:cfile quickfix<CR><C-c>', {silent=true})
vim.api.nvim_set_keymap('', '<A-c>', '<Cmd>lua vim.cmd("cclose")<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-o>', '<Cmd>lua vim.cmd("copen")<CR>', {silent=true})
vim.api.nvim_set_keymap('n', 'gd', '<C-c>g[<CR>', {silent=true})

--
-- Neogit

-- local neogit = require("neogit")
-- 
-- neogit.setup {
--   integrations = {
--     diffview = true
--   }
-- }

--


--
-- Statusline

local lsp_status = require('lsp-status')
lsp_status.register_progress()
lsp_status.config({
    indicator_errors = 'E',
    indicator_warnings = 'W',
    indicator_info = 'I',
    indicator_hint = 'H',
    indicator_ok = 'Ok',
    status_symbol = '',
  })
--
-- require('lualine').setup{
--   options = {theme = 'solarized_light', icons_enabled = false},
--   sections = {
--     lualine_a = {'mode'},
--     lualine_b = {'branch', 'diff', 'diagnostics'},
--     lualine_c = {'filename'},
--     lualine_x = {'encoding', 'fileformat', 'filetype'},
--     lualine_y = {'progress'},
--     lualine_z = {'location'}
--   }
-- }

--

--
--

--
local nvim_lsp = require('lspconfig')
-- Use an on_attach function to only map the following keys 
-- after the language server attaches to the current buffer
local custom_on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  -- lsp_status.on_attach(client, bufnr)
-- Mappings.
  local opts = { noremap=true, silent=true }
-- See :help vim.lsp.* for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  --buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  --buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float({scope="line"})<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>a', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('', '<A-e>', '<cmd>lua show_lsp_quickfix()<CR>', opts)
  buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  buf_set_keymap("n", "<space>s", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>", opts)
  
end
-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers =
  {  
    -- "hls",
    "rust_analyzer"
  }
local lspSettings =
  { hls =
      { haskell =
        { plugin =
          { hlint =
            { diagnosticsOn = false
            , codeActionsOn = false
            }
          }
        }
      }
  , rust_analyzer =
      {
        ["rust-analyzer"] = {
          assist = {
              importGranularity = "module",
              importPrefix = "by_self",
          },
          cargo = {
              loadOutDirsFromCheck = true
          },
          procMacro = {
              enable = true
          }
        }
      }
  }


--    "haskell.plugin.ghcide-completions.config.snippetsOn": false,
--    "haskell.plugin.hlint.diagnosticsOn": false,
--    "haskell.plugin.hlint.codeActionsOn": false

for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = custom_on_attach,
    settings = lspSettings[lsp],
    -- capabilities = capabilities,
  }
end
