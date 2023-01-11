-- require("packman")

-- vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)

  use "lifepillar/vim-solarized8"
  use "neovim/nvim-lspconfig"
  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-vsnip"
  use "hrsh7th/vim-vsnip"
  use "nvim-lua/lsp-status.nvim"
  use "neovimhaskell/haskell-vim"
  use "junegunn/fzf"
  use "junegunn/fzf.vim"
  use "Twinside/vim-hoogle"
  use "nvim-lua/plenary.nvim"
  use "TimUntersberger/neogit"
  use "sindrets/diffview.nvim"
  use "nvim-lualine/lualine.nvim"
  use "ryanoasis/vim-devicons"
  use "kyazdani42/nvim-web-devicons"
  use "kyazdani42/nvim-tree.lua"
  use "onsails/lspkind-nvim"
  use "onsails/lspkind-nvim"
  use "nvim-lua/popup.nvim"
  use "nvim-telescope/telescope.nvim"
  use "onsails/lspkind-nvim"
  use "folke/trouble.nvim"
  use "nvim-lua/lsp_extensions.nvim"
  use "nvim-treesitter/nvim-treesitter"
  use "cloudhead/neovim-ghcid"
  use "preservim/tagbar"
  use "liuchengxu/vista.vim"
  use "relastle/bluewery.vim"
  use "morhetz/gruvbox"
  use "cocopon/iceberg.vim"
  use "jacksonludwig/vim-earl-grey"
  use "kkga/vim-envy"
  use "casperstorm/sort-hvid.vim"
  use "rflban/homecolors.vim"
  use "sainnhe/gruvbox-material"
  use "LnL7/vim-nix"
  use "romgrk/doom-one.vim"
  use "NTBBloodbath/doom-one.nvim"
  use "sainnhe/everforest"
  use "KeitaNakamura/neodark.vim"
  use "adrian5/oceanic-next-vim"
  use "mswift42/vim-themes"
  use "tobi-wan-kenobi/zengarden"
  use "yuttie/sublimetext-spacegray.vim"
  use "antonk52/lake.vim"
  use "habamax/vim-saturnite"
  use "axvr/raider.vim"
  use "Softmotions/vim-dark-frost-theme"
  use "sheldonldev/vim-gruvdark"
  use "habamax/vim-habanight"
  use "nvim-telescope/telescope.nvim"
  use "pineapplegiant/spaceduck"
  use "sainnhe/edge"
  use "mzarnitsa/psql"
  use "lifepillar/pgsql.vim"
  use "zekzekus/menguless"
  use "vim-scripts/bw.vim"
  use "vim-scripts/zenesque.vim"
  use "chriskempson/base16-vim"
  use "mnishz/colorscheme-preview.vim"
  use "folke/tokyonight.nvim"
  use "rktjmp/lush.nvim"
  use "Lokaltog/monotone.nvim"
  use "cideM/yui"
end)
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
  if exists('g:neoray')
      set guifont=Iosevka:h16
      NeoraySet CursorAnimTime 0.03
  endif
  let g:ghcid_keep_open=1 
  set clipboard=unnamedplus
  set completeopt=menu,menuone,noselect
]])
-- set colorcolumn=90

-- LSP complete

  -- Setup nvim-cmp.
-- local cmp = require'cmp'
-- 
-- cmp.setup({
--   snippet = {
--     expand = function(args)
--       vim.fn["vsnip#anonymous"](args.body) -- For vsnip user.
--     end,
--   },
--   mapping = {
--     ['<C-p>'] = cmp.mapping.select_prev_item(),
--     ['<C-n>'] = cmp.mapping.select_next_item(),
--     ['<C-d>'] = cmp.mapping.scroll_docs(-4),
--     ['<C-f>'] = cmp.mapping.scroll_docs(4),
--     ['<C-space>'] = cmp.mapping.complete(),
--     ['<C-e>'] = cmp.mapping.close(),
--     ['<CR>'] = cmp.mapping.confirm({ select = true }),
--   },
--   sources = {
--     { name = 'nvim_lsp' },
--     -- { name = 'vsnip' },
--     -- { name = 'buffer' },
--   },
-- 
--   completion = {
--       autocomplete = false
--   },
-- })

