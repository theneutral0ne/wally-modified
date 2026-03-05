-- Wally Modified: Practical Full Example (Two Windows)
-- Showcase of every control + runtime API.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified.lua"))()

-- Turn on if you need bind diagnostics:
Library.BindDebug = false

local Flags = {}
local ScriptPresetKey = "WallyPracticalExample"

local PresetManager = Library:CreatePresetManager(ScriptPresetKey, {
    location = Flags,
    rootFolder = "WallyModifiedPresets",
    extension = ".json",
    clearOnLoad = true,
    separateByPlace = true,
})

-- All current CreateWindow option fields shown explicitly.
local WindowOptions = {
    topcolor = Color3.fromRGB(30, 30, 30),
    titlecolor = Color3.fromRGB(255, 255, 255),

    underlinecolor = "rainbow", -- supports Color3 too
    bgcolor = Color3.fromRGB(35, 35, 35),
    boxcolor = Color3.fromRGB(35, 35, 35),
    btncolor = Color3.fromRGB(25, 25, 25),
    dropcolor = Color3.fromRGB(25, 25, 25),
    sectncolor = Color3.fromRGB(25, 25, 25),
    bordercolor = Color3.fromRGB(60, 60, 60),

    font = Enum.Font.SourceSans,
    titlefont = Enum.Font.Code,

    fontsize = 17,
    titlesize = 18,

    textstroke = 1,
    titlestroke = 1,
    strokecolor = Color3.fromRGB(0, 0, 0),

    textcolor = Color3.fromRGB(255, 255, 255),
    titletextcolor = Color3.fromRGB(255, 255, 255),
    placeholdercolor = Color3.fromRGB(255, 255, 255),
    titlestrokecolor = Color3.fromRGB(0, 0, 0),

    autoscaletext = true,
    mintextsize = 10,
}

local MainWindow = Library:CreateWindow("Wally Practical - Main", WindowOptions)
local UtilityWindow = Library:CreateWindow("Wally Practical - Utility", WindowOptions)

local function ColorToRgbText(ColorValue)
    return string.format(
        "%d, %d, %d",
        math.floor(ColorValue.R * 255 + 0.5),
        math.floor(ColorValue.G * 255 + 0.5),
        math.floor(ColorValue.B * 255 + 0.5)
    )
end

