-- Wally Modified: Full Control Showcase
-- This demonstrates every control currently addable via a window.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified.lua"))()

local Flags = {}

local window = Library:CreateWindow("Wally Modified Showcase", {
    underlinecolor = "rainbow", -- supports "rainbow" or Color3
    topcolor = Color3.fromRGB(30, 30, 30),
    bgcolor = Color3.fromRGB(35, 35, 35),
    btncolor = Color3.fromRGB(25, 25, 25),
    dropcolor = Color3.fromRGB(25, 25, 25),
    bordercolor = Color3.fromRGB(60, 60, 60),
    textcolor = Color3.fromRGB(255, 255, 255),
})

-- Controls are added directly to the window object.
local function DumpTable(Table)
    local Output = {}
    for Key, Value in next, Table do
        Output[#Output + 1] = tostring(Key) .. "=" .. tostring(Value)
    end
    table.sort(Output)
    return table.concat(Output, ", ")
end

local function ColorToRGB(ColorValue)
    return string.format(
        "%d, %d, %d",
        math.floor(ColorValue.R * 255 + 0.5),
        math.floor(ColorValue.G * 255 + 0.5),
        math.floor(ColorValue.B * 255 + 0.5)
    )
end

---------------------------------------------------------------------
-- 1) Section
---------------------------------------------------------------------
window:Section("Actions")

---------------------------------------------------------------------
-- 2) Label
---------------------------------------------------------------------
local StatusLabel = window:Label("Status: Idle", {
    textSize = 18,
    textColor = Color3.fromRGB(255, 255, 255),
    bgColor = Color3.fromRGB(40, 40, 40),
})

---------------------------------------------------------------------
-- 3) Button
---------------------------------------------------------------------
window:Button("Print Hello", function()
    print("[Button] Hello From Wally Modified (Roblox)")
end)

---------------------------------------------------------------------
-- 4) Toggle
---------------------------------------------------------------------
local ToggleApi = window:Toggle("God Mode", {
    location = Flags,
    flag = "GodMode",
    default = false,
}, function(State)
    print("[Toggle] GodMode:", State)
end)

---------------------------------------------------------------------
-- 5) Bind
---------------------------------------------------------------------
window:Bind("Panic Key", {
    location = Flags,
    flag = "PanicBind",
    default = Enum.KeyCode.P,
    kbonly = true,
}, function()
    print("[Bind] Panic Key Pressed")
end)

---------------------------------------------------------------------
-- 6) Slider
---------------------------------------------------------------------
local SpeedSlider = window:Slider("Walk Speed", {
    location = Flags,
    flag = "WalkSpeed",
    min = 10,
    max = 100,
    default = 16,
    precise = true,
}, function(Value)
    print("[Slider] WalkSpeed:", Value)
end)

---------------------------------------------------------------------
-- 7) Box (Number)
---------------------------------------------------------------------
local NumberBox = window:Box("Max Targets", {
    location = Flags,
    flag = "MaxTargets",
    type = "number", -- "number" or "string"
    default = 5,
    min = 1,
    max = 300,
}, function(NewValue, OldValue, EnterPressed)
    print("[Box:Number]", OldValue, "->", NewValue, "Enter:", EnterPressed)
end)

---------------------------------------------------------------------
-- 8) Box (String)
---------------------------------------------------------------------
local StringBox = window:Box("Target Name", {
    location = Flags,
    flag = "TargetName",
    type = "string",
    default = "PlayerName",
}, function(NewValue, OldValue, EnterPressed)
    print("[Box:String]", OldValue, "->", NewValue, "Enter:", EnterPressed)
end)

---------------------------------------------------------------------
-- 9) ColorPicker (Color Circle)
---------------------------------------------------------------------
local AccentPicker = window:ColorPicker("Accent Color", {
    location = Flags,
    flag = "AccentColor",
    default = Color3.fromRGB(255, 80, 80),
    size = 92,
}, function(NewColor)
    print("[ColorPicker] AccentColor:", ColorToRGB(NewColor))
end)

---------------------------------------------------------------------
-- 10) Section
---------------------------------------------------------------------
window:Section("Selections")

---------------------------------------------------------------------
-- 11) Dropdown
---------------------------------------------------------------------
local ModeDropdown = window:Dropdown("Target Part", {
    location = Flags,
    flag = "TargetPart",
    list = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
}, function(Choice)
    print("[Dropdown] TargetPart:", Choice)
end)

---------------------------------------------------------------------
-- 12) SearchBox
---------------------------------------------------------------------
local RefreshSearch, SearchInput = window:SearchBox("Search Area...", {
    location = Flags,
    flag = "SelectedArea",
    list = {
        "Baseplate", "City", "Forest", "Desert", "Space", "Obby"
    },
}, function(Choice)
    print("[SearchBox] SelectedArea:", Choice)
end)

---------------------------------------------------------------------
-- 13) MultiSelectList
---------------------------------------------------------------------
local WeaponMulti = window:MultiSelectList("Allowed Tools", {
    location = Flags,
    flag = "AllowedTools",
    list = {"Sword", "RocketLauncher", "GravityCoil", "SpeedCoil", "Medkit", "BloxyCola"},
    default = {"Sword", "BloxyCola"},
    search = true,
    sort = true,
    rowHeight = 20,
    maxVisibleRows = 6,
    maxRows = 200,
}, function(SelectedLookup, SelectedArray)
    print("[MultiSelectList] Selected:", table.concat(SelectedArray, ", "))
end)

---------------------------------------------------------------------
-- Runtime API Examples (Set/Get/Refresh)
---------------------------------------------------------------------
window:Section("Runtime API Demo")

window:Button("Apply Preset", function()
    StatusLabel:Refresh("Status: Preset Applied")

    -- Toggle API
    ToggleApi:Set(true)

    -- Slider API
    SpeedSlider:Set(42)
    print("[Slider:Get] WalkSpeed:", SpeedSlider:Get())

    -- Dropdown API
    ModeDropdown:Refresh({"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"})
    ModeDropdown:Set("HumanoidRootPart")
    print("[Dropdown:Get]", ModeDropdown:Get())

    -- SearchBox API
    RefreshSearch({"Spawn", "Shop", "Arena", "ParkourTower"})
    SearchInput.Text = "Sp"

    -- MultiSelectList API
    WeaponMulti:Set("RocketLauncher", true)
    WeaponMulti:SetMany({"Medkit", "SpeedCoil"}, true)
    print("[Multi:Get Array]", table.concat(WeaponMulti:Get(true), ", "))

    -- ColorPicker API
    AccentPicker:Set(Color3.fromRGB(80, 170, 255))
    print("[ColorPicker:Get]", ColorToRGB(AccentPicker:Get()))

    print("[Flags]", DumpTable(Flags))
end)

window:Button("Clear MultiSelect", function()
    WeaponMulti:Clear(true)
end)

window:Button("Refresh MultiSelect List", function()
    WeaponMulti:Refresh({"Flashlight", "GrappleHook", "Balloon", "Bloxade"}, false, true)
end)

-- Global UI toggle key built into lib:
-- RightControl -> hide/show all windows
