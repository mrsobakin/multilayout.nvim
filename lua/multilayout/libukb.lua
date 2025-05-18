local utils = require("multilayout.utils")


local UKB_REPO = "https://github.com/mrsobakin/ukb"
local UKB_VERSION = "v0.2.1"


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


local function get_platform_info()
    local system = jit.os:lower()
    local arch = jit.arch

    if arch == "x64" then
        arch = "x86_64"
    end

    local name = system .. "-" .. arch

    return {
        name = name,
        system = system,
        arch = arch,
        suffix = ({
            linux   = ".so",
            windows = ".dll",
        })[system],
        supported = ({
            ["windows-x86_64"] = true,
            ["linux-x86_64"]   = true,
        })[name] or false,
    }
end


local function try_run(step, cmd)
    local res = vim.system(cmd):wait()
    if res.code ~= 0 then
        error(step .. " failed: " .. (res.stderr or "unknown error"))
    end
end


local M = {}


M.check_ffi = function()
    return (jit ~= nil) and pcall(require, "ffi")
end


M.install_ukb = function()
    local info = get_platform_info()

    if not info.supported then
        utils.notify("ukb is not supported on your platform (" .. info.name .. ")", vim.log.levels.ERROR)
        return nil
    end

    local data = vim.fn.stdpath("data") .. "/ukb"
    local libukb = data .. "/libukb-" .. UKB_VERSION .. "-" .. info.name .. info.suffix

    -- If ukb is present and is up to date, return it.
    if vim.uv.fs_stat(libukb) then
        return libukb
    end

    utils.notify("ukb not found. Installing...", vim.log.levels.WARN)

    -- Remove old versions if they exist
    pcall(vim.fs.rm, data, { recursive = true })
    vim.uv.fs_mkdir(data, tonumber('755', 8))

    local artifact_suffix = (info.system == "windows") and ".zip" or ".tar.gz"
    local artifact_name = "ukb-" .. UKB_VERSION .. "-" .. info.name .. artifact_suffix
    local artifact_url = UKB_REPO .. "/releases/download/" .. UKB_VERSION .. "/" .. artifact_name

    local tempdir = vim.uv.fs_mkdtemp(data .. "/tmp.XXXXXX")
    local ukb_archive = tempdir .. "/ukb" .. artifact_suffix

    local ok, logs = pcall(function()
        if info.system == "windows" then
            try_run("Download", {
                "powershell", "-c", "Invoke-WebRequest",
                "-Uri", artifact_url,
                "-OutFile", ukb_archive
            })

            try_run("Extraction", {
                "powershell", "-c", "Expand-Archive",
                "-LiteralPath", ukb_archive,
                "-DestinationPath", tempdir,
            })

            try_run("Rename", {
                "powershell", "-c", "move",
                tempdir .. "/lib/libukb" .. info.suffix,
                libukb
            })
        else
            try_run("Download", {
                "wget", artifact_url,
                "-O", ukb_archive,
            })

            try_run("Extraction", {
                "tar", "xf", ukb_archive,
                "-C", tempdir,
                "lib/libukb" .. info.suffix,
            })

            try_run("Rename", {
                "mv",
                tempdir .. "/lib/libukb" .. info.suffix,
                libukb
            })
        end
    end)

    pcall(vim.fs.rm, tempdir, { recursive = true })

    if not ok then
        utils.notify("ukb was not installed. Logs:\n" .. logs, vim.log.levels.ERROR)
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