local function TrimText(Value)
    return tostring(Value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function GetHumanoid(Character)
    if not Character then
        return nil
    end
    return Character:FindFirstChildOfClass("Humanoid")
end

local function GetOtherPlayerNames()
    local Names = {}
    for _, PlayerData in next, Players:GetPlayers() do
        if PlayerData ~= LocalPlayer then
            table.insert(Names, PlayerData.Name)
        end
    end
    table.sort(Names)
    return Names
end

local function FindPlayerByName(PlayerName)
    if type(PlayerName) ~= "string" or PlayerName == "" then
        return nil
    end

    for _, PlayerData in next, Players:GetPlayers() do
        if string.lower(PlayerData.Name) == string.lower(PlayerName) then
            return PlayerData
        end
    end

    return nil
end

local function ApplyMovement()
    local Character = LocalPlayer.Character
    local Humanoid = GetHumanoid(Character)
    if not Humanoid then
        return false
    end

    local Enabled = Flags.MovementEnabled ~= false
    local WalkSpeed = tonumber(Flags.WalkSpeed) or 16
    local JumpPower = tonumber(Flags.JumpPower) or 50

    if Enabled then
        Humanoid.WalkSpeed = WalkSpeed
        Humanoid.JumpPower = JumpPower
    else
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
    end

    return true
end

local EspBoxes = {}

local function DestroyEspBox(PlayerData)
    local Existing = EspBoxes[PlayerData]
    if Existing then
        Existing:Destroy()
        EspBoxes[PlayerData] = nil
    end
end

local function ShouldShowEspForPlayer(PlayerData)
    if PlayerData == LocalPlayer then
        return false
    end

    if Flags.BoxEspEnabled ~= true then
        return false
    end

    local Character = PlayerData.Character
    if not Character or not Character.Parent then
        return false
    end

    local Filter = string.lower(tostring(Flags.NameFilter or ""))
    if Filter ~= "" and (not string.find(string.lower(PlayerData.Name), Filter, 1, true)) then
        return false
    end

    local EspMode = tostring(Flags.EspMode or "All")
    if EspMode == "Enemies" and PlayerData.Team == LocalPlayer.Team then
        return false
    end
    if EspMode == "Teammates" and PlayerData.Team ~= LocalPlayer.Team then
        return false
    end

    local Ignored = Flags.EspIgnoredPlayers
    if type(Ignored) == "table" and Ignored[PlayerData.Name] then
        return false
    end

    return true
end

local function ApplyEspToPlayer(PlayerData)
    if not ShouldShowEspForPlayer(PlayerData) then
        DestroyEspBox(PlayerData)
        return
    end

    local Character = PlayerData.Character
    local Box = EspBoxes[PlayerData]

    if not Box then
        Box = Instance.new("SelectionBox")
        Box.Name = "WallyModifiedEspBox"
        Box.Parent = Character
        EspBoxes[PlayerData] = Box
    end

    local ColorValue = Flags.EspColor or Color3.fromRGB(255, 80, 80)
    local TransparencyValue = math.clamp(tonumber(Flags.EspTransparency) or 0.2, 0, 1)
    local ThicknessValue = math.clamp(tonumber(Flags.EspLineThickness) or 0.03, 0.01, 0.2)

    Box.Adornee = Character
    Box.Color3 = ColorValue
    Box.SurfaceColor3 = ColorValue
    Box.Transparency = TransparencyValue
    Box.SurfaceTransparency = TransparencyValue
    Box.LineThickness = ThicknessValue
end

local function RefreshEspForAllPlayers()
    for _, PlayerData in next, Players:GetPlayers() do
        ApplyEspToPlayer(PlayerData)
    end
end

local function CleanupRemovedPlayers()
    for PlayerData in next, EspBoxes do
        if not PlayerData.Parent then
            DestroyEspBox(PlayerData)
        end
    end
end

local function HookPlayer(PlayerData)
    if PlayerData == LocalPlayer then
        return
    end

    PlayerData.CharacterAdded:Connect(function()
        task.wait(0.1)
        ApplyEspToPlayer(PlayerData)
    end)

    PlayerData.CharacterRemoving:Connect(function()
        DestroyEspBox(PlayerData)
    end)

    ApplyEspToPlayer(PlayerData)
end

for _, PlayerData in next, Players:GetPlayers() do
    HookPlayer(PlayerData)
end

Players.PlayerAdded:Connect(function(PlayerData)
    HookPlayer(PlayerData)
    CleanupRemovedPlayers()
    RefreshEspForAllPlayers()
end)

Players.PlayerRemoving:Connect(function(PlayerData)
    DestroyEspBox(PlayerData)
    CleanupRemovedPlayers()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    ApplyMovement()
    RefreshEspForAllPlayers()
end)

local function BuildPresetPayload()
    local Payload = {
        MovementEnabled = Flags.MovementEnabled,
        WalkSpeed = Flags.WalkSpeed,
        JumpPower = Flags.JumpPower,
        BoxEspEnabled = Flags.BoxEspEnabled,
        EspMode = Flags.EspMode,
        NameFilter = Flags.NameFilter,
        EspLineThickness = Flags.EspLineThickness,
        EspColor = Flags.EspColor,
        EspTransparency = Flags.EspTransparency,
        EspIgnoredPlayers = Flags.EspIgnoredPlayers,
        EspToggleBind = Flags.EspToggleBind,
        TeleportTarget = Flags.TeleportTarget,
    }

    return Payload
end

-- MAIN WINDOW
MainWindow:Section("Movement")

local MovementToggle = MainWindow:Toggle("Movement Enabled", {
    location = Flags,
    flag = "MovementEnabled",
    default = true,
}, function()
    ApplyMovement()
end)

local WalkSpeedSlider = MainWindow:Slider("Walk Speed", {
    location = Flags,
    flag = "WalkSpeed",
    min = 16,
    max = 120,
    default = 16,
    precise = true,
    decimals = 1,
}, function()
    ApplyMovement()
end)

local JumpPowerBox = MainWindow:Box("Jump Power", {
    location = Flags,
    flag = "JumpPower",
    type = "number",
    default = 50,
    min = 25,
    max = 300,
}, function()
    ApplyMovement()
end)

MainWindow:Section("ESP")

local BoxEspToggle = MainWindow:Toggle("Box ESP Enabled", {
    location = Flags,
    flag = "BoxEspEnabled",
    default = false,
}, function()
    RefreshEspForAllPlayers()
end)

local EspModeDropdown = MainWindow:Dropdown("ESP Mode", {
    location = Flags,
    flag = "EspMode",
    list = {"All", "Enemies", "Teammates"},
}, function()
    RefreshEspForAllPlayers()
end)

local NameFilterBox = MainWindow:Box("Name Filter", {
    location = Flags,
    flag = "NameFilter",
    type = "string",
    default = "",
}, function()
    RefreshEspForAllPlayers()
end)

local EspLineThicknessSlider = MainWindow:Slider("ESP Line Thickness", {
    location = Flags,
    flag = "EspLineThickness",
    min = 0.01,
    max = 0.2,
    default = 0.03,
    precise = true,
    decimals = 3,
}, function()
    RefreshEspForAllPlayers()
end)

local EspColorPicker = MainWindow:ColorPicker("ESP Box Color", {
    location = Flags,
    flag = "EspColor",
    transparencylocation = Flags,
    transparencyflag = "EspTransparency",
    default = Color3.fromRGB(255, 80, 80),
    transparency = 0.2,
    size = 92,
}, function()
    RefreshEspForAllPlayers()
end)

MainWindow:Section("Players")

local EspIgnoredPlayersApi = MainWindow:MultiSelectList("ESP Ignored Players", {
    location = Flags,
    flag = "EspIgnoredPlayers",
    list = GetOtherPlayerNames(),
    default = {},
    search = true,
    sort = true,
    rowHeight = 20,
    maxVisibleRows = 6,
    maxRows = 200,
    listHeight = 120,
    placeholder = "Search players to ignore...",
}, function()
    RefreshEspForAllPlayers()
end)

local EspToggleBind = MainWindow:Bind("ESP Toggle Bind", {
    location = Flags,
    flag = "EspToggleBind",
    default = Enum.KeyCode.P,
    kbonly = true,
}, function()
    local NextState = not (Flags.BoxEspEnabled == true)
    BoxEspToggle:Set(NextState)
end)

local function ApplyFlagsToControls()
    MovementToggle:Set(Flags.MovementEnabled ~= false)
    WalkSpeedSlider:Set(tonumber(Flags.WalkSpeed) or 16)

    local JumpPowerValue = math.clamp(tonumber(Flags.JumpPower) or 50, 25, 300)
    Flags.JumpPower = JumpPowerValue
    JumpPowerBox.Text = tostring(JumpPowerValue)

    BoxEspToggle:Set(Flags.BoxEspEnabled == true)
    EspModeDropdown:Set(tostring(Flags.EspMode or "All"), false)

    NameFilterBox.Text = tostring(Flags.NameFilter or "")

    EspLineThicknessSlider:Set(tonumber(Flags.EspLineThickness) or 0.03)

    if typeof(Flags.EspColor) == "Color3" then
        EspColorPicker:Set(Flags.EspColor, false)
    end
    EspColorPicker:SetTransparency(tonumber(Flags.EspTransparency) or 0.2, false)

    EspIgnoredPlayersApi:Clear(false)
    if type(Flags.EspIgnoredPlayers) == "table" then
        EspIgnoredPlayersApi:SetMany(Flags.EspIgnoredPlayers, true, false)
    end

    if EspToggleBind and EspToggleBind.Set then
        EspToggleBind:Set(Flags.EspToggleBind)
    end
end

-- UTILITY WINDOW
UtilityWindow:Section("Status")

local BuildLabel = UtilityWindow:Label("Build: " .. tostring(Library.Build), {
    textSize = 17,
    textColor = Color3.fromRGB(220, 220, 220),
    bgColor = Color3.fromRGB(40, 40, 40),
    borderColor = Color3.fromRGB(65, 65, 65),
})

local StateLabel = UtilityWindow:Label("State: Ready", {
    textSize = 17,
    textColor = Color3.fromRGB(255, 255, 255),
    bgColor = Color3.fromRGB(35, 35, 35),
    borderColor = Color3.fromRGB(60, 60, 60),
})

UtilityWindow:Section("Teleport")

local RefreshTeleportSearch, TeleportSearchBox = UtilityWindow:SearchBox("Search player name...", {
    location = Flags,
    flag = "TeleportTarget",
    list = GetOtherPlayerNames(),
}, function(ChosenName)
    StateLabel:Refresh("State: Teleport target = " .. tostring(ChosenName))
end)

local TeleportButton = UtilityWindow:Button("Teleport To Target", function()
    local TargetPlayer = FindPlayerByName(Flags.TeleportTarget)
    local Character = LocalPlayer.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

    if not TargetPlayer then
        StateLabel:Refresh("State: Teleport failed (target not found)")
        return
    end

    local TargetCharacter = TargetPlayer.Character
    local TargetRoot = TargetCharacter and TargetCharacter:FindFirstChild("HumanoidRootPart")
    if not RootPart or not TargetRoot then
        StateLabel:Refresh("State: Teleport failed (missing HumanoidRootPart)")
        return
    end

    RootPart.CFrame = TargetRoot.CFrame + Vector3.new(0, 3, 0)
    StateLabel:Refresh("State: Teleported to " .. TargetPlayer.Name)
end)

UtilityWindow:Section("Presets")

local PresetInfoLabel = UtilityWindow:Label("Preset Script Key: " .. PresetManager:GetScriptKey(), {
    textSize = 16,
    textColor = Color3.fromRGB(210, 210, 210),
    bgColor = Color3.fromRGB(33, 33, 33),
    borderColor = Color3.fromRGB(60, 60, 60),
})

local PresetStateLabel = UtilityWindow:Label("Preset State: Idle", {
    textSize = 16,
    textColor = Color3.fromRGB(220, 220, 220),
    bgColor = Color3.fromRGB(33, 33, 33),
    borderColor = Color3.fromRGB(60, 60, 60),
})

local PresetNameBox = UtilityWindow:Box("Preset Name", {
    location = Flags,
    flag = "PresetName",
    type = "string",
    default = "Default",
})

local PresetDropdown = UtilityWindow:Dropdown("Saved Presets", {
    location = Flags,
    flag = "SelectedPreset",
    list = {"(none)"},
}, function(SelectedName)
    if SelectedName and SelectedName ~= "(none)" then
        Flags.PresetName = tostring(SelectedName)
        PresetNameBox.Text = tostring(SelectedName)
    end
end)

local function RefreshPresetDropdown(PreferredName)
    local Names, ListError = PresetManager:List()
    if type(Names) ~= "table" then
        Names = {}
    end

    local DropdownData = {}
    for _, NameData in next, Names do
        table.insert(DropdownData, tostring(NameData))
    end

    if #DropdownData == 0 then
        DropdownData = {"(none)"}
    end

    PresetDropdown:Refresh(DropdownData)

    local Wanted = TrimText(PreferredName)
    if Wanted == "" then
        Wanted = TrimText(Flags.SelectedPreset)
    end

    if Wanted ~= "" and Wanted ~= "(none)" and table.find(DropdownData, Wanted) then
        PresetDropdown:Set(Wanted, false)
    elseif #Names > 0 then
        PresetDropdown:Set(DropdownData[1], false)
        Wanted = DropdownData[1]
    else
        Flags.SelectedPreset = ""
        Wanted = ""
    end

    if Wanted ~= "" and Wanted ~= "(none)" then
        Flags.SelectedPreset = Wanted
        Flags.PresetName = Wanted
        PresetNameBox.Text = Wanted
    end

    if ListError then
        PresetStateLabel:Refresh("Preset State: List failed (" .. tostring(ListError) .. ")")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
    else
        PresetStateLabel:Refresh("Preset State: " .. tostring(#Names) .. " preset(s) found")
        PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175))
    end
end

if not PresetManager:IsAvailable() then
    PresetStateLabel:Refresh("Preset State: writefile/readfile API unavailable")
    PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
else
    RefreshPresetDropdown()
end

UtilityWindow:Button("Save Preset", function()
    if not PresetManager:IsAvailable() then
        PresetStateLabel:Refresh("Preset State: Save failed (file APIs unavailable)")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    local PresetName = TrimText(Flags.PresetName)
    if PresetName == "" then
        PresetStateLabel:Refresh("Preset State: Save failed (preset name is empty)")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    local OkSave, SaveResult = PresetManager:Save(PresetName, BuildPresetPayload())
    if not OkSave then
        PresetStateLabel:Refresh("Preset State: Save failed (" .. tostring(SaveResult) .. ")")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    RefreshPresetDropdown(SaveResult)
    PresetStateLabel:Refresh("Preset State: Saved \"" .. tostring(SaveResult) .. "\"")
    PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175))
    StateLabel:Refresh("State: Saved preset " .. tostring(SaveResult))
