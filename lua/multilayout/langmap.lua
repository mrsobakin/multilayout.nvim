local utils = require("multilayout.utils")


local M = {}


M.escape = function(str)
    local escape_chars = [[;,."|\]]
    return vim.fn.escape(str, escape_chars)
end


M.make = function(from, to)
    return M.escape(from) .. ';' .. M.escape(to)
end


-- Given layout translation map, computes a submap, such that it unambigously
-- translates keys even if the current keyboard layout is not known.
--
-- I.e, translation function domain and codomain do not intersect.
M.make_unique_map = function(from, to)
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


M.make_unique = function(from, to)
    return M.make(unpack(M.make_unique_map(from, to)))
end


return M