--
require'nvim-tree'.setup {
  actions = {
    open_file = {
      resize_window = false,
    },
  },
  -- disables netrw completely
  disable_netrw       = true,
  -- hijack netrw window on startup
  hijack_netrw        = true,
  -- open the tree when running this setup function
  open_on_setup       = false,
  -- will not open on setup if the filetype is in this list
  ignore_ft_on_setup  = {},
  -- closes neovim automatically when the tree is the last WINDOW in the view
  -- auto_close          = false,
  -- opens the tree when changing/opening a new tab if the tree wasn't previously opened
  open_on_tab         = false,
  -- hijacks new directory buffers when they are opened.
  -- update_to_buf_dir   = {
  --   -- enable the feature
  --   enable = true,
  --   -- allow to open the tree if it was previously closed
  --   auto_open = true,
  -- },
  -- hijack the cursor in the tree to put it at the start of the filename
  hijack_cursor       = false,
  -- updates the root directory of the tree on DirChanged (when your run :cd usually)
  update_cwd          = false,
  -- show lsp diagnostics in the signcolumn
  -- lsp_diagnostics     = false,
  -- update the focused file on BufEnter, un-collapses the folders recursively until it finds the file
  update_focused_file = {
    -- enables the feature
    enable      = false,
    -- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory
    -- only relevant when update_focused_file.enable is true
    update_cwd  = false,
    -- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory
    -- only relevant when update_focused_file.update_cwd is true and update_focused_file.enable is true
    ignore_list = {}
  },
  -- configuration options for the system open command (s in the tree by default)
  system_open = {
    -- the command to run this, leaving nil should work in most cases
    cmd  = nil,
    -- the command arguments as a list
    args = {}
  },

  view = {
    -- width of the window, can be either a number (columns) or a string in %, for left or right side placement
    width = 30,
    -- height of the window, can be either a number (columns) or a string in %, for top or bottom side placement
    height = 30,
    -- side of the tree, can be one of 'left' | 'right' | 'top' | 'bottom'
    side = 'left',
    -- if true the tree will resize itself after opening a file
    -- auto_resize = false,
    mappings = {
      -- custom only false will merge the list with the default mappings
      -- if true, it will only use your list to set the mappings
      custom_only = false,
      -- list of mappings to set on the tree manually
      list = {}
    }
  },

  filters = {
    custom = {'.git', 'dist-newstyle'}
  }
}

vim.g.nvim_tree_show_icons = {
  git = 0,
  folders = 1,
  files = 0,
  folder_arrows = 1
}

vim.g.nvim_tree_icons = {
    default= ,
    symlink= ,
    git= {
      unstaged= "✗",
      staged= "✓",
      unmerged= "",
      renamed= "➜",
      untracked= "★",
      deleted= "",
      ignored= "◌"
      },
    folder= {
      arrow_open= "-",
      arrow_closed= "+",
      default= "",
      open= "",
      empty= "",
      empty_open= "",
      symlink= "",
      symlink_open= "",
      },
    }

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
vim.api.nvim_set_keymap('', '<A-/>', ':NvimTreeFindFile<CR>', {})
vim.api.nvim_set_keymap('', '<F8>', ':NvimTreeToggle<CR>', {})

-- Lsp save keymaps
-- vim.api.nvim_set_keymap('n', 'ca', [[<Cmd>lua require('lspsaga.codeaction').code_action()<CR>]], {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('v', 'ca', ':<C-U>lua require(\'lspsaga.codeaction\').range_code_action()<CR>', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', 'gh', [[<Cmd>lua require'lspsaga.provider'.lsp_finder()<CR>]], {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', 'K', [[<Cmd>lua require('lspsaga.hover').render_hover_doc()<CR>]], {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', 'gs', [[<Cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>]], {noremap = true, silent = true})
vim.api.nvim_set_keymap('', '<A-g>', '<C-c>:Ghcid<CR><C-c>', {silent=true})
vim.api.nvim_set_keymap('', '<A-[>', '<Cmd>lua vim.cmd("cprev")<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-]>', '<Cmd>lua vim.cmd("cnext")<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-c>', '<Cmd>lua vim.cmd("cclose")<CR>', {silent=true})
vim.api.nvim_set_keymap('', '<A-o>', '<Cmd>lua vim.cmd("copen")<CR>', {silent=true})

--
-- Neogit

local neogit = require("neogit")

neogit.setup {
  integrations = {
    diffview = true
  }
}

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
-- local lualine = require('lualine')
-- lualine.setup{
--   options = {theme = 'solarized_light', icons_enabled = false},
--   sections = {lualine_c = {lsp_status.status, {'filename', full_path = true}}}
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
  -- local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  -- buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  lsp_status.on_attach(client, bufnr)
-- Mappings.
  local opts = { noremap=true, silent=true }
-- See :help vim.lsp.* for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
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
    "hls",
    "rust_analyzer",
    "rnix"
  }
local lspSettings =
  { rnix = {}

  , hls =
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
    -- capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities()),
  }
end
