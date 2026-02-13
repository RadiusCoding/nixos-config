-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
vim.wo.relativenumber = true
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    -- Claude Code integration
    {
      dir = vim.fn.stdpath("config") .. "/lua/claude-code",
      name = "claude-code",
      config = function()
        require("claude-code").setup({
          keymap = "<leader>fc", -- space f c
        })
      end,
    },
    -- Terminal toggle
    {
      dir = vim.fn.stdpath("config") .. "/lua/term-toggle",
      name = "term-toggle",
      config = function()
        require("term-toggle").setup({
          keymap = "<leader>ft", -- space f t
        })
      end,
    },
    -- 🎨 Theme
    {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000,
      opts = {
        style = "storm",
      },
    },

    -- ✨ Noice.nvim setup
    {
      "folke/noice.nvim",
      event = "VeryLazy",
      dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
      },
      opts = {
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        cmdline = {
          enabled = true,
          view = "cmdline_popup", -- 👈 Floating : command box
          format = {
            cmdline = { icon = "" },
            search_down = { icon = " " },
            search_up = { icon = " " },
          },
        },
        views = {
          cmdline_popup = {
            position = {
              row = "10%",
              col = "50%",
            },
            size = {
              width = 60,
              height = "auto",
            },
            border = {
              style = "rounded",
              padding = { 1, 2 },
            },
            win_options = {
              winblend = 10, -- transparency
              winhighlight = {
                Normal = "Normal",
                FloatBorder = "FloatBorder",
              },
            },
          },
        },
        presets = {
          bottom_search = false,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = true,
        },
      },
    },

    -- 🪄 Optional: Pretty notifications
    {
      "rcarriga/nvim-notify",
      config = function()
        require("notify").setup({
          background_colour = "#000000",
          stages = "fade_in_slide_out",
          timeout = 3000,
        })
        vim.notify = require("notify")
      end,
    },

    -- 🔧 LSP Configuration
    {
      "williamboman/mason.nvim",
      dependencies = {
        "williamboman/mason-lspconfig.nvim",
      },
      config = function()
        -- Setup Mason first
        require("mason").setup()
        require("mason-lspconfig").setup({
          ensure_installed = { "pyright", "ts_ls", "omnisharp" },
          automatic_installation = true,
        })

        -- LSP keybindings setup
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local bufnr = args.buf
            local opts = { buffer = bufnr, noremap = true, silent = true }

            -- Jump to definition
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            -- Jump to declaration
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            -- Show hover information
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            -- Jump to implementation
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            -- Show function signature
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
            -- Show references
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            -- Rename symbol
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
            -- Code action
            vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          end,
        })

        -- Setup language servers using new API
        -- Python
        vim.lsp.config.pyright = {
          cmd = { 'pyright-langserver', '--stdio' },
          filetypes = { 'python' },
          root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', '.git' },
        }

        -- JavaScript/TypeScript
        vim.lsp.config.ts_ls = {
          cmd = { 'typescript-language-server', '--stdio' },
          filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
          root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
        }

        -- C# / OmniSharp
        vim.lsp.config.omnisharp = {
          cmd = { 'omnisharp' },
          filetypes = { 'cs' },
          root_markers = { '*.sln', '*.csproj', '.git' },
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = true,
              OrganizeImports = true,
            },
            RoslynExtensionsOptions = {
              EnableAnalyzersSupport = true,
              EnableImportCompletion = true,
            },
          },
        }

        -- Enable language servers
        vim.lsp.enable('pyright')
        vim.lsp.enable('ts_ls')
        vim.lsp.enable('omnisharp')
      end,
    },
    -- 💡 Autocompletion
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ['<Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
          }),
          sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
          }, {
            { name = 'buffer' },
            { name = 'path' },
          }),
        })
      end,
    },

    -- 🔭 Telescope Fuzzy Finder
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.8",
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      config = function()
        local telescope = require("telescope")
        local builtin = require("telescope.builtin")

        telescope.setup({
          defaults = {
            mappings = {
              i = {
                ["<C-j>"] = "move_selection_next",
                ["<C-k>"] = "move_selection_previous",
              },
            },
          },
        })

        -- Keybindings
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Find help' })
        vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Recent files' })
        vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = 'Find word under cursor' })
      end,
    },

    -- 🗂️ Oil.nvim - File explorer as a buffer
    {
      "stevearc/oil.nvim",
      config = function()
        require("oil").setup()
        vim.keymap.set('n', '<leader>fo', '<cmd>Oil<cr>', { desc = 'Open Oil file explorer' })
      end,
    },

    -- 🔀 Gitsigns - Git integration
    {
      "lewis6991/gitsigns.nvim",
      event = "BufReadPre",
      config = function()
        require('gitsigns').setup {
          on_attach = function(bufnr)
            local gitsigns = require('gitsigns')

            local function map(mode, l, r, opts)
              opts = opts or {}
              opts.buffer = bufnr
              vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map('n', ']c', function()
              if vim.wo.diff then
                vim.cmd.normal({']c', bang = true})
              else
                gitsigns.nav_hunk('next')
              end
            end)

            map('n', '[c', function()
              if vim.wo.diff then
                vim.cmd.normal({'[c', bang = true})
              else
                gitsigns.nav_hunk('prev')
              end
            end)

            -- Actions
            map('n', '<leader>hs', gitsigns.stage_hunk)
            map('n', '<leader>hr', gitsigns.reset_hunk)

            map('v', '<leader>hs', function()
              gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end)

            map('v', '<leader>hr', function()
              gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end)

            map('n', '<leader>hS', gitsigns.stage_buffer)
            map('n', '<leader>hR', gitsigns.reset_buffer)
            map('n', '<leader>hp', gitsigns.preview_hunk)
            map('n', '<leader>hi', gitsigns.preview_hunk_inline)

            map('n', '<leader>hb', function()
              gitsigns.blame_line({ full = true })
            end)

            map('n', '<leader>hd', gitsigns.diffthis)

            map('n', '<leader>hD', function()
              gitsigns.diffthis('~')
            end)

            map('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
            map('n', '<leader>hq', gitsigns.setqflist)

            -- Toggles
            map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
            map('n', '<leader>tw', gitsigns.toggle_word_diff)

            -- Text object
            map({'o', 'x'}, 'ih', gitsigns.select_hunk)
          end,
          signs = {
            add          = { text = '┃' },
            change       = { text = '┃' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
          },
          signs_staged = {
            add          = { text = '┃' },
            change       = { text = '┃' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
          },
          signs_staged_enable = true,
          signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
          numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
          linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
          word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
          watch_gitdir = {
            follow_files = true
          },
          auto_attach = true,
          attach_to_untracked = false,
          current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
          current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = false,
            virt_text_priority = 100,
            use_focus = true,
          },
          current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
          sign_priority = 6,
          update_debounce = 100,
          status_formatter = nil, -- Use default
          max_file_length = 40000, -- Disable if file is longer than this (in lines)
          preview_config = {
            -- Options passed to nvim_open_win
            style = 'minimal',
            relative = 'cursor',
            row = 0,
            col = 1
          },
        }
      end,
    },
  },

  checker = { enabled = true },
})

-- Set colorscheme to TokyoNight Storm
vim.cmd([[colorscheme tokyonight-storm]])
