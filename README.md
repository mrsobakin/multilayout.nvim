# ⌨️  multilayout.nvim

Write your КуМир code blazingly fast!

## 🤔 What this plugin does?

This plugin aims to fix some common problems that occur for users with multiple keyboard layouts. It teaches vim to understand alternative layouts and automatically convert between them and the standard qwerty (or any other layout if you want!).

You won't need to think about switching layouts anymore: for example, if you write in Russian, you can type `сшц` and it will be automatically converted into `ciw`. This also works for commands! If you have built muscle memory for saving files via `:w`, you won't need to check which language you're typing in! Just write `:ц` and vim will understand what you mean.

## 🛠️ Installation & Configuration

Add the plugin using your preferred manager:

```lua
-- Minimal configuration for russian layout using lazy.nvim
require("lazy").setup({{ "mrsobakin/multilayout.nvim", opts = {
    layouts = {
        ru = "ru",
    },
    -- Enable if you want to have full multilayout.nvim functionality.
    use_libukb = false,
}}})
```

Default config and options description:

```lua
local config = {
    -- (unset by default)
    layouts = {
        -- Either table or string layout preset name (`ru`).
        ru = {
            -- Names of this layout, as `libukb` reports.
            names = { "Russian" },
            -- Character conversion table.
            -- You may specify only the differing characters.
            from  = [[ёйцукенгшщзхъфывапролджэячсмитьбю.Ё"№;:?ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,]],
            to    = [[`qwertyuiop[]asdfghjkl;'zxcvbnm,./~@#$^&QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?]],
        }
    },
    aliases = {
        -- Maximal length of default commands aliases.
        -- Increasing this value can lead to longer startup times.
        max_length = 2,
        -- Extra commands that you want to alias.
        -- They are aliased regardless of `max_length`.
        extra = { "sort" },
    },
    -- Whether to use `libukb`. If this is set to false, `langmap`
    -- won't automatically switch when your layout does.
    use_libukb = false,
    -- Path to the `libukb.so`. If `nil`, ukb will be automatically
    -- downloaded, builded and installed in the neovim data directory.
    libukb_path = nil,
    -- Function of type `callback(layout: string)`. Called whenever
    -- current keyboard layout changes.
    callback = nil,
}
```

If you want to use all **multilayout.nvim** features, you should enable `use_libukb`. To install it automatically, you must have `git`, `gcc` and `make` present on your system.

Currently, ukb suports only a small subset of platforms. You can see a full list of supported platforms [here](https://github.com/mrsobakin/ukb).

## 💡 FAQ

### ⚖️ How does this plugin differ from the [**langmapper.nvim**](https://github.com/Wansmer/langmapper.nvim)?

**multilayout.nvim** is different from **langmapper.nvim** in almost every way! In fact, these plugins functionality does not intersect at all — quite the opposite, they complement each other.

While langmapper primarily focuses on translating mappings, multilayout translates motions and commands. In other words, while langmapper fixes your fzf's `<leader>ff`, multilayout fixes your `ciw`, `gcc` and `:w`'s.

I highly recommend you to check out langmapper if you want to have the complete `shift-alt`-less experience.

### 🤓☝️ How does this plugin work?

For converting motions, this plugin utilizes builtin vim functionality — `langmap`. In fact, this is why most of the motions work with **langmapper.nvim**: it's default config recommends you to configure the `langmap`. So, you can make most of the motions work even without plugins.

But **multilayout.nvim** does a bit more than that! First of all, it automatically generates the `langmap` for you. And second — this is where all the magic starts — it is able to switch the `langmap` depending on your current layout. Some characters are present on both layouts, but placed in different physical locations, which makes it impossible to use a single `langmap` for all layouts. **multilayout.nvim** solves that problem using [**ukb**](https://github.com/mrsobakin/ukb) — a universal keyboard utility. The coolest part is that it does not spawn any additional processes — libukb is loaded directly via LuaJIT's ffi.

Commands are translated using `cabbrev` aliases. You can read about them below in the special thanks section.

## 🔗 Special thanks to:
- [This](https://vim.fandom.com/wiki/Replace_a_builtin_command_using_cabbrev) ancient article about cabbrev 
- **langmapper.nvim**, for the non-ascii character splitting function[*](https://github.com/Wansmer/langmapper.nvim/blob/main/lua/langmapper/helpers.lua)
- Dudes developing NeoVim for the awesome NeoVim API documentation
