local M = {}

M.zip = function(it1, it2)
    return function()
        local a, b = it1(), it2()
        if a and b then
            return a, b
        end
    end
end

M.values = function(t)
    local i = 0
    return function()
        i = i + 1;
        return t[i]
    end
end

M.abbrev_alias = function(alias, original)
    vim.cmd.cabbrev({ alias, "<c-r>=((getcmdtype()==':' && getcmdpos()==1) ? '" .. original .. "' : '" .. alias .. "')<CR>" })
end

M.split_multibyte = function(str)
    -- From: https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/4
    -- ...And from: https://github.com/Wansmer/langmapper.nvim/blob/main/lua/langmapper/helpers.lua
    local function char_byte_count(s, i)
        local char = string.byte(s, i or 1)

        -- Get byte count of unicode character (RFC 3629)
        if char > 0 and char <= 127 then
            return 1
        elseif char >= 194 and char <= 223 then
            return 2
        elseif char >= 224 and char <= 239 then
            return 3
        elseif char >= 240 and char <= 244 then
            return 4
        end
    end

    local symbols = {}
    for i = 1, vim.fn.strlen(str), 1 do
        local len = char_byte_count(str, i)
        if len then
            table.insert(symbols, str:sub(i, i + len - 1))
        end
    end

    return symbols
end

return M
