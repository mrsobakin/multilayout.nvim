local utils = require("multilayout.utils")
local libukb = require("multilayout.libukb")


local function langmap_escape(str)
    local escape_chars = [[;,."|\]]
    return vim.fn.escape(str, escape_chars)
end


local function make_langmap(from, to)
    return langmap_escape(from) .. ';' .. langmap_escape(to)
end


-- Given layout translation map, computes a submap, such that it unambigously
-- translates keys even if the current keyboard layout is not known.
--
-- I.e, translation function domain and codomain do not intersect.
local function make_unique_keymap(from, to)
    local counter = {}

    from = utils.split_multibyte(from)
    to = utils.split_multibyte(to)

    for i = 1, #from do
        local f = from[i]
        local t = to[i]

        counter[f] = (counter[f] or 0) + 1
        counter[t] = (counter[t] or 0) + 1
    end

    local unique_from = ""
    local unique_to = ""

    for i = 1, #from do
        local f = from[i]
        local t = to[i]

        if counter[f] == 1 then
            unique_from = unique_from .. f
            unique_to = unique_to .. t
        end
    end

    return {unique_from, unique_to}
end


local M = {}


M.prepare_config = function(config)
    local n_layouts = 0

    if config.layouts then
        for _ in pairs(config.layouts) do n_layouts = n_layouts + 1 end
    end

    if n_layouts == 0 then
        utils.notify("No layouts are provided.", vim.log.levels.ERROR)
        return false
    end

    if n_layouts > 1 then
        utils.notify("Currently, maximum supported number of layouts is 1", vim.log.levels.ERROR)
        return false
    end

    local default_langmap = nil

    for _, layout in pairs(config.layouts) do
        -- TODO: for multiple layouts, default_langmap should be calculated diffrerently!!!
        default_langmap = make_langmap(unpack(make_unique_keymap(layout.from, layout.to)))
        layout.langmap = make_langmap(layout.from, layout.to)
    end

    config.default_langmap = default_langmap

    return true
end


M.setup = function(config)
    if config.use_libukb and (config.libukb_path == nil) then
        config.libukb_path = libukb.install_ukb()

        if config.libukb_path == nil then
            config.use_libukb = false
        end
    end

    vim.opt.langmap = config.default_langmap

    if not config.use_libukb then
        return
    end

    libukb.run(config.libukb_path, config.layouts, config.default_langmap, config.callback)
end


M.get_current_layout = function()
    libukb.get_current_layout()
end


return M
