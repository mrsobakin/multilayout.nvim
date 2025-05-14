local aliases = require("multilayout.aliases")
local langmap = require("multilayout.langmap")
local layout_presets = require("multilayout.static.layouts")
local libukb = require("multilayout.libukb")
local utils = require("multilayout.utils")


local function config_with_defaults(config)
    local default_config = {
        aliases = {
            max_length = 2,
            extra = { "sort" },
        },
        use_libukb = false,
        libukb_path = nil,
        callback = nil,
    }

    for k, v in pairs(config) do
        default_config[k] = v
    end

    return default_config
end


-- Validates config and precompute additional fields for it.
local function process_config(config)
    config = config_with_defaults(config)

    local n_layouts = 0

    if config.layouts then
        for _ in pairs(config.layouts) do n_layouts = n_layouts + 1 end
    end

    if n_layouts == 0 then
        utils.notify("No layouts are provided.", vim.log.levels.ERROR)
        return nil
    end

    if n_layouts > 1 then
        utils.notify("Currently, maximum supported number of layouts is 1", vim.log.levels.ERROR)
        return nil
    end

    local default_langmap = nil

    for id, layout in pairs(config.layouts) do
        if type(layout) == "string" then
            local layout_preset = layout_presets[layout]

            if layout_preset == nil then
                utils.notify("Unknown layout preset: " .. layout, vim.log.levels.ERROR)
                return false
            end

            layout = layout_preset
            config.layouts[id] = layout_preset
        end

        -- TODO: for multiple layouts, default_langmap should be calculated diffrerently!!!
        default_langmap = langmap.make_unique(layout.from, layout.to)
        layout.langmap = langmap.make(layout.from, layout.to)
    end

    config.default_langmap = default_langmap

    return config
end


local M = {}


M.setup = function(config)
    local ctx = process_config(config)

    if not ctx then
        return
    end

    -- Auto-install ukb
    if ctx.use_libukb and (ctx.libukb_path == nil) then
        ctx.libukb_path = libukb.install_ukb()

        if ctx.libukb_path == nil then
            ctx.use_libukb = false
        end
    end

    -- TODO: different for multiple layouts.
    local from, to = nil, nil
    for _, layout in pairs(ctx.layouts) do
        from, to = layout.from, layout.to
        aliases.setup(from, to, ctx.aliases.max_length, ctx.aliases.extra)
    end

    -- Set universal langmap that is valid regardless of current layout
    vim.opt.langmap = ctx.default_langmap

    -- If ukb is enabled, run ukb daemon.
    if ctx.use_libukb then
        libukb.run(ctx.libukb_path, ctx.layouts, ctx.default_langmap, ctx.callback)
    end
end


M.get_current_layout = function()
    return libukb.get_current_layout()
end


return M
