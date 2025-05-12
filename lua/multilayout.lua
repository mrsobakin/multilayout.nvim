local aliases = require("multilayout.aliases")
local langmap = require("multilayout.langmap")


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


local M = {}


M.setup = function(config)
    config = config_with_defaults(config)

    -- Compute additional fields for config
    if not langmap.prepare_config(config) then
        return
    end

    local from, to = nil, nil
    for _, layout in pairs(config.layouts) do
        from, to = layout.from, layout.to
    end

    aliases.setup(from, to, config.aliases.max_length, config.aliases.extra)
    langmap.setup(config)
end


M.get_current_layout = function()
    return langmap.get_current_layout()
end


return M
