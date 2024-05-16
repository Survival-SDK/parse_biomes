#!/usr/bin/env lua

-- local profiler = require "ELProfiler"

local filename = arg[1]

if not filename then
    print("Usage:\n./split_biomes.lua <filename>")
    return 1
end

local in_file = io.open(filename, "rb")
if not in_file then
    print("Unable to open input file")
    return 1
end

os.execute("rm -f " .. filename .. ".splitted/*")
os.execute("mkdir -p " .. filename .. ".splitted")

local function split(inputstr)
    local first_comma_index = string.find(inputstr, ",")
    local second_comma_index = string.find(inputstr, ",", first_comma_index + 1)

    return string.sub(inputstr, 1, first_comma_index - 1),
     string.sub(inputstr, first_comma_index + 1, second_comma_index - 1)
end

local function process_line(out_ctx, line)
    local tok_lon, tok_lat = split(line)
    local lon = math.floor(tonumber(tok_lon))
    local lat = math.floor(tonumber(tok_lat))
    local file_index = lon .. lat

    if not out_ctx.files[file_index] then
        local filename = out_ctx.filename_prefix .. ".splitted/" .. lon .. "_" .. lat
        out_ctx.files[file_index] = io.open(filename, "a")
        if not out_ctx.files[file_index] then
            print("Unable to open output file \"" .. filename .. "\"")
            return false
        end
    end

    out_ctx.files[file_index]:write(line .. "\n")

    return true
end

local out_ctx = {
    filename_prefix = filename,
    files = {},
}

while true do
    local in_content = in_file:read("*l")
    if not in_content then
        break
    end

    if not process_line(out_ctx, in_content) then
        break
    end
end

for _, out_file in pairs(out_ctx.files) do
    out_file:close()
end

in_file:close()