end)

UtilityWindow:Button("Load Preset", function()
    if not PresetManager:IsAvailable() then
        PresetStateLabel:Refresh("Preset State: Load failed (file APIs unavailable)")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    local PresetName = TrimText(Flags.SelectedPreset)
    if PresetName == "" or PresetName == "(none)" then
        PresetName = TrimText(Flags.PresetName)
    end

    if PresetName == "" or PresetName == "(none)" then
        PresetStateLabel:Refresh("Preset State: Load failed (no preset selected)")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    local Buffer = {}
    local OkLoad, DataOrError = PresetManager:Load(PresetName, Buffer, true)
    if not OkLoad then
        PresetStateLabel:Refresh("Preset State: Load failed (" .. tostring(DataOrError) .. ")")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    for Key, Value in next, DataOrError do
        Flags[Key] = Value
    end

    ApplyFlagsToControls()

    TeleportSearchBox.Text = tostring(Flags.TeleportTarget or "")
    RefreshEspForAllPlayers()
    ApplyMovement()

    RefreshPresetDropdown(PresetName)
    PresetStateLabel:Refresh("Preset State: Loaded \"" .. tostring(PresetName) .. "\"")
    PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175))
    StateLabel:Refresh("State: Loaded preset " .. tostring(PresetName))
end)

