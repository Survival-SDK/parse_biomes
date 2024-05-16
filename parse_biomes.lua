#!/usr/bin/env lua

local lunajson = require "lunajson"
-- local profiler = require "ELProfiler"

local parallel_degree_kilometers = {
    [0] = 111,
    [1] = 111,
    [2] = 111,
    [3] = 111,
    [4] = 111,
    [5] = 110,
    [6] = 110,
    [7] = 110,
    [8] = 110,
    [9] = 109,
    [10] = 109,
    [11] = 109,
    [12] = 108,
    [13] = 108,
    [14] = 108,
    [15] = 107,
    [16] = 107,
    [17] = 106,
    [18] = 105,
    [19] = 105,
    [20] = 104,
    [21] = 103,
    [22] = 103,
    [23] = 102,
    [24] = 101,
    [25] = 100,
    [26] = 100,
    [27] = 99,
    [28] = 98,
    [29] = 97,
    [30] = 96,
    [31] = 95,
    [32] = 94,
    [33] = 93,
    [34] = 92,
    [35] = 91,
    [36] = 90,
    [37] = 89,
    [38] = 87,
    [39] = 86,
    [40] = 85,
    [41] = 84,
    [42] = 82,
    [43] = 81,
    [44] = 80,
    [45] = 78,
    [46] = 77,
    [47] = 76,
    [48] = 74,
    [49] = 73,
    [50] = 71,
    [51] = 70,
    [52] = 68,
    [53] = 67,
    [54] = 65,
    [55] = 63,
    [56] = 62,
    [57] = 60,
    [58] = 59,
    [59] = 57,
    [60] = 55,
    [61] = 54,
    [62] = 52,
    [63] = 50,
    [64] = 48,
    [65] = 47,
    [66] = 45,
    [67] = 43,
    [68] = 41,
    [69] = 40,
    [70] = 38,
    [71] = 36,
    [72] = 34,
    [73] = 32,
    [74] = 30,
    [75] = 28,
    [76] = 27,
    [77] = 25,
    [78] = 23,
    [79] = 21,
    [80] = 19,
    [81] = 17,
    [82] = 15,
    [83] = 13,
    [84] = 11,
    [85] = 9,
    [86] = 7,
    [87] = 5,
    [88] = 3,
    [89] = 1,
    [90] = 0,
}

local meridian_degree_kilometers = 111
local quadkm_side = 50

local function geocoord_to_chunk(lon, lat)
    local lon_floor, lon_frac = math.modf(lon)
    local lat_floor, lat_frac = math.modf(lat)
    local result = {
        lon = lon_floor,
        lat = lat_floor,
    }
    local parallel_len = parallel_degree_kilometers[math.abs(lat_floor)]

    result.col = math.floor(lon_frac * parallel_len) + 1
    result.row = math.floor(lat_frac * meridian_degree_kilometers) + 1
    result.ccl = math.floor(lon_frac * parallel_len * quadkm_side - result.col * quadkm_side) + 1
    result.crw = math.floor(lat_frac * meridian_degree_kilometers * quadkm_side - result.row * quadkm_side) + 1

    if result.col <= 0 then
        result.col = result.col + parallel_len + 1
    end
    if result.row <= 0 then
        result.row = result.row + meridian_degree_kilometers + 1
    end
    if result.ccl <= 0 then
        result.ccl = result.ccl + quadkm_side + 1
    end
    if result.crw <= 0 then
        result.crw = result.crw + quadkm_side + 1
    end

    return result
end

local filename = arg[1]

if not filename then
    print("Usage:\n./parse_biomes.lua <filename>")
    return 1
end

local in_file = io.open(filename, "rb")
if not in_file then
    print("Unable to open input file")
    return 1
end

os.execute("rm -f " .. filename .. ".processed/*")
os.execute("mkdir -p " .. filename .. ".processed")

local function split(inputstr)
    local first_comma_index = string.find(inputstr, ",")
    local second_comma_index = string.find(inputstr, ",", first_comma_index + 1)

    return tonumber(string.sub(inputstr, 1, first_comma_index - 1)),
     tonumber(string.sub(inputstr, first_comma_index + 1, second_comma_index - 1)),
     tonumber(string.sub(inputstr, second_comma_index + 1, -1))
end

local function process_line(out_ctx, line)
    local lon, lat, value = split(line)
    local chunk = geocoord_to_chunk(lon, lat)
    local lon_lat_col_row = chunk.lon .. "_" .. chunk.lat .. "_" .. chunk.col .. "_" .. chunk.row

    if not out_ctx[lon_lat_col_row] then
        out_ctx[lon_lat_col_row] = {}
    end
    if not out_ctx[lon_lat_col_row][chunk.ccl] then
        out_ctx[lon_lat_col_row][chunk.ccl] = {}
    end
    out_ctx[lon_lat_col_row][chunk.ccl][chunk.crw] = value

    return true
end

local out_ctx = {}

while true do
    local in_content = in_file:read("*l")

    if not in_content then
        break
    end

    if not process_line(out_ctx, in_content) then
        break
    end
end

local function fill_holes_in_rows(quadkm)
    for ccl = 1, quadkm_side, 1 do
        if not quadkm[ccl] then
            goto continue
        end

        for crw = 1, quadkm_side, 1 do
            if not quadkm[ccl][crw] then
                if crw == 1 then
                    quadkm[ccl][crw] = quadkm[ccl][crw + 1]
                else
                    quadkm[ccl][crw] = quadkm[ccl][crw - 1]
                end
            end
        end

        ::continue::
    end
end

local function fill_holes_in_columns(quadkm)
    for ccl = 1, quadkm_side, 1 do
        if not quadkm[ccl] then
            if ccl == 1 then

                quadkm[ccl] = quadkm[ccl + 1] and quadkm[ccl + 1] or quadkm[ccl + 2]
            else
                quadkm[ccl] = quadkm[ccl - 1]
            end
        end
    end
end

local function export(lon_lat_col_row, quadkm)
    local struct = { biomes = {} }

    for ccl = 1, quadkm_side, 1 do
        for crw = 1, quadkm_side, 1 do
            local col = quadkm[ccl]
            if not col then
                print(ccl, quadkm[ccl])
                print(ccl + 1, quadkm[ccl + 1])
                print(ccl + 2, quadkm[ccl + 2])
            end
            local value = col[crw]
            table.insert(struct.biomes, value)
        end
    end

    local json = lunajson.encode(struct)
    local out_filename = filename .. ".processed/" .. lon_lat_col_row .. ".json"
    local out_file = io.open(out_filename, "wb")
    if not out_file then
        print("Unable to open output file \"" .. out_filename .. "\"")
        return false
    end

    out_file:write(json)
    out_file:close()

    return true
end

for lon_lat_col_row, quadkm in pairs(out_ctx) do
    fill_holes_in_rows(quadkm)
    fill_holes_in_columns(quadkm)
    if not export(lon_lat_col_row, quadkm) then
        break
    end
end

in_file:close()
