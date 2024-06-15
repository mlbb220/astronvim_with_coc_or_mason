local is_available = require("astrocore").is_available

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@param opts AstroCoreOpts
    opts = function(_, opts)
      if not opts.mappings then opts.mappings = require("astrocore").empty_map_table() end
      local maps = opts.mappings
      if maps then
        -- telescope plugin mappings
        if is_available "telescope.nvim" then
          maps.v["<Leader>f"] = { desc = "󰍉 Find" }
          maps.n["<Leader>fT"] = { "<cmd>TodoTelescope<cr>", desc = "Find TODOs" }
          -- buffer switching
          maps.n["<Leader>bt"] = {
            function()
              if #vim.t.bufs > 1 then
                require("telescope.builtin").buffers { sort_mru = true, ignore_current_buffer = true }
              else
                require("astrocore").notify "No other buffers open"
              end
            end,
            desc = "Switch Buffers In Telescope",
          }
          maps.n["<Leader>o"] =
            { "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>", desc = "Open File browser in cwd path" }
          maps.n["<Leader>e"] = { "<Cmd>Telescope file_browser<CR>", desc = "Open File browser in current path" }
        end
      end
      opts.mappings = maps
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/popup.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    opts = function(_, opts)
      local actions = require "telescope.actions"
      local fb_actions = require "telescope._extensions.file_browser.actions"
      local os_sep = require("plenary.Path").sep
      local action_state = require "telescope.actions.state"

      return require("astrocore").extend_tbl(opts, {
        pickers = {
          find_files = {
            -- dot file
            hidden = true,
          },
          buffers = {
            path_display = { "smart" },
            mappings = {
              i = { ["<C-d>"] = actions.delete_buffer },
              n = { ["d"] = actions.delete_buffer },
            },
          },
        },
        extensions = {
          file_browser = {
            on_input_filter_cb = function(prompt)
              if prompt:sub(-1, -1) == os_sep then
                local prompt_bufnr = vim.api.nvim_get_current_buf()
                if vim.bo[prompt_bufnr].filetype == "TelescopePrompt" then
                  local current_picker = action_state.get_current_picker(prompt_bufnr)
                  if current_picker.finder.files then
                    fb_actions.toggle_browser(prompt_bufnr, { reset_prompt = true })
                    current_picker:set_prompt(prompt:sub(1, -2))
                  end
                end
              end
            end,
            hijack_netrw = true,
            initial_mode = "insert",
            quiet = true,
            git_status = false,
            mappings = {
              i = {
                ["<C-g>"] = false,
                ["<C-.>"] = fb_actions.toggle_hidden,
                ["<C-h>"] = fb_actions.backspace,
                ["<C-l>"] = actions.select_default,
              },
              n = {
                ["g"] = false,
                ["."] = fb_actions.toggle_hidden,
                ["h"] = fb_actions.backspace,
                ["l"] = actions.select_default,
              },
            },
          },
        },
      })
    end,
    config = function(...)
      local telescope = require "telescope"
      require "astronvim.plugins.configs.telescope"(...)
      -- telescope.load_extension "goctl"
      telescope.load_extension "file_browser"
    end,
  },
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      highlights = {
        -- set highlights for all themes
        -- use a function override to let us use lua to retrieve
        -- colors from highlight group there is no default table
        -- so we don't need to put a parameter for this function
        init = function()
          local get_hlgroup = require("astroui").get_hlgroup
          -- get highlights from highlight groups
          local normal = get_hlgroup "Normal"
          local fg, bg = normal.fg, normal.bg
          local bg_alt = get_hlgroup("Visual").bg
          local green = get_hlgroup("String").fg
          local red = get_hlgroup("Error").fg
          -- return a table of highlights for telescope based on
          -- colors gotten from highlight groups
          return {
            TelescopeBorder = { fg = bg_alt, bg = bg },
            TelescopeNormal = { bg = bg },
            TelescopePreviewBorder = { fg = bg, bg = bg },
            TelescopePreviewNormal = { bg = bg },
            TelescopePreviewTitle = { fg = bg, bg = green },
            TelescopePromptBorder = { fg = bg_alt, bg = bg_alt },
            TelescopePromptNormal = { fg = fg, bg = bg_alt },
            TelescopePromptPrefix = { fg = red, bg = bg_alt },
            TelescopePromptTitle = { fg = bg, bg = red },
            TelescopeResultsBorder = { fg = bg, bg = bg },
            TelescopeResultsNormal = { bg = bg },
            TelescopeResultsTitle = { fg = bg, bg = bg },
          }
        end,
      },
    },
  },
}
