-- Wally Modified: Practical Full Example (Multi-Window)
-- Showcase of every control + runtime API.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified.lua"))()

Library.BindDebug = false

local Flags = {}
local ScriptFolderName = "WallyPracticalExample"

local WindowOptions = {
    topcolor = Color3.fromRGB(30, 30, 30),
    titlecolor = Color3.fromRGB(255, 255, 255),

    underlinecolor = "rainbow",
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
    mintextsize = 8,
    itemspacing = 2,
    togglestyle = "checkmark",
    toggleoncolor = Color3.fromRGB(0, 255, 140),
    toggleoffcolor = Color3.fromRGB(35, 35, 35),
    persistwindow = true,
}

local MainWindow = Library:CreateWindow("Wally Practical - Main", WindowOptions)
local UtilityWindow = Library:CreateWindow("Wally Practical - Utility", WindowOptions)
Library:OnFlagChanged("WalkSpeed", function(NewValue, OldValue)
    print("[OnFlagChanged] WalkSpeed:", OldValue, "->", NewValue)
end)
local SettingsWindowApi = Library:SettingsWindows({
    title = "Wally Practical - Settings",
    windowOptions = WindowOptions,
    scriptFolder = ScriptFolderName,
    presets = {
        extension = ".json",
        clearOnLoad = true,
        separateByPlace = true,
    },
})

local function GetLocalPlayerThumbnail()
    local Ok, Thumbnail = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)

    if Ok and type(Thumbnail) == "string" and Thumbnail ~= "" then
        return Thumbnail
    end

    return "rbxassetid://0"
end

local ImagePreviewWindow
local function EnsureImagePreviewWindow()
    if ImagePreviewWindow and ImagePreviewWindow.Window and ImagePreviewWindow.Window.object and ImagePreviewWindow.Window.object.Parent then
        return ImagePreviewWindow
    end

    local Ok, Result = pcall(function()
        local PreviewWindow = Library:CreateImagePreviewWindow("Wally Practical - Image Preview", {
            windowOptions = WindowOptions,
            persistwindow = true,
            image = GetLocalPlayerThumbnail(),
            caption = "LocalPlayer Headshot Preview",
            previewHeight = 190,
            scaleType = Enum.ScaleType.Fit,
            backgroundColor = Color3.fromRGB(20, 20, 20),
            borderColor = Color3.fromRGB(65, 65, 65),
        })
        if PreviewWindow and PreviewWindow.SetVisible then
            PreviewWindow:SetVisible(false)
        end
        return PreviewWindow
    end)

    if not Ok then
        warn("[Wally Modified Example] Image preview init failed:", Result)
        return nil
    end

    ImagePreviewWindow = Result
    return ImagePreviewWindow
end
local function ColorToRgbText(ColorValue)
    return string.format(
        "%d, %d, %d",
        math.floor(ColorValue.R * 255 + 0.5),
        math.floor(ColorValue.G * 255 + 0.5),
        math.floor(ColorValue.B * 255 + 0.5)
    )
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
    step = 0.5,
    valueWidth = 44,
}, function()
    ApplyMovement()
