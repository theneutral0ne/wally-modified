            table.remove(Library.RainbowTable, ExistingIndex);
        end
        if typeof(SolidColor) == "Color3" then
            Underline.BackgroundColor3 = SolidColor;
        end
    end

    function Library:GetWindowOptions()
        local Output = {};
        if type(self.Options) == "table" then
            for Key, Value in next, self.Options do
                Output[Key] = Value;
            end
        end
        return Output;
    end

    function Library:ApplyWindowOptions()
        local ActiveOptions = self.Options;
        if type(ActiveOptions) ~= "table" then
            ActiveOptions = setmetatable({}, {__index = Defaults});
            self.Options = ActiveOptions;
        end

        for Index = #self.Windows, 1, -1 do
            local WindowData = self.Windows[Index];
            local WindowObject = WindowData and WindowData.object;
            if (not WindowObject) or (not WindowObject.Parent) then
                table.remove(self.Windows, Index);
            else
                local WindowOptions = WindowData.options or ActiveOptions;
                local ItemSpacing = math.clamp(
                    math.floor((tonumber(WindowOptions.itemspacing or WindowOptions.methodspacing or WindowOptions.controlspacing or WindowOptions.spacing) or 0) + 0.5),
                    0,
                    40
                );
                local Width = 190;

                WindowObject.BackgroundColor3 = WindowOptions.topcolor;
                WindowData.MinWidth = Width;
                WindowData.MaxWidth = Width;
                WindowData.Resizable = false;
                WindowData.ResizeGripEnabled = false;
                WindowData.AutoWidth = false;
                WindowData.AutoWidthPadding = 0;
                if type(WindowData.SetWidth) == "function" then
                    WindowData:SetWidth(Width);
                else
                    WindowObject.Size = UDim2.new(0, Width, WindowObject.Size.Y.Scale, WindowObject.Size.Y.Offset);
                end

                local WindowTitle = WindowObject:FindFirstChild("window_title");
                if WindowTitle then
                    WindowTitle.Font = WindowOptions.titlefont;
                    WindowTitle.TextSize = WindowOptions.titlesize;
                    WindowTitle.TextColor3 = WindowOptions.titletextcolor;
                    WindowTitle.TextStrokeTransparency = WindowOptions.titlestroke;
                    WindowTitle.TextStrokeColor3 = WindowOptions.titlestrokecolor;
                end

                local WindowToggle = WindowObject:FindFirstChild("window_toggle");
                if WindowToggle then
                    WindowToggle.Font = WindowOptions.titlefont;
                    WindowToggle.TextSize = WindowOptions.titlesize;
                    WindowToggle.TextColor3 = WindowOptions.titletextcolor;
                    WindowToggle.TextStrokeTransparency = WindowOptions.titlestroke;
                    WindowToggle.TextStrokeColor3 = WindowOptions.titlestrokecolor;
                end

                local Underline = WindowObject:FindFirstChild("Underline");
                if Underline then
                    local UseRainbow = (WindowOptions.underlinecolor == "rainbow");
                    local SolidColor = WindowOptions.underlinecolor;
                    if UseRainbow then
                        SolidColor = nil;
                    elseif typeof(SolidColor) ~= "Color3" then
                        SolidColor = Defaults.underlinecolor;
                    end
                    SetUnderlineRainbowState(Underline, UseRainbow, SolidColor);
                end

                local ContainerData = WindowData.container or WindowObject:FindFirstChild("ContainerData");
                if ContainerData then
                    ContainerData.BackgroundColor3 = WindowOptions.bgcolor;
                end

                local ListLayout = WindowData.list or (ContainerData and ContainerData:FindFirstChild("List"));
                if ListLayout then
                    ListLayout.Padding = UDim.new(0, ItemSpacing);
                end

                if type(WindowData.Resize) == "function" then
                    WindowData:Resize();
                end
            end
        end

        for Index = #self.ToggleRegistry, 1, -1 do
            local Entry = self.ToggleRegistry[Index];
            if (not Entry) or (not Entry.Button) or (not Entry.Button.Parent) then
                table.remove(self.ToggleRegistry, Index);
            elseif type(Entry.Update) == "function" then
                pcall(Entry.Update);
            end
        end

        return true;
    end

    function Library:SetWindowOptions(NewOptions, ApplyNow)
        if type(NewOptions) ~= "table" then
            return false, "options must be a table";
        end

        if type(self.Options) ~= "table" then
            self.Options = setmetatable({}, {__index = Defaults});
        end

        for Key, Value in next, NewOptions do
            self.Options[Key] = Value;
        end

        for _, WindowData in next, self.Windows do
            if WindowData and type(WindowData.options) == "table" then
                for Key, Value in next, NewOptions do
                    WindowData.options[Key] = Value;
                end
            end
        end

        if ApplyNow ~= false then
            self:ApplyWindowOptions();
        end

        return true;
    end

    function Library:UpdateWindowOptions(NewOptions, ApplyNow)
        return self:SetWindowOptions(NewOptions, ApplyNow);
    end

    function Library:SettingsWindow(Options)
        Options = Options or {};

        local function TrimText(Value)
            return tostring(Value or ""):gsub("^%s+", ""):gsub("%s+$", "");
        end

        local function EnsureColor(Value, Fallback)
            if typeof(Value) == "Color3" then
                return Value;
            end
            return Fallback;
        end

        local CurrentOptions = self:GetWindowOptions();
        local ThemeState = {
            ToggleStyle = (string.lower(tostring(CurrentOptions.togglestyle or "checkmark")) == "fill" and "fill" or "checkmark");
            ItemSpacing = math.clamp(tonumber(CurrentOptions.itemspacing) or 0, 0, 40);
            ToggleOnColor = EnsureColor(CurrentOptions.toggleoncolor, Color3.fromRGB(0, 255, 140));
            ToggleOffColor = EnsureColor(CurrentOptions.toggleoffcolor, Color3.fromRGB(35, 35, 35));
            UnderlineMode = (CurrentOptions.underlinecolor == "rainbow" and "Rainbow" or "Solid");
            UnderlineColor = EnsureColor(CurrentOptions.underlinecolor, Color3.fromRGB(0, 255, 140));
            PresetName = tostring(Options.defaultPresetName or "Default");
            SelectedPreset = "";
        };

        local SettingsWindow = self:CreateWindow(tostring(Options.title or "Wally Settings"), Options.windowOptions);

        local PresetConfig = (type(Options.presets) == "table" and Options.presets) or {};
        local ScriptFolderName = tostring(
            PresetConfig.scriptFolder
            or Options.scriptFolder
            or PresetConfig.folder
            or Options.folder
            or PresetConfig.rootFolder
            or Options.rootFolder
            or "WallyModifiedScript"
        );
        local PresetManager = self:CreateScriptPresetManager("Presets", {
            rootFolder = ScriptFolderName;
            extension = PresetConfig.extension or Options.extension or ".json";
            clearOnLoad = (PresetConfig.clearOnLoad ~= false);
            separateByPlace = (PresetConfig.separateByPlace ~= false);
        });
        self.WindowPersistenceRootFolder = PresetManager:GetRootFolder();
        self.WindowPersistenceScriptKey = PresetManager:GetScriptKey();
        self.WindowPersistenceFileName = "windows.json";

        for _, WindowData in next, self.Windows do
            if WindowData and WindowData.object and WindowData.object.Parent then
                local WindowName = tostring(WindowData.object.Name or "Window");
                local WindowOptionsData = WindowData.options or {};
                local PersistEnabled = (
                    WindowOptionsData.persist == true
                    or WindowOptionsData.persistwindow == true
                    or (type(self.Options) == "table" and self.Options.persistwindow == true)
                );
                if PersistEnabled then
                    self:AttachWindowPersistence(WindowData, WindowName, {
                        persist = true;
                        windowPersistence = {
                            rootFolder = self.WindowPersistenceRootFolder;
                            scriptFolder = self.WindowPersistenceScriptKey;
                            fileName = self.WindowPersistenceFileName;
                        };
                    });
                end
            end
        end

        local IsSyncing = false;
        local ToggleStyleDropdown;
        local ItemSpacingSlider;
        local UnderlineModeDropdown;
        local ToggleOnColorPicker;
        local ToggleOffColorPicker;
        local UnderlineColorPicker;

        local function ApplyThemeState()
            if IsSyncing then
                return;
            end

            local UnderlineValue = ThemeState.UnderlineColor;
            if ThemeState.UnderlineMode == "Rainbow" then
                UnderlineValue = "rainbow";
            end

            self:SetWindowOptions({
                togglestyle = string.lower(tostring(ThemeState.ToggleStyle or "checkmark"));
                itemspacing = math.clamp(tonumber(ThemeState.ItemSpacing) or 0, 0, 40);
                toggleoncolor = EnsureColor(ThemeState.ToggleOnColor, Color3.fromRGB(0, 255, 140));
                toggleoffcolor = EnsureColor(ThemeState.ToggleOffColor, Color3.fromRGB(35, 35, 35));
                underlinecolor = UnderlineValue;
                notifyaccentcolor = (UnderlineValue == "rainbow" and Color3.fromRGB(0, 255, 140) or EnsureColor(ThemeState.UnderlineColor, Color3.fromRGB(0, 255, 140)));
            }, true);
        end

        local function SyncControlsFromState()
            IsSyncing = true;
            if ToggleStyleDropdown then
                ToggleStyleDropdown:Set(ThemeState.ToggleStyle, false);
            end
            if UnderlineModeDropdown then
                UnderlineModeDropdown:Set(ThemeState.UnderlineMode, false);
            end
            if ItemSpacingSlider then
                ItemSpacingSlider:Set(ThemeState.ItemSpacing);
            end
            if ToggleOnColorPicker then
                ToggleOnColorPicker:Set(ThemeState.ToggleOnColor, false);
            end
            if ToggleOffColorPicker then
                ToggleOffColorPicker:Set(ThemeState.ToggleOffColor, false);
            end
            if UnderlineColorPicker then
                UnderlineColorPicker:Set(ThemeState.UnderlineColor, false);
            end
            IsSyncing = false;
            ApplyThemeState();
        end

        SettingsWindow:Section("Window Theme");

        ToggleStyleDropdown = SettingsWindow:Dropdown("Toggle Style", {
            location = ThemeState;
            flag = "ToggleStyle";
            list = (ThemeState.ToggleStyle == "fill" and {"fill", "checkmark"} or {"checkmark", "fill"});
        }, function()
            ApplyThemeState();
        end);

        ItemSpacingSlider = SettingsWindow:Slider("Item Spacing", {
            location = ThemeState;
            flag = "ItemSpacing";
            min = 0;
            max = 16;
            default = ThemeState.ItemSpacing;
        }, function()
            ApplyThemeState();
        end);

        ToggleOnColorPicker = SettingsWindow:ColorPicker("Toggle On Color", {
            location = ThemeState;
            flag = "ToggleOnColor";
            default = ThemeState.ToggleOnColor;
            size = 84;
        }, function()
            ApplyThemeState();
        end);

        ToggleOffColorPicker = SettingsWindow:ColorPicker("Toggle Off Color", {
            location = ThemeState;
            flag = "ToggleOffColor";
            default = ThemeState.ToggleOffColor;
            size = 84;
        }, function()
            ApplyThemeState();
        end);

        UnderlineModeDropdown = SettingsWindow:Dropdown("Underline Mode", {
            location = ThemeState;
            flag = "UnderlineMode";
            list = (ThemeState.UnderlineMode == "Rainbow" and {"Rainbow", "Solid"} or {"Solid", "Rainbow"});
        }, function()
            ApplyThemeState();
        end);

        UnderlineColorPicker = SettingsWindow:ColorPicker("Underline Color", {
            location = ThemeState;
            flag = "UnderlineColor";
            default = ThemeState.UnderlineColor;
            size = 84;
        }, function()
            if ThemeState.UnderlineMode ~= "Rainbow" then
                ApplyThemeState();
            end
        end);

        SettingsWindow:Button("Reset Theme", function()
            ThemeState.ToggleStyle = "checkmark";
            ThemeState.ItemSpacing = 0;
            ThemeState.ToggleOnColor = Color3.fromRGB(0, 255, 140);
            ThemeState.ToggleOffColor = Color3.fromRGB(35, 35, 35);
            ThemeState.UnderlineMode = "Rainbow";
            ThemeState.UnderlineColor = Color3.fromRGB(0, 255, 140);
            SyncControlsFromState();
            self:Notify("Wally Settings", "Theme reset.", 2);
        end);

        SettingsWindow:Section("Script Presets");
        local PresetInfoLabel = SettingsWindow:Label("Preset Folder: " .. tostring(PresetManager:GetFolder()), {
            textSize = 16;
            textColor = Color3.fromRGB(210, 210, 210);
            bgColor = Color3.fromRGB(33, 33, 33);
            borderColor = Color3.fromRGB(60, 60, 60);
        });
        local PresetStateLabel = SettingsWindow:Label("Preset State: Idle", {
            textSize = 16;
            textColor = Color3.fromRGB(220, 220, 220);
            bgColor = Color3.fromRGB(33, 33, 33);
            borderColor = Color3.fromRGB(60, 60, 60);
        });

        local PresetNameBox = SettingsWindow:Box("Preset Name", {
            location = ThemeState;
            flag = "PresetName";
            type = "string";
            default = ThemeState.PresetName;
        });

        local PresetDropdown = SettingsWindow:Dropdown("Saved Presets", {
            location = ThemeState;
            flag = "SelectedPreset";
            list = {"(none)"};
        }, function(SelectedName)
            if SelectedName and SelectedName ~= "(none)" then
                ThemeState.PresetName = tostring(SelectedName);
                PresetNameBox.Text = tostring(SelectedName);
            end
        end);

        local function RefreshPresetDropdown(PreferredName)
            local Names, ListError = PresetManager:List();
            if type(Names) ~= "table" then
                Names = {};
            end

            local DropdownData = {};
            for _, NameData in next, Names do
                table.insert(DropdownData, tostring(NameData));
            end
            if #DropdownData == 0 then
                DropdownData = {"(none)"};
            end

            PresetDropdown:Refresh(DropdownData);

            local Wanted = TrimText(PreferredName);
            if Wanted == "" then
                Wanted = TrimText(ThemeState.SelectedPreset);
            end

            if Wanted ~= "" and Wanted ~= "(none)" and table.find(DropdownData, Wanted) then
                PresetDropdown:Set(Wanted, false);
            elseif #Names > 0 then
                Wanted = DropdownData[1];
                PresetDropdown:Set(Wanted, false);
            else
                Wanted = "";
            end

            if Wanted ~= "" and Wanted ~= "(none)" then
                ThemeState.SelectedPreset = Wanted;
                ThemeState.PresetName = Wanted;
                PresetNameBox.Text = Wanted;
            else
                ThemeState.SelectedPreset = "";
            end

            if ListError then
                PresetStateLabel:Refresh("Preset State: List failed (" .. tostring(ListError) .. ")");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
            else
                PresetStateLabel:Refresh("Preset State: " .. tostring(#Names) .. " preset(s) found");
                PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175));
            end
        end

        if not PresetManager:IsAvailable() then
            PresetStateLabel:Refresh("Preset State: writefile/readfile API unavailable");
            PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
        else
            RefreshPresetDropdown();
        end

        SettingsWindow:Button("Save Preset", function()
            if not PresetManager:IsAvailable() then
                PresetStateLabel:Refresh("Preset State: Save failed (file APIs unavailable)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local PresetName = TrimText(ThemeState.PresetName);
            if PresetName == "" then
                PresetStateLabel:Refresh("Preset State: Save failed (preset name is empty)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local OkSave, SaveResult = PresetManager:Save(PresetName);
            if not OkSave then
                PresetStateLabel:Refresh("Preset State: Save failed (" .. tostring(SaveResult) .. ")");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            RefreshPresetDropdown(SaveResult);
            PresetStateLabel:Refresh("Preset State: Saved \"" .. tostring(SaveResult) .. "\"");
            PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175));
            self:Notify("Wally Settings", "Saved preset: " .. tostring(SaveResult), 2);
        end);

        SettingsWindow:Button("Load Preset", function()
            if not PresetManager:IsAvailable() then
                PresetStateLabel:Refresh("Preset State: Load failed (file APIs unavailable)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local PresetName = TrimText(ThemeState.SelectedPreset);
            if PresetName == "" or PresetName == "(none)" then
                PresetName = TrimText(ThemeState.PresetName);
            end
            if PresetName == "" or PresetName == "(none)" then
                PresetStateLabel:Refresh("Preset State: Load failed (no preset selected)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local OkLoad, DataOrError = PresetManager:Load(PresetName, nil, true);
            if not OkLoad then
                PresetStateLabel:Refresh("Preset State: Load failed (" .. tostring(DataOrError) .. ")");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            ThemeState.ToggleStyle = (string.lower(tostring(ThemeState.ToggleStyle or "checkmark")) == "fill" and "fill" or "checkmark");
            ThemeState.ItemSpacing = math.clamp(tonumber(ThemeState.ItemSpacing) or 0, 0, 40);
            ThemeState.ToggleOnColor = EnsureColor(ThemeState.ToggleOnColor, Color3.fromRGB(0, 255, 140));
            ThemeState.ToggleOffColor = EnsureColor(ThemeState.ToggleOffColor, Color3.fromRGB(35, 35, 35));
            ThemeState.UnderlineMode = (ThemeState.UnderlineMode == "Rainbow" and "Rainbow" or "Solid");
            ThemeState.UnderlineColor = EnsureColor(ThemeState.UnderlineColor, Color3.fromRGB(0, 255, 140));

            SyncControlsFromState();
            RefreshPresetDropdown(PresetName);
            PresetStateLabel:Refresh("Preset State: Loaded \"" .. tostring(PresetName) .. "\"");
            PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175));
            self:Notify("Wally Settings", "Loaded preset: " .. tostring(PresetName), 2);
        end);

        SettingsWindow:Button("Delete Preset", function()
            if not PresetManager:IsAvailable() then
                PresetStateLabel:Refresh("Preset State: Delete failed (file APIs unavailable)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local PresetName = TrimText(ThemeState.SelectedPreset);
            if PresetName == "" or PresetName == "(none)" then
                PresetName = TrimText(ThemeState.PresetName);
            end
            if PresetName == "" or PresetName == "(none)" then
                PresetStateLabel:Refresh("Preset State: Delete failed (no preset selected)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local OkDelete, DeleteError = PresetManager:Delete(PresetName);
            if not OkDelete then
                PresetStateLabel:Refresh("Preset State: Delete failed (" .. tostring(DeleteError) .. ")");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            RefreshPresetDropdown();
            PresetStateLabel:Refresh("Preset State: Deleted \"" .. tostring(PresetName) .. "\"");
            PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175));
            self:Notify("Wally Settings", "Deleted preset: " .. tostring(PresetName), 2);
        end);

        SettingsWindow:Button("Refresh Presets", function()
            RefreshPresetDropdown();
        end);

        local SchemaInfoLabel = SettingsWindow:Label("Preset Schema Version: " .. tostring(PresetManager:GetSchemaVersion()), {
            textSize = 15;
            textColor = Color3.fromRGB(190, 220, 255);
            bgColor = Color3.fromRGB(30, 34, 40);
            borderColor = Color3.fromRGB(60, 68, 78);
        });

        SettingsWindow:Button("Export Preset (Clipboard)", function()
            if not PresetManager:IsAvailable() then
                PresetStateLabel:Refresh("Preset State: Export failed (file APIs unavailable)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local Clipboard = (type(setclipboard) == "function" and setclipboard) or nil;
            if not Clipboard then
                PresetStateLabel:Refresh("Preset State: Export failed (setclipboard unavailable)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local PresetName = TrimText(ThemeState.SelectedPreset);
            if PresetName == "" or PresetName == "(none)" then
                PresetName = TrimText(ThemeState.PresetName);
            end
            if PresetName == "" or PresetName == "(none)" then
                PresetStateLabel:Refresh("Preset State: Export failed (no preset selected)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local OkExport, Exported = PresetManager:Export(PresetName);
            if not OkExport then
                PresetStateLabel:Refresh("Preset State: Export failed (" .. tostring(Exported) .. ")");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local OkClip = pcall(Clipboard, tostring(Exported));
            if not OkClip then
                PresetStateLabel:Refresh("Preset State: Export failed (clipboard write error)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            PresetStateLabel:Refresh("Preset State: Exported \"" .. tostring(PresetName) .. "\" to clipboard");
            PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175));
            self:NotifySuccess("Wally Settings", "Exported preset to clipboard", 2);
        end);

        SettingsWindow:Button("Import Preset (Clipboard)", function()
            if not PresetManager:IsAvailable() then
                PresetStateLabel:Refresh("Preset State: Import failed (file APIs unavailable)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local GetClipboard = (type(getclipboard) == "function" and getclipboard) or nil;
            if not GetClipboard then
                PresetStateLabel:Refresh("Preset State: Import failed (getclipboard unavailable)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local PresetName = TrimText(ThemeState.PresetName);
            if PresetName == "" then
                PresetName = "Imported";
                ThemeState.PresetName = PresetName;
                PresetNameBox.Text = PresetName;
            end

            local OkClip, ClipboardData = pcall(GetClipboard);
            if not OkClip or type(ClipboardData) ~= "string" or ClipboardData == "" then
                PresetStateLabel:Refresh("Preset State: Import failed (clipboard is empty)");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            local OkImport, Result = PresetManager:Import(PresetName, ClipboardData, true);
            if not OkImport then
                PresetStateLabel:Refresh("Preset State: Import failed (" .. tostring(Result) .. ")");
                PresetStateLabel:SetColor(Color3.fromRGB(255, 145, 145));
                return;
            end

            RefreshPresetDropdown(Result);
            PresetStateLabel:Refresh("Preset State: Imported \"" .. tostring(Result) .. "\" from clipboard");
            PresetStateLabel:SetColor(Color3.fromRGB(175, 255, 175));
            self:NotifySuccess("Wally Settings", "Imported preset from clipboard", 2);
        end);

        SyncControlsFromState();
        PresetInfoLabel:Refresh("Preset Folder: " .. tostring(PresetManager:GetFolder()));
        SchemaInfoLabel:Refresh("Preset Schema Version: " .. tostring(PresetManager:GetSchemaVersion()));

        return {
            Window = SettingsWindow;
            Theme = ThemeState;
            PresetManager = PresetManager;
            Apply = ApplyThemeState;
            Sync = SyncControlsFromState;
            RefreshPresets = RefreshPresetDropdown;
        };
    end

    function Library:SettingsWindows(Options)
        local SelfRef = self;
        local ActualOptions = Options;

        if (type(SelfRef) ~= "table")
            or (type(SelfRef.CreateWindow) ~= "function")
            or (type(SelfRef.SettingsWindow) ~= "function")
        then
            ActualOptions = SelfRef;
            SelfRef = Library;
        end

        return SelfRef:SettingsWindow(ActualOptions);
    end

    function Library:GetAutoScriptStorageKey()
        local function Sanitize(Value, Fallback)
            local Text = tostring(Value or Fallback or "Script");
            Text = Text:gsub("[%c]", ""):gsub("[\\/:*?\"<>|]", "_");
            Text = Text:gsub("%s+", "_"):gsub("_+", "_");
            Text = Text:gsub("^_+", ""):gsub("_+$", "");
            if Text == "" then
                Text = tostring(Fallback or "Script");
            end
            return Text;
        end

        local function HashText(Text)
            local Hash = 5381;
            for Index = 1, #Text do
                Hash = ((Hash * 33) + string.byte(Text, Index)) % 2147483647;
            end
            return tostring(Hash);
        end

        local Source = "";
        if type(getfenv) == "function" then
            for Level = 3, 12 do
                local OkEnv, Env = pcall(getfenv, Level);
                if OkEnv and type(Env) == "table" then
                    local ScriptObject = rawget(Env, "script");
                    if typeof(ScriptObject) == "Instance" then
                        local OkName, FullName = pcall(function()
                            return ScriptObject:GetFullName();
                        end);
                        if OkName and type(FullName) == "string" and FullName ~= "" then
                            Source = FullName;
                            break;
                        end
                        Source = tostring(ScriptObject.Name or "");
                        break;
                    end
                end
            end
        end

        if Source == "" and debug and debug.info then
            for Level = 3, 12 do
                local OkSource, SourceData = pcall(function()
                    return debug.info(Level, "s");
                end);
                if OkSource and type(SourceData) == "string" and SourceData ~= "" then
                    Source = SourceData;
                    break;
                end
            end
        end

        if Source == "" then
            Source = "UnknownScript";
        end

        local PlacePart = tostring(game.PlaceId or 0);
        local Combined = Source .. "|Place:" .. PlacePart;
        return Sanitize(Source, "Script") .. "_" .. HashText(Combined);
    end

    function Library:AttachWindowPersistence(WindowData, WindowName, Options)
        if type(WindowData) ~= "table" or (not WindowData.object) or (not WindowData.object.Parent) then
            return false, "invalid window";
        end

        local PersistEnabled = false;
        local PersistOptions = {};
        if type(Options) == "table" then
            if Options.persist == true or Options.persistwindow == true or Options.windowPersistence == true then
                PersistEnabled = true;
            end
            if type(Options.windowPersistence) == "table" then
                for Key, Value in next, Options.windowPersistence do
                    PersistOptions[Key] = Value;
                end
                PersistEnabled = (PersistOptions.enabled ~= false);
            end
        end
        if not PersistEnabled and type(self.Options) == "table" and self.Options.persistwindow == true then
            PersistEnabled = true;
        end
        if not PersistEnabled then
            return false, "disabled";
        end

        local IsFolder = (type(isfolder) == "function" and isfolder) or nil;
        local MakeFolder = (type(makefolder) == "function" and makefolder) or nil;
        local IsFile = (type(isfile) == "function" and isfile) or nil;
        local ReadFile = (type(readfile) == "function" and readfile) or nil;
        local WriteFile = (type(writefile) == "function" and writefile) or nil;
        if not (IsFolder and MakeFolder and IsFile and ReadFile and WriteFile) then
            return false, "file APIs unavailable";
        end

        local function Sanitize(Value, Fallback)
            local Text = tostring(Value or Fallback or "Window");
            Text = Text:gsub("[%c]", ""):gsub("[\\/:*?\"<>|]", "_");
            Text = Text:gsub("%s+", "_"):gsub("_+", "_");
            Text = Text:gsub("^_+", ""):gsub("_+$", "");
            if Text == "" then
                Text = tostring(Fallback or "Window");
            end
            return Text;
        end

        local RootFolder = tostring(PersistOptions.rootFolder or PersistOptions.folder or self.WindowPersistenceRootFolder or "WallyModifiedPresets");
        local ScriptFolder = tostring(PersistOptions.scriptFolder or PersistOptions.scriptKey or self.WindowPersistenceScriptKey or self:GetAutoScriptStorageKey());
        local ScriptPath = RootFolder .. "/" .. Sanitize(ScriptFolder, "Script");
        local FilePath = ScriptPath .. "/" .. tostring(PersistOptions.fileName or self.WindowPersistenceFileName or "windows.json");
        local WindowKey = tostring(PersistOptions.windowKey or WindowName or "Window");
        WindowKey = Sanitize(WindowKey, "Window");
        local PersistenceStorageKey = tostring(FilePath) .. "::" .. tostring(WindowKey);

        if WindowData._PersistenceStorageKey == PersistenceStorageKey then
            return true, FilePath;
        end

        if type(WindowData._PersistenceConnections) == "table" then
            for _, Connection in next, WindowData._PersistenceConnections do
                if Connection and Connection.Disconnect then
                    pcall(function()
                        Connection:Disconnect();
                    end);
                end
            end
            WindowData._PersistenceConnections = nil;
        end

        local function EnsureFolder()
            local OkRoot, RootExists = pcall(IsFolder, RootFolder);
            if (not OkRoot) or (not RootExists) then
                local OkMakeRoot = pcall(MakeFolder, RootFolder);
                if not OkMakeRoot then
                    return false;
                end
            end

            local OkScript, ScriptExists = pcall(IsFolder, ScriptPath);
            if (not OkScript) or (not ScriptExists) then
                local OkMakeScript = pcall(MakeFolder, ScriptPath);
                if not OkMakeScript then
                    return false;
                end
            end
            return true;
        end

        local function ReadAllState()
            if not EnsureFolder() then
                return {};
            end
            local OkFile, Exists = pcall(IsFile, FilePath);
            if (not OkFile) or (not Exists) then
                return {};
            end

            local OkRead, Content = pcall(ReadFile, FilePath);
            if not OkRead then
                return {};
            end

            local OkDecode, Data = pcall(function()
                return HttpService:JSONDecode(Content);
            end);
            if not OkDecode or type(Data) ~= "table" then
                return {};
            end
            return Data;
        end

        local function SaveAllState(Data)
            if type(Data) ~= "table" then
                return false;
            end
            if not EnsureFolder() then
                return false;
            end

            local OkEncode, Encoded = pcall(function()
                return HttpService:JSONEncode(Data);
            end);
            if not OkEncode then
                return false;
            end

            local OkWrite = pcall(WriteFile, FilePath, Encoded);
            return OkWrite == true;
        end

        local StateData = ReadAllState();
        local Existing = StateData[WindowKey];
        if type(Existing) == "table" then
            if type(Existing.position) == "table" then
                local PX = tonumber(Existing.position.xScale) or 0;
                local Pxo = tonumber(Existing.position.xOffset) or WindowData.object.Position.X.Offset;
                local PY = tonumber(Existing.position.yScale) or 0;
                local Pyo = tonumber(Existing.position.yOffset) or WindowData.object.Position.Y.Offset;
                WindowData.object.Position = UDim2.new(PX, Pxo, PY, Pyo);
            end
            if Existing.minimized ~= nil and type(WindowData.SetMinimized) == "function" then
                WindowData:SetMinimized(Existing.minimized == true, false);
            end
        end

        local SaveQueued = false;
        local function QueueSave()
            if SaveQueued then
                return;
            end
            SaveQueued = true;
            task.delay(0.15, function()
                SaveQueued = false;
                if (not WindowData.object) or (not WindowData.object.Parent) then
                    return;
                end

                local Current = ReadAllState();
                Current[WindowKey] = {
                    minimized = (type(WindowData.GetMinimized) == "function" and WindowData:GetMinimized() or false);
                    position = {
                        xScale = WindowData.object.Position.X.Scale;
                        xOffset = WindowData.object.Position.X.Offset;
                        yScale = WindowData.object.Position.Y.Scale;
                        yOffset = WindowData.object.Position.Y.Offset;
                    };
                    savedAt = os.time();
                    build = tostring(self.Build or "");
                };
                SaveAllState(Current);
            end);
        end

        local Connections = {};
        Connections[#Connections + 1] = WindowData.object:GetPropertyChangedSignal("Position"):Connect(QueueSave);
        Connections[#Connections + 1] = WindowData.object:GetAttributeChangedSignal("WallyWindowToggled"):Connect(QueueSave);
        WindowData.OnToggleChanged = function()
            QueueSave();
        end
        WindowData._PersistenceStorageKey = PersistenceStorageKey;
        WindowData._PersistenceConnections = Connections;
        QueueSave();
        return true, FilePath;
    end
		
    function Library:CreateWindow(Name, Options)
			
        if (not Library.Container) then
            local ParentGui = ResolveGuiParent();
            local RootGui = self:Create("ScreenGui", {
                self:Create('Frame', {
                    Name = 'Container';
                    Size = UDim2.new(1, -30, 1, 0);
                    Position = UDim2.new(0, 20, 0, 20);
                    BackgroundTransparency = 1;
                    Active = false;
                });
                Parent = ParentGui;
            });
            Library.RootGui = RootGui;
            table.insert(Library.CleanupInstances, RootGui);
            Library.Container = RootGui:FindFirstChild('Container');
        end
        if Options then
            local MergedOptions = {};
            for Key, Value in next, Options do
                MergedOptions[Key] = Value;
            end
			Library.Options = setmetatable(MergedOptions, {__index = Defaults});
        elseif (not Library.Options) then
			Library.Options = setmetatable({}, {__index = Defaults});
        end
		
        local WindowData = Types.Window(Name, Library.Options);
        local DragConnections = Dragger.New(WindowData.object);
        if type(DragConnections) == "table" then
            WindowData.InternalConnections = WindowData.InternalConnections or {};
            for _, Connection in next, DragConnections do
                table.insert(WindowData.InternalConnections, Connection);
            end
        end
        WindowData:BringToFront();
        self:ApplyWindowOptions();
        self:AttachWindowPersistence(WindowData, Name, Options);
        return WindowData
    end

    function Library:CreateImagePreviewWindow(Name, Options)
        if type(Name) == "table" and Options == nil then
            Options = Name;
            Name = nil;
        end

        Options = Options or {};

        local Title = tostring(Name or Options.title or "Image Preview");
        local WindowOptions = {};
        local ActiveOptions = self:GetWindowOptions();
        if type(ActiveOptions) == "table" then
            for Key, Value in next, ActiveOptions do
                WindowOptions[Key] = Value;
            end
        end
        if type(Options.windowOptions) == "table" then
            for Key, Value in next, Options.windowOptions do
                WindowOptions[Key] = Value;
            end
        end

        local function ApplyWindowOverride(Key, Value)
            if Value ~= nil then
                WindowOptions[Key] = Value;
            end
        end

        local function ResolveOption(...)
            local Values = {...};
            for Index = 1, select("#", ...) do
                if Values[Index] ~= nil then
                    return Values[Index];
                end
            end
            return nil;
        end

        ApplyWindowOverride("itemspacing", Options.windowItemSpacing);
        ApplyWindowOverride("persistwindow", ResolveOption(Options.persistwindow, Options.persistWindow, Options.persist));
        ApplyWindowOverride("windowPersistence", Options.windowPersistence);
        ApplyWindowOverride("windowPersistenceOptions", Options.windowPersistenceOptions);

        local PreviousOptions = self.Options;
        local WindowData = self:CreateWindow(Title, WindowOptions);
        if PreviousOptions then
            self.Options = PreviousOptions;
        end
        if type(WindowData) ~= "table" or (not WindowData.object) then
            return nil;
        end

        local PreviewPadding = math.max(0, math.floor((tonumber(Options.padding) or 5) + 0.5));
        local PreviewHeight = math.max(64, math.floor((tonumber(Options.previewHeight or Options.height) or 180) + 0.5));
        local CaptionHeight = math.max(16, math.floor((tonumber(Options.captionHeight) or 20) + 0.5));
        local CurrentCaption = tostring(Options.caption or "");
        local InitialImage = Options.image or Options.imageId or Options.asset or "";
        local CurrentImageWidth = tonumber(Options.previewWidth or Options.imageWidth);
        if CurrentImageWidth then
            CurrentImageWidth = math.max(40, math.floor(CurrentImageWidth + 0.5));
        end

        local function NormalizeImage(ImageValue)
            if ImageValue == nil then
                return "";
            end
            if type(ImageValue) == "number" then
                return "rbxassetid://" .. tostring(math.floor(ImageValue + 0.5));
            end
            local Text = tostring(ImageValue);
            if Text == "" then
                return "";
            end
            if string.match(Text, "^%d+$") then
                return "rbxassetid://" .. Text;
            end
            return Text;
        end

        local function ResolveScaleType(Value)
            if typeof(Value) == "EnumItem" and Value.EnumType == Enum.ScaleType then
                return Value;
            end
            local Text = string.lower(tostring(Value or ""));
            if Text == "stretch" then
                return Enum.ScaleType.Stretch;
            end
            if Text == "slice" then
                return Enum.ScaleType.Slice;
            end
            if Text == "tile" then
                return Enum.ScaleType.Tile;
            end
            if Text == "crop" then
                return Enum.ScaleType.Crop;
            end
            return Enum.ScaleType.Fit;
        end

        local PreviewRoot = self:Create("Frame", {
            Name = "ImagePreviewRoot";
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            LayoutOrder = WindowData:GetOrder();
            Parent = WindowData.container;
        });

        local PreviewFrame = self:Create("Frame", {
            Name = "ImagePreviewFrame";
            BackgroundColor3 = (typeof(Options.backgroundColor or Options.bgColor) == "Color3" and (Options.backgroundColor or Options.bgColor))
                or (WindowData.options and WindowData.options.boxcolor)
                or Library.Options.boxcolor;
            BorderColor3 = (typeof(Options.borderColor) == "Color3" and Options.borderColor)
                or (WindowData.options and WindowData.options.bordercolor)
                or Library.Options.bordercolor;
            BorderSizePixel = 1;
            ClipsDescendants = true;
            Position = UDim2.new(0, PreviewPadding, 0, PreviewPadding);
            Size = UDim2.new(1, -(PreviewPadding * 2), 0, PreviewHeight);
            Parent = PreviewRoot;
        });

        local PreviewImage = self:Create("ImageLabel", {
            Name = "Image";
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Position = UDim2.new(0, 0, 0, 0);
            Image = NormalizeImage(InitialImage);
            ScaleType = ResolveScaleType(Options.scaleType);
            ImageColor3 = (typeof(Options.imageColor or Options.color) == "Color3" and (Options.imageColor or Options.color)) or Color3.fromRGB(255, 255, 255);
            ImageTransparency = math.clamp(tonumber(Options.imageTransparency or Options.transparency) or 0, 0, 1);
            Parent = PreviewFrame;
        });

        local CaptionLabel = self:Create("TextLabel", {
            Name = "Caption";
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Text = CurrentCaption;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Center;
            Position = UDim2.new(0, PreviewPadding, 0, PreviewPadding + PreviewHeight + 4);
            Size = UDim2.new(1, -(PreviewPadding * 2), 0, CaptionHeight);
            Font = (WindowData.options and WindowData.options.font) or Library.Options.font;
            TextSize = (WindowData.options and WindowData.options.fontsize) or Library.Options.fontsize;
            TextColor3 = (WindowData.options and WindowData.options.textcolor) or Library.Options.textcolor;
            TextStrokeTransparency = (WindowData.options and WindowData.options.textstroke) or Library.Options.textstroke;
            TextStrokeColor3 = (WindowData.options and WindowData.options.strokecolor) or Library.Options.strokecolor;
            Visible = (CurrentCaption ~= "");
            Parent = PreviewRoot;
        });

        local function GetEffectivePreviewWidth()
            if CurrentImageWidth == nil then
                return nil;
            end
            local Width = math.max(40, math.floor(CurrentImageWidth + 0.5));
            local MaxWidth = math.max(40, ((WindowData:GetWidth() or 190) - (PreviewPadding * 2)));
            return math.clamp(Width, 40, MaxWidth);
        end

        local IsUpdatingLayout = false;
        local function UpdateLayout()
            if IsUpdatingLayout then
                return;
            end
            IsUpdatingLayout = true;
            if (not PreviewRoot.Parent) or (not WindowData.object) or (not WindowData.object.Parent) then
                IsUpdatingLayout = false;
                return;
            end

            local CaptionVisible = (CurrentCaption ~= "");
            local BaseOffsetY = PreviewPadding;

            local EffectiveWidth = GetEffectivePreviewWidth();
            if EffectiveWidth then
                local XOffset = math.max(PreviewPadding, math.floor(((WindowData:GetWidth() or (EffectiveWidth + (PreviewPadding * 2))) - EffectiveWidth) * 0.5));
                PreviewFrame.Size = UDim2.new(0, EffectiveWidth, 0, PreviewHeight);
                PreviewFrame.Position = UDim2.new(0, XOffset, 0, BaseOffsetY);
            else
                PreviewFrame.Size = UDim2.new(1, -(PreviewPadding * 2), 0, PreviewHeight);
                PreviewFrame.Position = UDim2.new(0, PreviewPadding, 0, BaseOffsetY);
            end

            local TotalHeight = (PreviewPadding * 2) + PreviewHeight;
            if CaptionVisible then
                CaptionLabel.Visible = true;
                CaptionLabel.Text = CurrentCaption;
                CaptionLabel.Position = UDim2.new(0, PreviewPadding, 0, BaseOffsetY + PreviewHeight + 4);
                CaptionLabel.Size = UDim2.new(1, -(PreviewPadding * 2), 0, CaptionHeight);
                TotalHeight = TotalHeight + CaptionHeight + 2;
            else
                CaptionLabel.Visible = false;
                CaptionLabel.Text = "";
            end

            PreviewRoot.Size = UDim2.new(1, 0, 0, TotalHeight);
            WindowData:Resize();
            IsUpdatingLayout = false;
        end

        table.insert(WindowData.InternalConnections, WindowData.object:GetPropertyChangedSignal("Size"):Connect(function()
            UpdateLayout();
        end));

        UpdateLayout();

        local ApiData = {
            Window = WindowData;
            Root = PreviewRoot;
            Frame = PreviewFrame;
            Image = PreviewImage;
            CaptionLabel = CaptionLabel;
            SetImage = function(_, ImageValue)
                local Normalized = NormalizeImage(ImageValue);
                PreviewImage.Image = Normalized;
                return Normalized;
            end;
            GetImage = function()
                return PreviewImage.Image;
            end;
            SetCaption = function(_, Text)
                CurrentCaption = tostring(Text or "");
                UpdateLayout();
                return CurrentCaption;
            end;
            GetCaption = function()
                return CurrentCaption;
            end;
            SetScaleType = function(_, ScaleType)
                PreviewImage.ScaleType = ResolveScaleType(ScaleType);
                return PreviewImage.ScaleType;
            end;
            GetScaleType = function()
                return PreviewImage.ScaleType;
            end;
            SetColor = function(_, ColorValue)
                if typeof(ColorValue) == "Color3" then
                    PreviewImage.ImageColor3 = ColorValue;
                end
                return PreviewImage.ImageColor3;
            end;
            GetColor = function()
                return PreviewImage.ImageColor3;
            end;
            SetTransparency = function(_, Alpha)
                PreviewImage.ImageTransparency = math.clamp(tonumber(Alpha) or PreviewImage.ImageTransparency, 0, 1);
                return PreviewImage.ImageTransparency;
            end;
            GetTransparency = function()
                return PreviewImage.ImageTransparency;
            end;
            SetBackgroundColor = function(_, ColorValue)
                if typeof(ColorValue) == "Color3" then
                    PreviewFrame.BackgroundColor3 = ColorValue;
                end
                return PreviewFrame.BackgroundColor3;
            end;
            GetBackgroundColor = function()
                return PreviewFrame.BackgroundColor3;
            end;
            SetBorderColor = function(_, ColorValue)
                if typeof(ColorValue) == "Color3" then
                    PreviewFrame.BorderColor3 = ColorValue;
                end
                return PreviewFrame.BorderColor3;
            end;
            GetBorderColor = function()
                return PreviewFrame.BorderColor3;
            end;
            SetSize = function(_, Width, Height)
                if Width ~= nil then
                    if type(Width) == "string" and string.lower(Width) == "auto" then
                        CurrentImageWidth = nil;
                    else
                        CurrentImageWidth = math.max(40, math.floor((tonumber(Width) or CurrentImageWidth or 40) + 0.5));
                    end
                end
                if Height ~= nil then
                    PreviewHeight = math.max(64, math.floor((tonumber(Height) or PreviewHeight) + 0.5));
                end
                UpdateLayout();
                return CurrentImageWidth, PreviewHeight;
            end;
            GetSize = function()
                return CurrentImageWidth, PreviewHeight;
            end;
            SetVisible = function(_, State)
                if WindowData.object and WindowData.object.Parent then
                    WindowData.object.Visible = (State == true);
                end
                return WindowData.object and WindowData.object.Visible == true;
            end;
            IsVisible = function()
                return WindowData.object and WindowData.object.Visible == true;
            end;
            SetPosition = function(_, XOffset, YOffset)
                return WindowData:SetPosition(XOffset, YOffset);
            end;
            GetPosition = function()
                return WindowData:GetPosition();
            end;
            Center = function()
                return WindowData:Center();
            end;
            BringToFront = function()
                return WindowData:BringToFront();
            end;
            Destroy = function()
                return WindowData:Destroy();
            end;
        };

        return ApiData;
    end

    function Library:ImagePreviewWindow(Name, Options)
        return self:CreateImagePreviewWindow(Name, Options);
    end

    function Library:CreateModelPreviewWindow(Name, Options)
        if type(Name) == "table" and Options == nil then
            Options = Name;
            Name = nil;
        end

        Options = Options or {};

        local Title = tostring(Name or Options.title or "Model Preview");
        local WindowOptions = {};
        local ActiveOptions = self:GetWindowOptions();
        if type(ActiveOptions) == "table" then
            for Key, Value in next, ActiveOptions do
                WindowOptions[Key] = Value;
            end
        end
        if type(Options.windowOptions) == "table" then
            for Key, Value in next, Options.windowOptions do
                WindowOptions[Key] = Value;
            end
        end

        local function ApplyWindowOverride(Key, Value)
            if Value ~= nil then
                WindowOptions[Key] = Value;
            end
        end

        local function ResolveOption(...)
            local Values = {...};
            for Index = 1, select("#", ...) do
                if Values[Index] ~= nil then
                    return Values[Index];
                end
            end
            return nil;
        end

        ApplyWindowOverride("itemspacing", Options.windowItemSpacing);
        ApplyWindowOverride("persistwindow", ResolveOption(Options.persistwindow, Options.persistWindow, Options.persist));
        ApplyWindowOverride("windowPersistence", Options.windowPersistence);
        ApplyWindowOverride("windowPersistenceOptions", Options.windowPersistenceOptions);

        local PreviousOptions = self.Options;
        local WindowData = self:CreateWindow(Title, WindowOptions);
        if PreviousOptions then
            self.Options = PreviousOptions;
        end
        if type(WindowData) ~= "table" or (not WindowData.object) then
            return nil;
        end

        local PreviewPadding = math.max(0, math.floor((tonumber(Options.padding) or 5) + 0.5));
        local PreviewHeight = math.max(96, math.floor((tonumber(Options.previewHeight or Options.height) or 220) + 0.5));
        local CaptionHeight = math.max(16, math.floor((tonumber(Options.captionHeight) or 20) + 0.5));
        local CurrentCaption = tostring(Options.caption or "");
        local CurrentPreviewWidth = tonumber(Options.previewWidth or Options.modelWidth);
        if CurrentPreviewWidth then
            CurrentPreviewWidth = math.max(60, math.floor(CurrentPreviewWidth + 0.5));
        end

        local CurrentModelSource = nil;
        local CurrentPreviewModel = nil;

        local DragEnabled = (Options.drag ~= false and Options.rotateOnDrag ~= false);
        local ZoomEnabled = (Options.zoom ~= false);
        local DragSensitivity = math.clamp(tonumber(Options.dragSensitivity or Options.sensitivity) or 0.35, 0.05, 4);
        local ZoomSensitivity = math.clamp(tonumber(Options.zoomSensitivity) or 2, 0.1, 25);

        local CurrentYaw = tonumber(Options.yaw);
        if CurrentYaw == nil then
            CurrentYaw = 35;
        end
        local CurrentPitch = math.clamp(tonumber(Options.pitch) or 15, -85, 85);

        local MinDistance = math.max(1, tonumber(Options.minDistance) or 2);
        local MaxDistance = math.max(MinDistance + 1, tonumber(Options.maxDistance) or 250);
        local CurrentDistance = tonumber(Options.distance);
        if CurrentDistance then
            CurrentDistance = math.clamp(CurrentDistance, MinDistance, MaxDistance);
        end

        local CameraFov = math.clamp(tonumber(Options.fov) or 70, 20, 100);
        local CameraNearPlane = math.clamp(tonumber(Options.nearPlaneZ) or 0.1, 0.01, 8);

        local PreviewRoot = self:Create("Frame", {
            Name = "ModelPreviewRoot";
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            LayoutOrder = WindowData:GetOrder();
            Parent = WindowData.container;
        });

        local PreviewFrame = self:Create("Frame", {
            Name = "ModelPreviewFrame";
            BackgroundColor3 = (typeof(Options.backgroundColor or Options.bgColor) == "Color3" and (Options.backgroundColor or Options.bgColor))
                or (WindowData.options and WindowData.options.boxcolor)
                or Library.Options.boxcolor;
            BorderColor3 = (typeof(Options.borderColor) == "Color3" and Options.borderColor)
                or (WindowData.options and WindowData.options.bordercolor)
                or Library.Options.bordercolor;
            BorderSizePixel = 1;
            ClipsDescendants = true;
            Position = UDim2.new(0, PreviewPadding, 0, PreviewPadding);
            Size = UDim2.new(1, -(PreviewPadding * 2), 0, PreviewHeight);
            Parent = PreviewRoot;
        });

        local Viewport = self:Create("ViewportFrame", {
            Name = "Viewport";
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            Position = UDim2.new(0, 0, 0, 0);
            Ambient = (typeof(Options.ambient) == "Color3" and Options.ambient) or Color3.fromRGB(160, 160, 160);
            LightColor = (typeof(Options.lightColor) == "Color3" and Options.lightColor) or Color3.fromRGB(255, 255, 255);
            LightDirection = (typeof(Options.lightDirection) == "Vector3" and Options.lightDirection) or Vector3.new(-1, -1, -1);
            CurrentCamera = nil;
            Parent = PreviewFrame;
        });
        Viewport.Active = true;

        local WorldModel = Instance.new("WorldModel");
        WorldModel.Name = "World";
        WorldModel.Parent = Viewport;

        local PreviewCamera = Instance.new("Camera");
        PreviewCamera.Name = "PreviewCamera";
        PreviewCamera.FieldOfView = CameraFov;
        pcall(function()
            PreviewCamera.NearPlaneZ = CameraNearPlane;
        end);
        PreviewCamera.Parent = Viewport;
        Viewport.CurrentCamera = PreviewCamera;

        local CaptionLabel = self:Create("TextLabel", {
            Name = "Caption";
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Text = CurrentCaption;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Center;
            Position = UDim2.new(0, PreviewPadding, 0, PreviewPadding + PreviewHeight + 4);
            Size = UDim2.new(1, -(PreviewPadding * 2), 0, CaptionHeight);
            Font = (WindowData.options and WindowData.options.font) or Library.Options.font;
            TextSize = (WindowData.options and WindowData.options.fontsize) or Library.Options.fontsize;
            TextColor3 = (WindowData.options and WindowData.options.textcolor) or Library.Options.textcolor;
            TextStrokeTransparency = (WindowData.options and WindowData.options.textstroke) or Library.Options.textstroke;
            TextStrokeColor3 = (WindowData.options and WindowData.options.strokecolor) or Library.Options.strokecolor;
            Visible = (CurrentCaption ~= "");
            Parent = PreviewRoot;
        });

        local function GetEffectivePreviewWidth()
            if CurrentPreviewWidth == nil then
                return nil;
            end
            local Width = math.max(60, math.floor(CurrentPreviewWidth + 0.5));
            local MaxWidth = math.max(60, ((WindowData:GetWidth() or 190) - (PreviewPadding * 2)));
            return math.clamp(Width, 60, MaxWidth);
        end

        local IsUpdatingLayout = false;
        local function UpdateLayout()
            if IsUpdatingLayout then
                return;
            end
            IsUpdatingLayout = true;
            if (not PreviewRoot.Parent) or (not WindowData.object) or (not WindowData.object.Parent) then
                IsUpdatingLayout = false;
                return;
            end

            local CaptionVisible = (CurrentCaption ~= "");
            local BaseOffsetY = PreviewPadding;

            local EffectiveWidth = GetEffectivePreviewWidth();
            if EffectiveWidth then
                local XOffset = math.max(PreviewPadding, math.floor(((WindowData:GetWidth() or (EffectiveWidth + (PreviewPadding * 2))) - EffectiveWidth) * 0.5));
                PreviewFrame.Size = UDim2.new(0, EffectiveWidth, 0, PreviewHeight);
                PreviewFrame.Position = UDim2.new(0, XOffset, 0, BaseOffsetY);
            else
                PreviewFrame.Size = UDim2.new(1, -(PreviewPadding * 2), 0, PreviewHeight);
                PreviewFrame.Position = UDim2.new(0, PreviewPadding, 0, BaseOffsetY);
            end

            local TotalHeight = (PreviewPadding * 2) + PreviewHeight;
            if CaptionVisible then
                CaptionLabel.Visible = true;
                CaptionLabel.Text = CurrentCaption;
                CaptionLabel.Position = UDim2.new(0, PreviewPadding, 0, BaseOffsetY + PreviewHeight + 4);
                CaptionLabel.Size = UDim2.new(1, -(PreviewPadding * 2), 0, CaptionHeight);
                TotalHeight = TotalHeight + CaptionHeight + 2;
            else
                CaptionLabel.Visible = false;
                CaptionLabel.Text = "";
            end

            PreviewRoot.Size = UDim2.new(1, 0, 0, TotalHeight);
            WindowData:Resize();
            IsUpdatingLayout = false;
        end

        local function ResolveModelSource(Value)
            if typeof(Value) == "Instance" then
                return Value;
            end

            if type(Value) == "string" then
                local Query = tostring(Value);
                if Query == "" then
                    return nil;
                end
                local Found = Workspace:FindFirstChild(Query, true);
                if typeof(Found) == "Instance" then
                    return Found;
                end
            end

            return nil;
        end

        local function DestroyCurrentModel()
            if CurrentPreviewModel and CurrentPreviewModel.Parent then
                pcall(function()
                    CurrentPreviewModel:Destroy();
                end);
            end
            CurrentPreviewModel = nil;
            CurrentModelSource = nil;
        end

        local function CloneSourceForPreview(SourceInstance)
            if typeof(SourceInstance) ~= "Instance" then
                return nil, "source must be an Instance";
            end

            local Changed = {};
            local function EnsureArchivable(Target)
                if typeof(Target) ~= "Instance" then
                    return;
                end

                local OkRead, OldValue = pcall(function()
                    return Target.Archivable;
                end);
                if (not OkRead) or OldValue == true then
                    return;
                end

                local OkSet = pcall(function()
                    Target.Archivable = true;
                end);
                if OkSet then
                    table.insert(Changed, {
                        Instance = Target;
                        OldValue = OldValue;
                    });
                end
            end

            EnsureArchivable(SourceInstance);
            for _, Descendant in next, SourceInstance:GetDescendants() do
                EnsureArchivable(Descendant);
            end

            local OkClone, CloneResult = pcall(function()
                return SourceInstance:Clone();
            end);

            for Index = #Changed, 1, -1 do
                local Entry = Changed[Index];
                if Entry and Entry.Instance then
                    pcall(function()
                        Entry.Instance.Archivable = (Entry.OldValue == true);
                    end);
                end
            end

            if not OkClone then
                return nil, "failed to clone source: " .. tostring(CloneResult);
            end

            return CloneResult;
        end

        local function BuildPreviewModel(SourceInstance)
            if typeof(SourceInstance) ~= "Instance" then
                return nil, "source must be an Instance";
            end

            local SourceClone, CloneError = CloneSourceForPreview(SourceInstance);
            if not SourceClone then
                return nil, CloneError or "failed to clone source";
            end

            local RootModel = Instance.new("Model");
            RootModel.Name = "PreviewModel";
            SourceClone.Parent = RootModel;

            local PartCount = 0;
            for _, Descendant in next, RootModel:GetDescendants() do
                if Descendant:IsA("BasePart") then
                    PartCount = PartCount + 1;
                    pcall(function()
                        Descendant.Anchored = true;
                        Descendant.CanCollide = false;
                        Descendant.CanTouch = false;
                        Descendant.CanQuery = false;
                    end);
                elseif Descendant:IsA("Script") or Descendant:IsA("LocalScript") then
                    pcall(function()
                        Descendant.Disabled = true;
                    end);
                end
            end

            if PartCount <= 0 then
                RootModel:Destroy();
                return nil, "model has no BasePart descendants";
            end

            return RootModel;
        end

        local function GetModelBounds(ModelInstance)
            if typeof(ModelInstance) ~= "Instance" or (not ModelInstance.Parent) then
                return CFrame.new(), Vector3.new(4, 4, 4);
            end

            local OkBounds, BoundsCf, BoundsSize = pcall(function()
                return ModelInstance:GetBoundingBox();
            end);
            if OkBounds and typeof(BoundsCf) == "CFrame" and typeof(BoundsSize) == "Vector3" then
                return BoundsCf, BoundsSize;
            end

            return CFrame.new(), Vector3.new(4, 4, 4);
        end

        local function CenterModelAtOrigin(ModelInstance)
            local BoundsCf = GetModelBounds(ModelInstance);
            local OkPivot, PivotCf = pcall(function()
                return ModelInstance:GetPivot();
            end);
            if not OkPivot or typeof(PivotCf) ~= "CFrame" then
                return GetModelBounds(ModelInstance);
            end

            local Shift = CFrame.new(-BoundsCf.Position);
            pcall(function()
                ModelInstance:PivotTo(Shift * PivotCf);
            end);

            return GetModelBounds(ModelInstance);
        end

        local function ComputeDistanceForSize(Size)
            local MaxAxis = math.max(Size.X, Size.Y, Size.Z);
            local Radius = math.max(MaxAxis * 0.5, 0.5);
            local HalfFov = math.rad(math.clamp(PreviewCamera.FieldOfView * 0.5, 5, 85));
            local FitDistance = Radius / math.tan(HalfFov);
            local PaddingDistance = Radius * 1.45;
            return math.clamp(FitDistance + PaddingDistance, MinDistance, MaxDistance);
        end

        local function UpdateCamera()
            local Distance = math.clamp(tonumber(CurrentDistance) or MinDistance, MinDistance, MaxDistance);
            CurrentDistance = Distance;
            CurrentPitch = math.clamp(tonumber(CurrentPitch) or 0, -85, 85);
            CurrentYaw = tonumber(CurrentYaw) or 0;

            local Rotation = CFrame.fromEulerAnglesYXZ(math.rad(CurrentPitch), math.rad(CurrentYaw), 0);
            local Offset = Rotation:VectorToWorldSpace(Vector3.new(0, 0, Distance));
            PreviewCamera.CFrame = CFrame.lookAt(Offset, Vector3.new(0, 0, 0));
        end

        local function SetModelSource(SourceValue)
            local Resolved = ResolveModelSource(SourceValue);
            if not Resolved then
                return false, "model source not found";
            end

            local NewPreviewModel, BuildError = BuildPreviewModel(Resolved);
            if not NewPreviewModel then
                return false, BuildError;
            end

            DestroyCurrentModel();
            CurrentPreviewModel = NewPreviewModel;
            CurrentModelSource = Resolved;
            CurrentPreviewModel.Parent = WorldModel;

            local _, BoundsSize = CenterModelAtOrigin(CurrentPreviewModel);
            if CurrentDistance == nil or Options.keepDistanceOnModelChange ~= true then
                CurrentDistance = ComputeDistanceForSize(BoundsSize);
            else
                CurrentDistance = math.clamp(CurrentDistance, MinDistance, MaxDistance);
            end
            UpdateCamera();
            return true;
        end

        local Dragging = false;
        local LastPointer = nil;

        table.insert(WindowData.InternalConnections, Viewport.InputBegan:Connect(function(Input)
            if DragEnabled and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                Dragging = true;
                LastPointer = Input.Position;
            end
        end));

        table.insert(WindowData.InternalConnections, Viewport.InputChanged:Connect(function(Input)
            if ZoomEnabled and Input.UserInputType == Enum.UserInputType.MouseWheel then
                local WheelDelta = tonumber(Input.Position.Z) or 0;
                if WheelDelta ~= 0 then
                    CurrentDistance = math.clamp((tonumber(CurrentDistance) or MinDistance) - (WheelDelta * ZoomSensitivity), MinDistance, MaxDistance);
                    UpdateCamera();
                end
            end
        end));

        table.insert(WindowData.InternalConnections, UserInputService.InputChanged:Connect(function(Input)
            if not Dragging then
                return;
            end
            if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
                return;
            end
            if typeof(Input.Position) ~= "Vector3" then
                return;
            end

            if typeof(LastPointer) ~= "Vector3" then
                LastPointer = Input.Position;
                return;
            end

            local Delta = Input.Position - LastPointer;
            LastPointer = Input.Position;
            CurrentYaw = (tonumber(CurrentYaw) or 0) - (Delta.X * DragSensitivity);
            CurrentPitch = math.clamp((tonumber(CurrentPitch) or 0) - (Delta.Y * DragSensitivity), -85, 85);
            UpdateCamera();
        end));

        table.insert(WindowData.InternalConnections, UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false;
                LastPointer = nil;
            end
        end));

        table.insert(WindowData.InternalConnections, WindowData.object:GetPropertyChangedSignal("Size"):Connect(function()
            UpdateLayout();
        end));

        UpdateLayout();
        UpdateCamera();

        local InitialModel = ResolveOption(Options.model, Options.instance, Options.source, Options.target);
        if InitialModel ~= nil then
            local OkSet, ErrorMessage = SetModelSource(InitialModel);
            if (not OkSet) and Library.BindDebug then
                warn("[Wally Modified][ModelPreview] Failed to set initial model: " .. tostring(ErrorMessage));
            end
        end

        local ApiData = {
            Window = WindowData;
            Root = PreviewRoot;
            Frame = PreviewFrame;
            Viewport = Viewport;
            World = WorldModel;
            Camera = PreviewCamera;
            CaptionLabel = CaptionLabel;
            SetModel = function(_, SourceValue)
                return SetModelSource(SourceValue);
            end;
            GetModel = function()
                return CurrentModelSource;
            end;
            ClearModel = function()
                DestroyCurrentModel();
                UpdateCamera();
                return true;
            end;
            SetCaption = function(_, Text)
                CurrentCaption = tostring(Text or "");
                UpdateLayout();
                return CurrentCaption;
            end;
            GetCaption = function()
                return CurrentCaption;
            end;
            SetRotation = function(_, Yaw, Pitch)
                if Yaw ~= nil then
                    CurrentYaw = tonumber(Yaw) or CurrentYaw;
                end
                if Pitch ~= nil then
                    CurrentPitch = math.clamp(tonumber(Pitch) or CurrentPitch, -85, 85);
                end
                UpdateCamera();
                return CurrentYaw, CurrentPitch;
            end;
            GetRotation = function()
                return CurrentYaw, CurrentPitch;
            end;
            SetZoom = function(_, Distance)
                CurrentDistance = math.clamp(tonumber(Distance) or CurrentDistance or MinDistance, MinDistance, MaxDistance);
                UpdateCamera();
                return CurrentDistance;
            end;
            GetZoom = function()
                return CurrentDistance;
            end;
            SetFov = function(_, NewFov)
                local Fov = math.clamp(tonumber(NewFov) or PreviewCamera.FieldOfView, 20, 100);
                PreviewCamera.FieldOfView = Fov;
                if CurrentPreviewModel and CurrentPreviewModel.Parent and Options.keepDistanceOnModelChange ~= true then
                    local _, Size = GetModelBounds(CurrentPreviewModel);
                    CurrentDistance = ComputeDistanceForSize(Size);
                end
                UpdateCamera();
                return PreviewCamera.FieldOfView;
            end;
            GetFov = function()
                return PreviewCamera.FieldOfView;
            end;
            SetDragEnabled = function(_, State)
                DragEnabled = (State == true);
                return DragEnabled;
            end;
            GetDragEnabled = function()
                return DragEnabled;
            end;
            SetZoomEnabled = function(_, State)
                ZoomEnabled = (State == true);
                return ZoomEnabled;
            end;
            GetZoomEnabled = function()
                return ZoomEnabled;
            end;
            SetBackgroundColor = function(_, ColorValue)
                if typeof(ColorValue) == "Color3" then
                    PreviewFrame.BackgroundColor3 = ColorValue;
                end
                return PreviewFrame.BackgroundColor3;
            end;
            GetBackgroundColor = function()
                return PreviewFrame.BackgroundColor3;
            end;
            SetBorderColor = function(_, ColorValue)
                if typeof(ColorValue) == "Color3" then
                    PreviewFrame.BorderColor3 = ColorValue;
                end
                return PreviewFrame.BorderColor3;
            end;
            GetBorderColor = function()
                return PreviewFrame.BorderColor3;
            end;
            SetSize = function(_, Width, Height)
                if Width ~= nil then
                    if type(Width) == "string" and string.lower(Width) == "auto" then
                        CurrentPreviewWidth = nil;
                    else
                        CurrentPreviewWidth = math.max(60, math.floor((tonumber(Width) or CurrentPreviewWidth or 60) + 0.5));
                    end
                end
                if Height ~= nil then
                    PreviewHeight = math.max(96, math.floor((tonumber(Height) or PreviewHeight) + 0.5));
                end
                UpdateLayout();
                return CurrentPreviewWidth, PreviewHeight;
            end;
            GetSize = function()
                return CurrentPreviewWidth, PreviewHeight;
            end;
            SetVisible = function(_, State)
                if WindowData.object and WindowData.object.Parent then
                    WindowData.object.Visible = (State == true);
                end
                return WindowData.object and WindowData.object.Visible == true;
            end;
            IsVisible = function()
                return WindowData.object and WindowData.object.Visible == true;
            end;
            SetPosition = function(_, XOffset, YOffset)
                return WindowData:SetPosition(XOffset, YOffset);
            end;
            GetPosition = function()
                return WindowData:GetPosition();
            end;
            Center = function()
                return WindowData:Center();
            end;
            BringToFront = function()
                return WindowData:BringToFront();
            end;
            Destroy = function()
                return WindowData:Destroy();
            end;
        };

        return ApiData;
    end

    function Library:ModelPreviewWindow(Name, Options)
        return self:CreateModelPreviewWindow(Name, Options);
    end

    function Library:Destroy()
        if self._Destroying == true then
            return false, "destroy already in progress";
        end
        self._Destroying = true;

        if type(self.ActiveColorPopupController) == "function" then
            pcall(self.ActiveColorPopupController, false, true);
        end
        self.ActiveColorPopup = nil;
        self.ActiveColorPopupController = nil;

        local WindowSnapshot = {};
        for _, WindowData in next, self.Windows or {} do
            table.insert(WindowSnapshot, WindowData);
        end
        for _, WindowData in next, WindowSnapshot do
            if type(WindowData) == "table" and type(WindowData.Destroy) == "function" then
                pcall(function()
                    WindowData:Destroy();
                end);
            elseif type(WindowData) == "table" and WindowData.object and WindowData.object.Parent then
                pcall(function()
                    WindowData.object:Destroy();
                end);
            end
        end

        local function DisconnectAll(ConnectionTable)
            if type(ConnectionTable) ~= "table" then
                return;
            end
            for _, Connection in next, ConnectionTable do
                if Connection and Connection.Disconnect then
                    pcall(function()
                        Connection:Disconnect();
                    end);
                end
            end
            table.clear(ConnectionTable);
        end

        DisconnectAll(self.InternalConnections);
        DisconnectAll(self.DependencyConnections);
        self.GlobalToggleConnection = nil;
        self.BindInputBeganConnection = nil;
        self.BindInputEndedConnection = nil;
        self.RainbowConnection = nil;

        local Destroyed = {};
        local function TryDestroy(InstanceObject)
            if typeof(InstanceObject) ~= "Instance" then
                return;
            end
            if Destroyed[InstanceObject] then
                return;
            end
            Destroyed[InstanceObject] = true;
            if InstanceObject.Parent then
                pcall(function()
                    InstanceObject:Destroy();
                end);
            end
        end

        if type(self.TooltipBindings) == "table" then
            for _, Entry in next, self.TooltipBindings do
                if type(Entry) == "table" then
                    for _, Connection in next, Entry do
                        if Connection and Connection.Disconnect then
                            pcall(function()
                                Connection:Disconnect();
                            end);
                        end
                    end
                end
            end
        end

        TryDestroy(self.RootGui);
        TryDestroy(self.TooltipGui);
        TryDestroy(self.NotificationGui);
        if type(self.CleanupInstances) == "table" then
            for _, InstanceObject in next, self.CleanupInstances do
                TryDestroy(InstanceObject);
            end
            table.clear(self.CleanupInstances);
        end

        self.RootGui = nil;
        self.Container = nil;
        self.TooltipGui = nil;
        self.TooltipFrame = nil;
        self.TooltipTextLabel = nil;
        self.TooltipBindings = nil;
        self.NotificationGui = nil;
        self.NotificationContainer = nil;
        self.NotificationList = nil;
        self.Notifications = {};

        self.Queue = {};
        self.Windows = {};
        self.Callbacks = {};
        self.RainbowTable = {};
        self.Binds = {};
        self.ToggleRegistry = {};
        self.FlagLocations = {};
        self.FlagLocationLookup = {};
        self.RegisteredFlags = {};
        self.FlagControllers = {};
        self.ControlApisByRoot = {};
        self.ControlApisByFlag = {};
        self.DependencyControls = {};
        self.FlagChangeListeners = {};
        self.FlagChangeAnyListeners = {};
        self.Binding = false;
        self.Count = 0;
        self.Toggled = true;
        self.Options = setmetatable({}, {__index = Defaults});
        self._Destroying = false;
        return true;
    end

    Library.Options = setmetatable({}, {__index = Defaults})

    local RainbowHue = 0;
    Library.RainbowConnection = RunService.RenderStepped:Connect(function(dt)
        if #Library.RainbowTable == 0 then
            return;
        end

        RainbowHue = (RainbowHue + (dt * 0.18)) % 1;
        for Index = #Library.RainbowTable, 1, -1 do
            local Obj = Library.RainbowTable[Index];
            if Obj and Obj.Parent then
                Obj.BackgroundColor3 = Color3.fromHSV(RainbowHue, 1, 1);
            else
                table.remove(Library.RainbowTable, Index);
            end
        end
    end);
    table.insert(Library.InternalConnections, Library.RainbowConnection);

    local function NormalizeRuntimeBind(Bind)
        local function GetEnumItemSafe(EnumType, Name)
            if type(Name) ~= "string" or Name == "" then
                return nil;
            end

            for _, EnumItem in next, EnumType:GetEnumItems() do
                if EnumItem.Name == Name then
                    return EnumItem;
                end
            end
            return nil;
        end

        local KeyType = typeof(Bind);
        if KeyType == "InputObject" then
            if Bind.UserInputType == Enum.UserInputType.Keyboard or Bind.UserInputType == Enum.UserInputType.TextInput then
                return Bind.KeyCode;
            end
            return Bind.UserInputType;
        end

        if KeyType == "EnumItem" then
            if Bind.EnumType == Enum.KeyCode or Bind.EnumType == Enum.UserInputType then
                return Bind;
            end
            return nil;
        end

        local KeyString = tostring(Bind):gsub("^Enum%.KeyCode%.", ""):gsub("^Enum%.UserInputType%.", "");
        local KeyCode = GetEnumItemSafe(Enum.KeyCode, KeyString);
        if KeyCode then
            return KeyCode;
        end

        return GetEnumItemSafe(Enum.UserInputType, KeyString);
    end

    local function IsReallyPressed(Bind, Inp)
        local NormalizedBind = NormalizeRuntimeBind(Bind);
        if not NormalizedBind then
            return false;
        end

        if NormalizedBind.EnumType == Enum.UserInputType then
            return Inp.UserInputType == NormalizedBind;
        end

        return Inp.KeyCode == NormalizedBind;
    end

    local function NormalizeBindMode(Mode)
        local ModeText = string.lower(tostring(Mode or "press"));
        if ModeText == "toggle" then
            return "toggle";
        end
        if ModeText == "hold" or ModeText == "held" then
            return "hold";
        end
        if ModeText == "always" then
            return "always";
        end
        return "press";
    end

    local function HandleBindPress(FlagName, BindsData, Input)
        local GetMode = BindsData and BindsData.GetMode;
        local Mode = NormalizeBindMode(type(GetMode) == "function" and GetMode() or BindsData.Mode);
        local Callback = BindsData and BindsData.Callback;
        local ApiData = BindsData and BindsData.Api;
        if type(Callback) ~= "function" then
            return;
        end
        if Library:AreCallbacksSuspended() then
            return;
        end

        if Mode == "always" then
            return;
        end

        if Mode == "toggle" then
            local GetState = BindsData.GetState;
            local SetState = BindsData.SetState;
            local NewState = true;
            if type(GetState) == "function" then
                NewState = not (GetState() == true);
            end
            if type(SetState) == "function" then
                SetState(BindsData, NewState, true);
            else
                Callback(NewState, Input, "toggle_press");
                if ApiData and type(ApiData.EmitChanged) == "function" then
                    ApiData:EmitChanged(NewState, Input, "toggle_press");
                end
            end
            return;
        end

        if Mode == "hold" then
            local GetState = BindsData.GetState;
            local SetState = BindsData.SetState;
            local IsHeld = (type(GetState) == "function" and GetState() == true);
            if not IsHeld then
                if type(SetState) == "function" then
                    SetState(BindsData, true, true);
                else
                    Callback(true, Input, "hold_start");
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(true, Input, "hold_start");
                    end
                end
            end
            return;
        end

        Callback(Input, nil, "press");
        if ApiData and type(ApiData.EmitChanged) == "function" then
            ApiData:EmitChanged(Input, nil, "press");
        end
    end

    local function HandleBindRelease(BindsData, Input)
        local GetMode = BindsData and BindsData.GetMode;
        local Mode = NormalizeBindMode(type(GetMode) == "function" and GetMode() or BindsData.Mode);
        if Mode ~= "hold" then
            return;
        end

        local Callback = BindsData and BindsData.Callback;
        local ApiData = BindsData and BindsData.Api;
        if type(Callback) ~= "function" then
            return;
        end
        if Library:AreCallbacksSuspended() then
            return;
        end

        local GetState = BindsData.GetState;
        local SetState = BindsData.SetState;
        local IsHeld = (type(GetState) == "function" and GetState() == true);
        if IsHeld then
            if type(SetState) == "function" then
                SetState(BindsData, false, true);
            else
                Callback(false, Input, "hold_end");
                if ApiData and type(ApiData.EmitChanged) == "function" then
                    ApiData:EmitChanged(false, Input, "hold_end");
                end
            end
        end
    end

    Library.BindInputBeganConnection = UserInputService.InputBegan:Connect(function(Input, Gpe)
        if Library.Binding or Gpe then
            return;
        end

        for Index, BindsData in next, Library.Binds do
            local RealBinding = BindsData.Location and BindsData.Location[Index];
            if RealBinding and IsReallyPressed(RealBinding, Input) then
                if Library.BindDebug then
                    local BindingName = "Unknown";
                    if typeof(RealBinding) == "EnumItem" then
                        BindingName = RealBinding.Name;
                    else
                        BindingName = tostring(RealBinding);
                    end
                    warn("[Wally Modified][BindDebug][" .. tostring(Index) .. "] Triggered by " .. tostring(Input.KeyCode.Name) .. " (bound to " .. tostring(BindingName) .. ")");
                end
                HandleBindPress(Index, BindsData, Input);
            end
        end
    end);
    table.insert(Library.InternalConnections, Library.BindInputBeganConnection);

    Library.BindInputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
        if Library.Binding then
            return;
        end

        for Index, BindsData in next, Library.Binds do
            local RealBinding = BindsData.Location and BindsData.Location[Index];
            if RealBinding and IsReallyPressed(RealBinding, Input) then
                HandleBindRelease(BindsData, Input);
            end
        end
    end);
    table.insert(Library.InternalConnections, Library.BindInputEndedConnection);
end

return Library