UtilityWindow:Button("Delete Preset", function()
    if not PresetManager:IsAvailable() then
        PresetStateLabel:Refresh("Preset State: Delete failed (file APIs unavailable)")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    local PresetName = TrimText(Flags.SelectedPreset)
    if PresetName == "" or PresetName == "(none)" then
        PresetName = TrimText(Flags.PresetName)
    end

    if PresetName == "" or PresetName == "(none)" then
        PresetStateLabel:Refresh("Preset State: Delete failed (no preset selected)")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    local OkDelete, DeleteError = PresetManager:Delete(PresetName)
    if not OkDelete then
        PresetStateLabel:Refresh("Preset State: Delete failed (" .. tostring(DeleteError) .. ")")
        PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145))
        return
    end

    RefreshPresetDropdown()
    PresetStateLabel:Refresh("Preset State: Deleted \"" .. tostring(PresetName) .. "\"")
    PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175))
    StateLabel:Refresh("State: Deleted preset " .. tostring(PresetName))
end)

UtilityWindow:Button("Refresh Preset List", function()
    RefreshPresetDropdown()
    StateLabel:Refresh("State: Refreshed preset list")
end)

UtilityWindow:Section("Runtime API Demo")

local ReapplyEspButton = UtilityWindow:Button("Reapply ESP", function()
    ApplyMovement()
    RefreshEspForAllPlayers()
    StateLabel:Refresh("State: Reapplied movement + ESP")
end)

