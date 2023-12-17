local utils = require("multilayout.utils")
local ALL_COMMANDS = require("multilayout.allcommands").ALL_COMMANDS

local M = {}

local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
local ru = [[ёйцукенгшщзхъфывапролджэячсмитьËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]


local translate = {}

for orig, alias in utils.zip(utils.values(utils.split_multibyte(en)), utils.values(utils.split_multibyte(ru))) do
    translate[orig] = alias
end

function translatestring(str)
    local newstr = ""
    for char in utils.values(utils.split_multibyte(str)) do
        if translate[char] then
            newstr = newstr .. translate[char]
        else
            newstr = newstr .. char
        end
    end
    return newstr
end

function translatechar(char)
    if translate[char] then
        return translate[char]
    else
        return char
    end
end

M.setup = function(opts)
    for cmd in utils.values(ALL_COMMANDS) do
        local start, opt = cmd[1], cmd[2]

        local fullorig = start
        local fullalias = translatestring(fullorig)

        utils.abbrev_alias(fullalias, fullorig)

        for char in utils.values(utils.split_multibyte(opt)) do
            fullorig = fullorig .. char
            fullalias = fullalias .. translatechar(char)
            utils.abbrev_alias(fullalias, fullorig)
        end
    end
end

return M
