local commands = require("multilayout.static.commands")
local utils = require("multilayout.utils")


local function make_translate_map(from, to)
    local translate = {}

    for orig, alias in utils.zip(utils.iter_multibyte(from), utils.iter_multibyte(to)) do
        translate[orig] = alias
    end

    return translate
end


local function translate_string(translate, str)
    local newstr = ""
    for char in utils.iter_multibyte(str) do
        if translate[char] then
            newstr = newstr .. translate[char]
        else
            newstr = newstr .. char
        end
    end
    return newstr
end


local function translate_char(translate, char)
    if translate[char] then
        return translate[char]
    else
        return char
    end
end


local M = {}


M.setup = function(from, to, max_len, extras)
    local map = make_translate_map(to, from)

    if extras then
        for _, extra in ipairs(extras) do
            utils.abbrev_alias(translate_string(map, extra), extra)
        end
    end

    for cmd in utils.values(commands) do
        local start, opt = cmd[1], cmd[2]
        local len = #start

        if len > max_len then
            goto skip
        end

        local orig = start
        local alias = translate_string(map, orig)
        utils.abbrev_alias(alias, orig)

        for char in utils.iter_multibyte(opt) do
            len = len + 1

            if len > max_len then
                break
            end

            orig = orig .. char
            alias = alias .. translate_char(map, char)

            utils.abbrev_alias(alias, orig)
        end

        ::skip::
    end
end


return M