UtilityWindow:Button("Call Reapply via :Fire()", function()
    ReapplyEspButton:Fire()
end)

UtilityWindow:Button("Apply Demo Preset", function()
    MovementToggle:Set(true)
    BoxEspToggle:Set(true)

    WalkSpeedSlider:Set(42)
    EspLineThicknessSlider:Set(0.05)

    EspModeDropdown:Set("All", true)

    EspColorPicker:Set(Color3.fromRGB(80, 170, 255), true)
    EspColorPicker:SetTransparency(0.35, true)

    local H, S, V = EspColorPicker:GetHSV()
    EspColorPicker:SetHSV(H, S, math.clamp(V * 0.9, 0, 1), true)

    local Alpha = EspColorPicker:GetAlpha()
    EspColorPicker:SetAlpha(Alpha, true)

    EspIgnoredPlayersApi:Clear(false)
    EspIgnoredPlayersApi:SetMany({"Nobody"}, false, false)

    RefreshTeleportSearch(GetOtherPlayerNames())
    TeleportSearchBox.Text = ""

    BuildLabel:SetBackground(Color3.fromRGB(30, 45, 35))
    BuildLabel:SetColor(Color3.fromRGB(170, 255, 200))

    local ActiveColor = EspColorPicker:Get()
    local ActiveTransparency = EspColorPicker:GetTransparency()

    StateLabel:Refresh(
        "State: Preset | WS=" .. tostring(WalkSpeedSlider:Get())
            .. " | Mode=" .. tostring(EspModeDropdown:Get())
            .. " | Color=" .. ColorToRgbText(ActiveColor)
            .. " | Alpha=" .. string.format("%.2f", ActiveTransparency)
    )

    ApplyMovement()
    RefreshEspForAllPlayers()
end)

