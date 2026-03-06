local LoaderEnv = (type(getgenv) == "function" and getgenv()) or _G
local LoaderConfig = type(LoaderEnv.WALLY_MODIFIED_LOADER) == "table" and LoaderEnv.WALLY_MODIFIED_LOADER or {}

local PartPaths = type(LoaderConfig.PartPaths) == "table" and LoaderConfig.PartPaths or {
    "wally-modified-parts/part1.lua",
    "wally-modified-parts/part2.lua",
    "wally-modified-parts/part3.lua",
    "wally-modified-parts/part4.lua"
}

local RemoteBaseUrl = LoaderConfig.RemoteBaseUrl
if type(RemoteBaseUrl) ~= "string" or RemoteBaseUrl == "" then
    RemoteBaseUrl = "https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified-parts/"
end
if string.sub(RemoteBaseUrl, -1) ~= "/" then
    RemoteBaseUrl = RemoteBaseUrl .. "/"
end

local function ReadLocal(Path)
    if type(readfile) ~= "function" then
        return nil
    end

    local Ok, Source = pcall(readfile, Path)
    if Ok and type(Source) == "string" and Source ~= "" then
        return Source
    end

    return nil
end

local function ReadRemote(Path)
    if type(game) ~= "userdata" and type(game) ~= "table" then
        return nil
    end

    local FileName = Path:match("[^/]+$") or Path
    local Url = RemoteBaseUrl .. FileName

    local Ok, Source = pcall(function()
        return game:HttpGet(Url)
    end)
    if Ok and type(Source) == "string" and Source ~= "" then
        return Source
    end

    return nil
end

local Chunks = {}
for _, Path in ipairs(PartPaths) do
    local Source = ReadLocal(Path)
    if not Source then
        Source = ReadRemote(Path)
    end

    assert(type(Source) == "string", string.format("[Wally Modified Loader] Failed to load source part: %s", tostring(Path)))
    Chunks[#Chunks + 1] = Source
end

local MergedSource = table.concat(Chunks, "\n")
local Compile = loadstring or load
assert(type(Compile) == "function", "[Wally Modified Loader] loadstring/load is unavailable")

local Chunk, CompileError = Compile(MergedSource)
assert(Chunk, string.format("[Wally Modified Loader] Compile failed: %s", tostring(CompileError)))

return Chunk()
