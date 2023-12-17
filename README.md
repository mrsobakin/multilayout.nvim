# ⌨️  multilayout.nvim

Less headache for NeoVim users with multiple keyboard layouts.

Write your КуМир code blazingly fast!

### 🤔 What's this plugin about?

This plugin allows multi-layout users to execute vim commands without changing the current keyboard layout. For example, `:ц` command automatically becomes `:w`, for users of russian layout. This plugin supports all builtin vim commands and all keyboard layouts, as the character conversion maps can be set by user.

### 🚀 Features

- **Flexible Layouts:** Supports all built-in commands and lets you create custom character conversion tables.
- **Unified experience:** Enter commands without thinking about keyboard layouts.
- **Boosted Productivity:** Enormous speed up in text writing (you don't have to switch layouts anymore. Over a year, this saves you a whole 10 minutes in pressing keys)

### 🛠️ Installation

Add the plugin using your preferred manager:

```lua
-- Using lazy.nvim
require("lazy").setup({
    { "mrsobakin/multilayout.nvim", config = {} }
})
```

### 📝 Usage

1. Define your character conversion table in your Neovim config:

    ```lua
    -- Example configuration in Lua
    require('multilayout').setup({})
    ```

2. Start enjoying your `Shift+Alt`-less* experience. 

    <sub>* The plugin works if you use BASED (😎) key bindings (like Shift+Shift) too.<sub>

### 🔗 Special thanks to:
- [This](https://vim.fandom.com/wiki/Replace_a_builtin_command_using_cabbrev) ancient article about cabbrev 
- `langmapper.nvim`, for the non-ascii character splitting function[*](https://github.com/Wansmer/langmapper.nvim/blob/main/lua/langmapper/helpers.lua)
- Dudes developing NeoVim for the awesome NeoVim API documentation