UtilityWindow:Button("Refresh Player Lists", function()
    local Names = GetOtherPlayerNames()

    EspModeDropdown:Refresh({"All", "Enemies", "Teammates"})
    RefreshTeleportSearch(Names)
    EspIgnoredPlayersApi:Refresh(Names, true, false)

    local SelectedMap = EspIgnoredPlayersApi:Get(false)
    local Count = 0
    for _ in next, SelectedMap do
        Count = Count + 1
    end

    BuildLabel:Refresh("Build: " .. tostring(Library.Build) .. " | Ignored=" .. tostring(Count))
    StateLabel:Refresh("State: Refreshed dynamic lists")
    RefreshEspForAllPlayers()
end)

UtilityWindow:Button("Ignore First Two Players", function()
    local Names = GetOtherPlayerNames()
    if Names[1] then
        EspIgnoredPlayersApi:Set(Names[1], true, false)
    end
    if Names[2] then
        EspIgnoredPlayersApi:Set(Names[2], true, false)
    end

    local SelectedArray = EspIgnoredPlayersApi:Get(true)
    StateLabel:Refresh("State: Ignored -> " .. table.concat(SelectedArray, ", "))
    RefreshEspForAllPlayers()
end)

UtilityWindow:Button("Use Teleport Button :Fire()", function()
    TeleportButton:Fire()
end)

UtilityWindow:Button("Box Return Demo (Set JumpPower TextBox)", function()
    JumpPowerBox.Text = "90"
    Flags.JumpPower = 90
    ApplyMovement()
    StateLabel:Refresh("State: JumpPower set through Box return object")
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    CleanupRemovedPlayers()
end)

ApplyMovement()
RefreshEspForAllPlayers()

StateLabel:Refresh("State: Ready")
BuildLabel:Refresh("Build: " .. tostring(Library.Build) .. " | BindDebug=" .. tostring(Library.BindDebug))
