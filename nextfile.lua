local mp = require('mp')
local utils = require('mp.utils')
local msg = require('mp.msg')
local settings = {
    filetypes = {
        'jpg', 'jpeg', 'png', 'tif', 'tiff', 'gif', 'webp', 'svg', 'bmp',
        'mp3', 'wav', 'ogm', 'flac', 'm4a', 'wma', 'ogg', 'opus',
        'mkv', 'avi', 'mp4', 'ogv', 'webm', 'rmvb', 'flv', 'wmv', 'mpeg', 'mpg', 'm4v', '3gp'
    },

    --at end of directory jump to start and vice versa
    allow_looping = true,

    --order by natural (version) numbers, thus behaving case-insensitively and treating multi-digit numbers atomically
    --e.x.: true will result in the following order:   09A 9A  09a 9a  10A 10a
    --      while false will result in:                09a 09A 10a 10A 9a  9A
    version_flag = true,
}

local filetype_lookup = {}
for _, ext in ipairs(settings.filetypes) do
    filetype_lookup[ext] = true
end

local function show_osd_message(file)
    mp.osd_message("Now playing: " .. file, 3)  -- Adjust OSD display time as needed
end

local function filter_media(files)
    --- Filter out files with unwanted extensions.
    local valid_files = {}
    for _, file in ipairs(files) do
        local ext = file:match("^.+%.(.+)$")
        if ext and filetype_lookup[ext:lower()] then
            table.insert(valid_files, file)
        end
    end
    return valid_files
end

local function movetofile(forward)
    if mp.get_property('filename'):match("^%a%a+:%/%/") then
        return
    end
    local pwd = mp.get_property('working-directory')
    local relpath = mp.get_property('path')
    if not pwd or not relpath then
        return
    end

    local path = utils.join_path(pwd, relpath)
    local filename = mp.get_property("filename")
    local dir = utils.split_path(path)
    local files = utils.readdir(dir, "files")
    table.sort(files)

    local found = false
    local memory = nil
    local lastfile = true
    local firstfile = nil

    for _, file in ipairs(filter_media(files)) do
        if found == true then
            mp.commandv("loadfile", utils.join_path(dir, file), "replace")
            lastfile = false
            show_osd_message(file)
            break
        end
        if file == filename then
            found = true
            if not forward then
                lastfile = false
                if settings.allow_looping and firstfile == nil then
                    found = false
                else
                    if firstfile == nil then
                        break
                    end
                    mp.commandv("loadfile", utils.join_path(dir, memory), "replace")
                    show_osd_message(memory)
                    break
                end
            end
        end
        memory = file
        if firstfile == nil then
            firstfile = file
        end
    end
    if lastfile and firstfile and settings.allow_looping then
        mp.commandv("loadfile", utils.join_path(dir, firstfile), "replace")
        show_osd_message(firstfile)
    end
    if not found and memory then
        mp.commandv("loadfile", utils.join_path(dir, memory), "replace")
        show_osd_message(memory)
    end
end

local function nexthandler()
    movetofile(true)
end

local function prevhandler()
    movetofile(false)
end

mp.add_key_binding('Alt+LEFT', 'ajt__previous_file', prevhandler)
mp.add_key_binding('Alt+RIGHT', 'ajt__next_file', nexthandler)