end)
WalkSpeedSlider:OnChanged(function(Value)
    print("[OnChanged] WalkSpeed slider:", Value)
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
    step = 0.005,
    valueWidth = 52,
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
    size = 150,
    drag = true,
    wheelRadiusScale = 1,
    wheelOutsidePadding = 6,
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
UtilityWindow:Label("Window settings moved to dedicated settings window.", {
    textSize = 16,
    textColor = Color3.fromRGB(220, 220, 220),
    bgColor = Color3.fromRGB(35, 35, 35),
    borderColor = Color3.fromRGB(60, 60, 60),
})

UtilityWindow:Button("Open Settings Window", function()
    if SettingsWindowApi and SettingsWindowApi.Window and SettingsWindowApi.Window.object then
        SettingsWindowApi.Window.object.Visible = true
    end
    StateLabel:Refresh("State: Opened settings window")
end)

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

UtilityWindow:Section("Image Preview")

local PreviewImageSourceBox = UtilityWindow:Box("Preview Image Source", {
    location = Flags,
    flag = "PreviewImageSource",
    type = "string",
    default = "",
    tooltip = "rbxassetid://<id>, numeric id, or thumbnail URL.",
})

UtilityWindow:Button("Apply Preview Image Source", function()
    local PreviewWindow = EnsureImagePreviewWindow()
    if not PreviewWindow then
        StateLabel:Refresh("State: Preview window unavailable")
        return
    end

    local SourceValue = tostring(Flags.PreviewImageSource or "")
    if SourceValue == "" then
        SourceValue = "rbxassetid://0"
    end
    PreviewWindow:SetImage(SourceValue)
    PreviewWindow:SetCaption("Custom Source: " .. SourceValue)
    PreviewWindow:SetVisible(true)
    PreviewWindow:BringToFront()
    StateLabel:Refresh("State: Applied preview source")
end)

UtilityWindow:Button("Use LocalPlayer Thumbnail", function()
    local PreviewWindow = EnsureImagePreviewWindow()
    if not PreviewWindow then
        StateLabel:Refresh("State: Preview window unavailable")
        return
    end

    local Thumbnail = GetLocalPlayerThumbnail()
    Flags.PreviewImageSource = Thumbnail
    PreviewImageSourceBox:Set(Thumbnail, false)
    PreviewWindow:SetImage(Thumbnail)
    PreviewWindow:SetCaption(LocalPlayer.Name .. " Headshot")
    PreviewWindow:SetVisible(true)
    PreviewWindow:BringToFront()
    StateLabel:Refresh("State: Loaded LocalPlayer thumbnail")
end)

UtilityWindow:Button("Toggle Preview Window", function()
    local PreviewWindow = EnsureImagePreviewWindow()
    if not PreviewWindow then
        StateLabel:Refresh("State: Preview window unavailable")
        return
    end

    local NextVisible = not PreviewWindow:IsVisible()
    PreviewWindow:SetVisible(NextVisible)
    if NextVisible then
        PreviewWindow:BringToFront()
    end
    StateLabel:Refresh("State: Image preview visible = " .. tostring(NextVisible))
end)

UtilityWindow:Button("Center Preview Window", function()
    local PreviewWindow = EnsureImagePreviewWindow()
    if not PreviewWindow then
        StateLabel:Refresh("State: Preview window unavailable")
        return
    end

    PreviewWindow:SetVisible(true)
    PreviewWindow:Center()
    PreviewWindow:BringToFront()
    StateLabel:Refresh("State: Centered image preview window")
end)

UtilityWindow:Section("Runtime API Demo")

UtilityWindow:Button("Bring Utility To Front", function()
    UtilityWindow:BringToFront()
    StateLabel:Refresh("State: Utility window brought to front")
end)

UtilityWindow:Button("Center Utility Window", function()
    UtilityWindow:Center()
    StateLabel:Refresh("State: Utility window centered")
end)

UtilityWindow:Button("Nudge Utility +20 X", function()
    local Position = UtilityWindow:GetPosition()
    if Position then
        UtilityWindow:SetPosition(Position.X.Offset + 20, Position.Y.Offset)
        StateLabel:Refresh("State: Utility moved to X=" .. tostring(Position.X.Offset + 20))
    end
end)

UtilityWindow:Button("Show Notification", function()
    Library:Notify({
        title = "Wally Modified",
        text = "Notification system is active. This message auto-closes after 4 seconds.",
        duration = 4,
    })
    StateLabel:Refresh("State: Sent test notification")
end)

UtilityWindow:Button("Show Level Notifications", function()
    Library:NotifyInfo("Wally Modified", "Info level toast", 2)
    Library:NotifySuccess("Wally Modified", "Success level toast", 2)
    Library:NotifyWarn("Wally Modified", "Warn level toast", 2)
    Library:NotifyError("Wally Modified", "Error level toast", 2)
    StateLabel:Refresh("State: Sent level notifications")
end)

UtilityWindow:Button("Suspend Callbacks (1s)", function()
    Library:SuspendCallbacks(true)
    StateLabel:Refresh("State: Callbacks suspended for 1 second")
    task.delay(1, function()
        Library:SuspendCallbacks(false)
        StateLabel:Refresh("State: Callbacks resumed")
    end)
end)

local ReapplyEspButton = UtilityWindow:Button("Reapply ESP", function()
    ApplyMovement()
    RefreshEspForAllPlayers()
    StateLabel:Refresh("State: Reapplied movement + ESP")
end)

UtilityWindow:Button("Call Reapply via :Fire()", function()
    ReapplyEspButton:Fire()
end)

UtilityWindow:Button("Apply Demo Preset", function()
    Library:BatchUpdate(function()
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
    end, {
        suspendCallbacks = true,
        refreshDependencies = true,
    })

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

UtilityWindow:Button("Destroy Entire UI Library", function()
    Library:Destroy()
end)

local AdvancedWindow = Library:CreateWindow("Wally Practical - Advanced", WindowOptions)
local GeneralTab = AdvancedWindow:CreateTab("General")
local AdvancedTab = AdvancedWindow:CreateTab("Advanced")
local AdvancedSubTab = AdvancedTab:CreateSubTab("Sub Options")
local WalkSpeedBeforeHold = nil

GeneralTab:SearchBar("Filter Controls", {
    tooltip = "Type to filter controls in the active tab.",
})

local AdvancedEnabledToggle = GeneralTab:Toggle("Advanced Controls Enabled", {
    location = Flags,
    flag = "AdvancedControlsEnabled",
    default = false,
    tooltip = "Dependency root flag for advanced controls.",
}, function(Value)
    StateLabel:Refresh("State: Advanced controls = " .. tostring(Value))
end)

local AdvancedStrengthSlider = GeneralTab:Slider("Advanced Strength", {
    location = Flags,
    flag = "AdvancedStrength",
    min = 0,
    max = 100,
    default = 50,
    valueWidth = 44,
    tooltip = "Only enabled when Advanced Controls Enabled is true.",
    enabledWhen = {
        flag = "AdvancedControlsEnabled",
        value = true,
    },
}, function(Value)
    StateLabel:Refresh("State: Advanced strength = " .. tostring(Value))
end)

local LargeDropdownItems = {}
for Index = 1, 350 do
    LargeDropdownItems[Index] = "Preset Option " .. tostring(Index)
end

local LargeDropdown = GeneralTab:Dropdown("Large Virtualized Dropdown", {
    location = Flags,
    flag = "LargeDropdownSelection",
    list = LargeDropdownItems,
    tooltip = "Large dataset dropdown to exercise virtualized rendering.",
}, function(Value)
    StateLabel:Refresh("State: Large dropdown -> " .. tostring(Value))
end)

local LargeMultiSelectItems = {}
for Index = 1, 500 do
    LargeMultiSelectItems[Index] = "Tag_" .. tostring(Index)
end

local LargeMultiSelect = GeneralTab:MultiSelectList("Large Virtualized List", {
    location = Flags,
    flag = "LargeMultiSelectTags",
    list = LargeMultiSelectItems,
    search = true,
    sort = false,
    maxRows = 500,
    maxVisibleRows = 6,
    listHeight = 120,
    tooltip = "Large list to demonstrate virtualized multi-select rendering.",
}, function(_, SelectedArray)
    StateLabel:Refresh("State: Selected tags = " .. tostring(#SelectedArray))
end)

local HiddenUntilEnabledLabel = GeneralTab:Label("This label appears when advanced controls are enabled.", {
    tooltip = "Visibility dependency example.",
    visibleWhen = {
        flag = "AdvancedControlsEnabled",
        value = true,
    },
})

local HoldBind = AdvancedTab:Bind("Sprint Hold Bind", {
    location = Flags,
    flag = "SprintHoldBind",
    default = Enum.KeyCode.LeftShift,
    mode = "hold",
    tooltip = "Hold mode: callback receives true on press, false on release.",
}, function(State)
    if State == true then
        WalkSpeedBeforeHold = tonumber(Flags.WalkSpeed) or 16
        WalkSpeedSlider:Set(80)
    else
        WalkSpeedSlider:Set(tonumber(WalkSpeedBeforeHold) or 16)
        WalkSpeedBeforeHold = nil
    end
    ApplyMovement()
end)

AdvancedSubTab:Button("Destroy Advanced Window", function()
    if AdvancedWindow and AdvancedWindow.object and AdvancedWindow.object.Parent then
        AdvancedWindow:Destroy()
    end
end)

local ToggleBind = AdvancedSubTab:Bind("ESP Toggle Mode Bind", {
    location = Flags,
    flag = "EspToggleModeBind",
    default = Enum.KeyCode.O,
    mode = "toggle",
    tooltip = "Toggle mode: callback receives bool on each press.",
}, function(State)
    BoxEspToggle:Set(State == true)
    RefreshEspForAllPlayers()
end)

AdvancedSubTab:Button("Set Toggle Bind Mode -> Press", {
    tooltip = "Runtime bind mode switching demo.",
}, function()
    ToggleBind:SetMode("press", true)
    StateLabel:Refresh("State: ESP toggle bind mode set to press")
end)

AdvancedSubTab:Button("Hide Advanced Strength Via API", {
    tooltip = "Uses Library:GetControlApiByFlag",
}, function()
    local Api = Library:GetControlApiByFlag("AdvancedStrength")
    if Api and Api.SetVisible then
        Api:SetVisible(false)
        StateLabel:Refresh("State: Advanced Strength hidden via API")
    end
end)

AdvancedSubTab:Button("Show Advanced Strength Via API", function()
    local Api = Library:GetControlApiByFlag("AdvancedStrength")
    if Api and Api.SetVisible then
        Api:SetVisible(true)
        StateLabel:Refresh("State: Advanced Strength shown via API")
    end
end)

AdvancedSubTab:Button("Disable Advanced Strength Via API", {
    tooltip = "Visible/enabled API demo (SetEnabled false).",
}, function()
    local Api = Library:GetControlApiByFlag("AdvancedStrength")
    if Api and Api.SetEnabled then
        Api:SetEnabled(false)
        StateLabel:Refresh("State: Advanced Strength disabled via API")
    end
end)

AdvancedSubTab:Button("Enable Advanced Strength Via API", function()
    local Api = Library:GetControlApiByFlag("AdvancedStrength")
    if Api and Api.SetEnabled then
        Api:SetEnabled(true)
        StateLabel:Refresh("State: Advanced Strength enabled via API")
    end
end)

AdvancedSubTab:Button("Refresh Dependency Evaluation", {
    tooltip = "Calls Library:RefreshDependencies().",
}, function()
    local Count = Library:RefreshDependencies()
    StateLabel:Refresh("State: Dependencies refreshed (" .. tostring(Count) .. " controls)")
end)

AdvancedSubTab:Button("Set ESP Bind Mode -> Always", {
    tooltip = "Bind mode demo (always mode).",
}, function()
    ToggleBind:SetMode("always", true)
    StateLabel:Refresh("State: ESP bind mode set to always")
end)

AdvancedSubTab:Button("Set ESP Bind Mode -> Toggle", function()
    ToggleBind:SetMode("toggle", true)
    StateLabel:Refresh("State: ESP bind mode set to toggle")
end)

AdvancedSubTab:Button("Refresh Large Data Sources", function()
    LargeDropdown:Refresh(LargeDropdownItems)
    LargeMultiSelect:Refresh(LargeMultiSelectItems, true, false)
    StateLabel:Refresh("State: Refreshed large dropdown/list data")
end)

HiddenUntilEnabledLabel:Refresh("This label appears when advanced controls are enabled.")

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    CleanupRemovedPlayers()
end)

ApplyMovement()
RefreshEspForAllPlayers()

StateLabel:Refresh("State: Ready")
BuildLabel:Refresh("Build: " .. tostring(Library.Build) .. " | BindDebug=" .. tostring(Library.BindDebug))
