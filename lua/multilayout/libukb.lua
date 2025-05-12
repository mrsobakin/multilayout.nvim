local utils = require("multilayout.utils")


local LIBUKB_VERSION = "v0.0.1"


local set_langmap = vim.schedule_wrap(function(langmap)
    vim.opt.langmap = langmap
end)


local notify = vim.schedule_wrap(function(msg, level)
    utils.notify(msg, level)
end)


local function libukb_task(libukb_path, layout_tx_fd, control_tx_fd)
    local layout = vim.uv.new_pipe(false)
    layout:open(layout_tx_fd)

    local control = vim.uv.new_pipe(false)
    control:open(control_tx_fd)

    local ffi = require("ffi")
    local lib = ffi.load(libukb_path)

    ffi.cdef[[
        typedef void (*ukb_layout_cb_t)(const char*);
        typedef struct ukb_backend ukb_backend_t;

        const ukb_backend_t* ukb_find_available(void);

        const char* ukb_backend_name(const ukb_backend_t*);
        const char* ukb_backend_listen(const ukb_backend_t*, ukb_layout_cb_t);
    ]]

    ukb_backend = lib.ukb_find_available()

    if ukb_backend == nil then
        vim.uv.write(control, {"e", "ukb: No available backend was found"})
        layout:close()
        control:close()
        return
    end

    local cb = ffi.cast("ukb_layout_cb_t", function(value)
        vim.uv.write(layout, ffi.string(value))
    end)

    lib.ukb_backend_listen(ukb_backend, cb)
end


local current_layout = nil

local function run_layout_task(layout_rx_fd, layouts, default_langmap, callback)
    local layout = vim.uv.new_pipe(false)
    layout:open(layout_rx_fd)

    local name_to_id = function(name)
        for id, layout in pairs(layouts) do
            for _, layout_name in ipairs(layout.names) do
                if name == layout_name then
                    return id
                end
            end
        end

        return nil
    end

    vim.uv.read_start(layout, function(err, data)
        assert(not err, err)

        if data then
            local layout_id = name_to_id(data)
            current_layout = layout_id

            if layout_id then
                set_langmap(layouts[layout_id].langmap)
            else
                set_langmap(default_langmap)
            end
        else
            -- If layout pipe closes (i.e. libukb task has terminated), restore
            -- universal langmap to at least keep the default layout working.
            set_langmap(default_langmap)
            current_layout = nil
        end

        if callback then
            callback(current_layout)
        end
    end)
end


local function run_control_task(control_rx_fd)
    local control = vim.uv.new_pipe(false)
    control:open(control_rx_fd)

    vim.uv.read_start(control, function(err, data)
        assert(not err, err)

        if data then
            local type = string.sub(data, 1, 1)
            data = string.sub(data, 2)

            if type == "e" then
                notify(data, vim.log.levels.ERROR)
            elseif type == "w" then
                notify(data, vim.log.levels.WARN)
            end
        end
    end)
end



local M = {}


M.install_ukb = function()
    local data = vim.fn.stdpath("data") .. "/ukb"
    local ukbdir = data .. "/" .. LIBUKB_VERSION
    local libukb = ukbdir .. "/libukb.so"

    if vim.uv.fs_stat(libukb) then
        return libukb
    end

    -- Remove old versions if they exist
    pcall(vim.fs.rm, data, { recursive = true })

    utils.notify("No libukb found. Installing...", vim.log.levels.WARN)

    vim.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/mrsobakin/ukb",
        "--branch=" .. LIBUKB_VERSION,
        ukbdir,
    }):wait()

    utils.notify("Building libukb...", vim.log.levels.WARN)

    local result = vim.system({ "make" }, { cwd = ukbdir }):wait()

    if result.code ~= 0 then
        utils.notify("Something went wrong. Here's the `make` result:", vim.log.levels.ERROR)
        print(vim.inspect(result))
        return nil
    end

    return libukb
end


M.run = function(libukb_path, layouts, default_langmap, callback)
    local layout_pipe = utils.mkpipe()
    local control_pipe = utils.mkpipe()

    run_control_task(control_pipe.read)
    run_layout_task(layout_pipe.read, layouts, default_langmap, callback)
    vim.uv.new_thread(libukb_task, libukb_path, layout_pipe.write, control_pipe.write)
end


M.get_current_layout = function()
    return current_layout
end


return M
