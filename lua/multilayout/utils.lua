local M = {}


M.notify = function(msg, level)
    vim.notify("multilayout.nvim: " .. msg, level)
end


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


-- Using the forbidden knowledge of ancients: https://vim.fandom.com/wiki/Replace_a_builtin_command_using_cabbrev
M.abbrev_alias = function(alias, original)
    vim.cmd.cabbrev({ alias, "<c-r>=((getcmdtype()==':' && getcmdpos()==1) ? '" .. original .. "' : '" .. alias .. "')<CR>" })
end


M.mkpipe = function()
    local pipe = vim.uv.pipe({ nonblock = true }, { nonblock = true })
    assert(pipe, "failed to open pipe")
    return pipe
end


-- From: https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/4
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


-- ...And kinda from: https://github.com/Wansmer/langmapper.nvim/blob/main/lua/langmapper/helpers.lua
M.split_multibyte = function(str)
    local symbols = {}

    local i = 1
    local to = #str

    while i <= to do
        local len = char_byte_count(str, i)

        if not len then
            return symbols
        end

        table.insert(symbols, str:sub(i, i + len - 1))
        i = i + len
    end

    return symbols
end


M.iter_multibyte = function(str)
    local i = 1
    local to = #str

    return function()
        if i > to then
            return
        end

        local len = char_byte_count(str, i)

        if not len then
            return
        end

        local char = str:sub(i, i + len - 1)

        i = i + len

        return char
    end
end


return M
