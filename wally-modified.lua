local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");
local CoreGui = game:GetService("CoreGui");
local HttpService = game:GetService("HttpService");
local TextService = game:GetService("TextService");
local Workspace = game:GetService("Workspace");

local Library = {
    Count = 0,
    Queue = {},
    Windows = {},
    Callbacks = {},
    RainbowTable = {},
    Toggled = true,
    Binds = {},
    ToggleRegistry = {},
    FlagLocations = {},
    FlagLocationLookup = {},
    RegisteredFlags = {},
    FlagControllers = {},
    Build = "2026-03-06.58",
    BindDebug = false,
    CallbackSuspendDepth = 0,
    BatchUpdateDepth = 0,
    InternalConnections = {},
    CleanupInstances = {},
    FlagChangeListeners = {},
    FlagChangeAnyListeners = {},
    ZIndexCounter = 30
};
local Defaults; do
    local Dragger = {}; do
        function Dragger.New(Frame)
            Frame.Active = true;

            local Dragging = false;
            local DragInput;
            local DragStart;
            local StartPos;
            local Connections = {};

            Connections[#Connections + 1] = Frame.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = true;
                    DragStart = Input.Position;
                    StartPos = Frame.Position;

                    Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false;
                        end
                    end)
                end
            end)

            Connections[#Connections + 1] = Frame.InputChanged:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement then
                    DragInput = Input;
                end
            end)

            Connections[#Connections + 1] = UserInputService.InputChanged:Connect(function(Input)
                if Dragging and Input == DragInput then
                    local Delta = Input.Position - DragStart;
                    Frame.Position = UDim2.new(
                        StartPos.X.Scale,
                        StartPos.X.Offset + Delta.X,
                        StartPos.Y.Scale,
                        StartPos.Y.Offset + Delta.Y
                    );
                end
            end)

            return Connections;
        end

        Library.GlobalToggleConnection = UserInputService.InputBegan:Connect(function(Key, Gpe)
            if (not Gpe) then
                if Key.KeyCode == Enum.KeyCode.RightControl then
                    Library.Toggled = not Library.Toggled;
                    for _, Data in next, Library.Queue do
                        local Position = (Library.Toggled and Data.Position or UDim2.new(-1, 0, -0.5,0))
                        if Data.Window and Data.Window.Parent then
                            Data.Window:TweenPosition(Position, (Library.Toggled and 'Out' or 'In'), 'Quad', 0.15, true)
                        end
                    end
                end
            end
        end);
        table.insert(Library.InternalConnections, Library.GlobalToggleConnection);
    end

    local function ResolveGuiParent()
        local ParentGui = CoreGui;
        if type(gethui) == "function" then
            local Ok, Gui = pcall(gethui);
            if Ok and Gui then
                ParentGui = Gui;
            end
        end
        return ParentGui;
    end
    
	    local Types = {}; do
	        Types.__index = Types;
	        function Types.Window(Name, Options)
	            Library.Count = Library.Count + 1
	            local ItemSpacing = math.clamp(
	                math.floor((tonumber(Options.itemspacing or Options.methodspacing or Options.controlspacing or Options.spacing) or 0) + 0.5),
	                0,
	                40
	            );
                local WindowWidth = 190;
                local WindowStride = 200;
                local UseResizeGrip = false;
	            local NewWindow = Library:Create('Frame', {
                Name = Name;
                Size = UDim2.new(0, WindowWidth, 0, 30);
                BackgroundColor3 = Options.topcolor;
                BorderSizePixel = 0;
                Parent = Library.Container;
                Position = UDim2.new(0, (15 + (WindowStride * Library.Count) - WindowStride), 0, 0);
                ZIndex = 3;
                Library:Create('TextLabel', {
                    Name = "window_title";
                    Text = Name;
                    Size = UDim2.new(1, -70, 1, 0);
                    Position = UDim2.new(0, 5, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Enum.Font.Code;
                    TextSize = Options.titlesize;
                    Font = Options.titlefont;
                    TextColor3 = Options.titletextcolor;
                    TextStrokeTransparency = Library.Options.titlestroke;
                    TextStrokeColor3 = Library.Options.titlestrokecolor;
                    TextScaled = true;
                    TextWrapped = false;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    ZIndex = 3;
                });
                Library:Create("TextButton", {
                    Size = UDim2.new(0, 30, 0, 30);
                    Position = UDim2.new(1, -35, 0, 0);
                    BackgroundTransparency = 1;
                    Text = "-";
                    TextSize = Options.titlesize;
                    Font = Options.titlefont;
                    Name = 'window_toggle';
                    TextColor3 = Options.titletextcolor;
                    TextStrokeTransparency = Library.Options.titlestroke;
                    TextStrokeColor3 = Library.Options.titlestrokecolor;
                    TextScaled = false;
                    ZIndex = 3;
                });
                Library:Create("Frame", {
                    Name = 'Underline';
                    Size = UDim2.new(1, 0, 0, 2);
                    Position = UDim2.new(0, 0, 1, -2);
                    BackgroundColor3 = (Options.underlinecolor ~= "rainbow" and Options.underlinecolor or Color3.new());
                    BorderSizePixel = 0;
                    ZIndex = 3;
                });
                Library:Create('Frame', {
                    Name = 'ContainerData';
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = Options.bgcolor;
                    ClipsDescendants = false;
	                    Library:Create('UIListLayout', {
	                        Name = 'List';
	                        SortOrder = Enum.SortOrder.LayoutOrder;
	                        Padding = UDim.new(0, ItemSpacing);
	                    })
	                });
	            })

            local ContainerData = NewWindow:FindFirstChild("ContainerData");
            local ListLayout = ContainerData and ContainerData:FindFirstChild("List");
            local WindowToggle = NewWindow:FindFirstChild("window_toggle");
            local function GetContentHeight()
                if ListLayout then
                    return math.max(ListLayout.AbsoluteContentSize.Y + 5, 0);
                end

                local Y = 0;
                for _, Child in next, ContainerData:GetChildren() do
                    if (not Child:IsA("UIListLayout")) then
                        Y = Y + Child.AbsoluteSize.Y;
                    end
                end
                return Y + 5;
            end
            
            if Options.underlinecolor == "rainbow" then
                table.insert(Library.RainbowTable, NewWindow:FindFirstChild('Underline'))
            end

            local WindowData = setmetatable({
                Count = 0;
                object = NewWindow;
                ContainerData = ContainerData;
                container = ContainerData;
                ListData = ListLayout;
                list = ListLayout;
                options = Options;
                Options = Options;
                toggled = true;
                flags   = {};
                OrderData = 0;
                order = 0;
                AutoFlagPrefix = tostring(Name or "Window") .. "_" .. tostring(Library.Count);
                Width = WindowWidth;
                MinWidth = WindowWidth;
                MaxWidth = WindowWidth;
                Resizable = false;
                ResizeGripEnabled = false;
                AutoWidth = false;
                AutoWidthPadding = 0;
                InternalConnections = {};
                PopupInstances = {};

            }, Types)

            local function MeasureTextWidth(TextObject)
                if (not TextObject) or (not TextObject.Parent) then
                    return 0;
                end

                local TextValue = tostring(TextObject.Text or "");
                if TextValue == "" then
                    return 0;
                end

                local TextSize = tonumber(TextObject.TextSize) or tonumber(WindowData.options and WindowData.options.fontsize) or 17;
                if TextObject.TextScaled then
                    TextSize = math.max(TextSize, tonumber(WindowData.options and WindowData.options.fontsize) or 17);
                end

                local OkBounds, Bounds = pcall(function()
                    return TextService:GetTextSize(TextValue, math.max(1, math.floor(TextSize + 0.5)), TextObject.Font, Vector2.new(4096, 512));
                end);
                if OkBounds and typeof(Bounds) == "Vector2" then
                    return Bounds.X;
                end
                return 0;
            end

            local ResizeGrip;
            local function UpdateQueueStoredPosition()
                for _, QueueData in next, Library.Queue do
                    if QueueData and QueueData.Window == NewWindow then
                        QueueData.Position = NewWindow.Position;
                        break;
                    end
                end
            end

            function WindowData:SetWidth(NewWidth)
                local Width = WindowWidth;
                self.Width = Width;
                if self.object and self.object.Parent then
                    self.object.Size = UDim2.new(0, Width, self.object.Size.Y.Scale, self.object.Size.Y.Offset);
                end
                if type(self.RefreshTabHostSize) == "function" then
                    self:RefreshTabHostSize();
                end
                return self.Width;
            end

            function WindowData:GetWidth()
                if self.object and self.object.Parent then
                    return tonumber(self.object.Size.X.Offset) or WindowWidth;
                end
                return WindowWidth;
            end

            function WindowData:SetAutoWidth(State, RefreshNow)
                self.AutoWidth = false;
                return false;
            end

            function WindowData:GetAutoWidth()
                return false;
            end

            function WindowData:RefreshAutoWidth(Force)
                return self:GetWidth();
            end

            function WindowData:SetPosition(XOffset, YOffset)
                if (not self.object) or (not self.object.Parent) then
                    return nil;
                end

                if typeof(XOffset) == "UDim2" then
                    self.object.Position = XOffset;
                    UpdateQueueStoredPosition();
                    return self.object.Position;
                end

                local PositionData = self.object.Position;
                local X = math.floor((tonumber(XOffset) or PositionData.X.Offset) + 0.5);
                local Y = math.floor((tonumber(YOffset) or PositionData.Y.Offset) + 0.5);
                self.object.Position = UDim2.new(PositionData.X.Scale, X, PositionData.Y.Scale, Y);
                UpdateQueueStoredPosition();
                return self.object.Position;
            end

            function WindowData:GetPosition()
                if (not self.object) or (not self.object.Parent) then
                    return nil;
                end
                return self.object.Position;
            end

            function WindowData:Center()
                if (not self.object) or (not self.object.Parent) then
                    return nil;
                end

                local ParentGuiObject = self.object.Parent;
                local ParentSize = ParentGuiObject.AbsoluteSize;
                local TargetWidth = self:GetWidth();
                local TargetHeight = 30 + ((self.container and self.container.Size and self.container.Size.Y.Offset) or 0);

                local NewX = math.floor(((ParentSize.X - TargetWidth) * 0.5) + 0.5);
                local NewY = math.floor(((ParentSize.Y - TargetHeight) * 0.5) + 0.5);
                return self:SetPosition(NewX, NewY);
            end

            function WindowData:BringToFront()
                if (not self.object) or (not self.object.Parent) then
                    return false;
                end

                local ParentObject = self.object.Parent;
                local CurrentPosition = self.object.Position;
                local CurrentSize = self.object.Size;
                self.object.Parent = nil;
                self.object.Parent = ParentObject;
                self.object.Position = CurrentPosition;
                self.object.Size = CurrentSize;
                return true;
            end

            table.insert(Library.Queue, {
                Window = WindowData.object;
                Position = WindowData.object.Position;
            })
            table.insert(Library.Windows, WindowData);

            local function UpdateResizeGripPosition()
                if not ResizeGrip or (not ResizeGrip.Parent) then
                    return;
                end
                local ContentHeight = 0;
                if WindowData.toggled and WindowData.container and WindowData.container.Parent then
                    ContentHeight = WindowData.container.Size.Y.Offset;
                end
                ResizeGrip.Position = UDim2.new(1, -10, 0, 20 + ContentHeight);
                ResizeGrip.Visible = (WindowData.Resizable == true and WindowData.toggled);
            end
            WindowData.UpdateResizeGripPosition = UpdateResizeGripPosition;

            if UseResizeGrip then
                ResizeGrip = Library:Create("TextButton", {
                    Name = "ResizeGrip";
                    Text = "";
                    AutoButtonColor = false;
                    Size = UDim2.new(0, 10, 0, 10);
                    Position = UDim2.new(1, -10, 0, 20);
                    BackgroundColor3 = Options.bordercolor;
                    BorderColor3 = Options.strokecolor;
                    ZIndex = 6;
                    Parent = NewWindow;
                });

                local Resizing = false;
                local ResizeStartX = 0;
                local ResizeStartWidth = WindowData:GetWidth();
                table.insert(WindowData.InternalConnections, ResizeGrip.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Resizing = true;
                        ResizeStartX = Input.Position.X;
                        ResizeStartWidth = WindowData:GetWidth();
                    end
                end));
                table.insert(WindowData.InternalConnections, UserInputService.InputChanged:Connect(function(Input)
                    if Resizing and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        local DeltaX = Input.Position.X - ResizeStartX;
                        WindowData:SetWidth(ResizeStartWidth + DeltaX);
                        UpdateResizeGripPosition();
                    end
                end));
                table.insert(WindowData.InternalConnections, UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Resizing = false;
                    end
                end));
                UpdateResizeGripPosition();
            end

            table.insert(WindowData.InternalConnections, NewWindow:GetPropertyChangedSignal("Position"):Connect(function()
                UpdateQueueStoredPosition();
                UpdateResizeGripPosition();
            end));
            table.insert(WindowData.InternalConnections, NewWindow.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    WindowData:BringToFront();
                end
            end));

            if ListLayout then
                ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if WindowData.toggled then
                        WindowData.container.Size = UDim2.new(1, 0, 0, GetContentHeight());
                    end
                    WindowData:RefreshAutoWidth(false);
                    UpdateResizeGripPosition();
                end)
            end

            local function ApplyWindowToggleState(NewState, Animate)
                WindowData.toggled = (NewState == true);
                WindowToggle.Text = (WindowData.toggled and "-" or "+");
                NewWindow:SetAttribute("WallyWindowToggled", WindowData.toggled);
                if (not WindowData.toggled) then
                    WindowData.container.ClipsDescendants = true;
                end

                local TargetSize = WindowData.toggled and UDim2.new(1, 0, 0, GetContentHeight()) or UDim2.new(1, 0, 0, 0);
                if Animate == false then
                    WindowData.container.Size = TargetSize;
                    if WindowData.toggled then
                        WindowData.container.ClipsDescendants = false;
                    end
                else
                    local TargetDirection = WindowData.toggled and "In" or "Out";
                    WindowData.container:TweenSize(TargetSize, TargetDirection, "Quint", .3, true);
                    task.delay(0.31, function()
                        if WindowData and WindowData.container and WindowData.container.Parent and WindowData.toggled then
                            WindowData.container.ClipsDescendants = false;
                        end
                    end);
                end

                if type(WindowData.OnToggleChanged) == "function" then
                    pcall(WindowData.OnToggleChanged, WindowData.toggled);
                end
                UpdateResizeGripPosition();
            end

            WindowToggle.MouseButton1Click:Connect(function()
                ApplyWindowToggleState(not WindowData.toggled, true);
            end)

            function WindowData:SetMinimized(IsMinimized, Animate)
                ApplyWindowToggleState(not (IsMinimized == true), Animate ~= false);
            end

            function WindowData:SetExpanded(IsExpanded, Animate)
                ApplyWindowToggleState(IsExpanded ~= false, Animate ~= false);
            end

            function WindowData:GetMinimized()
                return not WindowData.toggled;
            end

            function WindowData:Destroy()
                if self._Destroyed == true then
                    return false;
                end
                self._Destroyed = true;

                if type(self._PersistenceConnections) == "table" then
                    for _, Connection in next, self._PersistenceConnections do
                        if Connection and Connection.Disconnect then
                            pcall(function()
                                Connection:Disconnect();
                            end);
                        end
                    end
                    self._PersistenceConnections = nil;
                end

                if type(self.InternalConnections) == "table" then
                    for _, Connection in next, self.InternalConnections do
                        if Connection and Connection.Disconnect then
                            pcall(function()
                                Connection:Disconnect();
                            end);
                        end
                    end
                    self.InternalConnections = nil;
                end

                if type(self.PopupInstances) == "table" then
                    for _, PopupObject in next, self.PopupInstances do
                        if typeof(PopupObject) == "Instance" and PopupObject.Parent then
                            pcall(function()
                                PopupObject:Destroy();
                            end);
                        end
                    end
                    self.PopupInstances = nil;
                end

                for Index = #Library.Windows, 1, -1 do
                    if Library.Windows[Index] == self then
                        table.remove(Library.Windows, Index);
                    end
                end

                local WindowObject = self.object;
                for Index = #Library.Queue, 1, -1 do
                    local QueueData = Library.Queue[Index];
                    if QueueData and QueueData.Window == WindowObject then
                        table.remove(Library.Queue, Index);
                    end
                end

                for FlagName, BindData in next, Library.Binds do
                    if BindData and BindData.Location == self.flags then
                        Library.Binds[FlagName] = nil;
                    end
                end

                if type(self.flags) == "table" then
                    for FlagName in next, self.flags do
                        if Library.Callbacks then
                            Library.Callbacks[FlagName] = nil;
                        end
                    end
                end

                if Library.ControlApisByRoot and WindowObject then
                    for RootObject in next, Library.ControlApisByRoot do
                        if typeof(RootObject) == "Instance" then
                            if RootObject == WindowObject or RootObject:IsDescendantOf(WindowObject) then
                                local ApiData = Library.ControlApisByRoot[RootObject];
                                if type(ApiData) == "table" and ApiData.FlagName and Library.ControlApisByFlag then
                                    if Library.ControlApisByFlag[ApiData.FlagName] == ApiData then
                                        Library.ControlApisByFlag[ApiData.FlagName] = nil;
                                    end
                                end
                                Library.ControlApisByRoot[RootObject] = nil;
                            end
                        end
                    end
                end

                if WindowObject and WindowObject.Parent then
                    pcall(function()
                        WindowObject:Destroy();
                    end);
                end
                self.object = nil;
                return true;
            end

            NewWindow:SetAttribute("WallyWindowToggled", WindowData.toggled);
            WindowData:RefreshAutoWidth(false);

            return WindowData;
        end
        
        function Types:Resize()
            if self.toggled then
                if self.list then
                    self.container.Size = UDim2.new(1, 0, 0, math.max(self.list.AbsoluteContentSize.Y + 5, 0));
                else
                    local Y = 0;
                    for _, ValueData in next, self.container:GetChildren() do
                        if (not ValueData:IsA('UIListLayout')) then
                            Y = Y + ValueData.AbsoluteSize.Y;
                        end
                    end
                    self.container.Size = UDim2.new(1, 0, 0, Y + 5);
                end
            end

            local ParentWindow = self.ParentWindow or self;
            if ParentWindow and type(ParentWindow.UpdateResizeGripPosition) == "function" then
                ParentWindow:UpdateResizeGripPosition();
            end
        end
        
        function Types:GetOrder() 
            local OrderData = self.order or 0;
            self.order = OrderData + 1;
            return OrderData;
        end

        function Types:ResolveFlag(ProvidedFlag, Name, Kind)
            local FlagName = tostring(ProvidedFlag or "");
            if FlagName ~= "" then
                return FlagName;
            end

            self.AutoFlagCounter = (self.AutoFlagCounter or 0) + 1;
            local Prefix = tostring(self.AutoFlagPrefix or "Window");
            Prefix = Prefix:gsub("[%c%s]+", "_"):gsub("[^%w_]", "_"):gsub("_+", "_");
            Prefix = Prefix:gsub("^_+", ""):gsub("_+$", "");
            if Prefix == "" then
                Prefix = "Window";
            end

            local NamePart = tostring(Name or Kind or "Flag");
            NamePart = NamePart:gsub("[%c%s]+", "_"):gsub("[^%w_]", "_"):gsub("_+", "_");
            NamePart = NamePart:gsub("^_+", ""):gsub("_+$", "");
            if NamePart == "" then
                NamePart = tostring(Kind or "Flag");
            end

            return "__WallyAuto_" .. Prefix .. "_" .. tostring(Kind or "Flag") .. "_" .. tostring(self.AutoFlagCounter) .. "_" .. NamePart;
        end

        local function CoerceBoolean(Value, DefaultValue)
            if Value == nil then
                return DefaultValue == true;
            end
            return Value == true;
        end

        local function ShouldDispatchCallback(FireCallback)
            if FireCallback == false then
                return false;
            end
            return (Library.CallbackSuspendDepth or 0) <= 0;
        end

        local function NotifyFlagChanged(FlagName, Location, NewValue, OldValue, Source)
            if type(Library.EmitFlagChanged) == "function" then
                Library:EmitFlagChanged(FlagName, Location, NewValue, OldValue, Source);
                return;
            end

            local Key = tostring(FlagName or "");
            if Key == "" then
                return;
            end

            local Payload = {
                Flag = Key;
                flag = Key;
                Location = Location;
                location = Location;
                Value = NewValue;
                value = NewValue;
                OldValue = OldValue;
                oldValue = OldValue;
                Source = Source;
                source = Source;
            };

            local ListenersByFlag = Library.FlagChangeListeners or {};
            local FlagListeners = ListenersByFlag[Key];
            if type(FlagListeners) == "table" then
                for Index = #FlagListeners, 1, -1 do
                    local Entry = FlagListeners[Index];
                    local Callback = Entry and Entry.Callback;
                    local ScopeLocation = Entry and Entry.Location;
                    if type(Callback) ~= "function" then
                        table.remove(FlagListeners, Index);
                    elseif ScopeLocation == nil or ScopeLocation == Location then
                        pcall(Callback, NewValue, OldValue, Payload);
                    end
                end
            end

            local AnyListeners = Library.FlagChangeAnyListeners or {};
            for Index = #AnyListeners, 1, -1 do
                local Entry = AnyListeners[Index];
                local Callback = Entry and Entry.Callback;
                local ScopeLocation = Entry and Entry.Location;
                if type(Callback) ~= "function" then
                    table.remove(AnyListeners, Index);
                elseif ScopeLocation == nil or ScopeLocation == Location then
                    pcall(Callback, Key, NewValue, OldValue, Payload);
                end
            end
        end

        local function SetFlagValue(Location, FlagName, NewValue, Source, ForceDispatch)
            if type(Location) ~= "table" then
                return false, nil;
            end

            local Key = tostring(FlagName or "");
            if Key == "" then
                return false, nil;
            end

            local OldValue = Location[Key];
            Location[Key] = NewValue;
            Library:RegisterFlag(Location, Key);

            if ForceDispatch == true or OldValue ~= NewValue then
                NotifyFlagChanged(Key, Location, NewValue, OldValue, Source);
                return true, OldValue;
            end

            return false, OldValue;
        end

        local function NormalizeDependencyMode(Value)
            local Mode = string.lower(tostring(Value or "all"));
            if Mode == "or" then
                Mode = "any";
            end
            if Mode ~= "any" then
                Mode = "all";
            end
            return Mode;
        end

        local function ResolveDependencyFlagValue(Location, FlagName)
            if type(FlagName) ~= "string" or FlagName == "" then
                return nil;
            end

            if type(Location) == "table" and Location[FlagName] ~= nil then
                return Location[FlagName];
            end

            local Entry = Library.RegisteredFlags and Library.RegisteredFlags[FlagName];
            local Locations = Entry and Entry.Locations;
            if type(Locations) == "table" then
                for _, OtherLocation in next, Locations do
                    if type(OtherLocation) == "table" and OtherLocation[FlagName] ~= nil then
                        return OtherLocation[FlagName];
                    end
                end
            end

            local Fallback = Library.FlagLocations or {};
            for _, OtherLocation in next, Fallback do
                if type(OtherLocation) == "table" and OtherLocation[FlagName] ~= nil then
                    return OtherLocation[FlagName];
                end
            end

            return nil;
        end

        local function EvaluateSingleDependencyRule(Rule, Location)
            if Rule == nil then
                return true;
            end

            local RuleType = type(Rule);
            if RuleType == "function" then
                local Ok, Result = pcall(Rule, Location, Library);
                return Ok and Result == true;
            end

            if RuleType == "string" then
                local Value = ResolveDependencyFlagValue(Location, Rule);
                return not not Value;
            end

            if RuleType ~= "table" then
                return Rule == true;
            end

            if type(Rule.flag) == "string" and Rule.flag ~= "" then
                local Value = ResolveDependencyFlagValue(Location, Rule.flag);

                if type(Rule.predicate) == "function" then
                    local Ok, Result = pcall(Rule.predicate, Value, Location, Library);
                    if not Ok then
                        return false;
                    end
                    return Result == true;
                end

                if Rule.exists ~= nil then
                    local Exists = (Value ~= nil);
                    if Exists ~= (Rule.exists == true) then
                        return false;
                    end
                end

                if Rule.min ~= nil and tonumber(Value) then
                    if tonumber(Value) < tonumber(Rule.min) then
                        return false;
                    end
                end
                if Rule.max ~= nil and tonumber(Value) then
                    if tonumber(Value) > tonumber(Rule.max) then
                        return false;
                    end
                end

                if Rule.notValue ~= nil and Value == Rule.notValue then
                    return false;
                end
                if Rule.notEquals ~= nil and Value == Rule.notEquals then
                    return false;
                end

                if Rule.value ~= nil then
                    return Value == Rule.value;
                end
                if Rule.equals ~= nil then
                    return Value == Rule.equals;
                end
                if Rule.is ~= nil then
                    return Value == Rule.is;
                end

                return not not Value;
            end

            local IsArray = false;
            for Key in next, Rule do
                if type(Key) == "number" then
                    IsArray = true;
                    break;
                end
            end

            if IsArray then
                local Mode = NormalizeDependencyMode(Rule.mode or Rule.operator);
                if Mode == "any" then
                    for _, SubRule in next, Rule do
                        if EvaluateSingleDependencyRule(SubRule, Location) then
                            return true;
                        end
                    end
                    return false;
                end

                for _, SubRule in next, Rule do
                    if not EvaluateSingleDependencyRule(SubRule, Location) then
                        return false;
                    end
                end
                return true;
            end

            for FlagName, ExpectedValue in next, Rule do
                if FlagName ~= "mode" and FlagName ~= "operator" then
                    local CurrentValue = ResolveDependencyFlagValue(Location, tostring(FlagName));
                    if CurrentValue ~= ExpectedValue then
                        return false;
                    end
                end
            end
            return true;
        end

        function Types:ApplyControlSearchFilter()
            local Query = string.lower(tostring(self.ControlSearchQuery or ""));
            local HasQuery = Query ~= "";
            local Controls = self.Controls or {};
            for _, ControlData in next, Controls do
                local SearchText = string.lower(tostring(ControlData.SearchText or ""));
                local IsMatch = (not HasQuery) or (string.find(SearchText, Query, 1, true) ~= nil);
                if type(ControlData.SetSearchMatch) == "function" then
                    pcall(ControlData.SetSearchMatch, IsMatch);
                elseif ControlData.Root and ControlData.Root.Parent then
                    ControlData.Root.Visible = IsMatch;
                end
            end

            if type(self.Resize) == "function" then
                self:Resize();
            end
            if type(self.RefreshTabHostSize) == "function" then
                self:RefreshTabHostSize();
            end
        end

        function Types:SetSearchQuery(Query)
            self.ControlSearchQuery = tostring(Query or "");
            self:ApplyControlSearchFilter();
        end

        function Types:AttachControlFeatures(Root, Options, Api, InteractiveTargets, SearchText)
            Options = Options or {};
            Api = Api or {};

            local Location = Options.location or self.flags;
            local ControlVisible = CoerceBoolean(Options.visible, true);
            local ControlEnabled = CoerceBoolean(Options.enabled, true);
            local SearchMatched = true;
            local VisibilityRule = Options.dependsOn or Options.visibleWhen or Options.showWhen;
            local EnabledRule = Options.enabledWhen or Options.enableWhen;
            local TooltipText = Options.tooltip or Options.help or Options.description or Options.hint;
            if TooltipText == nil then
                local FallbackTooltip = tostring(SearchText or "");
                if FallbackTooltip ~= "" then
                    TooltipText = FallbackTooltip;
                end
            end
            local LastShown = nil;
            local LastEnabled = nil;
            local DependencyConnections = {};
            local ChangeListeners = {};

            local Targets = {};
            if type(InteractiveTargets) == "table" then
                for _, Target in next, InteractiveTargets do
                    if typeof(Target) == "Instance" then
                        table.insert(Targets, Target);
                    end
                end
            elseif typeof(InteractiveTargets) == "Instance" then
                table.insert(Targets, InteractiveTargets);
            end

            local function SetTargetEnabled(Target, IsEnabled)
                if not Target or (not Target.Parent) or (not Target:IsA("GuiObject")) then
                    return;
                end

                Target.Active = IsEnabled;
                if Target:IsA("TextButton") or Target:IsA("ImageButton") then
                    Target.AutoButtonColor = IsEnabled;
                end
                if Target:IsA("TextBox") then
                    pcall(function()
                        Target.TextEditable = IsEnabled;
                    end);
                end

                if IsEnabled then
                    if Target:GetAttribute("WallyDisabledState") ~= true then
                        return;
                    end
                    if Target:GetAttribute("WallyOrigTextTransparency") ~= nil then
                        local OldTextTransparency = tonumber(Target:GetAttribute("WallyOrigTextTransparency"));
                        if OldTextTransparency ~= nil and (Target:IsA("TextLabel") or Target:IsA("TextButton") or Target:IsA("TextBox")) then
                            pcall(function()
                                Target.TextTransparency = OldTextTransparency;
                            end);
                        end
                    end
                    if Target:GetAttribute("WallyOrigBackgroundTransparency") ~= nil then
                        local OldBgTransparency = tonumber(Target:GetAttribute("WallyOrigBackgroundTransparency"));
                        if OldBgTransparency ~= nil then
                            Target.BackgroundTransparency = OldBgTransparency;
                        end
                    end
                    Target:SetAttribute("WallyDisabledState", false);
                else
                    if Target:GetAttribute("WallyDisabledState") == true then
                        return;
                    end
                    if Target:IsA("TextLabel") or Target:IsA("TextButton") or Target:IsA("TextBox") then
                        if Target:GetAttribute("WallyOrigTextTransparency") == nil then
                            Target:SetAttribute("WallyOrigTextTransparency", Target.TextTransparency);
                        end
                        Target.TextTransparency = math.clamp((tonumber(Target.TextTransparency) or 0) + 0.35, 0, 1);
                    end
                    if Target:GetAttribute("WallyOrigBackgroundTransparency") == nil then
                        Target:SetAttribute("WallyOrigBackgroundTransparency", Target.BackgroundTransparency);
                    end
                    Target.BackgroundTransparency = math.clamp((tonumber(Target.BackgroundTransparency) or 0) + 0.2, 0, 1);
                    Target:SetAttribute("WallyDisabledState", true);
                end
            end

            local function EmitChanged(...)
                for Index = #ChangeListeners, 1, -1 do
                    local Listener = ChangeListeners[Index];
                    if type(Listener) ~= "table" or Listener.Connected ~= true or type(Listener.Callback) ~= "function" then
                        table.remove(ChangeListeners, Index);
                    else
                        pcall(Listener.Callback, ...);
                    end
                end
            end

            function Api:OnChanged(Callback)
                if type(Callback) ~= "function" then
                    return nil;
                end

                local Listener = {
                    Connected = true;
                    Callback = Callback;
                };
                table.insert(ChangeListeners, Listener);

                return {
                    Connected = true;
                    Disconnect = function(Self)
                        if Listener.Connected ~= true then
                            if type(Self) == "table" then
                                Self.Connected = false;
                            end
                            return false;
                        end
                        Listener.Connected = false;
                        Listener.Callback = nil;
                        if type(Self) == "table" then
                            Self.Connected = false;
                        end
                        return true;
                    end
                };
            end

            function Api:EmitChanged(...)
                EmitChanged(...);
            end

            local function EvaluateDependencies()
                local VisiblePass = EvaluateSingleDependencyRule(VisibilityRule, Location);
                local EnabledPass = EvaluateSingleDependencyRule(EnabledRule, Location);
                local ShouldShow = ControlVisible and SearchMatched and VisiblePass;
                local ShouldEnable = ControlEnabled and EnabledPass;
                local VisibilityChanged = (LastShown ~= ShouldShow);
                local EnabledChanged = (LastEnabled ~= ShouldEnable);

                if Root and Root.Parent then
                    Root.Visible = ShouldShow;
                end

                if EnabledChanged then
                    for _, Target in next, Targets do
                        SetTargetEnabled(Target, ShouldEnable);
                    end
                end

                if VisibilityChanged then
                    if type(self.Resize) == "function" then
                        self:Resize();
                    end
                    if type(self.RefreshTabHostSize) == "function" then
                        self:RefreshTabHostSize();
                    end
                end

                LastShown = ShouldShow;
                LastEnabled = ShouldEnable;
                return ShouldShow, ShouldEnable;
            end

            local function DisconnectDependencyConnections()
                for Index = #DependencyConnections, 1, -1 do
                    local Connection = DependencyConnections[Index];
                    if Connection and Connection.Disconnect then
                        pcall(function()
                            Connection:Disconnect();
                        end);
                    end
                    DependencyConnections[Index] = nil;
                end
            end

            local function CollectDependencyFlags(Rule, Output)
                if Rule == nil then
                    return;
                end

                local RuleType = type(Rule);
                if RuleType == "string" then
                    local Key = tostring(Rule);
                    if Key ~= "" then
                        Output[Key] = true;
                    end
                    return;
                end

                if RuleType ~= "table" then
                    return;
                end

                local FlagData = Rule.flag;
                if type(FlagData) == "string" and FlagData ~= "" then
                    Output[FlagData] = true;
                end

                local IsArray = false;
                for Key in next, Rule do
                    if type(Key) == "number" then
                        IsArray = true;
                        break;
                    end
                end

                if IsArray then
                    for _, SubRule in next, Rule do
                        CollectDependencyFlags(SubRule, Output);
                    end
                    return;
                end

                if type(FlagData) == "string" and FlagData ~= "" then
                    return;
                end

                for Key, Value in next, Rule do
                    if Key ~= "mode" and Key ~= "operator" and Key ~= "predicate" and Key ~= "flag" then
                        if type(Key) == "string" and Key ~= "" then
                            Output[Key] = true;
                        end
                        if type(Value) == "table" then
                            CollectDependencyFlags(Value, Output);
                        end
                    end
                end
            end

            local function RebindDependencySignals()
                DisconnectDependencyConnections();
                local SeenFlags = {};
                CollectDependencyFlags(VisibilityRule, SeenFlags);
                CollectDependencyFlags(EnabledRule, SeenFlags);

                for FlagName in next, SeenFlags do
                    if type(Library.OnFlagChanged) == "function" then
                        local Connection = Library:OnFlagChanged(FlagName, function()
                            EvaluateDependencies();
                        end);
                        if Connection and Connection.Disconnect then
                            table.insert(DependencyConnections, Connection);
                        end
                    end
                end

                if Root and Root.Parent then
                    local DestroyConnection = Root.AncestryChanged:Connect(function(_, ParentData)
                        if not ParentData then
                            DisconnectDependencyConnections();
                        end
                    end);
                    table.insert(DependencyConnections, DestroyConnection);
                end
            end

            function Api:SetVisible(State)
                ControlVisible = CoerceBoolean(State, true);
                EvaluateDependencies();
                return ControlVisible;
            end

            function Api:GetVisible()
                return ControlVisible;
            end

            function Api:SetEnabled(State)
                ControlEnabled = CoerceBoolean(State, true);
                EvaluateDependencies();
                return ControlEnabled;
            end

            function Api:GetEnabled()
                return ControlEnabled;
            end

            function Api:SetVisibilityDependency(Rule)
                VisibilityRule = Rule;
                RebindDependencySignals();
                EvaluateDependencies();
                return true;
            end

            function Api:SetEnabledDependency(Rule)
                EnabledRule = Rule;
                RebindDependencySignals();
                EvaluateDependencies();
                return true;
            end

            function Api:SetDependency(Rule)
                VisibilityRule = Rule;
                RebindDependencySignals();
                EvaluateDependencies();
                return true;
            end

            function Api:SetSearchMatch(IsMatch)
                SearchMatched = (IsMatch ~= false);
                EvaluateDependencies();
                return SearchMatched;
            end

            function Api:SetTooltip(Text)
                TooltipText = Text;
                local Resolver = function()
                    return TooltipText;
                end
                if Root and Root.Parent then
                    Library:AttachTooltip(Root, Resolver);
                end
                for _, Target in next, Targets do
                    if Target and Target.Parent then
                        Library:AttachTooltip(Target, Resolver);
                    end
                end
                return true;
            end

            function Api:RefreshDependency()
                return EvaluateDependencies();
            end

            if Root and Root.Parent and Options.searchIgnore ~= true then
                self.Controls = self.Controls or {};
                table.insert(self.Controls, {
                    Root = Root;
                    SearchText = tostring(SearchText or "");
                    SetSearchMatch = function(IsMatch)
                        Api:SetSearchMatch(IsMatch);
                    end;
                });
            end

            Library.ControlApisByRoot = Library.ControlApisByRoot or {};
            if Root then
                Library.ControlApisByRoot[Root] = Api;
            end

            local FlagName = tostring(Options.flag or "");
            Api.Root = Root;
            Api.Location = Location;
            Api.FlagName = (FlagName ~= "" and FlagName or nil);
            if FlagName ~= "" then
                Library.ControlApisByFlag = Library.ControlApisByFlag or {};
                Library.ControlApisByFlag[FlagName] = Api;
            end

            Library.DependencyControls = Library.DependencyControls or {};
            table.insert(Library.DependencyControls, {
                Root = Root;
                Refresh = function()
                    Api:RefreshDependency();
                end;
            });

            if TooltipText ~= nil then
                Api:SetTooltip(TooltipText);
            end

            if self.ControlSearchQuery and self.ControlSearchQuery ~= "" then
                local Query = string.lower(tostring(self.ControlSearchQuery));
                local ControlText = string.lower(tostring(SearchText or ""));
                SearchMatched = string.find(ControlText, Query, 1, true) ~= nil;
            end

            RebindDependencySignals();
            EvaluateDependencies();
            return Api;
        end

        local function WrapInstanceApi(InstanceObject, ApiData)
            return setmetatable(ApiData or {}, {
                __index = function(TableData, Key)
                    local Direct = rawget(TableData, Key);
                    if Direct ~= nil then
                        return Direct;
                    end
                    if not InstanceObject then
                        return nil;
                    end

                    local OkRead, Value = pcall(function()
                        return InstanceObject[Key];
                    end);
                    if not OkRead then
                        return nil;
                    end

                    if type(Value) == "function" then
                        return function(_, ...)
                            return Value(InstanceObject, ...);
                        end
                    end
                    return Value;
                end,
                __newindex = function(TableData, Key, Value)
                    if rawget(TableData, Key) ~= nil then
                        rawset(TableData, Key, Value);
                        return;
                    end

                    if InstanceObject then
                        local OkWrite = pcall(function()
                            InstanceObject[Key] = Value;
                        end);
                        if OkWrite then
                            return;
                        end
                    end

                    rawset(TableData, Key, Value);
                end,
            });
        end

        local function EnsureTabHost(Owner, TabOptions)
            if Owner.TabHost and Owner.TabHost.Parent and Owner.TabHeader and Owner.TabPages then
                return Owner.TabHost, Owner.TabHeader, Owner.TabPages;
            end

            local HeaderHeight = math.clamp(math.floor((tonumber(TabOptions and (TabOptions.headerHeight or TabOptions.tabHeaderHeight) or 22) or 22) + 0.5), 16, 30);
            local HostFrame = Library:Create("Frame", {
                Name = "TabHost";
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, HeaderHeight + 4);
                LayoutOrder = Owner:GetOrder();
                Parent = Owner.container;
                Library:Create("Frame", {
                    Name = "Header";
                    Position = UDim2.new(0, 5, 0, 0);
                    Size = UDim2.new(1, -10, 0, HeaderHeight);
                    BackgroundTransparency = 1;
                    BorderSizePixel = 0;
                    Library:Create("UIListLayout", {
                        Name = "List";
                        FillDirection = Enum.FillDirection.Horizontal;
                        SortOrder = Enum.SortOrder.LayoutOrder;
                        Padding = UDim.new(0, 2);
                    });
                });
                Library:Create("Frame", {
                    Name = "Pages";
                    Position = UDim2.new(0, 5, 0, HeaderHeight + 2);
                    Size = UDim2.new(1, -10, 0, 0);
                    BackgroundTransparency = 1;
                    BorderSizePixel = 0;
                    ClipsDescendants = false;
                });
            });

            Owner.TabHost = HostFrame;
            Owner.TabHeader = HostFrame:FindFirstChild("Header");
            Owner.TabPages = HostFrame:FindFirstChild("Pages");
            Owner.TabHeaderHeight = HeaderHeight;
            Owner.Tabs = Owner.Tabs or {};
            Owner.ActiveTab = Owner.ActiveTab or nil;

            if Owner.TabHeader then
                Owner.TabHeader:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    if type(Owner.RefreshTabHostSize) == "function" then
                        Owner:RefreshTabHostSize();
                    end
                end);
            end

            function Owner:RefreshTabHostSize()
                if (not self.TabHost) or (not self.TabHost.Parent) then
                    return;
                end

                local ContentHeight = 0;
                local TabCount = #self.Tabs;
                local HeaderWidth = (self.TabHeader and self.TabHeader.AbsoluteSize.X) or 0;
                local HeaderList = self.TabHeader and self.TabHeader:FindFirstChild("List");
                local HeaderPadding = 2;
                if HeaderList and HeaderList:IsA("UIListLayout") then
                    HeaderPadding = HeaderList.Padding.Offset;
                end
                local EvenWidth = 0;
                if TabCount > 1 and HeaderWidth > 0 then
                    local Available = HeaderWidth - ((TabCount - 1) * HeaderPadding);
                    EvenWidth = math.max(48, math.floor((Available / TabCount) + 0.5));
                end
                for _, Entry in next, self.Tabs do
                    local IsActive = (self.ActiveTab == Entry);
                    if Entry.Button and Entry.Button.Parent then
                        if TabCount == 1 then
                            Entry.Button.Size = UDim2.new(1, 0, 1, 0);
                        elseif EvenWidth > 0 then
                            Entry.Button.Size = UDim2.new(0, EvenWidth, 1, 0);
                        else
                            local AutoWidth = math.clamp((string.len(tostring(Entry.Name or "")) * 7) + 22, 50, 170);
                            Entry.Button.Size = UDim2.new(0, AutoWidth, 1, 0);
                        end
                        Entry.Button.BackgroundColor3 = (IsActive and self.options.btncolor or self.options.dropcolor);
                        Entry.Button.TextColor3 = self.options.textcolor;
                    end

                    if Entry.Page and Entry.Page.Parent then
                        Entry.Page.Visible = IsActive;
                        if IsActive then
                            local TabList = Entry.TabObject and Entry.TabObject.list;
                            if TabList and TabList.Parent then
                                ContentHeight = math.max(TabList.AbsoluteContentSize.Y + 5, 0);
                            else
                                local Height = 0;
                                for _, Child in next, Entry.Page:GetChildren() do
                                    if not Child:IsA("UIListLayout") then
                                        Height = Height + Child.AbsoluteSize.Y;
                                    end
                                end
                                ContentHeight = Height + 5;
                            end
                            Entry.Page.Size = UDim2.new(1, 0, 0, ContentHeight);
                        else
                            Entry.Page.Size = UDim2.new(1, 0, 0, 0);
                        end
                    end
                end

                self.TabPages.Size = UDim2.new(1, -10, 0, ContentHeight);
                self.TabHost.Size = UDim2.new(1, 0, 0, self.TabHeaderHeight + 2 + ContentHeight);

                if type(self.Resize) == "function" then
                    self:Resize();
                end
                if self.ParentTabOwner and type(self.ParentTabOwner.RefreshTabHostSize) == "function" then
                    self.ParentTabOwner:RefreshTabHostSize();
                end
                if self.ParentWindow and type(self.ParentWindow.RefreshAutoWidth) == "function" then
                    self.ParentWindow:RefreshAutoWidth(false);
                end
            end

            return Owner.TabHost, Owner.TabHeader, Owner.TabPages;
        end

        function Types:Tab(Name, Options)
            Options = Options or {};
            local TabName = tostring(Name or "Tab");

            local _, Header, Pages = EnsureTabHost(self, Options);
            self.Tabs = self.Tabs or {};

            local Existing;
            for _, Entry in next, self.Tabs do
                if Entry.Name == TabName then
                    Existing = Entry;
                    break;
                end
            end
            if Existing then
                self.ActiveTab = Existing;
                if type(self.RefreshTabHostSize) == "function" then
                    self:RefreshTabHostSize();
                end
                return Existing.TabObject;
            end

            local TabButton = Library:Create("TextButton", {
                Name = "TabButton_" .. tostring(#self.Tabs + 1);
                Text = TabName;
                AutoButtonColor = true;
                Size = UDim2.new(0, math.clamp((string.len(TabName) * 7) + 22, 50, 170), 1, 0);
                BackgroundColor3 = self.options.dropcolor;
                BorderColor3 = self.options.bordercolor;
                TextColor3 = self.options.textcolor;
                TextStrokeTransparency = self.options.textstroke;
                TextStrokeColor3 = self.options.strokecolor;
                Font = self.options.font;
                TextSize = self.options.fontsize;
                TextScaled = false;
                TextWrapped = false;
                TextTruncate = Enum.TextTruncate.AtEnd;
                Parent = Header;
                LayoutOrder = #self.Tabs + 1;
            });

            local Page = Library:Create("Frame", {
                Name = "TabPage_" .. tostring(#self.Tabs + 1);
                BackgroundTransparency = 1;
                Visible = false;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 0);
                Parent = Pages;
                Library:Create("UIListLayout", {
                    Name = "List";
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Padding = UDim.new(0, math.clamp(math.floor((tonumber(self.options.itemspacing) or 0) + 0.5), 0, 40));
                });
            });

            local PageList = Page:FindFirstChild("List");
            local TabObject = setmetatable({
                Count = 0;
                object = Page;
                ContainerData = Page;
                container = Page;
                ListData = PageList;
                list = PageList;
                options = self.options;
                Options = self.options;
                toggled = true;
                flags = self.flags;
                OrderData = 0;
                order = 0;
                ParentWindow = self.ParentWindow or self;
                ParentTabOwner = self;
                AutoFlagPrefix = tostring((self.AutoFlagPrefix or "Tab")) .. "_" .. TabName;
            }, Types);

            local Entry = {
                Name = TabName;
                Button = TabButton;
                Page = Page;
                TabObject = TabObject;
            };
            table.insert(self.Tabs, Entry);

            if PageList then
                PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if type(TabObject.Resize) == "function" then
                        TabObject:Resize();
                    end
                    if type(self.RefreshTabHostSize) == "function" then
                        self:RefreshTabHostSize();
                    end
                end);
            end

            TabButton.MouseButton1Click:Connect(function()
                self.ActiveTab = Entry;
                if type(self.RefreshTabHostSize) == "function" then
                    self:RefreshTabHostSize();
                end
            end);

            if not self.ActiveTab then
                self.ActiveTab = Entry;
            end
            if type(self.RefreshTabHostSize) == "function" then
                self:RefreshTabHostSize();
            end

            return TabObject;
        end

        function Types:CreateTab(Name, Options)
            return self:Tab(Name, Options);
        end

        function Types:SubTab(Name, Options)
            return self:Tab(Name, Options);
        end

        function Types:CreateSubTab(Name, Options)
            return self:SubTab(Name, Options);
        end

        function Types:SearchBar(Name, Options, Callback)
            if type(Options) == "function" and Callback == nil then
                Callback = Options;
                Options = {};
            end
            Options = Options or {};
            local Placeholder = tostring(Name or Options.placeholder or "Search Controls");
            local CallbackData = Callback or function() end;

            local CheckData = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Parent = self.container;
                Library:Create("TextBox", {
                    Name = "SearchInput";
                    Text = tostring(Options.default or "");
                    PlaceholderText = Placeholder;
                    ClearTextOnFocus = false;
                    Font = self.options.font;
                    TextSize = self.options.fontsize;
                    TextColor3 = self.options.textcolor;
                    TextStrokeTransparency = self.options.textstroke;
                    TextStrokeColor3 = self.options.strokecolor;
                    PlaceholderColor3 = self.options.placeholdercolor;
                    BackgroundColor3 = self.options.dropcolor;
                    BorderColor3 = self.options.bordercolor;
                    Position = UDim2.new(0, 5, 0, 4);
                    Size = UDim2.new(1, -10, 0, 20);
                });
            });

            local SearchInput = CheckData:FindFirstChild("SearchInput");
            local IsInternalChange = false;
            local ApiData;

            local function ApplyQuery(Query)
                if type(self.SetSearchQuery) == "function" then
                    self:SetSearchQuery(Query);
                end
                if ShouldDispatchCallback(true) then
                    CallbackData(Query);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(Query);
                    end
                end
            end

            SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
                if IsInternalChange then
                    return;
                end
                ApplyQuery(SearchInput.Text);
            end);

            self:Resize();
            ApiData = {
                Set = function(_, NewValue, FireCallback)
                    IsInternalChange = true;
                    SearchInput.Text = tostring(NewValue or "");
                    IsInternalChange = false;
                    if ShouldDispatchCallback(FireCallback) then
                        ApplyQuery(SearchInput.Text);
                    else
                        if type(self.SetSearchQuery) == "function" then
                            self:SetSearchQuery(SearchInput.Text);
                        end
                    end
                end,
                Get = function()
                    return SearchInput.Text;
                end,
                Clear = function(_, FireCallback)
                    IsInternalChange = true;
                    SearchInput.Text = "";
                    IsInternalChange = false;
                    if ShouldDispatchCallback(FireCallback) then
                        ApplyQuery("");
                    else
                        if type(self.SetSearchQuery) == "function" then
                            self:SetSearchQuery("");
                        end
                    end
                end,
                Input = SearchInput;
            };

            if SearchInput.Text ~= "" then
                ApplyQuery(SearchInput.Text);
            end

            local FeatureOptions = {};
            for Key, Value in next, Options do
                FeatureOptions[Key] = Value;
            end
            FeatureOptions.searchIgnore = true;
            return self:AttachControlFeatures(CheckData, FeatureOptions, ApiData, {SearchInput}, "Search Bar");
        end

        function Types:CreateSearchBar(Name, Options, Callback)
            return self:SearchBar(Name, Options, Callback);
        end
        
        function Types:Toggle(Name, Options, Callback)
            Options = Options or {};
            local Default  = Options.default or false;
            local Location = Options.location or self.flags;
            local Flag     = self:ResolveFlag(Options.flag, Name, "Toggle");
            local Callback = Callback or function() end;

            local function ResolveToggleTheme()
                local ActiveOptions = self.options or Library.Options or {};
                local ToggleStyle = string.lower(tostring(Options.togglestyle or Options.toggleStyle or ActiveOptions.togglestyle or "checkmark"));
                local IsFillStyle = (
                    ToggleStyle == "fill"
                    or ToggleStyle == "filled"
                    or ToggleStyle == "filledbox"
                    or ToggleStyle == "filledboxes"
                    or ToggleStyle == "filledboxs"
                    or ToggleStyle == "box"
                );

                local FillOnColor = Options.toggleoncolor or Options.oncolor or ActiveOptions.toggleoncolor or ActiveOptions.textcolor or Color3.fromRGB(255, 255, 255);
                local FillOffColor = Options.toggleoffcolor or Options.offcolor or ActiveOptions.toggleoffcolor or ActiveOptions.bgcolor or Color3.fromRGB(35, 35, 35);

                if typeof(FillOnColor) ~= "Color3" then
                    FillOnColor = ActiveOptions.textcolor or Color3.fromRGB(255, 255, 255);
                end
                if typeof(FillOffColor) ~= "Color3" then
                    FillOffColor = ActiveOptions.bgcolor or Color3.fromRGB(35, 35, 35);
                end

                return ActiveOptions, IsFillStyle, FillOnColor, FillOffColor;
            end
            
            Location[Flag] = (Default == true);
            Library:RegisterFlag(Location, Flag);
            local InitialOptions = self.options or Library.Options or {};

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = 'Title';
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = InitialOptions.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -35, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = InitialOptions.font;
                    TextSize = InitialOptions.fontsize;
                    TextStrokeTransparency = InitialOptions.textstroke;
                    TextStrokeColor3 = InitialOptions.strokecolor;
                    TextScaled = true;
                    TextWrapped = false;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                });
                Library:Create('TextButton', {
                    Text = "";
                    Font = InitialOptions.font;
                    TextSize = InitialOptions.fontsize;
                    Name = 'Checkmark';
                    Size = UDim2.new(0, 20, 0, 20);
                    Position = UDim2.new(1, -25, 0, 4);
                    TextColor3 = InitialOptions.textcolor;
                    BackgroundColor3 = InitialOptions.bgcolor;
                    BorderColor3 = InitialOptions.bordercolor;
                    TextStrokeTransparency = InitialOptions.textstroke;
                    TextStrokeColor3 = InitialOptions.strokecolor;
                    TextScaled = false;
                });
                Parent = self.container;
            });

            local ToggleLabel = CheckData:FindFirstChild("Title");
            local ToggleButton = CheckData:FindFirstChild("Checkmark");
            local ApiData;
            local function UpdateVisualState()
                local ActiveOptions, IsFillStyle, FillOnColor, FillOffColor = ResolveToggleTheme();

                ToggleLabel.Font = ActiveOptions.font;
                ToggleLabel.TextSize = ActiveOptions.fontsize;
                ToggleLabel.TextColor3 = ActiveOptions.textcolor;
                ToggleLabel.TextStrokeTransparency = ActiveOptions.textstroke;
                ToggleLabel.TextStrokeColor3 = ActiveOptions.strokecolor;

                ToggleButton.Font = ActiveOptions.font;
                ToggleButton.TextSize = ActiveOptions.fontsize;
                ToggleButton.TextColor3 = ActiveOptions.textcolor;
                ToggleButton.BorderColor3 = ActiveOptions.bordercolor;
                ToggleButton.TextStrokeTransparency = ActiveOptions.textstroke;
                ToggleButton.TextStrokeColor3 = ActiveOptions.strokecolor;

                if IsFillStyle then
                    ToggleButton.Text = "";
                    ToggleButton.BackgroundColor3 = (Location[Flag] and FillOnColor or FillOffColor);
                else
                    ToggleButton.Text = (Location[Flag] and utf8.char(10003) or "");
                    ToggleButton.BackgroundColor3 = ActiveOptions.bgcolor;
                end
            end
                
            local function SetToggleState(NewValue, FireCallback)
                SetFlagValue(Location, Flag, (NewValue == true), ApiData, false);
                if ShouldDispatchCallback(FireCallback) then
                    Callback(Location[Flag]);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(Location[Flag]);
                    end
                end
                UpdateVisualState();
            end

            local function Click()
                SetToggleState(not Location[Flag], true);
            end

            ToggleButton.MouseButton1Click:Connect(Click)
            Library.Callbacks[Flag] = Click;
            UpdateVisualState();

            table.insert(Library.ToggleRegistry, {
                Button = ToggleButton;
                Update = UpdateVisualState;
            });

            Library:RegisterFlagController(Location, Flag, {
                Set = function(Value, FireCallback)
                    SetToggleState(Value, FireCallback);
                end
            });

            if Location[Flag] == true then
                if ShouldDispatchCallback(true) then
                    Callback(Location[Flag]);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(Location[Flag]);
                    end
                end
            end

            self:Resize();
            ApiData = {
                Set = function(self, b)
                    SetToggleState(b, true);
                end,
                Get = function()
                    return Location[Flag];
                end
            };

            return self:AttachControlFeatures(CheckData, Options, ApiData, {ToggleButton}, tostring(Name));
        end
        
        function Types:Button(Name, Options, Callback)
            if type(Options) == "function" and Callback == nil then
                Callback = Options;
                Options = {};
            end
            Options = Options or {};
            Callback = Callback or function() end;
            
            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextButton', {
                    Name = Name;
                    Text = Name;
                    BackgroundColor3 = Library.Options.btncolor;
                    BorderColor3 = Library.Options.bordercolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    TextColor3 = Library.Options.textcolor;
                    Position = UDim2.new(0, 5, 0, 5);
                    Size     = UDim2.new(1, -10, 0, 20);
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                });
                Parent = self.container;
            });
            
            local ButtonObject = CheckData:FindFirstChild(Name);
            local ApiData;
            ButtonObject.MouseButton1Click:Connect(function(...)
                if ShouldDispatchCallback(true) then
                    Callback(...);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(...);
                    end
                end
            end)
            self:Resize();

            ApiData = {
                Fire = function()
                    if ShouldDispatchCallback(true) then
                        Callback();
                        if ApiData and type(ApiData.EmitChanged) == "function" then
                            ApiData:EmitChanged();
                        end
                    end
                end
            };

            return self:AttachControlFeatures(CheckData, Options, ApiData, {ButtonObject}, tostring(Name));
        end
        
        function Types:Box(Name, Options, Callback)
            Options = Options or {};
            local ValueType = Options.type or "";
            local Default = Options.default or "";
            local Location = Options.location or self.flags;
            local Flag     = self:ResolveFlag(Options.flag, Name, "Box");
            local Callback = Callback or function() end;
            local Min      = Options.min or 0;
            local Max      = Options.max or 9e9;

            if ValueType == "number" then
                local NumericDefault = tonumber(Default);
                if NumericDefault then
                    Default = math.clamp(NumericDefault, Min, Max);
                    Location[Flag] = Default;
                else
                    Default = "";
                    Location[Flag] = "";
                end
            else
                Default = tostring(Default);
                Location[Flag] = Default;
            end
            Library:RegisterFlag(Location, Flag);

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = "Title";
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -72, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextScaled = true;
                    TextWrapped = false;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                });
                Library:Create('TextBox', {
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Text = tostring(Default);
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    Name = 'Box';
                    Size = UDim2.new(0, 60, 0, 20);
                    Position = UDim2.new(1, -65, 0, 3);
                    TextColor3 = Library.Options.textcolor;
                    BackgroundColor3 = Library.Options.boxcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    PlaceholderColor3 = Library.Options.placeholdercolor;
                    TextScaled = false;
                });
                Parent = self.container;
            });
        
            local BoxData = CheckData:FindFirstChild('Box');

            local ApiData;
            local function SetBoxValue(NewValue, FireCallback, EventData)
                local Old = Location[Flag];
                if ValueType == "number" then
                    local Numeric = tonumber(NewValue);
                    if (not Numeric) then
                        SetFlagValue(Location, Flag, "", ApiData, false);
                        BoxData.Text = "";
                    else
                        local Clamped = math.clamp(Numeric, Min, Max);
                        SetFlagValue(Location, Flag, Clamped, ApiData, false);
                        BoxData.Text = tostring(Clamped);
                    end
                else
                    local TextValue = tostring(NewValue or "");
                    SetFlagValue(Location, Flag, TextValue, ApiData, false);
                    BoxData.Text = TextValue;
                end

                if ShouldDispatchCallback(FireCallback) then
                    Callback(Location[Flag], Old, EventData);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(Location[Flag], Old, EventData);
                    end
                end
            end

            BoxData.FocusLost:Connect(function(e)
                if ValueType == "number" then
                    local Numeric = tonumber(BoxData.Text)
                    if (not Numeric) then
                        BoxData.Text = tostring(Location[Flag] or "");
                    else
                        SetBoxValue(Numeric, true, e);
                    end
                else
                    SetBoxValue(BoxData.Text, true, e);
                end
            end)
            
            if ValueType == 'number' then
                BoxData:GetPropertyChangedSignal('Text'):Connect(function()
                    local Normalized = string.gsub(BoxData.Text, "[^%d%.%-]", "");
                    if BoxData.Text ~= Normalized then
                        BoxData.Text = Normalized;
                    end
                end)
            end

            Library:RegisterFlagController(Location, Flag, {
                Set = function(Value, FireCallback)
                    SetBoxValue(Value, FireCallback, nil);
                end
            });
            
            self:Resize();
            ApiData = {
                Object = BoxData;
                TextBox = BoxData;
                Get = function()
                    return Location[Flag];
                end,
                Set = function(_, NewValue, FireCallback)
                    SetBoxValue(NewValue, FireCallback, nil);
                end,
            };

            local EnhancedApi = self:AttachControlFeatures(CheckData, Options, ApiData, {BoxData}, tostring(Name));
            return WrapInstanceApi(BoxData, EnhancedApi)
        end
        
        function Types:Bind(Name, Options, Callback)
            Options = Options or {};
            local Location     = Options.location or self.flags;
            local KeyboardOnly = Options.kbonly or false
            local Flag         = self:ResolveFlag(Options.flag, Name, "Bind");
            local ModeFlag     = tostring(Options.modeflag or Options.modeFlag or (Flag .. "_Mode"));
            local Callback     = Callback or function() end;
            local Default      = Options.default;
            local ModeOption   = Options.mode or Options.bindmode or Options.keybindmode or "press";

            local Banned = {
                Return = true;
                Space = true;
                Tab = true;
                Unknown = true;
            }
            
            local ShortNames = {
                RightControl = 'RightCtrl';
                LeftControl = 'LeftCtrl';
                LeftShift = 'LShift';
                RightShift = 'RShift';
                MouseButton1 = "Mouse1";
                MouseButton2 = "Mouse2";
            }
            
            local Allowed = {
                MouseButton1 = true;
                MouseButton2 = true;
            }

            local function NormalizeMode(Value)
                local Mode = string.lower(tostring(Value or "press"));
                if Mode == "toggle" then
                    return "toggle";
                end
                if Mode == "hold" or Mode == "held" then
                    return "hold";
                end
                if Mode == "always" then
                    return "always";
                end
                return "press";
            end

            local CurrentMode = NormalizeMode(ModeOption);
            local ToggleState = false;
            local HoldState = false;
            local AlwaysState = false;
            SetFlagValue(Location, ModeFlag, CurrentMode, nil, false);
            Library:RegisterFlag(Location, Flag);

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

            local function DebugBindLog(Message)
                if Library.BindDebug then
                    warn("[Wally Modified][BindDebug][" .. tostring(Flag ~= "" and Flag or Name) .. "] " .. tostring(Message));
                end
            end

            local function ReadInputObject(InputObject)
                local ValueType = typeof(InputObject);

                local OkUserInputType, UserInputType = pcall(function()
                    return InputObject.UserInputType;
                end);

                local OkKeyCode, KeyCode = pcall(function()
                    return InputObject.KeyCode;
                end);

                if not OkUserInputType then
                    return nil, nil, ValueType;
                end

                if not OkKeyCode then
                    KeyCode = nil;
                end

                return UserInputType, KeyCode, ValueType;
            end

            local function GetUserInputTypeName(UserInputType)
                if typeof(UserInputType) == "EnumItem" and UserInputType.EnumType == Enum.UserInputType then
                    return UserInputType.Name;
                end

                local Text = tostring(UserInputType):gsub("^Enum%.UserInputType%.", "");
                if Text ~= "" and Text ~= "nil" then
                    return Text;
                end

                return nil;
            end

            local function ParseKeyCode(KeyCodeValue)
                if typeof(KeyCodeValue) == "EnumItem" and KeyCodeValue.EnumType == Enum.KeyCode then
                    return KeyCodeValue;
                end

                local Text;
                if type(KeyCodeValue) == "string" then
                    Text = KeyCodeValue;
                else
                    Text = tostring(KeyCodeValue);
                end

                if type(Text) == "string" then
                    Text = Text:gsub("^Enum%.KeyCode%.", "");
                    return GetEnumItemSafe(Enum.KeyCode, Text);
                end

                return nil;
            end

            local function DetectPressedKeyboardKey()
                for _, KeyCode in next, Enum.KeyCode:GetEnumItems() do
                    if KeyCode ~= Enum.KeyCode.Unknown and (not Banned[KeyCode.Name]) and (not string.find(KeyCode.Name, "MouseButton", 1, true)) then
                        if UserInputService:IsKeyDown(KeyCode) then
                            return KeyCode;
                        end
                    end
                end
                return nil;
            end

            local function GetBindingFromInputObject(InputObject)
                local UserInputType, KeyCode = ReadInputObject(InputObject);
                if not UserInputType then
                    return nil;
                end

                local UserInputTypeName = GetUserInputTypeName(UserInputType);
                if UserInputTypeName == "Keyboard" or UserInputTypeName == "TextInput" then
                    local ParsedKeyCode = ParseKeyCode(KeyCode);
                    if ParsedKeyCode and ParsedKeyCode ~= Enum.KeyCode.Unknown and (not Banned[ParsedKeyCode.Name]) then
                        return ParsedKeyCode;
                    end

                    local FallbackKey = DetectPressedKeyboardKey();
                    if FallbackKey then
                        DebugBindLog("Fallback detected key via IsKeyDown: " .. tostring(FallbackKey.Name));
                        return FallbackKey;
                    end
                    return nil;
                end

                if (not KeyboardOnly) and UserInputTypeName and Allowed[UserInputTypeName] then
                    local ParsedInputType = GetEnumItemSafe(Enum.UserInputType, UserInputTypeName);
                    return ParsedInputType or UserInputType;
                end

                return nil;
            end

            local function NormalizeBinding(Value)
                if Value == nil then
                    return nil;
                end

                local ValueType = typeof(Value);
                if ValueType == "InputObject" then
                    return GetBindingFromInputObject(Value);
                end

                if ValueType == "EnumItem" then
                    if Value.EnumType == Enum.KeyCode then
                        return (not Banned[Value.Name]) and Value or nil;
                    end
                    if Value.EnumType == Enum.UserInputType then
                        return ((not KeyboardOnly) and Allowed[Value.Name]) and Value or nil;
                    end
                    return nil;
                end

                local Text = tostring(Value);
                if type(Text) == "string" then
                    Text = Text:gsub("^Enum%.KeyCode%.", ""):gsub("^Enum%.UserInputType%.", "");
                    local ParsedKeyCode = GetEnumItemSafe(Enum.KeyCode, Text);
                    if ParsedKeyCode and (not Banned[ParsedKeyCode.Name]) then
                        return ParsedKeyCode;
                    end

                    local ParsedInputType = GetEnumItemSafe(Enum.UserInputType, Text);
                    if ParsedInputType and (not KeyboardOnly) and Allowed[ParsedInputType.Name] then
                        return ParsedInputType;
                    end
                end

                return nil;
            end

            local function GetInputName(Value)
                if Value == nil then
                    return "None";
                end

                local Normalized = NormalizeBinding(Value);
                if Normalized then
                    return ShortNames[Normalized.Name] or Normalized.Name;
                end

                local ValueType = typeof(Value);
                if ValueType == "InputObject" then
                    local KeyName = (Value.UserInputType ~= Enum.UserInputType.Keyboard and Value.UserInputType.Name or Value.KeyCode.Name);
                    return ShortNames[KeyName] or KeyName;
                end

                if ValueType == "EnumItem" then
                    return ShortNames[Value.Name] or Value.Name;
                end

                local Text = tostring(Value);
                return ShortNames[Text] or Text;
            end

            local ApiData = {};

            local NormalizedDefault = NormalizeBinding(Default);
            if NormalizedDefault then
                SetFlagValue(Location, Flag, NormalizedDefault, ApiData, false);
            end

            local DisplayName = GetInputName(Location[Flag]);
            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 30);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = "Title";
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -72, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    BorderColor3     = Library.Options.bordercolor;
                    BorderSizePixel  = 1;
                    TextScaled = true;
                    TextWrapped = false;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                });
                Library:Create('TextButton', {
                    Name = 'Keybind';
                    Text = DisplayName;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    Size = UDim2.new(0, 60, 0, 20);
                    Position = UDim2.new(1, -65, 0, 5);
                    TextColor3 = Library.Options.textcolor;
                    BackgroundColor3 = Library.Options.bgcolor;
                    BorderColor3     = Library.Options.bordercolor;
                    BorderSizePixel  = 1;
                    TextScaled = false;
                });
                Parent = self.container;
            });
             
            local ButtonData = CheckData:FindFirstChild("Keybind");
            ButtonData.MouseButton1Click:Connect(function()
                Library.Binding = true

                local Ok, ErrorData = pcall(function()
                    local FocusedTextBox = UserInputService:GetFocusedTextBox();
                    if FocusedTextBox then
                        FocusedTextBox:ReleaseFocus();
                    end

                    local PreviousBinding = Location[Flag];
                    ButtonData.Text = "..."
                    while Library.Binding do
                        local InputObject, Gpe = UserInputService.InputBegan:Wait();
                        local UserInputType, KeyCode, InputValueType = ReadInputObject(InputObject);
                        local UserInputTypeName = GetUserInputTypeName(UserInputType);
                        local ParsedKeyCode = ParseKeyCode(KeyCode);

                        local KeyName = "nil";
                        if ParsedKeyCode then
                            KeyName = ParsedKeyCode.Name;
                        elseif typeof(KeyCode) == "EnumItem" then
                            KeyName = KeyCode.Name;
                        end

                        DebugBindLog(string.format(
                            "Captured Input | TypeOf=%s | UserInputType=%s | UserInputTypeName=%s | KeyCode=%s | KeyName=%s | Gpe=%s",
                            tostring(InputValueType),
                            tostring(UserInputType),
                            tostring(UserInputTypeName),
                            tostring(KeyCode),
                            tostring(KeyName),
                            tostring(Gpe)
                        ));

                        if UserInputTypeName == "Keyboard" or UserInputTypeName == "TextInput" then
                            if ParsedKeyCode == Enum.KeyCode.Escape then
                                DebugBindLog("Rebind cancelled with Escape");
                                break;
                            end
                            if ParsedKeyCode == Enum.KeyCode.Backspace or ParsedKeyCode == Enum.KeyCode.Delete then
                                SetFlagValue(Location, Flag, nil, ApiData, true);
                                DebugBindLog("Binding cleared with Backspace/Delete");
                                break;
                            end
                        end

                        local Normalized = GetBindingFromInputObject(InputObject);
                        if Normalized then
                            SetFlagValue(Location, Flag, Normalized, ApiData, true);
                            DebugBindLog("Binding changed to " .. tostring(Normalized.Name));
                            break;
                        else
                            DebugBindLog("Input ignored (not a bindable key/mouse)");
                        end
                    end

                    if ApiData and type(ApiData.EmitChanged) == "function" and PreviousBinding ~= Location[Flag] then
                        ApiData:EmitChanged(Location[Flag], PreviousBinding, "binding_changed");
                    end
                end);

                if not Ok then
                    warn("[Wally Modified] Bind normalize failed: " .. tostring(ErrorData));
                end

                ButtonData.Text = GetInputName(Location[Flag]);

                task.wait(0.1)
                Library.Binding = false;
            end)
            
            if Location[Flag] then
                SetFlagValue(Location, Flag, NormalizeBinding(Location[Flag]), ApiData, false);
            end
            ButtonData.Text = GetInputName(Location[Flag]);

	            self:Resize();

	            function ApiData:Set(NewBinding, FireCallback)
	                local Normalized = NormalizeBinding(NewBinding);
	                if NewBinding ~= nil and (not Normalized) then
	                    return false, "invalid binding";
	                end

	                local OldBinding = Location[Flag];
	                SetFlagValue(Location, Flag, Normalized, ApiData, false);
	                ButtonData.Text = GetInputName(Location[Flag]);

	                if FireCallback == true and ShouldDispatchCallback(true) then
	                    Callback(Location[Flag]);
                        if type(ApiData.EmitChanged) == "function" then
                            ApiData:EmitChanged(Location[Flag], OldBinding, "binding_set");
                        end
	                end

	                return true, Location[Flag];
	            end

	            function ApiData:Clear(FireCallback)
	                local OldBinding = Location[Flag];
	                SetFlagValue(Location, Flag, nil, ApiData, false);
	                ButtonData.Text = GetInputName(Location[Flag]);

	                if FireCallback == true and ShouldDispatchCallback(true) then
	                    Callback(Location[Flag]);
                        if type(ApiData.EmitChanged) == "function" then
                            ApiData:EmitChanged(Location[Flag], OldBinding, "binding_cleared");
                        end
	                end

	                return true;
	            end

	            function ApiData:Get()
	                return Location[Flag];
	            end

                function ApiData:SetMode(NewMode, FireCallback)
                    local OldMode = CurrentMode;
                    local NextMode = NormalizeMode(NewMode);
                    if OldMode == NextMode then
                        return NextMode;
                    end

                    if OldMode == "hold" and HoldState then
                        HoldState = false;
                        if ShouldDispatchCallback(FireCallback) then
                            Callback(false, Location[Flag], "hold_end");
                            if type(ApiData.EmitChanged) == "function" then
                                ApiData:EmitChanged(false, Location[Flag], "hold_end");
                            end
                        end
                    end
                    if OldMode == "toggle" and ToggleState then
                        ToggleState = false;
                    end
                    if OldMode == "always" and AlwaysState then
                        AlwaysState = false;
                        if ShouldDispatchCallback(FireCallback) then
                            Callback(false, Location[Flag], "always_end");
                            if type(ApiData.EmitChanged) == "function" then
                                ApiData:EmitChanged(false, Location[Flag], "always_end");
                            end
                        end
                    end

                    CurrentMode = NextMode;
                    SetFlagValue(Location, ModeFlag, CurrentMode, ApiData, false);
                    if NextMode == "always" then
                        AlwaysState = true;
                        if ShouldDispatchCallback(FireCallback) then
                            Callback(true, Location[Flag], "always_start");
                            if type(ApiData.EmitChanged) == "function" then
                                ApiData:EmitChanged(true, Location[Flag], "always_start");
                            end
                        end
                    end

                    return CurrentMode;
                end

                function ApiData:GetMode()
                    return CurrentMode;
                end

                function ApiData:GetState()
                    if CurrentMode == "toggle" then
                        return ToggleState;
                    end
                    if CurrentMode == "hold" then
                        return HoldState;
                    end
                    if CurrentMode == "always" then
                        return AlwaysState;
                    end
                    return false;
                end

                function ApiData:SetState(NewState, FireCallback)
                    local Desired = (NewState == true);
                    if CurrentMode == "toggle" then
                        ToggleState = Desired;
                        if ShouldDispatchCallback(FireCallback) then
                            Callback(ToggleState, Location[Flag], "toggle_state");
                            if type(ApiData.EmitChanged) == "function" then
                                ApiData:EmitChanged(ToggleState, Location[Flag], "toggle_state");
                            end
                        end
                        return ToggleState;
                    end
                    if CurrentMode == "hold" then
                        HoldState = Desired;
                        if ShouldDispatchCallback(FireCallback) then
                            Callback(HoldState, Location[Flag], (HoldState and "hold_start" or "hold_end"));
                            if type(ApiData.EmitChanged) == "function" then
                                ApiData:EmitChanged(HoldState, Location[Flag], (HoldState and "hold_start" or "hold_end"));
                            end
                        end
                        return HoldState;
                    end
                    if CurrentMode == "always" then
                        AlwaysState = Desired;
                        if ShouldDispatchCallback(FireCallback) then
                            Callback(AlwaysState, Location[Flag], (AlwaysState and "always_start" or "always_end"));
                            if type(ApiData.EmitChanged) == "function" then
                                ApiData:EmitChanged(AlwaysState, Location[Flag], (AlwaysState and "always_start" or "always_end"));
                            end
                        end
                        return AlwaysState;
                    end
                    return false;
                end

                Library:RegisterFlagController(Location, Flag, {
                    Set = function(NewBinding, FireCallback)
                        ApiData:Set(NewBinding, FireCallback);
                    end
                });
                Library:RegisterFlagController(Location, ModeFlag, {
                    Set = function(NewMode, FireCallback)
                        ApiData:SetMode(NewMode, FireCallback);
                    end
                });

	            local BindEntry = {
	                Location = Location;
	                Callback = Callback;
                    Api = ApiData;
                    GetMode = function()
                        return CurrentMode;
                    end;
                    SetMode = function(_, NewMode)
                        return ApiData:SetMode(NewMode, false);
                    end;
                    GetBinding = function()
                        return Location[Flag];
                    end;
                    GetState = function()
                        return ApiData:GetState();
                    end;
                    SetState = function(_, NewState, FireCallback)
                        return ApiData:SetState(NewState, FireCallback);
                    end;
	            };
                Library.Binds[Flag] = BindEntry;

                if CurrentMode == "always" then
                    AlwaysState = true;
                    if ShouldDispatchCallback(true) then
                        Callback(true, Location[Flag], "always_start");
                        if type(ApiData.EmitChanged) == "function" then
                            ApiData:EmitChanged(true, Location[Flag], "always_start");
                        end
                    end
                end

	            return self:AttachControlFeatures(CheckData, Options, ApiData, {ButtonData}, tostring(Name));
	        end
    
        function Types:Section(Name, Options)
            Options = Options or {};
            local OrderData = self:GetOrder();
            local DeterminedSize = UDim2.new(1, 0, 0, 25)
            local DeterminedPos = UDim2.new(0, 0, 0, 4);
            local SecondarySize = UDim2.new(1, 0, 0, 20);
                        
            if OrderData == 0 then
                DeterminedSize = UDim2.new(1, 0, 0, 21)
                DeterminedPos = UDim2.new(0, 0, 0, -1);
                SecondarySize = nil
            end
            
            local CheckData = Library:Create('Frame', {
                Name = 'Section';
                BackgroundTransparency = 1;
                Size = DeterminedSize;
                BackgroundColor3 = Library.Options.sectncolor;
                BorderSizePixel = 0;
                LayoutOrder = OrderData;
                Library:Create('TextLabel', {
                    Name = 'section_lbl';
                    Text = Name;
                    BackgroundTransparency = 0;
                    BorderSizePixel = 0;
                    BackgroundColor3 = Library.Options.sectncolor;
                    TextColor3 = Library.Options.textcolor;
                    Position = DeterminedPos;
                    Size     = (SecondarySize or UDim2.new(1, 0, 1, 0));
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                });
                Parent = self.container;
            });
        
            self:Resize();
            local ApiData = {};
            self:AttachControlFeatures(CheckData, Options, ApiData, {}, tostring(Name));
            return ApiData;
        end

        function Types:Label(Name, Options)
            Options = Options or {};

            local TextValue = tostring(Options.text or Options.Text or Name or "");
            local TextSize = tonumber(Options.textSize or Options.TextSize) or Library.Options.fontsize;
            local TextColor = Options.textColor or Options.TextColor or Library.Options.textcolor;
            local BgColor = Options.bgColor or Options.BgColor or Library.Options.sectncolor;
            local BorderColor = Options.borderColor or Options.BorderColor or Library.Options.bordercolor;
            local Height = tonumber(Options.height or Options.Height) or 25;
            local BgTransparency = tonumber(Options.backgroundTransparency or Options.BgTransparency);
            if BgTransparency == nil then
                BgTransparency = 0;
            end

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, Height);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = 'LabelText';
                    Text = TextValue;
                    BackgroundColor3 = BgColor;
                    BackgroundTransparency = BgTransparency;
                    BorderColor3 = BorderColor;
                    TextColor3 = TextColor;
                    Position = UDim2.new(0, 5, 0, 3);
                    Size = UDim2.new(1, -10, 1, -6);
                    Font = Library.Options.font;
                    TextSize = TextSize;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                });
                Parent = self.container;
            });

            local LabelObject = CheckData:FindFirstChild("LabelText");
            self:Resize();

            local ApiData = {
                Refresh = function(_, NewText)
                    LabelObject.Text = tostring(NewText);
                    local ParentWindow = self.ParentWindow or self;
                    if ParentWindow and type(ParentWindow.RefreshAutoWidth) == "function" then
                        ParentWindow:RefreshAutoWidth(false);
                    end
                end,
                SetColor = function(_, NewColor)
                    if typeof(NewColor) == "Color3" then
                        LabelObject.TextColor3 = NewColor;
                    end
                end,
                SetBackground = function(_, NewColor)
                    if typeof(NewColor) == "Color3" then
                        LabelObject.BackgroundColor3 = NewColor;
                    end
                end
            };

            return self:AttachControlFeatures(CheckData, Options, ApiData, {LabelObject}, tostring(TextValue));
        end

        function Types:ColorPicker(Name, Options, Callback)
            if typeof(Options) == "Color3" then
                Options = {default = Options};
            elseif type(Options) == "function" and Callback == nil then
                Callback = Options;
                Options = {};
            end

            Options = Options or {};
            local Location = Options.location or self.flags;
            local Flag = self:ResolveFlag(Options.flag, Name, "ColorPicker");
            local Callback = Callback or function() end;
            local TransparencyLocation = Options.transparencylocation or Location;
            local TransparencyFlag = Options.transparencyflag;
            if TransparencyFlag == nil or tostring(TransparencyFlag) == "" then
                TransparencyFlag = Flag .. "_Transparency";
            end

            local Default = Options.default or Options.color or Color3.fromRGB(255, 0, 0);
            if typeof(Default) ~= "Color3" then
                Default = Color3.fromRGB(255, 0, 0);
            end
            local DefaultTransparency = math.clamp(tonumber(Options.transparency or Options.alpha or 0) or 0, 0, 1);

            local PickerSize = math.clamp(tonumber(Options.size) or 120, 90, 180);
            local WheelImage = Options.wheelImage or "rbxassetid://6020299385";
            local WheelRadiusScale = math.clamp(tonumber(Options.wheelRadiusScale) or 1, 0.6, 1);
            local WheelOutsidePadding = math.max(0, tonumber(Options.wheelOutsidePadding) or 4);
            local EnableDrag = true;
            if Options.drag ~= nil then
                EnableDrag = Options.drag == true;
            elseif Options.draggable ~= nil then
                EnableDrag = Options.draggable == true;
            end
            local WheelTop = 6;
            local ShadeTop = WheelTop + PickerSize + 6;
            local AlphaTop = ShadeTop + 20;
            local HexTop = AlphaTop + 20;
            local RgbTop = HexTop + 22;
            local PopupWidth = PickerSize + 10;
            local PopupHeight = RgbTop + 22 + 6;

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = 'Title';
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size = UDim2.new(1, -35, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    TextScaled = true;
                    TextWrapped = false;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                });
                Library:Create('TextButton', {
                    Name = 'Preview';
                    Text = "";
                    AutoButtonColor = false;
                    Size = UDim2.new(0, 22, 0, 14);
                    Position = UDim2.new(1, -28, 0, 4);
                    BackgroundColor3 = Default;
                    BorderColor3 = Library.Options.bordercolor;
                });
                Parent = self.container;
            });

            local PopupParent = (Library.Container and Library.Container.Parent) or ResolveGuiParent();
            local PopupData = Library:Create('Frame', {
                Name = 'ColorPickerPopup';
                Visible = false;
                Size = UDim2.new(0, PopupWidth, 0, 0);
                Position = UDim2.new(0, 0, 0, 0);
                BackgroundColor3 = Library.Options.bgcolor;
                BorderColor3 = Library.Options.bordercolor;
                ClipsDescendants = true;
                Active = true;
                Parent = PopupParent;
                Library:Create('Frame', {
                    Name = 'WheelContainer';
                    Position = UDim2.new(0.5, -math.floor(PickerSize * 0.5), 0, WheelTop);
                    Size = UDim2.new(0, PickerSize, 0, PickerSize);
                    BackgroundColor3 = Library.Options.bgcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    Active = true;
                    Library:Create('ImageLabel', {
                        Name = 'Wheel';
                        BackgroundTransparency = 1;
                        Size = UDim2.new(1, 0, 1, 0);
                        Image = WheelImage;
                        ScaleType = Enum.ScaleType.Stretch;
                        Active = true;
                        Library:Create('Frame', {
                            Name = 'Selector';
                            AnchorPoint = Vector2.new(0.5, 0.5);
                            Size = UDim2.new(0, 10, 0, 10);
                            BackgroundTransparency = 1;
                            BorderSizePixel = 0;
                            Position = UDim2.new(0.5, 0, 0.5, 0);
                            Library:Create('Frame', {
                                Name = 'Outer';
                                AnchorPoint = Vector2.new(0.5, 0.5);
                                Position = UDim2.new(0.5, 0, 0.5, 0);
                                Size = UDim2.new(0, 10, 0, 10);
                                BackgroundTransparency = 1;
                                BorderColor3 = Color3.new(0, 0, 0);
                                BorderSizePixel = 2;
                                Library:Create('Frame', {
                                    Name = 'Inner';
                                    AnchorPoint = Vector2.new(0.5, 0.5);
                                    Position = UDim2.new(0.5, 0, 0.5, 0);
                                    Size = UDim2.new(0, 6, 0, 6);
                                    BackgroundTransparency = 1;
                                    BorderColor3 = Color3.new(1, 1, 1);
                                    BorderSizePixel = 1;
                                });
                            });
                        });
                    });
                });
                Library:Create('Frame', {
                    Name = 'ShadeBar';
                    Position = UDim2.new(0.5, -math.floor(PickerSize * 0.5), 0, ShadeTop);
                    Size = UDim2.new(0, PickerSize, 0, 14);
                    BackgroundColor3 = Library.Options.bgcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    ClipsDescendants = true;
                    Active = true;
                    Library:Create('Frame', {
                        Name = 'ShadeTint';
                        Position = UDim2.new(0, 0, 0, 0);
                        Size = UDim2.new(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = Color3.fromRGB(255, 0, 0);
                        Library:Create('UIGradient', {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1));
                                ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0));
                            });
                        });
                    });
                    Library:Create('Frame', {
                        Name = 'ShadeKnob';
                        AnchorPoint = Vector2.new(0.5, 0.5);
                        Position = UDim2.new(0, 0, 0.5, 0);
                        Size = UDim2.new(0, 6, 1, 2);
                        BackgroundColor3 = Library.Options.textcolor;
                        BorderColor3 = Library.Options.strokecolor;
                    });
                });
                Library:Create('Frame', {
                    Name = 'AlphaBar';
                    Position = UDim2.new(0.5, -math.floor(PickerSize * 0.5), 0, AlphaTop);
                    Size = UDim2.new(0, PickerSize, 0, 14);
                    BackgroundColor3 = Library.Options.bgcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    ClipsDescendants = true;
                    Active = true;
                    Library:Create('Frame', {
                        Name = 'AlphaTint';
                        Position = UDim2.new(0, 0, 0, 0);
                        Size = UDim2.new(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = Default;
                        Library:Create('UIGradient', {
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0);
                                NumberSequenceKeypoint.new(1, 1);
                            });
                        });
                    });
                    Library:Create('Frame', {
                        Name = 'AlphaKnob';
                        AnchorPoint = Vector2.new(0.5, 0.5);
                        Position = UDim2.new(0, 0, 0.5, 0);
                        Size = UDim2.new(0, 6, 1, 2);
                        BackgroundColor3 = Library.Options.textcolor;
                        BorderColor3 = Library.Options.strokecolor;
                    });
                });
                Library:Create('Frame', {
                    Name = 'HexRow';
                    Position = UDim2.new(0, 5, 0, HexTop);
                    Size = UDim2.new(1, -10, 0, 20);
                    BackgroundTransparency = 1;
                    Library:Create('TextLabel', {
                        Name = 'Label';
                        Text = "HEX";
                        BackgroundTransparency = 1;
                        TextColor3 = Library.Options.textcolor;
                        Position = UDim2.new(0, 0, 0, 0);
                        Size = UDim2.new(0, 34, 1, 0);
                        TextXAlignment = Enum.TextXAlignment.Left;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    });
                    Library:Create('TextBox', {
                        Name = 'Input';
                        Text = "";
                        ClearTextOnFocus = false;
                        PlaceholderText = "#RRGGBB";
                        TextColor3 = Library.Options.textcolor;
                        BackgroundColor3 = Library.Options.boxcolor;
                        BorderColor3 = Library.Options.bordercolor;
                        PlaceholderColor3 = Library.Options.placeholdercolor;
                        Position = UDim2.new(0, 34, 0, 0);
                        Size = UDim2.new(1, -34, 1, 0);
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    });
                });
                Library:Create('Frame', {
                    Name = 'RgbRow';
                    Position = UDim2.new(0, 5, 0, RgbTop);
                    Size = UDim2.new(1, -10, 0, 20);
                    BackgroundTransparency = 1;
                    Library:Create('TextLabel', {
                        Name = 'Label';
                        Text = "RGB";
                        BackgroundTransparency = 1;
                        TextColor3 = Library.Options.textcolor;
                        Position = UDim2.new(0, 0, 0, 0);
                        Size = UDim2.new(0, 34, 1, 0);
                        TextXAlignment = Enum.TextXAlignment.Left;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    });
                    Library:Create('TextBox', {
                        Name = 'Input';
                        Text = "";
                        ClearTextOnFocus = false;
                        PlaceholderText = "255, 0, 0";
                        TextColor3 = Library.Options.textcolor;
                        BackgroundColor3 = Library.Options.boxcolor;
                        BorderColor3 = Library.Options.bordercolor;
                        PlaceholderColor3 = Library.Options.placeholdercolor;
                        Position = UDim2.new(0, 34, 0, 0);
                        Size = UDim2.new(1, -34, 1, 0);
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    });
                });
            });

            local ModalBlocker = Library:Create('TextButton', {
                Name = 'ColorPickerModalBlocker';
                Visible = false;
                Text = "";
                AutoButtonColor = false;
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Active = true;
                Selectable = false;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 40;
                Parent = PopupParent;
            });
            PopupData.Parent = ModalBlocker;
            table.insert(Library.CleanupInstances, ModalBlocker);
            local ParentWindowData = self.ParentWindow or self;
            if type(ParentWindowData) == "table" then
                ParentWindowData.PopupInstances = ParentWindowData.PopupInstances or {};
                table.insert(ParentWindowData.PopupInstances, ModalBlocker);
            end

            local function SetGuiZIndex(Root, Z)
                if Root:IsA("GuiObject") then
                    Root.ZIndex = Z;
                end
                for _, Descendant in next, Root:GetDescendants() do
                    if Descendant:IsA("GuiObject") then
                        Descendant.ZIndex = Z;
                    end
                end
            end
            SetGuiZIndex(PopupData, 41);

            local PopupCloseButton = Library:Create('TextButton', {
                Name = 'Close';
                Text = "x";
                AutoButtonColor = false;
                Size = UDim2.new(0, 14, 0, 14);
                Position = UDim2.new(1, -16, 0, 2);
                BackgroundColor3 = Library.Options.boxcolor;
                BorderColor3 = Library.Options.bordercolor;
                TextColor3 = Library.Options.textcolor;
                Font = Library.Options.font;
                TextSize = Library.Options.fontsize;
                TextStrokeTransparency = Library.Options.textstroke;
                TextStrokeColor3 = Library.Options.strokecolor;
                ZIndex = 42;
                Parent = PopupData;
            });

            local Preview = CheckData:FindFirstChild("Preview");
            local WheelContainer = PopupData:FindFirstChild("WheelContainer");
            local Wheel = WheelContainer and WheelContainer:FindFirstChild("Wheel");
            local Selector = Wheel and Wheel:FindFirstChild("Selector");
            local ShadeBar = PopupData:FindFirstChild("ShadeBar");
            local ShadeTint = ShadeBar and ShadeBar:FindFirstChild("ShadeTint");
            local ShadeKnob = ShadeBar and ShadeBar:FindFirstChild("ShadeKnob");
            local AlphaBar = PopupData:FindFirstChild("AlphaBar");
            local AlphaTint = AlphaBar and AlphaBar:FindFirstChild("AlphaTint");
            local AlphaKnob = AlphaBar and AlphaBar:FindFirstChild("AlphaKnob");
            local HexInput = PopupData:FindFirstChild("HexRow") and PopupData.HexRow:FindFirstChild("Input");
            local RgbInput = PopupData:FindFirstChild("RgbRow") and PopupData.RgbRow:FindFirstChild("Input");

            local WheelDragging = false;
            local ShadeDragging = false;
            local AlphaDragging = false;
            local PopupOpen = false;
            local ActiveWheelInput;
            local ActiveShadeInput;
            local ActiveAlphaInput;

            local Hue, Saturation, Value = Default:ToHSV();
            local CurrentColor = Default;
            local CurrentTransparency = DefaultTransparency;
            local ApiData;

            local function Clamp01(Number)
                return math.clamp(tonumber(Number) or 0, 0, 1);
            end

            local function ColorToRgbTuple(NewColor)
                return math.floor(NewColor.R * 255 + 0.5), math.floor(NewColor.G * 255 + 0.5), math.floor(NewColor.B * 255 + 0.5);
            end

            local function ColorToHex(NewColor)
                local R, G, B = ColorToRgbTuple(NewColor);
                return string.format("#%02X%02X%02X", R, G, B);
            end

            local function ParseHex(Text)
                local Working = tostring(Text or ""):upper():gsub("%s+", ""):gsub("#", "");
                if #Working == 3 and Working:find("^[%x]+$") then
                    Working = Working:sub(1, 1):rep(2) .. Working:sub(2, 2):rep(2) .. Working:sub(3, 3):rep(2);
                end
                if #Working ~= 6 or (not Working:find("^[%x]+$")) then
                    return nil;
                end

                local R = tonumber(Working:sub(1, 2), 16);
                local G = tonumber(Working:sub(3, 4), 16);
                local B = tonumber(Working:sub(5, 6), 16);
                if (not R) or (not G) or (not B) then
                    return nil;
                end

                return Color3.fromRGB(R, G, B);
            end

            local function ParseRgb(Text)
                local Numbers = {};
                for Number in tostring(Text or ""):gmatch("[%-]?%d+") do
                    Numbers[#Numbers + 1] = math.clamp(tonumber(Number) or 0, 0, 255);
                    if #Numbers == 3 then
                        break;
                    end
                end

                if #Numbers < 3 then
                    return nil;
                end

                return Color3.fromRGB(Numbers[1], Numbers[2], Numbers[3]);
            end

            local function GetRadius()
                local Radius = math.min(Wheel.AbsoluteSize.X, Wheel.AbsoluteSize.Y) * 0.5;
                if Radius <= 0 then
                    Radius = PickerSize * 0.5;
                end
                return Radius * WheelRadiusScale;
            end

            local function IsPointInsideGui(GuiObject, Point)
                if not GuiObject or (not GuiObject.Parent) then
                    return false;
                end
                local Position = GuiObject.AbsolutePosition;
                local Size = GuiObject.AbsoluteSize;
                return Point.X >= Position.X and Point.X <= (Position.X + Size.X) and Point.Y >= Position.Y and Point.Y <= (Position.Y + Size.Y);
            end

            local function ResolvePointerPosition(InputObject)
                if InputObject and typeof(InputObject.Position) == "Vector3" then
                    return Vector2.new(InputObject.Position.X, InputObject.Position.Y);
                end
                local MousePos = UserInputService:GetMouseLocation();
                return Vector2.new(MousePos.X, MousePos.Y);
            end

            local function HueToWheelAngle(HueValue)
                return (0.5 - HueValue) * (2 * math.pi);
            end

            local function WheelAngleToHue(AngleValue)
                return (0.5 - (AngleValue / (2 * math.pi))) % 1;
            end

            local function UpdateInputs()
                local FocusedBox = UserInputService:GetFocusedTextBox();
                if HexInput and FocusedBox ~= HexInput then
                    HexInput.Text = ColorToHex(CurrentColor);
                end
                if RgbInput and FocusedBox ~= RgbInput then
                    local R, G, B = ColorToRgbTuple(CurrentColor);
                    RgbInput.Text = string.format("%d, %d, %d", R, G, B);
                end
            end

            local function UpdateVisuals()
                if Selector then
                    local Radius = GetRadius();
                    local Angle = HueToWheelAngle(Hue);
                    local Distance = Saturation * Radius;
                    local Offset = Vector2.new(math.cos(Angle), math.sin(Angle)) * Distance;
                    Selector.Position = UDim2.new(0.5, Offset.X, 0.5, Offset.Y);
                end

                if ShadeTint then
                    ShadeTint.BackgroundColor3 = Color3.fromHSV(Hue, Saturation, 1);
                end

                if ShadeKnob then
                    ShadeKnob.Position = UDim2.new(1 - Value, 0, 0.5, 0);
                end

                if AlphaTint then
                    AlphaTint.BackgroundColor3 = CurrentColor;
                end

                if AlphaKnob then
                    AlphaKnob.Position = UDim2.new(CurrentTransparency, 0, 0.5, 0);
                end

                if Preview then
                    Preview.BackgroundColor3 = CurrentColor;
                    Preview.BackgroundTransparency = CurrentTransparency;
                end
            end

            local function ApplyState(NewHue, NewSaturation, NewValue, NewTransparency, FireCallback)
                Hue = (tonumber(NewHue) or Hue or 0) % 1;
                Saturation = Clamp01(NewSaturation or Saturation);
                Value = Clamp01(NewValue or Value);
                CurrentTransparency = Clamp01(NewTransparency or CurrentTransparency);
                CurrentColor = Color3.fromHSV(Hue, Saturation, Value);

                local OldColor = Location[Flag];
                local OldTransparency = (TransparencyFlag ~= nil and tostring(TransparencyFlag) ~= "" and TransparencyLocation[TransparencyFlag]) or nil;
                SetFlagValue(Location, Flag, CurrentColor, ApiData, false);
                if TransparencyFlag ~= nil and tostring(TransparencyFlag) ~= "" then
                    SetFlagValue(TransparencyLocation, TransparencyFlag, CurrentTransparency, ApiData, false);
                end

                UpdateVisuals();
                UpdateInputs();

                if ShouldDispatchCallback(FireCallback) then
                    Callback(CurrentColor, CurrentTransparency);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(CurrentColor, CurrentTransparency, OldColor, OldTransparency);
                    end
                end
            end

            local function ApplyColor(NewColor, FireCallback, NewTransparency)
                if typeof(NewColor) ~= "Color3" then
                    return;
                end
                local NewHue, NewSaturation, NewValue = NewColor:ToHSV();
                ApplyState(NewHue, NewSaturation, NewValue, NewTransparency, FireCallback);
            end

            local function PositionPopup()
                if (not Preview) or (not Preview.Parent) then
                    return;
                end

                local Camera = workspace.CurrentCamera;
                local ViewportSize = (Camera and Camera.ViewportSize) or Vector2.new(1920, 1080);
                local PreviewPos = Preview.AbsolutePosition;
                local PreviewSize = Preview.AbsoluteSize;
                local X = PreviewPos.X + PreviewSize.X + 6;
                local Y = PreviewPos.Y - 4;

                if X + PopupWidth > ViewportSize.X - 6 then
                    X = PreviewPos.X - PopupWidth - 6;
                end
                if X < 6 then
                    X = 6;
                end
                if Y + PopupHeight > ViewportSize.Y - 6 then
                    Y = ViewportSize.Y - PopupHeight - 6;
                end
                if Y < 6 then
                    Y = 6;
                end

                PopupData.Position = UDim2.new(0, X, 0, Y);
            end

            local function SetPopupVisible(State, Instant)
                if State then
                    if Library.ActiveColorPopup and Library.ActiveColorPopup ~= PopupData and type(Library.ActiveColorPopupController) == "function" then
                        pcall(Library.ActiveColorPopupController, false, true);
                    end

                    PopupOpen = true;
                    PositionPopup();
                    PopupData.Visible = true;
                    ModalBlocker.Visible = true;

                    if Instant then
                        PopupData.Size = UDim2.new(0, PopupWidth, 0, PopupHeight);
                    else
                        PopupData.Size = UDim2.new(0, PopupWidth, 0, 0);
                        PopupData:TweenSize(UDim2.new(0, PopupWidth, 0, PopupHeight), "Out", "Quint", .16, true);
                    end

                    Library.ActiveColorPopup = PopupData;
                    Library.ActiveColorPopupController = SetPopupVisible;
                    return;
                end

                PopupOpen = false;
                WheelDragging = false;
                ShadeDragging = false;
                AlphaDragging = false;
                ActiveWheelInput = nil;
                ActiveShadeInput = nil;
                ActiveAlphaInput = nil;

                if Library.ActiveColorPopup == PopupData then
                    Library.ActiveColorPopup = nil;
                    Library.ActiveColorPopupController = nil;
                end

                if (not PopupData.Parent) then
                    return;
                end

                if Instant then
                    PopupData.Visible = false;
                    PopupData.Size = UDim2.new(0, PopupWidth, 0, 0);
                    ModalBlocker.Visible = false;
                else
                    PopupData:TweenSize(UDim2.new(0, PopupWidth, 0, 0), "In", "Quint", .13, true);
                    task.delay(0.14, function()
                        if (not PopupOpen) and PopupData and PopupData.Parent then
                            PopupData.Visible = false;
                            ModalBlocker.Visible = false;
                        end
                    end);
                end
            end

            local function UpdateFromWheelPointer(PointerPos)
                local MousePos = PointerPos or ResolvePointerPosition(ActiveWheelInput);
                local Center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize * 0.5);
                local Offset = MousePos - Center;
                local Radius = GetRadius();

                local Magnitude = Offset.Magnitude;
                if Magnitude > (Radius + WheelOutsidePadding) then
                    return;
                end
                if Magnitude > Radius and Magnitude > 0 then
                    Offset = Offset.Unit * Radius;
                    Magnitude = Radius;
                end

                local NewSaturation = (Radius > 0 and (Magnitude / Radius) or 0);
                local Angle = math.atan2(Offset.Y, Offset.X);
                local NewHue = WheelAngleToHue(Angle);
                ApplyState(NewHue, NewSaturation, 1, CurrentTransparency, true);
            end

            local function UpdateFromShadePointer(PointerPos)
                local MousePos = PointerPos or ResolvePointerPosition(ActiveShadeInput);
                local ShadeWidth = math.max(ShadeBar.AbsoluteSize.X, 1);
                local Percent = (MousePos.X - ShadeBar.AbsolutePosition.X) / ShadeWidth;
                Percent = math.clamp(Percent, 0, 1);
                ApplyState(Hue, Saturation, 1 - Percent, CurrentTransparency, true);
            end

            local function UpdateFromAlphaPointer(PointerPos)
                local MousePos = PointerPos or ResolvePointerPosition(ActiveAlphaInput);
                local AlphaWidth = math.max(AlphaBar.AbsoluteSize.X, 1);
                local Percent = (MousePos.X - AlphaBar.AbsolutePosition.X) / AlphaWidth;
                Percent = math.clamp(Percent, 0, 1);
                ApplyState(Hue, Saturation, Value, Percent, true);
            end

            local function IsPointerInput(InputObject)
                return InputObject.UserInputType == Enum.UserInputType.MouseButton1 or InputObject.UserInputType == Enum.UserInputType.Touch;
            end

            local function BeginWheelDrag(Input)
                if (not PopupOpen) or (not IsPointerInput(Input)) then
                    return;
                end

                local PointerPos = ResolvePointerPosition(Input);

                local Center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize * 0.5);
                local Radius = GetRadius();
                if (PointerPos - Center).Magnitude > (Radius + WheelOutsidePadding) then
                    return;
                end

                UpdateFromWheelPointer(PointerPos);
                if EnableDrag then
                    WheelDragging = true;
                    ShadeDragging = false;
                    AlphaDragging = false;
                    ActiveWheelInput = Input;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = nil;
                else
                    WheelDragging = false;
                    ShadeDragging = false;
                    AlphaDragging = false;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = nil;
                end
            end

            local function BeginShadeDrag(Input)
                if (not PopupOpen) or (not IsPointerInput(Input)) then
                    return;
                end

                local PointerPos = ResolvePointerPosition(Input);
                if not IsPointInsideGui(ShadeBar, PointerPos) then
                    return;
                end

                UpdateFromShadePointer(PointerPos);
                if EnableDrag then
                    WheelDragging = false;
                    ShadeDragging = true;
                    AlphaDragging = false;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = Input;
                    ActiveAlphaInput = nil;
                else
                    WheelDragging = false;
                    ShadeDragging = false;
                    AlphaDragging = false;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = nil;
                end
            end

            local function BeginAlphaDrag(Input)
                if (not PopupOpen) or (not IsPointerInput(Input)) then
                    return;
                end

                local PointerPos = ResolvePointerPosition(Input);
                if not IsPointInsideGui(AlphaBar, PointerPos) then
                    return;
                end

                UpdateFromAlphaPointer(PointerPos);
                if EnableDrag then
                    WheelDragging = false;
                    ShadeDragging = false;
                    AlphaDragging = true;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = Input;
                else
                    WheelDragging = false;
                    ShadeDragging = false;
                    AlphaDragging = false;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = nil;
                end
            end

            if Preview then
                Preview.MouseButton1Click:Connect(function()
                    SetPopupVisible(not PopupOpen, false);
                end);
            end
            PopupCloseButton.MouseButton1Click:Connect(function()
                SetPopupVisible(false, false);
            end);

            WheelContainer.InputBegan:Connect(function(Input)
                BeginWheelDrag(Input);
            end);
            Wheel.InputBegan:Connect(function(Input)
                BeginWheelDrag(Input);
            end);

            ModalBlocker.InputBegan:Connect(function(Input)
                if PopupOpen and IsPointerInput(Input) then
                    local PointerPos = ResolvePointerPosition(Input);
                    if not IsPointInsideGui(PopupData, PointerPos) then
                        task.defer(function()
                            if PopupOpen then
                                SetPopupVisible(false, false);
                            end
                        end);
                    end
                end
            end);

            ShadeBar.InputBegan:Connect(function(Input)
                BeginShadeDrag(Input);
            end);

            AlphaBar.InputBegan:Connect(function(Input)
                BeginAlphaDrag(Input);
            end);

            UserInputService.InputChanged:Connect(function(Input)
                if (not PopupOpen) then
                    return;
                end

                if (not EnableDrag) then
                    return;
                end

                if WheelDragging and ActiveWheelInput then
                    if ActiveWheelInput.UserInputType == Enum.UserInputType.Touch then
                        if Input == ActiveWheelInput then
                            UpdateFromWheelPointer(ResolvePointerPosition(Input));
                        end
                    elseif Input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateFromWheelPointer(ResolvePointerPosition(Input));
                    end
                end
                if ShadeDragging and ActiveShadeInput then
                    if ActiveShadeInput.UserInputType == Enum.UserInputType.Touch then
                        if Input == ActiveShadeInput then
                            UpdateFromShadePointer(ResolvePointerPosition(Input));
                        end
                    elseif Input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateFromShadePointer(ResolvePointerPosition(Input));
                    end
                end
                if AlphaDragging and ActiveAlphaInput then
                    if ActiveAlphaInput.UserInputType == Enum.UserInputType.Touch then
                        if Input == ActiveAlphaInput then
                            UpdateFromAlphaPointer(ResolvePointerPosition(Input));
                        end
                    elseif Input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateFromAlphaPointer(ResolvePointerPosition(Input));
                    end
                end
            end);

            UserInputService.InputEnded:Connect(function(Input)
                if IsPointerInput(Input) then
                    if Input == ActiveWheelInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and ActiveWheelInput and ActiveWheelInput.UserInputType == Enum.UserInputType.MouseButton1) then
                        WheelDragging = false;
                        ActiveWheelInput = nil;
                    end
                    if Input == ActiveShadeInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and ActiveShadeInput and ActiveShadeInput.UserInputType == Enum.UserInputType.MouseButton1) then
                        ShadeDragging = false;
                        ActiveShadeInput = nil;
                    end
                    if Input == ActiveAlphaInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and ActiveAlphaInput and ActiveAlphaInput.UserInputType == Enum.UserInputType.MouseButton1) then
                        AlphaDragging = false;
                        ActiveAlphaInput = nil;
                    end
                end
            end);

            HexInput.FocusLost:Connect(function()
                local Parsed = ParseHex(HexInput.Text);
                if Parsed then
                    ApplyColor(Parsed, true, CurrentTransparency);
                else
                    UpdateInputs();
                end
            end);

            RgbInput.FocusLost:Connect(function()
                local Parsed = ParseRgb(RgbInput.Text);
                if Parsed then
                    ApplyColor(Parsed, true, CurrentTransparency);
                else
                    UpdateInputs();
                end
            end);

            ApplyColor(Default, false, DefaultTransparency);
            SetPopupVisible(false, true);

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewColor, FireCallback)
                    ApplyColor(NewColor, FireCallback, CurrentTransparency);
                end
            });
            if TransparencyFlag ~= nil and tostring(TransparencyFlag) ~= "" then
                Library:RegisterFlagController(TransparencyLocation, TransparencyFlag, {
                    Set = function(NewTransparency, FireCallback)
                        ApplyState(Hue, Saturation, Value, NewTransparency, FireCallback);
                    end
                });
            end

            self:Resize();
            ApiData = {
                Set = function(_, NewColor, FireCallback)
                    ApplyColor(NewColor, FireCallback, CurrentTransparency);
                end,
                Get = function()
                    return Location[Flag];
                end,
                SetHSV = function(_, NewHue, NewSaturation, NewValue, FireCallback)
                    ApplyState(NewHue, NewSaturation, NewValue, CurrentTransparency, FireCallback);
                end,
                GetHSV = function()
                    return Hue, Saturation, Value;
                end,
                SetTransparency = function(_, NewTransparency, FireCallback)
                    ApplyState(Hue, Saturation, Value, NewTransparency, FireCallback);
                end,
                GetTransparency = function()
                    return CurrentTransparency;
                end,
                SetAlpha = function(_, NewTransparency, FireCallback)
                    ApplyState(Hue, Saturation, Value, NewTransparency, FireCallback);
                end,
                GetAlpha = function()
                    return CurrentTransparency;
                end
            };

            return self:AttachControlFeatures(CheckData, Options, ApiData, {Preview, HexInput, RgbInput, PopupCloseButton}, tostring(Name));
        end

        function Types:Slider(Name, Options, Callback)
            Options = Options or {};
            local Default = Options.default or Options.min;
            local Min = Options.min or 0;
            local Max = Options.max or 1;
            local Location = Options.location or self.flags;
            local Precise  = Options.precise  or false
            local Decimals = math.clamp(math.floor(tonumber(Options.decimals) or 2), 0, 6);
            local Step = tonumber(Options.step);
            if Step ~= nil then
                Step = math.abs(Step);
                if Step <= 0 then
                    Step = nil;
                end
            end
            local SliderValueWidth = math.clamp(math.floor((tonumber(Options.valueWidth or Options.valuewidth or Options.valueLabelWidth) or 40) + 0.5), 24, 80);
            local SliderTrackInset = SliderValueWidth + 2;
            local SliderContainerWidth = math.clamp(SliderTrackInset + 36, 58, 140);
            local SliderTitleRightPadding = SliderContainerWidth + 8;
            local Flag     = self:ResolveFlag(Options.flag, Name, "Slider");
            local Callback = Callback or function() end

            if Min > Max then
                Min, Max = Max, Min;
            end

            local function GetStepDecimals(Value)
                if type(Value) ~= "number" then
                    return 0;
                end
                local Text = tostring(Value);
                local DotIndex = string.find(Text, ".", 1, true);
                if not DotIndex then
                    return 0;
                end
                local Count = #Text - DotIndex;
                return math.clamp(Count, 0, 6);
            end
            local StepDecimals = GetStepDecimals(Step);
            local DisplayDecimals = math.clamp(math.max(Decimals, StepDecimals), 0, 6);

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = Name;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Text = "";
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    Position = UDim2.new(0, 5, 0, 2);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    Library:Create('TextLabel', {
                        Name = 'Title';
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                        Text = "\r" .. Name;
                        BackgroundTransparency = 1;
                        TextColor3 = Library.Options.textcolor;
                        Position = UDim2.new(0, 0, 0, 0);
                        Size     = UDim2.new(1, -SliderTitleRightPadding, 1, 0);
                        TextXAlignment = Enum.TextXAlignment.Left;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextScaled = true;
                        TextWrapped = false;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                    });
                    Library:Create('Frame', {
                        Name = 'Container';
                        Size = UDim2.new(0, SliderContainerWidth, 0, 20);
                        Position = UDim2.new(1, -(SliderContainerWidth + 5), 0, 3);
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        Library:Create('TextLabel', {
                            Name = 'ValueLabel';
                            Text = Default;
                            BackgroundTransparency = 1;
                            TextColor3 = Library.Options.textcolor;
                            Position = UDim2.new(0, 0, 0, 0);
                            Size     = UDim2.new(0, SliderValueWidth, 1, 0);
                            TextXAlignment = Enum.TextXAlignment.Right;
                            Font = Library.Options.font;
                            TextSize = Library.Options.fontsize;
                            TextScaled = false;
                            TextWrapped = false;
                            TextTruncate = Enum.TextTruncate.AtEnd;
                            TextStrokeTransparency = Library.Options.textstroke;
                            TextStrokeColor3 = Library.Options.strokecolor;
                        });
                        Library:Create('TextButton', {
                            Name = 'Button';
                            Size = UDim2.new(0, 5, 1, -2);
                            Position = UDim2.new(0, SliderTrackInset, 0, 1);
                            AutoButtonColor = false;
                            Text = "";
                            BackgroundColor3 = Color3.fromRGB(20, 20, 20);
                            BorderSizePixel = 0;
                            ZIndex = 2;
                            TextStrokeTransparency = Library.Options.textstroke;
                            TextStrokeColor3 = Library.Options.strokecolor;
                        });
                        Library:Create('Frame', {
                            Name = 'Line';
                            BackgroundTransparency = 0;
                            Position = UDim2.new(0, SliderTrackInset, 0.5, 0);
                            Size     = UDim2.new(1, -SliderTrackInset, 0, 1);
                            BackgroundColor3 = Library.Options.textcolor;
                            BorderSizePixel = 0;
                        });
                    })
                });
                Parent = self.container;
            });

            local Overlay = CheckData:FindFirstChild(Name);
            local SliderContainer = Overlay:FindFirstChild("Container");
            local Knob = SliderContainer:FindFirstChild("Button");
            local ValueLabel = SliderContainer:FindFirstChild("ValueLabel");

            local Dragging = false;
            local CurrentValue;
            local PrecisionFactor = 10 ^ Decimals;
            local TrackInset = SliderTrackInset;
            local ApiData;
            Library:RegisterFlag(Location, Flag);

            local function NormalizeValue(Raw)
                local Value = math.clamp(tonumber(Raw) or Min, Min, Max);

                if Step then
                    local Steps = math.floor((((Value - Min) / Step) + 0.5));
                    Value = Min + (Steps * Step);
                    Value = math.clamp(Value, Min, Max);
                end

                if Precise then
                    return math.floor((Value * PrecisionFactor) + 0.5) / PrecisionFactor;
                end
                if Step and StepDecimals > 0 then
                    local StepPrecision = 10 ^ StepDecimals;
                    return math.floor((Value * StepPrecision) + 0.5) / StepPrecision;
                end
                return math.floor(Value);
            end

            local function FormatValue(Value)
                if Precise or (Step and StepDecimals > 0) then
                    return string.format("%." .. tostring(DisplayDecimals) .. "f", Value);
                end
                return tostring(Value);
            end

            local function ValueToPercent(Value)
                if Max == Min then
                    return 0;
                end
                return math.clamp((Value - Min) / (Max - Min), 0, 1);
            end

            local function SetValue(RawValue, FireCallback)
                local Value = NormalizeValue(RawValue);
                local Percent = ValueToPercent(Value);
                local TrackWidth = math.max(SliderContainer.AbsoluteSize.X - TrackInset, 1);
                local KnobWidth = math.max(Knob.AbsoluteSize.X, 5);
                local MaxOffset = math.max(TrackWidth - KnobWidth, 0);
                local KnobOffset = TrackInset + (MaxOffset * math.clamp(Percent, 0, 1));

                Knob.Position = UDim2.new(0, KnobOffset, 0, 1);
                ValueLabel.Text = FormatValue(Value);
                local OldValue = Location[Flag];
                SetFlagValue(Location, Flag, Value, ApiData, false);

                if CurrentValue ~= Value then
                    CurrentValue = Value;
                    if ShouldDispatchCallback(FireCallback) then
                        Callback(Value);
                        if ApiData and type(ApiData.EmitChanged) == "function" then
                            ApiData:EmitChanged(Value, OldValue);
                        end
                    end
                end
            end

            local function UpdateFromMouse()
                local MousePos = UserInputService:GetMouseLocation();
                local TrackWidth = math.max(SliderContainer.AbsoluteSize.X - TrackInset, 1);
                local TrackStartX = SliderContainer.AbsolutePosition.X + TrackInset;
                local Percent = (MousePos.X - TrackStartX) / TrackWidth;
                Percent = math.clamp(Percent, 0, 1);
                SetValue(Min + ((Max - Min) * Percent), true);
            end

            SliderContainer.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = true;
                    UpdateFromMouse();
                end
            end)

            Knob.MouseButton1Down:Connect(function()
                Dragging = true;
                UpdateFromMouse();
            end)

            UserInputService.InputChanged:Connect(function(Input)
                if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateFromMouse();
                end
            end)

            UserInputService.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = false;
                end
            end)

            SetValue(Default or Min, false);

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewValue, FireCallback)
                    SetValue(NewValue, FireCallback);
                end
            });

            self:Resize();
            ApiData = {
                Set = function(self, Value)
                    SetValue(Value, true);
                end,
                Get = function()
                    return Location[Flag];
                end
            };

            return self:AttachControlFeatures(CheckData, Options, ApiData, {SliderContainer, Knob}, tostring(Name));
        end 

        function Types:SearchBox(Text, Options, Callback)
            Options = Options or {};
            local ListData = Options.list or {};
            local Flag = self:ResolveFlag(Options.flag, Text, "SearchBox");
            local Location = Options.location or self.flags;
            local Callback = Callback or function() end;
            local ApiData;
            Library:RegisterFlag(Location, Flag);

            local Busy = false;
            local BoxData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextBox', {
                    Text = "";
                    PlaceholderText = Text;
                    PlaceholderColor3 = Color3.fromRGB(60, 60, 60);
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    Name = 'Box';
                    Size = UDim2.new(1, -10, 0, 20);
                    Position = UDim2.new(0, 5, 0, 4);
                    TextColor3 = Library.Options.textcolor;
                    BackgroundColor3 = Library.Options.dropcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Library:Create('ScrollingFrame', {
                        Position = UDim2.new(0, 0, 1, 1);
                        Name = 'Container';
                        BackgroundColor3 = Library.Options.btncolor;
                        ScrollBarThickness = 0;
                        BorderSizePixel = 0;
                        BorderColor3 = Library.Options.bordercolor;
                        Size = UDim2.new(1, 0, 0, 0);
                        Library:Create('UIListLayout', {
                            Name = 'ListLayout';
                            SortOrder = Enum.SortOrder.LayoutOrder;
                        });
                        ZIndex = 2;
                    });
                });
                Parent = self.container;
            })

            local InputBox = BoxData:FindFirstChild("Box");
            local ResultContainer = InputBox:FindFirstChild("Container");
            local function ClearRows()
                for _, Child in next, ResultContainer:GetChildren() do
                    if (not Child:IsA("UIListLayout")) then
                        Child:Destroy();
                    end
                end
            end

            local function Rebuild(QueryData)
                ResultContainer.ScrollBarThickness = 0;
                ClearRows();

                local LoweredQuery = string.lower(QueryData);
                local ShownData = 0;

                if #LoweredQuery > 0 then
                    for _, Item in next, ListData do
                        local ItemText = tostring(Item);
                        if string.sub(string.lower(ItemText), 1, string.len(LoweredQuery)) == LoweredQuery then
                            ShownData = ShownData + 1;
                            local ButtonData = Library:Create('TextButton', {
                                Text = ItemText;
                                Font = Library.Options.font;
                                TextSize = Library.Options.fontsize;
                                TextColor3 = Library.Options.textcolor;
                                BorderColor3 = Library.Options.bordercolor;
                                TextStrokeTransparency = Library.Options.textstroke;
                                TextStrokeColor3 = Library.Options.strokecolor;
                                Parent = ResultContainer;
                                Size = UDim2.new(1, 0, 0, 20);
                                LayoutOrder = ShownData;
                                BackgroundColor3 = Library.Options.btncolor;
                                ZIndex = 2;
                            })

                            ButtonData.MouseButton1Click:Connect(function()
                                Busy = true;
                                InputBox.Text = ButtonData.Text;
                                task.wait();
                                Busy = false;

                                local OldValue = Location[Flag];
                                SetFlagValue(Location, Flag, ButtonData.Text, ApiData, false);
                                if ShouldDispatchCallback(true) then
                                    Callback(Location[Flag]);
                                    if ApiData and type(ApiData.EmitChanged) == "function" then
                                        ApiData:EmitChanged(Location[Flag], OldValue);
                                    end
                                end

                                ResultContainer.ScrollBarThickness = 0;
                                ClearRows();
                                ResultContainer:TweenSize(UDim2.new(1, 0, 0, 0), 'Out', 'Quint', .3, true);
                            end)
                        end
                    end
                end

                local ContentHeight = 20 * ShownData;
                if ContentHeight > 100 then
                    ResultContainer.ScrollBarThickness = 5;
                end

                ResultContainer:TweenSize(UDim2.new(1, 0, 0, math.clamp(ContentHeight, 0, 100)), 'Out', 'Quint', .3, true);
                ResultContainer.CanvasSize = UDim2.new(1, 0, 0, ContentHeight);
            end

            InputBox:GetPropertyChangedSignal('Text'):Connect(function()
                if (not Busy) then
                    Rebuild(InputBox.Text)
                end
            end);

            local function Reload(NewList)
                ListData = (type(NewList) == "table" and NewList or {});
                Rebuild("")
            end

            local function SetSearchValue(NewValue, FireCallback)
                local TextValue = tostring(NewValue or "");
                Busy = true;
                InputBox.Text = TextValue;
                Busy = false;

                local OldValue = Location[Flag];
                SetFlagValue(Location, Flag, TextValue, ApiData, false);
                Rebuild(TextValue);
                if ShouldDispatchCallback(FireCallback) then
                    Callback(Location[Flag]);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(Location[Flag], OldValue);
                    end
                end
                local ParentWindow = self.ParentWindow or self;
                if ParentWindow and type(ParentWindow.RefreshAutoWidth) == "function" then
                    ParentWindow:RefreshAutoWidth(false);
                end
            end

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewValue, FireCallback)
                    SetSearchValue(NewValue, FireCallback);
                end
            });

            self:Resize();
            ApiData = {
                Refresh = Reload;
                Reload = Reload;
                Input = InputBox;
                Box = InputBox;
                Set = function(_, NewValue, FireCallback)
                    SetSearchValue(NewValue, FireCallback);
                end,
                Get = function()
                    return Location[Flag];
                end,
            };

            self:AttachControlFeatures(BoxData, Options, ApiData, {InputBox}, tostring(Text));
            return Reload, InputBox, ApiData;
        end
        
        function Types:Dropdown(Name, Options, Callback)
            Options = Options or {};
            local Location = Options.location or self.flags;
            local Flag = self:ResolveFlag(Options.flag, Name, "Dropdown");
            local Callback = Callback or function() end;
            local ListData = (type(Options.list) == "table" and Options.list or {});
            local DefaultSelection = ListData[1] or "";
            local ApiData;

            SetFlagValue(Location, Flag, DefaultSelection, ApiData, false);
            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                BackgroundColor3 = Color3.fromRGB(25, 25, 25);
                BorderSizePixel = 0;
                LayoutOrder = self:GetOrder();
                Library:Create('Frame', {
                    Name = 'dropdown_lbl';
                    BackgroundTransparency = 0;
                    BackgroundColor3 = Library.Options.dropcolor;
                    Position = UDim2.new(0, 5, 0, 4);
                    BorderColor3 = Library.Options.bordercolor;
                    Size     = UDim2.new(1, -10, 0, 20);
                    Library:Create('TextLabel', {
                        Name = 'Selection';
                        Size = UDim2.new(1, -24, 1, 0);
                        Text = (DefaultSelection ~= "" and tostring(DefaultSelection) or Name);
                        TextColor3 = Library.Options.textcolor;
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextScaled = false;
                        TextWrapped = false;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    });
                    Library:Create("TextButton", {
                        Name = 'drop';
                        BackgroundTransparency = 1;
                        Size = UDim2.new(0, 20, 1, 0);
                        Position = UDim2.new(1, -25, 0, 0);
                        Text = 'v';
                        TextColor3 = Library.Options.textcolor;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    })
                });
                Parent = self.container;
            });
            
            local ButtonData = CheckData:FindFirstChild('dropdown_lbl').drop;
            local Label = CheckData:FindFirstChild('dropdown_lbl');
            local SelectionLabel = Label:FindFirstChild('Selection');
            local Input;
            local ActiveContainer;
            Library:RegisterFlag(Location, Flag);

            local function SetDropdownValue(NewValue, FireCallback)
                if NewValue ~= nil then
                    local OldValue = Location[Flag];
                    SetFlagValue(Location, Flag, tostring(NewValue), ApiData, false);
                    SelectionLabel.Text = tostring(Location[Flag]);
                    SelectionLabel.TextColor3 = Library.Options.textcolor;
                    if ShouldDispatchCallback(FireCallback) then
                        Callback(Location[Flag]);
                        if ApiData and type(ApiData.EmitChanged) == "function" then
                            ApiData:EmitChanged(Location[Flag], OldValue);
                        end
                    end
                    local ParentWindow = self.ParentWindow or self;
                    if ParentWindow and type(ParentWindow.RefreshAutoWidth) == "function" then
                        ParentWindow:RefreshAutoWidth(false);
                    end
                end
            end
            
            local function IsInGui(Frame)
                if (not Frame) then
                    return false;
                end

                local Mouse = UserInputService:GetMouseLocation();

                local X1, X2 = Frame.AbsolutePosition.X, Frame.AbsolutePosition.X + Frame.AbsoluteSize.X;
                local Y1, Y2 = Frame.AbsolutePosition.Y, Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y;

                return (Mouse.X >= X1 and Mouse.X <= X2) and (Mouse.Y >= Y1 and Mouse.Y <= Y2);
            end

            local function CloseDropdown(SkipTween)
                if Input then
                    Input:Disconnect();
                    Input = nil;
                end

                local ContainerData = ActiveContainer;
                ActiveContainer = nil;

                SelectionLabel.TextColor3 = Library.Options.textcolor;
                SelectionLabel.Text = ((Location[Flag] ~= nil and Location[Flag] ~= "") and tostring(Location[Flag]) or Name);

                if not ContainerData then
                    return;
                end

                if SkipTween then
                    Debris:AddItem(ContainerData, 0);
                    return;
                end

                ContainerData:TweenSize(UDim2.new(1, 0, 0, 0), 'In', 'Quint', .2, true);
                task.delay(0.15, function()
                    Debris:AddItem(ContainerData, 0);
                end)
            end

            ButtonData.MouseButton1Click:Connect(function()
                if (Input and Input.Connected) then
                    CloseDropdown();
                    return;
                end 
                
                SelectionLabel.TextColor3 = Color3.fromRGB(60, 60, 60);
                SelectionLabel.Text = Name;

                local RowHeight = 20;
                local TotalItems = #ListData;
                local TotalHeight = TotalItems * RowHeight;
                local ViewHeight = math.min(TotalHeight, 100);
                local GoSize = UDim2.new(1, 0, 0, ViewHeight);
                local ScrollSize = (TotalHeight > ViewHeight and 5 or 0);

                local ContainerData = Library:Create('ScrollingFrame', {
                    TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                    BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                    Name = 'DropContainer';
                    Parent = Label;
                    Size = UDim2.new(1, 0, 0, 0);
                    BackgroundColor3 = Library.Options.bgcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    Position = UDim2.new(0, 0, 1, 0);
                    ScrollBarThickness = ScrollSize;
                    CanvasSize = UDim2.new(0, 0, 0, TotalHeight);
                    ZIndex = 5;
                    ClipsDescendants = true;
                });
                ActiveContainer = ContainerData;

                local PoolSize = math.clamp(math.ceil((ViewHeight / RowHeight)) + 2, 4, 24);
                local Rows = {};
                local function RenderRows()
                    local StartIndex = math.floor(ContainerData.CanvasPosition.Y / RowHeight) + 1;
                    for PoolIndex = 1, PoolSize do
                        local ItemIndex = StartIndex + PoolIndex - 1;
                        local Row = Rows[PoolIndex];
                        local ItemValue = ListData[ItemIndex];
                        if ItemValue ~= nil then
                            Row.Visible = true;
                            Row.Position = UDim2.new(0, 0, 0, (ItemIndex - 1) * RowHeight);
                            Row.Text = tostring(ItemValue);
                            Row:SetAttribute("WallyItemIndex", ItemIndex);
                        else
                            Row.Visible = false;
                            Row.Text = "";
                            Row:SetAttribute("WallyItemIndex", nil);
                        end
                    end
                end

                for PoolIndex = 1, PoolSize do
                    local Row = Library:Create('TextButton', {
                        Size = UDim2.new(1, 0, 0, RowHeight);
                        Position = UDim2.new(0, 0, 0, 0);
                        BackgroundColor3 = Library.Options.btncolor;
                        BorderColor3 = Library.Options.bordercolor;
                        Text = "";
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        Parent = ContainerData;
                        ZIndex = 5;
                        TextColor3 = Library.Options.textcolor;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                        TextXAlignment = Enum.TextXAlignment.Center;
                        AutoButtonColor = true;
                    });

                    Row.MouseButton1Click:Connect(function()
                        local ItemIndex = tonumber(Row:GetAttribute("WallyItemIndex"));
                        if ItemIndex and ListData[ItemIndex] ~= nil then
                            SetDropdownValue(ListData[ItemIndex], true);
                            CloseDropdown(true);
                        end
                    end);

                    Rows[PoolIndex] = Row;
                end

                ContainerData:GetPropertyChangedSignal("CanvasPosition"):Connect(RenderRows);
                RenderRows();
                ContainerData:TweenSize(GoSize, 'Out', 'Quint', .3, true)

                Input = UserInputService.InputBegan:Connect(function(InputObject)
                    if InputObject.UserInputType == Enum.UserInputType.MouseButton1 and (not IsInGui(ContainerData)) and (not IsInGui(Label)) then
                        CloseDropdown();
                    end
                end)
            end)
            
            self:Resize();
            local function Reload(self, Array)
                ListData = (type(Array) == "table" and Array or {});
                SetFlagValue(Location, Flag, (ListData[1] or ""), ApiData, false);
                CloseDropdown(true);
                SelectionLabel.Text = ((Location[Flag] ~= nil and Location[Flag] ~= "") and tostring(Location[Flag]) or Name);
                SelectionLabel.TextColor3 = Library.Options.textcolor;
            end

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewValue, FireCallback)
                    SetDropdownValue(NewValue, FireCallback);
                end
            });

            ApiData = {
                Refresh = Reload;
                Get = function()
                    return Location[Flag];
                end,
                Set = function(_, Value, FireCallback)
                    SetDropdownValue(Value, FireCallback);
                end
            };

            return self:AttachControlFeatures(CheckData, Options, ApiData, {ButtonData}, tostring(Name));
        end

        function Types:MultiSelectList(Name, Options, Callback)
            Options = Options or {};

            local Location = Options.location or self.flags;
            local Flag = self:ResolveFlag(Options.flag, Name, "MultiSelect");
            local Callback = Callback or function() end;
            local ListData = Options.list or {};
            local ApiData = {};
            Library:RegisterFlag(Location, Flag);

            local SearchEnabled = Options.search ~= false;
            local SortList = Options.sort ~= false;
            local CaseSensitive = Options.caseSensitive == true;
            local RowHeight = tonumber(Options.rowHeight) or 20;
            local MaxVisibleRows = tonumber(Options.maxVisibleRows) or 8;
            local MaxRows = tonumber(Options.maxRows) or 250;
            local ListHeight = tonumber(Options.listHeight) or (RowHeight * MaxVisibleRows);
            ListHeight = math.clamp(ListHeight, RowHeight * 2, 260);

            local Placeholder = Options.placeholder or ("Search " .. Name .. "...");

            local function Trim(Text)
                if type(Text) ~= "string" then
                    return "";
                end
                return (Text:gsub("^%s+", ""):gsub("%s+$", ""));
            end

            local function Normalize(Text)
                local Value = Trim(Text);
                if CaseSensitive then
                    return Value;
                end
                return string.lower(Value);
            end

            local function RebuildList(Source)
                local Result = {};
                local Seen = {};
                if type(Source) ~= "table" then
                    return Result;
                end

                for _, Item in next, Source do
                    local Cleaned = Trim(Item);
                    if Cleaned ~= "" and (not Seen[Cleaned]) then
                        Seen[Cleaned] = true;
                        table.insert(Result, Cleaned);
                    end
                end

                if SortList then
                    table.sort(Result, function(A, B)
                        return string.lower(A) < string.lower(B);
                    end);
                end

                return Result;
            end

            local function IsArray(TableData)
                if type(TableData) ~= "table" then
                    return false;
                end
                local Count = 0;
                local MaxIndex = 0;
                for Key, _ in next, TableData do
                    if type(Key) ~= "number" then
                        return false;
                    end
                    MaxIndex = math.max(MaxIndex, Key);
                    Count = Count + 1;
                end
                return Count == MaxIndex;
            end

            local function GetListLookup(Source)
                local Lookup = {};
                for _, Item in next, Source do
                    Lookup[Normalize(Item)] = Item;
                end
                return Lookup;
            end

            ListData = RebuildList(ListData);
            local ListLookup = GetListLookup(ListData);

            local SelectedData = {};

            local function ApplySelectionData(Data)
                if type(Data) ~= "table" then
                    return;
                end

                local Arr = IsArray(Data);
                for Key, Value in next, Data do
                    local Raw = (Arr and Value or Key);
                    local Enabled = (Arr and true or Value);
                    if Enabled then
                        local Cleaned = Trim(Raw);
                        local Canonical = ListLookup[Normalize(Cleaned)] or Cleaned;
                        if Canonical ~= "" then
                            SelectedData[Canonical] = true;
                        end
                    end
                end
            end

            if type(Location[Flag]) == "table" then
                ApplySelectionData(Location[Flag]);
            end

            local HasSelection = false;
            for _, Value in next, SelectedData do
                if Value then
                    HasSelection = true;
                    break;
                end
            end

            if (not HasSelection) and type(Options.default) == "table" then
                ApplySelectionData(Options.default);
            end

            SetFlagValue(Location, Flag, SelectedData, ApiData, false);

            local TitleHeight = 20;
            local SearchHeight = (SearchEnabled and 22 or 0);
            local ButtonWidth = 44;
            local TitleOffsetY = 2;
            local SearchOffsetY = TitleOffsetY + TitleHeight + (SearchEnabled and 2 or 0);
            local ListOffsetY = SearchOffsetY + SearchHeight + 2;
            local InfoOffsetY = ListOffsetY + ListHeight + 2;
            local ControlHeight = InfoOffsetY + 16 + 2;

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, ControlHeight);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = 'Title';
                    BackgroundTransparency = 1;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Position = UDim2.new(0, 5, 0, TitleOffsetY);
                    Size = UDim2.new(1, -((ButtonWidth * 2) + 20), 0, TitleHeight);
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextColor3 = Library.Options.textcolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    TextScaled = true;
                    TextWrapped = false;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                });
                Library:Create('TextButton', {
                    Name = 'SelectAll';
                    Text = 'All';
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextColor3 = Library.Options.textcolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    BackgroundColor3 = Library.Options.btncolor;
                    BorderColor3 = Library.Options.bordercolor;
                    Position = UDim2.new(1, -((ButtonWidth * 2) + 10), 0, TitleOffsetY);
                    Size = UDim2.new(0, ButtonWidth, 0, TitleHeight);
                });
                Library:Create('TextButton', {
                    Name = 'ClearAll';
                    Text = 'Clear';
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextColor3 = Library.Options.textcolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    BackgroundColor3 = Library.Options.btncolor;
                    BorderColor3 = Library.Options.bordercolor;
                    Position = UDim2.new(1, -(ButtonWidth + 5), 0, TitleOffsetY);
                    Size = UDim2.new(0, ButtonWidth, 0, TitleHeight);
                });
                Library:Create('TextBox', {
                    Name = 'SearchBox';
                    Visible = SearchEnabled;
                    Text = '';
                    PlaceholderText = Placeholder;
                    PlaceholderColor3 = Library.Options.placeholdercolor;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextColor3 = Library.Options.textcolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    BackgroundColor3 = Library.Options.dropcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    Position = UDim2.new(0, 5, 0, SearchOffsetY);
                    Size = UDim2.new(1, -10, 0, SearchHeight);
                    ClearTextOnFocus = false;
                });
                Library:Create('ScrollingFrame', {
                    Name = 'ListContainer';
                    Position = UDim2.new(0, 5, 0, ListOffsetY);
                    Size = UDim2.new(1, -10, 0, ListHeight);
                    BackgroundColor3 = Library.Options.bgcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    ScrollBarThickness = 5;
                    CanvasSize = UDim2.new(0, 0, 0, 0);
                    TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                    BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                });
                Library:Create('TextLabel', {
                    Name = 'Info';
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Position = UDim2.new(0, 5, 0, InfoOffsetY);
                    Size = UDim2.new(1, -10, 0, 16);
                    Font = Library.Options.font;
                    TextSize = math.max(Library.Options.fontsize - 2, 12);
                    TextColor3 = Color3.fromRGB(170, 170, 170);
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Text = '';
                });
                Parent = self.container;
            });

            local SearchBox = CheckData:FindFirstChild('SearchBox');
            local ContainerData = CheckData:FindFirstChild('ListContainer');
            local InfoLabel = CheckData:FindFirstChild('Info');
            local SelectAllButton = CheckData:FindFirstChild('SelectAll');
            local ClearButton = CheckData:FindFirstChild('ClearAll');
            local RowPool = {};
            local FilteredItems = {};
            local EmptyLabel;
            local HintLabel;
            local PoolSize = math.clamp(math.ceil(ListHeight / RowHeight) + 3, 6, 42);
            local Render;

            local function GetSelectedCount()
                local Total = 0;
                for _, Enabled in next, SelectedData do
                    if Enabled then
                        Total = Total + 1;
                    end
                end
                return Total;
            end

            local function GetSelectedArray()
                local Arr = {};
                local Seen = {};

                for _, Item in next, ListData do
                    if SelectedData[Item] then
                        table.insert(Arr, Item);
                        Seen[Item] = true;
                    end
                end

                for Item, Enabled in next, SelectedData do
                    if Enabled and (not Seen[Item]) then
                        table.insert(Arr, Item);
                    end
                end

                return Arr;
            end

            local function GetSelectedMap()
                local Map = {};
                for Item, Enabled in next, SelectedData do
                    if Enabled then
                        Map[Item] = true;
                    end
                end
                return Map;
            end

            local function UpdateSelection(DoCallback)
                local SelectedMap = GetSelectedMap();
                local SelectedArray = GetSelectedArray();
                SetFlagValue(Location, Flag, SelectedData, ApiData, true);
                if ShouldDispatchCallback(DoCallback) then
                    Callback(SelectedMap, SelectedArray);
                    if ApiData and type(ApiData.EmitChanged) == "function" then
                        ApiData:EmitChanged(SelectedMap, SelectedArray);
                    end
                end
            end

            local function IsMatch(Item, QueryData)
                if QueryData == "" then
                    return true;
                end

                local Source = (CaseSensitive and Item or string.lower(Item));
                return string.find(Source, QueryData, 1, true) ~= nil;
            end

            local function EnsureVirtualRows()
                if #RowPool > 0 then
                    return;
                end

                for PoolIndex = 1, PoolSize do
                    local Row = Library:Create('TextButton', {
                        Name = 'VirtualRow_' .. tostring(PoolIndex);
                        Text = '';
                        TextXAlignment = Enum.TextXAlignment.Left;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        TextColor3 = Library.Options.textcolor;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                        BorderColor3 = Library.Options.bordercolor;
                        BackgroundColor3 = Library.Options.btncolor;
                        AutoButtonColor = false;
                        Size = UDim2.new(1, -4, 0, RowHeight);
                        Position = UDim2.new(0, 2, 0, 0);
                        Parent = ContainerData;
                    });

                    Row.MouseButton1Click:Connect(function()
                        local ItemIndex = tonumber(Row:GetAttribute("WallyItemIndex"));
                        local Item = (ItemIndex and FilteredItems[ItemIndex]) or nil;
                        if Item then
                            if SelectedData[Item] then
                                SelectedData[Item] = nil;
                            else
                                SelectedData[Item] = true;
                            end
                            UpdateSelection();
                            if type(Render) == "function" then
                                Render();
                            end
                        end
                    end);

                    RowPool[#RowPool + 1] = Row;
                end
            end

            local function UpdateVirtualRows()
                EnsureVirtualRows();

                local StartIndex = math.floor(ContainerData.CanvasPosition.Y / RowHeight) + 1;
                for PoolIndex = 1, #RowPool do
                    local ItemIndex = StartIndex + PoolIndex - 1;
                    local Row = RowPool[PoolIndex];
                    local Item = FilteredItems[ItemIndex];
                    if Item then
                        local Enabled = SelectedData[Item] == true;
                        Row.Visible = true;
                        Row.Position = UDim2.new(0, 2, 0, (ItemIndex - 1) * RowHeight);
                        Row.Text = (Enabled and "[x] " or "[ ] ") .. Item;
                        Row.BackgroundColor3 = (Enabled and Color3.fromRGB(40, 95, 40) or Library.Options.btncolor);
                        Row:SetAttribute("WallyItemIndex", ItemIndex);
                    else
                        Row.Visible = false;
                        Row.Text = '';
                        Row:SetAttribute("WallyItemIndex", nil);
                    end
                end
            end

            local function ReadQuery()
                if not SearchEnabled then
                    return "";
                end
                return Normalize(SearchBox.Text);
            end

            Render = function()
                local QueryData = ReadQuery();
                local Matched = 0;
                FilteredItems = {};

                for _, Item in next, ListData do
                    if IsMatch(Item, QueryData) then
                        Matched = Matched + 1;
                        if #FilteredItems < MaxRows then
                            table.insert(FilteredItems, Item);
                        end
                    end
                end

                local CanvasRows = math.min(Matched, MaxRows);
                ContainerData.CanvasSize = UDim2.new(0, 0, 0, CanvasRows * RowHeight);
                ContainerData.ScrollBarThickness = (CanvasRows * RowHeight > ListHeight and 5 or 0);
                local MaxCanvasY = math.max((CanvasRows * RowHeight) - ListHeight, 0);
                local CurrentCanvasY = math.clamp(ContainerData.CanvasPosition.Y, 0, MaxCanvasY);
                ContainerData.CanvasPosition = Vector2.new(0, CurrentCanvasY);

                if Matched == 0 then
                    if not EmptyLabel or (not EmptyLabel.Parent) then
                        EmptyLabel = Library:Create('TextLabel', {
                            Name = 'NoMatches';
                            Text = 'No matches';
                            Font = Library.Options.font;
                            TextSize = Library.Options.fontsize;
                            TextColor3 = Library.Options.textcolor;
                            TextStrokeTransparency = Library.Options.textstroke;
                            TextStrokeColor3 = Library.Options.strokecolor;
                            BackgroundTransparency = 1;
                            Size = UDim2.new(1, -4, 0, RowHeight);
                            Position = UDim2.new(0, 2, 0, 0);
                            TextXAlignment = Enum.TextXAlignment.Left;
                            Parent = ContainerData;
                        });
                    end
                    EmptyLabel.Visible = true;
                    EmptyLabel.Text = "No matches";
                elseif EmptyLabel and EmptyLabel.Parent then
                    EmptyLabel.Visible = false;
                end

                if Matched > MaxRows then
                    if not HintLabel or (not HintLabel.Parent) then
                        HintLabel = Library:Create('TextLabel', {
                            Name = 'RefineHint';
                            Text = '';
                            Font = Library.Options.font;
                            TextSize = math.max(Library.Options.fontsize - 2, 12);
                            TextColor3 = Color3.fromRGB(180, 180, 180);
                            TextStrokeTransparency = Library.Options.textstroke;
                            TextStrokeColor3 = Library.Options.strokecolor;
                            BackgroundTransparency = 1;
                            Size = UDim2.new(1, -4, 0, 18);
                            Position = UDim2.new(0, 2, 0, 0);
                            TextXAlignment = Enum.TextXAlignment.Left;
                            Parent = ContainerData;
                        });
                    end
                    HintLabel.Visible = true;
                    HintLabel.Text = ('Refine search (%d matches, virtualized to %d)'):format(Matched, MaxRows);
                    HintLabel.Position = UDim2.new(0, 2, 0, math.max(0, (CanvasRows * RowHeight) - 18));
                elseif HintLabel and HintLabel.Parent then
                    HintLabel.Visible = false;
                end

                local Text = string.format("%d selected | %d matches", GetSelectedCount(), Matched);
                if Matched > MaxRows then
                    Text = Text .. string.format(" (virtualized %d)", MaxRows);
                end
                InfoLabel.Text = Text;

                UpdateVirtualRows();
            end
            ContainerData:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateVirtualRows);

            SelectAllButton.MouseButton1Click:Connect(function()
                local QueryData = ReadQuery();
                local Changed = false;

                for _, Item in next, ListData do
                    if IsMatch(Item, QueryData) and (not SelectedData[Item]) then
                        SelectedData[Item] = true;
                        Changed = true;
                    end
                end

                if Changed then
                    UpdateSelection();
                end
                Render();
            end);

            ClearButton.MouseButton1Click:Connect(function()
                for Item in next, SelectedData do
                    SelectedData[Item] = nil;
                end
                UpdateSelection();
                Render();
            end);

            if SearchEnabled then
                SearchBox:GetPropertyChangedSignal('Text'):Connect(Render);
            end

            self:Resize();
            Render();

            function ApiData:Get(asArray)
                if asArray then
                    return GetSelectedArray();
                end
                return GetSelectedMap();
            end

            function ApiData:Set(ItemName, Enabled, FireCallback)
                if type(ItemName) ~= "string" then
                    return;
                end

                local Item = Trim(ItemName);
                if Item == "" then
                    return;
                end

                local Canonical = ListLookup[Normalize(Item)] or Item;
                if Enabled == nil then
                    Enabled = not SelectedData[Canonical];
                end

                if Enabled then
                    SelectedData[Canonical] = true;
                else
                    SelectedData[Canonical] = nil;
                end

                UpdateSelection(FireCallback);
                Render();
            end

            function ApiData:SetMany(values, Enabled, FireCallback)
                if type(values) ~= "table" then
                    return;
                end

                local Arr = IsArray(values);
                for Key, Value in next, values do
                    local Raw = (Arr and Value or Key);
                    local TargetState = (Arr and Enabled ~= false or Value);
                    if type(Raw) == "string" then
                        local Cleaned = Trim(Raw);
                        if Cleaned ~= "" then
                            local Canonical = ListLookup[Normalize(Cleaned)] or Cleaned;
                            if TargetState then
                                SelectedData[Canonical] = true;
                            else
                                SelectedData[Canonical] = nil;
                            end
                        end
                    end
                end

                UpdateSelection(FireCallback);
                Render();
            end

            function ApiData:Clear(FireCallback)
                for Item in next, SelectedData do
                    SelectedData[Item] = nil;
                end

                UpdateSelection(FireCallback);
                Render();
            end

            function ApiData:Refresh(NewList, PreserveSelected, FireCallback)
                if type(NewList) == "table" then
                    ListData = RebuildList(NewList);
                    ListLookup = GetListLookup(ListData);
                end

                local KeepSelection = PreserveSelected ~= false;
                if KeepSelection then
                    local KeptSelection = {};
                    for _, Item in next, ListData do
                        if SelectedData[Item] then
                            KeptSelection[Item] = true;
                        end
                    end
                    SelectedData = KeptSelection;
                else
                    for Item in next, SelectedData do
                        SelectedData[Item] = nil;
                    end
                end

                UpdateSelection(FireCallback);
                Render();
            end

            local function SetMultiSelectValue(NewValue, FireCallback)
                for Item in next, SelectedData do
                    SelectedData[Item] = nil;
                end

                if type(NewValue) == "table" then
                    ApplySelectionData(NewValue);
                end

                UpdateSelection(FireCallback);
                Render();
            end

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewValue, FireCallback)
                    SetMultiSelectValue(NewValue, FireCallback);
                end
            });

            return self:AttachControlFeatures(CheckData, Options, ApiData, {SearchBox, SelectAllButton, ClearButton}, tostring(Name));
        end
    end
    
    function Library:Create(ClassName, Data)
        local Obj = Instance.new(ClassName);
        local ParentObject = Data.Parent;
        for Index, ValueData in next, Data do
            if Index ~= 'Parent' then
                
                if typeof(ValueData) == "Instance" then
                    ValueData.Parent = Obj;
                else
                    Obj[Index] = ValueData
                end
            end
        end

        local IsAutoScaleClass = (ClassName == "TextLabel" or ClassName == "TextButton" or ClassName == "TextBox");
        if IsAutoScaleClass then
            local AutoScaleEnabled = true;
            if Library.Options and Library.Options.autoscaletext ~= nil then
                AutoScaleEnabled = Library.Options.autoscaletext;
            end

            local ShouldScale = (Data.TextScaled ~= nil and Data.TextScaled) or (Data.TextScaled == nil and AutoScaleEnabled);
            if ShouldScale then
                Obj.TextScaled = true;
                if ClassName ~= "TextBox" then
                    Obj.TextTruncate = Enum.TextTruncate.AtEnd;
                end

                local DesiredMax = math.floor((tonumber(Data.TextSize) or tonumber(Obj.TextSize) or (Library.Options and Library.Options.fontsize) or 17) + 0.5);
                local DesiredMin = math.floor((tonumber(Library.Options and Library.Options.mintextsize) or 10) + 0.5);
                local MaxTextSize = math.max(1, DesiredMax);
                local MinTextSize = math.max(1, math.min(DesiredMin, MaxTextSize));

                local ExistingConstraint = Obj:FindFirstChildOfClass("UITextSizeConstraint");
                if ExistingConstraint then
                    ExistingConstraint.MinTextSize = MinTextSize;
                    ExistingConstraint.MaxTextSize = MaxTextSize;
                else
                    local SizeConstraint = Instance.new("UITextSizeConstraint");
                    SizeConstraint.MinTextSize = MinTextSize;
                    SizeConstraint.MaxTextSize = MaxTextSize;
                    SizeConstraint.Parent = Obj;
                end
            end
        end
        
        Obj.Parent = ParentObject;
        return Obj
    end

    function Library:EnsureTooltipGui()
        if self.TooltipGui and self.TooltipGui.Parent and self.TooltipFrame and self.TooltipFrame.Parent then
            return self.TooltipFrame;
        end

        local ParentGui = ResolveGuiParent();
        self.TooltipGui = self:Create("ScreenGui", {
            Name = "WallyModifiedTooltips";
            ResetOnSpawn = false;
            IgnoreGuiInset = true;
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
            DisplayOrder = 1001;
            Parent = ParentGui;
        });

        local TooltipFrame = self:Create("Frame", {
            Name = "Tooltip";
            Visible = false;
            BackgroundColor3 = Color3.fromRGB(22, 22, 22);
            BorderColor3 = Color3.fromRGB(70, 70, 70);
            Size = UDim2.new(0, 140, 0, 18);
            Position = UDim2.new(0, 0, 0, 0);
            ZIndex = 200;
            Parent = self.TooltipGui;
            Library:Create("TextLabel", {
                Name = "Text";
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 6, 0, 2);
                Size = UDim2.new(1, -12, 1, -4);
                Text = "";
                TextWrapped = true;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Top;
                Font = (self.Options and self.Options.font) or Enum.Font.SourceSans;
                TextSize = math.max(10, tonumber(self.Options and self.Options.fontsize) or 16);
                TextColor3 = (self.Options and self.Options.textcolor) or Color3.fromRGB(255, 255, 255);
                TextStrokeTransparency = (self.Options and self.Options.textstroke) or 1;
                TextStrokeColor3 = (self.Options and self.Options.strokecolor) or Color3.fromRGB(0, 0, 0);
                ZIndex = 201;
            });
        });

        self.TooltipFrame = TooltipFrame;
        self.TooltipTextLabel = TooltipFrame:FindFirstChild("Text");
        self.TooltipBindings = self.TooltipBindings or {};
        return TooltipFrame;
    end

    function Library:HideTooltip()
        if self.TooltipFrame and self.TooltipFrame.Parent then
            self.TooltipFrame.Visible = false;
        end
        self.ActiveTooltipSource = nil;
        self.ActiveTooltipTextResolver = nil;
    end

    function Library:ShowTooltip(Source, TextResolver)
        local TooltipFrame = self:EnsureTooltipGui();
        if not TooltipFrame then
            return;
        end

        self.ActiveTooltipSource = Source;
        self.ActiveTooltipTextResolver = TextResolver;

        local Text = "";
        if type(TextResolver) == "function" then
            local Ok, Result = pcall(TextResolver);
            if Ok and Result ~= nil then
                Text = tostring(Result);
            end
        elseif TextResolver ~= nil then
            Text = tostring(TextResolver);
        end

        if Text == "" then
            self:HideTooltip();
            return;
        end

        local FontData = (self.Options and self.Options.font) or Enum.Font.SourceSans;
        local TextSize = math.max(10, tonumber(self.Options and self.Options.fontsize) or 16);
        local OkBounds, Bounds = pcall(function()
            return TextService:GetTextSize(Text, TextSize, FontData, Vector2.new(340, 240));
        end);
        if not OkBounds or typeof(Bounds) ~= "Vector2" then
            Bounds = Vector2.new(120, 14);
        end

        if self.TooltipTextLabel then
            self.TooltipTextLabel.Font = FontData;
            self.TooltipTextLabel.TextSize = TextSize;
            self.TooltipTextLabel.Text = Text;
        end

        TooltipFrame.Size = UDim2.new(0, math.clamp(math.floor(Bounds.X + 14), 70, 360), 0, math.clamp(math.floor(Bounds.Y + 8), 18, 280));
        TooltipFrame.Visible = true;

        local MousePos = UserInputService:GetMouseLocation();
        TooltipFrame.Position = UDim2.new(0, MousePos.X + 14, 0, MousePos.Y + 12);
    end

    function Library:AttachTooltip(Target, TextOrResolver)
        if typeof(Target) ~= "Instance" or (not Target:IsA("GuiObject")) then
            return nil;
        end

        self:EnsureTooltipGui();
        self.TooltipBindings = self.TooltipBindings or {};

        local Existing = self.TooltipBindings[Target];
        if type(Existing) == "table" then
            for _, Connection in next, Existing do
                if Connection and Connection.Disconnect then
                    Connection:Disconnect();
                end
            end
        end

        local function ResolveText()
            if type(TextOrResolver) == "function" then
                return TextOrResolver();
            end
            return TextOrResolver;
        end

        local Connections = {};
        Connections[#Connections + 1] = Target.MouseEnter:Connect(function()
            self:ShowTooltip(Target, ResolveText);
        end);
        Connections[#Connections + 1] = Target.MouseMoved:Connect(function()
            if self.ActiveTooltipSource == Target and self.TooltipFrame and self.TooltipFrame.Parent then
                local MousePos = UserInputService:GetMouseLocation();
                self.TooltipFrame.Position = UDim2.new(0, MousePos.X + 14, 0, MousePos.Y + 12);
            end
        end);
        Connections[#Connections + 1] = Target.MouseLeave:Connect(function()
            if self.ActiveTooltipSource == Target then
                self:HideTooltip();
            end
        end);
        Connections[#Connections + 1] = Target.AncestryChanged:Connect(function(_, ParentData)
            if not ParentData then
                if self.ActiveTooltipSource == Target then
                    self:HideTooltip();
                end
                local Entry = self.TooltipBindings and self.TooltipBindings[Target];
                if type(Entry) == "table" then
                    for _, Connection in next, Entry do
                        if Connection and Connection.Disconnect then
                            Connection:Disconnect();
                        end
                    end
                end
                if self.TooltipBindings then
                    self.TooltipBindings[Target] = nil;
                end
            end
        end);

        self.TooltipBindings[Target] = Connections;
        return true;
    end

    function Library:EnsureNotificationContainer()
        if self.NotificationContainer and self.NotificationContainer.Parent then
            return self.NotificationContainer;
        end

        local ParentGui = ResolveGuiParent();
        if (not self.NotificationGui) or (not self.NotificationGui.Parent) then
            self.NotificationGui = self:Create("ScreenGui", {
                Name = "WallyModifiedNotifications";
                ResetOnSpawn = false;
                IgnoreGuiInset = true;
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
                DisplayOrder = 999;
                Parent = ParentGui;
            });
        end

        local Container = self.NotificationGui:FindFirstChild("Container");
        if not Container then
            local Width = math.clamp(math.floor((tonumber(self.Options and self.Options.notifywidth) or 280) + 0.5), 180, 460);
            local Padding = math.clamp(math.floor((tonumber(self.Options and self.Options.notifypadding) or 6) + 0.5), 0, 30);

            Container = self:Create("Frame", {
                Name = "Container";
                AnchorPoint = Vector2.new(1, 0);
                Position = UDim2.new(1, -10, 0, 10);
                Size = UDim2.new(0, Width + 18, 1, -20);
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Parent = self.NotificationGui;
                Library:Create("UIListLayout", {
                    Name = "List";
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    VerticalAlignment = Enum.VerticalAlignment.Top;
                    Padding = UDim.new(0, Padding);
                });
            });
        end

        self.NotificationContainer = Container;
        self.NotificationList = Container:FindFirstChild("List");
        self.Notifications = self.Notifications or {};
        self.NotificationId = self.NotificationId or 0;
        return Container;
    end

    function Library:Notify(Title, Text, Duration, Options)
        local Config = {};
        if type(Title) == "table" then
            for Key, Value in next, Title do
                Config[Key] = Value;
            end
        elseif type(Text) == "table" and Options == nil then
            for Key, Value in next, Text do
                Config[Key] = Value;
            end
            Config.text = Title;
        else
            Config.title = Title;
            Config.text = Text;
            Config.duration = Duration;
            if type(Options) == "table" then
                for Key, Value in next, Options do
                    Config[Key] = Value;
                end
            end
        end

        if Config.text == nil then
            Config.text = Config.title;
            Config.title = "Notification";
        end

        local TitleText = tostring(Config.title or "Notification");
        local MessageText = tostring(Config.text or "");

        local Width = math.clamp(math.floor((tonumber(Config.width or Config.size or (self.Options and self.Options.notifywidth) or 280) or 280) + 0.5), 180, 460);
        local Padding = math.clamp(math.floor((tonumber(Config.padding or (self.Options and self.Options.notifypadding) or 6) or 6) + 0.5), 0, 30);
        local MaxNotifications = math.clamp(
            math.floor((tonumber(Config.maxNotifications or Config.maxnotifications or (self.Options and self.Options.notifymax) or 6) or 6) + 0.5),
            1,
            30
        );

        local DurationValue = tonumber(Config.duration);
        local Sticky = (DurationValue ~= nil and DurationValue <= 0);
        local Lifetime = math.clamp(DurationValue or tonumber(self.Options and self.Options.notifyduration) or 4, 0.2, 300);

        local FontData = Config.font or (self.Options and self.Options.font) or Enum.Font.SourceSans;
        local TitleSize = math.clamp(math.floor((tonumber(Config.titleSize or (self.Options and self.Options.fontsize) or 17) or 17) + 0.5), 10, 40);
        local BodySize = math.clamp(math.floor((tonumber(Config.textSize or (TitleSize - 1)) or (TitleSize - 1)) + 0.5), 9, 36);

        local Level = string.lower(tostring(Config.level or Config.kind or Config.type or "info"));
        local LevelAccent = {
            info = Color3.fromRGB(90, 170, 255);
            success = Color3.fromRGB(80, 210, 120);
            warn = Color3.fromRGB(255, 190, 90);
            warning = Color3.fromRGB(255, 190, 90);
            error = Color3.fromRGB(255, 110, 110);
        };
        local LevelTitle = {
            info = "Info";
            success = "Success";
            warn = "Warning";
            warning = "Warning";
            error = "Error";
        };

        local NotifyBackground = Config.backgroundColor or Config.bgColor or (self.Options and self.Options.notifybgcolor) or Color3.fromRGB(28, 28, 28);
        local NotifyBorder = Config.borderColor or (self.Options and self.Options.notifybordercolor) or Color3.fromRGB(62, 62, 62);
        local NotifyAccent = Config.accentColor or Config.levelColor or LevelAccent[Level] or (self.Options and self.Options.notifyaccentcolor) or (self.Options and self.Options.underlinecolor) or Color3.fromRGB(0, 255, 140);
        local NotifyTitleColor = Config.titleColor or (self.Options and self.Options.notifytitlecolor) or (self.Options and self.Options.titletextcolor) or Color3.fromRGB(255, 255, 255);
        local NotifyTextColor = Config.textColor or (self.Options and self.Options.notifytextcolor) or (self.Options and self.Options.textcolor) or Color3.fromRGB(230, 230, 230);

        if Config.title == nil and Config.text ~= nil and LevelTitle[Level] then
            TitleText = LevelTitle[Level];
        end

        if NotifyAccent == "rainbow" then
            NotifyAccent = Color3.fromHSV((os.clock() * 0.15) % 1, 1, 1);
        end

        local Container = self:EnsureNotificationContainer();
        if not Container then
            return nil;
        end

        local List = self.NotificationList;
        if List then
            List.Padding = UDim.new(0, Padding);
        end
        Container.Size = UDim2.new(0, Width + 18, 1, -20);

        local MessageBounds = Vector2.new(0, BodySize);
        local OkTextSize, Bounds = pcall(function()
            return TextService:GetTextSize(MessageText, BodySize, FontData, Vector2.new(Width - 18, 1000));
        end);
        if OkTextSize and typeof(Bounds) == "Vector2" then
            MessageBounds = Bounds;
        end

        local DesiredHeight = math.clamp(24 + MessageBounds.Y + 10, 44, 220);
        if MessageText == "" then
            DesiredHeight = 36;
        end

        self.NotificationId = (self.NotificationId or 0) + 1;
        local Notification = self:Create("Frame", {
            Name = "Notification_" .. tostring(self.NotificationId);
            Size = UDim2.new(0, Width, 0, 0);
            BackgroundColor3 = NotifyBackground;
            BorderColor3 = NotifyBorder;
            ClipsDescendants = true;
            Parent = Container;
            LayoutOrder = self.NotificationId;
            ZIndex = 30;
            Library:Create("UICorner", {
                CornerRadius = UDim.new(0, math.clamp(math.floor((tonumber(Config.cornerRadius or 4) or 4) + 0.5), 0, 14));
            });
            Library:Create("Frame", {
                Name = "Accent";
                Size = UDim2.new(0, 3, 1, 0);
                BorderSizePixel = 0;
                BackgroundColor3 = NotifyAccent;
                ZIndex = 31;
            });
            Library:Create("TextLabel", {
                Name = "Title";
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0, 3);
                Size = UDim2.new(1, -30, 0, 17);
                Text = TitleText;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Center;
                Font = FontData;
                TextSize = TitleSize;
                TextScaled = false;
                TextColor3 = NotifyTitleColor;
                TextStrokeTransparency = self.Options and self.Options.textstroke or 1;
                TextStrokeColor3 = self.Options and self.Options.strokecolor or Color3.fromRGB(0, 0, 0);
                ZIndex = 31;
            });
            Library:Create("TextButton", {
                Name = "Close";
                BackgroundTransparency = 1;
                Position = UDim2.new(1, -21, 0, 2);
                Size = UDim2.new(0, 18, 0, 18);
                Text = "x";
                Font = FontData;
                TextSize = TitleSize;
                TextScaled = false;
                TextColor3 = NotifyTitleColor;
                TextStrokeTransparency = self.Options and self.Options.textstroke or 1;
                TextStrokeColor3 = self.Options and self.Options.strokecolor or Color3.fromRGB(0, 0, 0);
                ZIndex = 31;
            });
            Library:Create("TextLabel", {
                Name = "Body";
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0, 21);
                Size = UDim2.new(1, -16, 1, -23);
                Text = MessageText;
                TextWrapped = true;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Top;
                Font = FontData;
                TextSize = BodySize;
                TextScaled = false;
                TextColor3 = NotifyTextColor;
                TextStrokeTransparency = self.Options and self.Options.textstroke or 1;
                TextStrokeColor3 = self.Options and self.Options.strokecolor or Color3.fromRGB(0, 0, 0);
                ZIndex = 31;
            });
        });

        table.insert(self.Notifications, Notification);
        while #self.Notifications > MaxNotifications do
            local Oldest = table.remove(self.Notifications, 1);
            if Oldest and Oldest.Parent then
                Oldest:Destroy();
            end
        end

        local Closed = false;
        local function RemoveNotification(Instant)
            if Closed then
                return;
            end
            Closed = true;

            for Index = #self.Notifications, 1, -1 do
                if self.Notifications[Index] == Notification then
                    table.remove(self.Notifications, Index);
                    break;
                end
            end

            if Notification and Notification.Parent then
                if Instant then
                    Notification:Destroy();
                else
                    Notification:TweenSize(UDim2.new(0, Width, 0, 0), "In", "Quint", .16, true);
                    task.delay(0.17, function()
                        if Notification and Notification.Parent then
                            Notification:Destroy();
                        end
                    end);
                end
            end
        end

        local CloseButton = Notification:FindFirstChild("Close");
        if CloseButton then
            CloseButton.MouseButton1Click:Connect(function()
                RemoveNotification(false);
            end);
        end

        Notification:TweenSize(UDim2.new(0, Width, 0, DesiredHeight), "Out", "Quint", .18, true);

        if not Sticky then
            task.delay(Lifetime, function()
                RemoveNotification(false);
            end);
        end

        return {
            Close = function(_, Instant)
                RemoveNotification(Instant == true);
            end;
            Destroy = function(_, Instant)
                RemoveNotification(Instant == true);
            end;
        };
    end

    function Library:CreateNotification(...)
        return self:Notify(...);
    end

    function Library:Notification(...)
        return self:Notify(...);
    end

    function Library:NotifyInfo(Title, Text, Duration, Options)
        local Config = Options or {};
        if type(Title) == "table" then
            Config = Title;
        else
            Config.title = Title;
            Config.text = Text;
            Config.duration = Duration;
        end
        Config.level = "info";
        return self:Notify(Config);
    end

    function Library:NotifySuccess(Title, Text, Duration, Options)
        local Config = Options or {};
        if type(Title) == "table" then
            Config = Title;
        else
            Config.title = Title;
            Config.text = Text;
            Config.duration = Duration;
        end
        Config.level = "success";
        return self:Notify(Config);
    end

    function Library:NotifyWarn(Title, Text, Duration, Options)
        local Config = Options or {};
        if type(Title) == "table" then
            Config = Title;
        else
            Config.title = Title;
            Config.text = Text;
            Config.duration = Duration;
        end
        Config.level = "warn";
        return self:Notify(Config);
    end

    function Library:NotifyError(Title, Text, Duration, Options)
        local Config = Options or {};
        if type(Title) == "table" then
            Config = Title;
        else
            Config.title = Title;
            Config.text = Text;
            Config.duration = Duration;
        end
        Config.level = "error";
        return self:Notify(Config);
    end

    function Library:GetControlApiByFlag(FlagName)
        local Name = tostring(FlagName or "");
        if Name == "" then
            return nil;
        end
        local TableData = self.ControlApisByFlag or {};
        return TableData[Name];
    end

    function Library:GetControlApiByObject(Object)
        if typeof(Object) ~= "Instance" then
            return nil;
        end
        local TableData = self.ControlApisByRoot or {};
        return TableData[Object];
    end

    function Library:OnFlagChanged(FlagName, Callback, Options)
        if type(FlagName) == "function" and Callback == nil then
            Callback = FlagName;
            FlagName = nil;
        end

        if type(Callback) ~= "function" then
            return nil, "callback must be a function";
        end

        local ScopeLocation = nil;
        if type(Options) == "table" then
            if type(Options.location) == "table" then
                ScopeLocation = Options.location;
            elseif type(Options.scopeLocation) == "table" then
                ScopeLocation = Options.scopeLocation;
            end
        end

        local Key = tostring(FlagName or "");
        local Listener = {
            Connected = true;
            Callback = Callback;
            Location = ScopeLocation;
        };

        local Bucket;
        if Key == "" or Key == "*" then
            self.FlagChangeAnyListeners = self.FlagChangeAnyListeners or {};
            Bucket = self.FlagChangeAnyListeners;
        else
            self.FlagChangeListeners = self.FlagChangeListeners or {};
            self.FlagChangeListeners[Key] = self.FlagChangeListeners[Key] or {};
            Bucket = self.FlagChangeListeners[Key];
        end
        table.insert(Bucket, Listener);

        return {
            Connected = true;
            Disconnect = function(Self)
                if Listener.Connected ~= true then
                    if type(Self) == "table" then
                        Self.Connected = false;
                    end
                    return false;
                end
                Listener.Connected = false;
                Listener.Callback = nil;
                Listener.Location = nil;
                if type(Self) == "table" then
                    Self.Connected = false;
                end
                return true;
            end;
        };
    end

    function Library:EmitFlagChanged(FlagName, Location, NewValue, OldValue, Source)
        local Key = tostring(FlagName or "");
        if Key == "" then
            return false;
        end

        local Payload = {
            Flag = Key;
            flag = Key;
            Location = Location;
            location = Location;
            Value = NewValue;
            value = NewValue;
            OldValue = OldValue;
            oldValue = OldValue;
            Source = Source;
            source = Source;
        };

        local ListenersByFlag = self.FlagChangeListeners or {};
        local FlagListeners = ListenersByFlag[Key];
        if type(FlagListeners) == "table" then
            for Index = #FlagListeners, 1, -1 do
                local Entry = FlagListeners[Index];
                local Callback = Entry and Entry.Callback;
                local ScopeLocation = Entry and Entry.Location;
                if type(Callback) ~= "function" then
                    table.remove(FlagListeners, Index);
                elseif ScopeLocation == nil or ScopeLocation == Location then
                    pcall(Callback, NewValue, OldValue, Payload);
                end
            end
        end

        local AnyListeners = self.FlagChangeAnyListeners or {};
        for Index = #AnyListeners, 1, -1 do
            local Entry = AnyListeners[Index];
            local Callback = Entry and Entry.Callback;
            local ScopeLocation = Entry and Entry.Location;
            if type(Callback) ~= "function" then
                table.remove(AnyListeners, Index);
            elseif ScopeLocation == nil or ScopeLocation == Location then
                pcall(Callback, Key, NewValue, OldValue, Payload);
            end
        end

        return true;
    end

    function Library:RefreshDependencies()
        local Entries = self.DependencyControls or {};
        local Refreshed = 0;
        for Index = #Entries, 1, -1 do
            local Entry = Entries[Index];
            local RootObject = Entry and Entry.Root;
            local Refresh = Entry and Entry.Refresh;
            if (not RootObject) or (not RootObject.Parent) or type(Refresh) ~= "function" then
                table.remove(Entries, Index);
            else
                local Ok = pcall(Refresh);
                if Ok then
                    Refreshed = Refreshed + 1;
                end
            end
        end
        return Refreshed;
    end

    function Library:AreCallbacksSuspended()
        return (self.CallbackSuspendDepth or 0) > 0;
    end

    function Library:SuspendCallbacks(State)
        local ShouldSuspend = true;
        if State ~= nil then
            ShouldSuspend = (State == true);
        end

        self.CallbackSuspendDepth = math.max(tonumber(self.CallbackSuspendDepth) or 0, 0);
        if ShouldSuspend then
            self.CallbackSuspendDepth = self.CallbackSuspendDepth + 1;
        else
            self.CallbackSuspendDepth = math.max(self.CallbackSuspendDepth - 1, 0);
        end

        return self.CallbackSuspendDepth > 0, self.CallbackSuspendDepth;
    end

    function Library:ResumeCallbacks()
        return self:SuspendCallbacks(false);
    end

    function Library:BeginBatchUpdate(Options)
        if type(Options) == "boolean" then
            Options = {
                suspendCallbacks = Options;
            };
        end
        Options = Options or {};

        local Context = {
            __wallyBatch = true;
            suspendCallbacks = (Options.suspendCallbacks ~= false);
            refreshDependencies = (Options.refreshDependencies ~= false);
            _ended = false;
        };

        self.BatchUpdateDepth = (tonumber(self.BatchUpdateDepth) or 0) + 1;
        if Context.suspendCallbacks then
            self:SuspendCallbacks(true);
        end
        return Context;
    end

    function Library:EndBatchUpdate(Context, Options)
        if type(Context) == "boolean" and Options == nil then
            Options = {
                refreshDependencies = Context;
            };
            Context = nil;
        end

        Options = Options or {};
        if type(Context) == "table" and Context.__wallyBatch == true then
            if Context._ended then
                return false, "batch already ended";
            end
            Context._ended = true;
            if Context.suspendCallbacks then
                self:SuspendCallbacks(false);
            end
        end

        self.BatchUpdateDepth = math.max((tonumber(self.BatchUpdateDepth) or 1) - 1, 0);

        local ShouldRefresh = (Options.refreshDependencies ~= false);
        if type(Context) == "table" and Context.__wallyBatch == true then
            ShouldRefresh = (Context.refreshDependencies == true and Options.refreshDependencies ~= false);
        end

        if self.BatchUpdateDepth == 0 and ShouldRefresh then
            self:RefreshDependencies();
        end

        return true;
    end

    function Library:BatchUpdate(Worker, Options)
        if type(Worker) ~= "function" then
            return false, "worker must be a function";
        end

        local Context = self:BeginBatchUpdate(Options);
        local Results = table.pack(pcall(Worker, self));
        self:EndBatchUpdate(Context, Options);

        if not Results[1] then
            error(Results[2], 0);
        end
        return table.unpack(Results, 2, Results.n);
    end

    function Library:RegisterFlagLocation(Location)
        if type(Location) ~= "table" then
            return false;
        end

        self.FlagLocations = self.FlagLocations or {};
        self.FlagLocationLookup = self.FlagLocationLookup or {};

        if not self.FlagLocationLookup[Location] then
            self.FlagLocationLookup[Location] = true;
            table.insert(self.FlagLocations, Location);
        end

        return true;
    end

    function Library:RegisterFlag(Location, Flag)
        if type(Location) ~= "table" then
            return false;
        end

        self:RegisterFlagLocation(Location);

        local FlagName = tostring(Flag or "");
        if FlagName == "" then
            return false;
        end

        self.RegisteredFlags = self.RegisteredFlags or {};
        local Entry = self.RegisteredFlags[FlagName];
        if type(Entry) ~= "table" then
            Entry = {
                Locations = {};
                Lookup = {};
            };
            self.RegisteredFlags[FlagName] = Entry;
        end

        Entry.Locations = Entry.Locations or {};
        Entry.Lookup = Entry.Lookup or {};
        if not Entry.Lookup[Location] then
            Entry.Lookup[Location] = true;
            table.insert(Entry.Locations, Location);
        end

        return true;
    end

    function Library:RegisterFlagController(Location, Flag, Controller)
        if type(Location) ~= "table" then
            return false;
        end

        local FlagName = tostring(Flag or "");
        if FlagName == "" then
            return false;
        end

        self:RegisterFlag(Location, FlagName);

        self.FlagControllers = self.FlagControllers or {};
        local Entries = self.FlagControllers[FlagName];
        if type(Entries) ~= "table" then
            Entries = {};
            self.FlagControllers[FlagName] = Entries;
        end

        if type(Controller) == "table" then
            Controller.Location = Location;
            table.insert(Entries, Controller);
            return true;
        end

        return false;
    end

    function Library:CollectScriptPresetData()
        local Output = {};
        local Flags = self.RegisteredFlags or {};
        for FlagName, Entry in next, Flags do
            local Locations = Entry and Entry.Locations;
            if type(Locations) == "table" then
                for _, Location in next, Locations do
                    if type(Location) == "table" then
                        local Value = Location[FlagName];
                        if Value ~= nil then
                            Output[FlagName] = Value;
                            break;
                        end
                    end
                end
            end
        end
        return Output;
    end

    function Library:ApplyScriptPresetData(Data, ShouldClear)
        if type(Data) ~= "table" then
            return false, "preset data must be a table";
        end

        local function AssignFlagValue(Location, FlagName, Value, SourceTag)
            if type(Location) ~= "table" then
                return;
            end
            local OldValue = Location[FlagName];
            Location[FlagName] = Value;
            self:RegisterFlag(Location, FlagName);
            if OldValue ~= Value then
                self:EmitFlagChanged(FlagName, Location, Value, OldValue, SourceTag or "ApplyScriptPresetData");
            end
        end

        local Incoming = {};
        for Key in next, Data do
            local FlagName = tostring(Key or "");
            if FlagName ~= "" then
                Incoming[FlagName] = true;
            end
        end

        local Flags = self.RegisteredFlags or {};
        if ShouldClear then
            for FlagName, Entry in next, Flags do
                if not Incoming[FlagName] then
                    local Locations = Entry and Entry.Locations;
                    if type(Locations) == "table" then
                        for _, Location in next, Locations do
                            if type(Location) == "table" then
                                AssignFlagValue(Location, FlagName, nil, "ApplyScriptPresetData_Clear");
                            end
                        end
                    end
                end
            end
        end

        local ControllersByFlag = self.FlagControllers or {};
        for Key, Value in next, Data do
            local FlagName = tostring(Key or "");
            if FlagName ~= "" then
                local Applied = false;
                local Controllers = ControllersByFlag[FlagName];
                if type(Controllers) == "table" then
                    for Index = #Controllers, 1, -1 do
                        local Controller = Controllers[Index];
                        local SetFunction = Controller and Controller.Set;
                        local Location = Controller and Controller.Location;
                        if type(SetFunction) == "function" and type(Location) == "table" then
                            local OkSet = pcall(SetFunction, Value, true);
                            if OkSet then
                                Applied = true;
                            end
                        else
                            table.remove(Controllers, Index);
                        end
                    end
                end

                if not Applied then
                    local Entry = Flags[FlagName];
                    local Locations = Entry and Entry.Locations;
                    if type(Locations) == "table" then
                        for _, Location in next, Locations do
                            if type(Location) == "table" then
                                AssignFlagValue(Location, FlagName, Value, "ApplyScriptPresetData_Fallback");
                                Applied = true;
                            end
                        end
                    end
                end

                if not Applied then
                    local FallbackLocations = self.FlagLocations or {};
                    local FirstLocation = FallbackLocations[1];
                    if type(FirstLocation) == "table" then
                        AssignFlagValue(FirstLocation, FlagName, Value, "ApplyScriptPresetData_FirstLocation");
                    end
                end
            end
        end

        self:RefreshDependencies();
        return true;
    end

    function Library:CreatePresetManager(ScriptKeyOrOptions, MaybeOptions)
        local Options = {};
        if type(ScriptKeyOrOptions) == "string" then
            if type(MaybeOptions) == "table" then
                for Key, Value in next, MaybeOptions do
                    Options[Key] = Value;
                end
            end
            Options.scriptKey = ScriptKeyOrOptions;
        elseif type(ScriptKeyOrOptions) == "table" then
            for Key, Value in next, ScriptKeyOrOptions do
                Options[Key] = Value;
            end
        elseif type(MaybeOptions) == "table" then
            for Key, Value in next, MaybeOptions do
                Options[Key] = Value;
            end
        end

        local HasExplicitLocation = (type(Options.location) == "table");
        local ScopeData = string.lower(tostring(Options.scope or ""));
        local UseScriptScope;
        if Options.scriptWide ~= nil then
            UseScriptScope = (Options.scriptWide == true);
        elseif Options.global ~= nil then
            UseScriptScope = (Options.global == true);
        elseif ScopeData ~= "" then
            UseScriptScope = (ScopeData == "script" or ScopeData == "global" or ScopeData == "all");
        else
            UseScriptScope = (not HasExplicitLocation);
        end

        local Location = (HasExplicitLocation and Options.location) or {};
        if HasExplicitLocation then
            Library:RegisterFlagLocation(Location);
        end
        local RootFolder = tostring(Options.rootFolder or "WallyModifiedPresets");
        local Extension = tostring(Options.extension or ".json");
        local ClearOnLoad = (Options.clearOnLoad ~= false);
        local SeparateByPlace = (Options.separateByPlace ~= false);
        local SchemaVersion = math.max(1, math.floor((tonumber(Options.schemaVersion or Options.version) or 1) + 0.5));
        local Migrations = (type(Options.migrations) == "table" and Options.migrations) or {};

        if Extension ~= "" and string.sub(Extension, 1, 1) ~= "." then
            Extension = "." .. Extension;
        end

        local FileApi = {
            IsFolder = (type(isfolder) == "function" and isfolder) or nil;
            MakeFolder = (type(makefolder) == "function" and makefolder) or nil;
            IsFile = (type(isfile) == "function" and isfile) or nil;
            ReadFile = (type(readfile) == "function" and readfile) or nil;
            WriteFile = (type(writefile) == "function" and writefile) or nil;
            ListFiles = (type(listfiles) == "function" and listfiles) or nil;
            Delfile = (type(delfile) == "function" and delfile) or nil;
        };

        local function HasRequiredFileApi()
            return FileApi.IsFolder and FileApi.MakeFolder and FileApi.IsFile and FileApi.ReadFile and FileApi.WriteFile;
        end

        local function SanitizeName(Name, Fallback)
            local Value = tostring(Name or Fallback or "Default");
            Value = Value:gsub("[%c]", ""):gsub("[\\/:*?\"<>|]", "_");
            Value = Value:gsub("%s+", "_");
            Value = Value:gsub("_+", "_");
            Value = Value:gsub("^_+", ""):gsub("_+$", "");
            if Value == "" then
                Value = tostring(Fallback or "Default");
            end
            if #Value > 80 then
                Value = Value:sub(1, 80);
            end
            return Value;
        end

        local function HashText(Text)
            local Hash = 5381;
            for Index = 1, #Text do
                Hash = ((Hash * 33) + string.byte(Text, Index)) % 2147483647;
            end
            return tostring(Hash);
        end

        local function GetCallerDebugSource()
            if not (debug and debug.info) then
                return "";
            end

            for Level = 3, 12 do
                local OkSource, Source = pcall(function()
                    return debug.info(Level, "s");
                end);

                if OkSource and type(Source) == "string" and Source ~= "" then
                    local Lower = string.lower(Source);
                    if not string.find(Lower, "wally-modified.lua", 1, true) then
                        return Source;
                    end
                end
            end

            return "";
        end

        local function GetCallerScriptName()
            if type(getfenv) ~= "function" then
                return "";
            end

            for Level = 3, 12 do
                local OkEnv, Env = pcall(getfenv, Level);
                if OkEnv and type(Env) == "table" then
                    local ScriptObject = rawget(Env, "script");
                    if typeof(ScriptObject) == "Instance" then
                        local OkName, FullName = pcall(function()
                            return ScriptObject:GetFullName();
                        end);
                        if OkName and type(FullName) == "string" and FullName ~= "" then
                            return FullName;
                        end

                        local NameData = tostring(ScriptObject.Name or "");
                        if NameData ~= "" then
                            return NameData;
                        end
                    end
                end
            end

            return "";
        end

        local function GetAutoScriptKey()
            local ScriptName = GetCallerScriptName();
            local Source = GetCallerDebugSource();

            local Identity = ScriptName;
            if Identity == "" then
                Identity = Source;
            end
            if Identity == "" then
                Identity = "UnknownScript";
            end

            local HashSeed = Identity;
            if SeparateByPlace then
                HashSeed = HashSeed .. "|PlaceId:" .. tostring(game.PlaceId or 0);
            end

            local SourceHash = HashText(HashSeed);
            return SanitizeName(Identity, "Script") .. "_" .. SourceHash;
        end

        local ScriptKey = SanitizeName(Options.scriptKey or Options.scriptId or GetAutoScriptKey(), "Script");

        local function GetScriptFolder()
            return RootFolder .. "/" .. ScriptKey;
        end

        local function EnsureFolderTree()
            if not HasRequiredFileApi() then
                return false, "writefile/readfile APIs are not available in this executor";
            end

            local OkRoot, RootExists = pcall(FileApi.IsFolder, RootFolder);
            if (not OkRoot) or (not RootExists) then
                local OkMakeRoot = pcall(FileApi.MakeFolder, RootFolder);
                if not OkMakeRoot then
                    return false, "failed to create root preset folder";
                end
            end

            local ScriptFolder = GetScriptFolder();
            local OkScript, ScriptExists = pcall(FileApi.IsFolder, ScriptFolder);
            if (not OkScript) or (not ScriptExists) then
                local OkMakeScript = pcall(FileApi.MakeFolder, ScriptFolder);
                if not OkMakeScript then
                    return false, "failed to create script preset folder";
                end
            end

            return true;
        end

        local function GetPresetPath(PresetName)
            local SafeName = SanitizeName(PresetName, "Default");
            return GetScriptFolder() .. "/" .. SafeName .. Extension, SafeName;
        end

        local function GetEnumTypeFromString(EnumTypeName)
            if type(EnumTypeName) ~= "string" or EnumTypeName == "" then
                return nil;
            end

            local Trimmed = EnumTypeName:gsub("^Enum%.", "");
            local OkEnum, EnumType = pcall(function()
                return Enum[Trimmed];
            end);
            if OkEnum and EnumType then
                return EnumType;
            end
            return nil;
        end

        local function GetEnumItemByName(EnumType, ItemName)
            if not EnumType or type(ItemName) ~= "string" then
                return nil;
            end

            for _, EnumItem in next, EnumType:GetEnumItems() do
                if EnumItem.Name == ItemName then
                    return EnumItem;
                end
            end
            return nil;
        end

        local function SerializeValue(Value, Depth)
            Depth = Depth or 0;
            if Depth > 64 then
                return nil;
            end

            local ValueType = typeof(Value);
            if ValueType == "nil" then
                return nil;
            end

            if ValueType == "boolean" or ValueType == "number" or ValueType == "string" then
                return Value;
            end

            if ValueType == "Color3" then
                return {
                    __wallyType = "Color3";
                    r = Value.R;
                    g = Value.G;
                    b = Value.B;
                };
            end

            if ValueType == "EnumItem" then
                return {
                    __wallyType = "EnumItem";
                    enumType = tostring(Value.EnumType);
                    name = Value.Name;
                };
            end

            if ValueType == "table" then
                local Output = {};
                for Key, SubValue in next, Value do
                    local KeyType = typeof(Key);
                    local OutputKey = Key;
                    if KeyType ~= "string" and KeyType ~= "number" then
                        OutputKey = tostring(Key);
                    end
                    Output[OutputKey] = SerializeValue(SubValue, Depth + 1);
                end
                return Output;
            end

            return tostring(Value);
        end

        local function DeserializeValue(Value, Depth)
            Depth = Depth or 0;
            if Depth > 64 then
                return nil;
            end

            if type(Value) ~= "table" then
                return Value;
            end

            if Value.__wallyType == "Color3" then
                return Color3.new(
                    tonumber(Value.r) or 0,
                    tonumber(Value.g) or 0,
                    tonumber(Value.b) or 0
                );
            end

            if Value.__wallyType == "EnumItem" then
                local EnumType = GetEnumTypeFromString(Value.enumType);
                local EnumItem = GetEnumItemByName(EnumType, Value.name);
                if EnumItem then
                    return EnumItem;
                end
                return nil;
            end

            local Output = {};
            for Key, SubValue in next, Value do
                if Key ~= "__wallyType" then
                    Output[Key] = DeserializeValue(SubValue, Depth + 1);
                end
            end
            return Output;
        end

        local function ResolveMigrator(Version)
            if type(Migrations) ~= "table" then
                return nil;
            end
            return Migrations[Version] or Migrations[tostring(Version)] or Migrations["v" .. tostring(Version)];
        end

        local function ApplyMigrations(Data, FromVersion)
            local CurrentVersion = math.max(1, math.floor((tonumber(FromVersion) or 1) + 0.5));
            local Working = Data;
            if type(Working) ~= "table" then
                Working = {};
            end

            while CurrentVersion < SchemaVersion do
                local Migrator = ResolveMigrator(CurrentVersion);
                if type(Migrator) == "function" then
                    local OkMigrate, NextData = pcall(Migrator, Working, CurrentVersion, CurrentVersion + 1);
                    if not OkMigrate then
                        return false, "migration failed at v" .. tostring(CurrentVersion) .. ": " .. tostring(NextData);
                    end
                    if type(NextData) == "table" then
                        Working = NextData;
                    end
                end
                CurrentVersion = CurrentVersion + 1;
            end

            return true, Working, CurrentVersion;
        end

        local function ClearTable(TableData)
            for Key in next, TableData do
                TableData[Key] = nil;
            end
        end

        local function MergeInto(Target, Source, ShouldClear)
            if type(Target) ~= "table" or type(Source) ~= "table" then
                return;
            end

            if ShouldClear then
                ClearTable(Target);
            end

            for Key, Value in next, Source do
                Target[Key] = Value;
            end
        end

        local function ReadPresetData(PresetName)
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return false, FolderError;
            end

            local Path = GetPresetPath(PresetName);
            local OkFile, Exists = pcall(FileApi.IsFile, Path);
            if (not OkFile) or (not Exists) then
                return false, "preset file not found";
            end

            local OkRead, Content = pcall(FileApi.ReadFile, Path);
            if not OkRead then
                return false, "failed to read preset file";
            end

            local OkDecode, Decoded = pcall(function()
                return HttpService:JSONDecode(Content);
            end);
            if not OkDecode then
                return false, "failed to decode preset json";
            end

            local StoredVersion = 1;
            local RawData = Decoded;
            if type(Decoded) == "table" and Decoded.__wallyPreset == true then
                StoredVersion = math.max(1, math.floor((tonumber(Decoded.schemaVersion) or 1) + 0.5));
                RawData = Decoded.data;
            end

            local Data = DeserializeValue(RawData);
            if type(Data) ~= "table" then
                return false, "preset data is invalid";
            end

            local OkMigrate, MigratedData, FinalVersion = ApplyMigrations(Data, StoredVersion);
            if not OkMigrate then
                return false, MigratedData;
            end

            return true, MigratedData, {
                storedVersion = StoredVersion;
                schemaVersion = FinalVersion;
                migrated = (FinalVersion ~= StoredVersion);
                path = Path;
            };
        end

        local Manager = {};

        function Manager:IsAvailable()
            return HasRequiredFileApi();
        end

        function Manager:GetScriptKey()
            return ScriptKey;
        end

        function Manager:GetFolder()
            return GetScriptFolder();
        end

        function Manager:GetRootFolder()
            return RootFolder;
        end

        function Manager:GetExtension()
            return Extension;
        end

        function Manager:GetSchemaVersion()
            return SchemaVersion;
        end

        function Manager:SetSchemaVersion(NewVersion)
            local VersionValue = math.max(1, math.floor((tonumber(NewVersion) or SchemaVersion) + 0.5));
            SchemaVersion = VersionValue;
            return SchemaVersion;
        end

        function Manager:GetMigrations()
            return Migrations;
        end

        function Manager:SetMigrations(NewMigrations)
            if type(NewMigrations) ~= "table" then
                return false, "migrations must be a table";
            end
            Migrations = NewMigrations;
            return true;
        end

        function Manager:GetLocation()
            if UseScriptScope then
                return Library:CollectScriptPresetData();
            end
            return Location;
        end

        function Manager:SetLocation(NewLocation)
            if type(NewLocation) ~= "table" then
                return false, "location must be a table";
            end
            Location = NewLocation;
            UseScriptScope = false;
            Library:RegisterFlagLocation(Location);
            return true;
        end

        function Manager:IsScriptScope()
            return UseScriptScope;
        end

        function Manager:SetScriptKey(NewKey)
            ScriptKey = SanitizeName(NewKey, "Script");
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return false, FolderError;
            end
            return true, ScriptKey;
        end

        function Manager:GetPresetPath(PresetName)
            local Path, SafeName = GetPresetPath(PresetName);
            return Path, SafeName;
        end

        function Manager:Save(PresetName, SourceLocation)
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return false, FolderError;
            end

            local Source = nil;
            if type(SourceLocation) == "table" then
                Source = SourceLocation;
            elseif UseScriptScope then
                Source = Library:CollectScriptPresetData();
            else
                Source = Location;
            end
            if type(Source) ~= "table" then
                return false, "source location must be a table";
            end

            local Path, SafeName = GetPresetPath(PresetName);
            local Encoded;
            local OkEncode, EncodeError = pcall(function()
                Encoded = HttpService:JSONEncode({
                    __wallyPreset = true;
                    schemaVersion = SchemaVersion;
                    savedAt = os.time();
                    build = tostring(Library.Build or "");
                    data = SerializeValue(Source);
                });
            end);
            if not OkEncode then
                return false, "failed to encode preset: " .. tostring(EncodeError);
            end

            local OkWrite = pcall(FileApi.WriteFile, Path, Encoded);
            if not OkWrite then
                return false, "failed to write preset file";
            end

            return true, SafeName;
        end

        function Manager:Export(PresetName)
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return false, FolderError;
            end

            local Path = GetPresetPath(PresetName);
            local OkFile, Exists = pcall(FileApi.IsFile, Path);
            if (not OkFile) or (not Exists) then
                return false, "preset file not found";
            end

            local OkRead, Content = pcall(FileApi.ReadFile, Path);
            if not OkRead then
                return false, "failed to read preset file";
            end

            return true, tostring(Content);
        end

        function Manager:ExportCurrent(SourceLocation)
            local Source = nil;
            if type(SourceLocation) == "table" then
                Source = SourceLocation;
            elseif UseScriptScope then
                Source = Library:CollectScriptPresetData();
            else
                Source = Location;
            end
            if type(Source) ~= "table" then
                return false, "source location must be a table";
            end

            local OkEncode, Encoded = pcall(function()
                return HttpService:JSONEncode({
                    __wallyPreset = true;
                    schemaVersion = SchemaVersion;
                    savedAt = os.time();
                    build = tostring(Library.Build or "");
                    data = SerializeValue(Source);
                });
            end);
            if not OkEncode then
                return false, "failed to encode preset";
            end
            return true, Encoded;
        end

        function Manager:Import(PresetName, JsonContent, Overwrite)
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return false, FolderError;
            end

            if type(JsonContent) ~= "string" or JsonContent == "" then
                return false, "import data must be a json string";
            end

            local OkDecode, Decoded = pcall(function()
                return HttpService:JSONDecode(JsonContent);
            end);
            if not OkDecode or type(Decoded) ~= "table" then
                return false, "invalid json content";
            end

            local Payload = Decoded;
            if Payload.__wallyPreset ~= true then
                Payload = {
                    __wallyPreset = true;
                    schemaVersion = SchemaVersion;
                    savedAt = os.time();
                    build = tostring(Library.Build or "");
                    data = Payload;
                };
            elseif Payload.schemaVersion == nil then
                Payload.schemaVersion = SchemaVersion;
            end

            local Path, SafeName = GetPresetPath(PresetName);
            local OkFile, Exists = pcall(FileApi.IsFile, Path);
            if OkFile and Exists and Overwrite ~= true then
                return false, "preset already exists";
            end

            local Encoded;
            local OkEncode = pcall(function()
                Encoded = HttpService:JSONEncode(Payload);
            end);
            if not OkEncode then
                return false, "failed to encode imported preset";
            end

            local OkWrite = pcall(FileApi.WriteFile, Path, Encoded);
            if not OkWrite then
                return false, "failed to write imported preset";
            end

            return true, SafeName;
        end

        function Manager:Load(PresetName, TargetLocation, OverrideClearOnLoad)
            local OkRead, DataOrError, Meta = ReadPresetData(PresetName);
            if not OkRead then
                return false, DataOrError;
            end

            local ShouldClear = (OverrideClearOnLoad ~= nil and OverrideClearOnLoad) or (OverrideClearOnLoad == nil and ClearOnLoad);
            if type(TargetLocation) == "table" then
                MergeInto(TargetLocation, DataOrError, ShouldClear);
                if type(Meta) == "table" and Meta.migrated == true then
                    pcall(function()
                        self:Save(PresetName, DataOrError);
                    end);
                end
                return true, DataOrError;
            end

            if UseScriptScope then
                local OkApply, ApplyError = Library:ApplyScriptPresetData(DataOrError, ShouldClear);
                if not OkApply then
                    return false, ApplyError;
                end
                if type(Meta) == "table" and Meta.migrated == true then
                    pcall(function()
                        self:Save(PresetName, DataOrError);
                    end);
                end
                return true, DataOrError;
            end

            local Target = Location;
            if type(Target) ~= "table" then
                return false, "target location must be a table";
            end

            MergeInto(Target, DataOrError, ShouldClear);

            if type(Meta) == "table" and Meta.migrated == true then
                pcall(function()
                    self:Save(PresetName, DataOrError);
                end);
            end

            return true, DataOrError;
        end

        function Manager:LoadInto(PresetName, TargetLocation, OverrideClearOnLoad)
            return self:Load(PresetName, TargetLocation, OverrideClearOnLoad);
        end

        function Manager:Exists(PresetName)
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return false, FolderError;
            end

            local Path = GetPresetPath(PresetName);
            local OkFile, Exists = pcall(FileApi.IsFile, Path);
            if not OkFile then
                return false, "failed to check preset file";
            end

            return Exists == true;
        end

        function Manager:Delete(PresetName)
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return false, FolderError;
            end

            if not FileApi.Delfile then
                return false, "delfile API is not available in this executor";
            end

            local Path = GetPresetPath(PresetName);
            local OkFile, Exists = pcall(FileApi.IsFile, Path);
            if (not OkFile) or (not Exists) then
                return false, "preset file not found";
            end

            local OkDelete = pcall(FileApi.Delfile, Path);
            if not OkDelete then
                return false, "failed to delete preset file";
            end

            return true;
        end

        function Manager:List()
            local OkFolder, FolderError = EnsureFolderTree();
            if not OkFolder then
                return {}, FolderError;
            end

            if not FileApi.ListFiles then
                return {}, "listfiles API is not available in this executor";
            end

            local ScriptFolder = GetScriptFolder();
            local OkList, Files = pcall(FileApi.ListFiles, ScriptFolder);
            if not OkList or type(Files) ~= "table" then
                return {}, "failed to list preset files";
            end

            local Names = {};
            local LowerExt = string.lower(Extension);
            local LowerExtLen = #LowerExt;
            for _, FullPath in next, Files do
                local FileName = tostring(FullPath):match("([^/\\]+)$") or tostring(FullPath);
                local LowerName = string.lower(FileName);
                if LowerExtLen == 0 or LowerName:sub(-LowerExtLen) == LowerExt then
                    table.insert(Names, FileName:sub(1, #FileName - #Extension));
                end
            end

            table.sort(Names, function(A, B)
                return string.lower(A) < string.lower(B);
            end);

            return Names;
        end

        local OkFolder, FolderError = EnsureFolderTree();
        if not OkFolder and Library.BindDebug then
            warn("[Wally Modified][PresetManager] " .. tostring(FolderError));
        end

        return Manager;
    end

    function Library:CreateScriptPresetManager(ScriptKeyOrOptions, MaybeOptions)
        local Options = {};
        if type(ScriptKeyOrOptions) == "string" then
            if type(MaybeOptions) == "table" then
                for Key, Value in next, MaybeOptions do
                    Options[Key] = Value;
                end
            end
            Options.scriptKey = ScriptKeyOrOptions;
        elseif type(ScriptKeyOrOptions) == "table" then
            for Key, Value in next, ScriptKeyOrOptions do
                Options[Key] = Value;
            end
        elseif type(MaybeOptions) == "table" then
            for Key, Value in next, MaybeOptions do
                Options[Key] = Value;
            end
        end

        Options.scope = "script";
        Options.scriptWide = true;
        Options.location = nil;
        local Manager = self:CreatePresetManager(Options);
        if type(Manager) == "table" then
            self.WindowPersistenceRootFolder = Manager:GetRootFolder();
            self.WindowPersistenceScriptKey = Manager:GetScriptKey();
            if not self.WindowPersistenceFileName or self.WindowPersistenceFileName == "" then
                self.WindowPersistenceFileName = "windows.json";
            end
        end
        return Manager;
    end
    
    Defaults = {
        topcolor       = Color3.fromRGB(30, 30, 30);
        titlecolor     = Color3.fromRGB(255, 255, 255);
        
        underlinecolor = Color3.fromRGB(0, 255, 140);
        bgcolor        = Color3.fromRGB(35, 35, 35);
        boxcolor       = Color3.fromRGB(35, 35, 35);
        btncolor       = Color3.fromRGB(25, 25, 25);
        dropcolor      = Color3.fromRGB(25, 25, 25);
        sectncolor     = Color3.fromRGB(25, 25, 25);
        bordercolor    = Color3.fromRGB(60, 60, 60);

        font           = Enum.Font.SourceSans;
        titlefont      = Enum.Font.Code;

        fontsize       = 17;
        titlesize      = 18;

        textstroke     = 1;
        titlestroke    = 1;

        strokecolor    = Color3.fromRGB(0, 0, 0);

        textcolor      = Color3.fromRGB(255, 255, 255);
        titletextcolor = Color3.fromRGB(255, 255, 255);

        autoscaletext = true;
        mintextsize = 10;
        width = 190;
        itemspacing = 0;
        togglestyle = "checkmark";
        toggleoncolor = Color3.fromRGB(0, 255, 140);
        toggleoffcolor = Color3.fromRGB(35, 35, 35);

        notifybgcolor = Color3.fromRGB(28, 28, 28);
        notifybordercolor = Color3.fromRGB(62, 62, 62);
        notifyaccentcolor = Color3.fromRGB(0, 255, 140);
        notifytitlecolor = Color3.fromRGB(255, 255, 255);
        notifytextcolor = Color3.fromRGB(230, 230, 230);
        notifywidth = 280;
        notifyduration = 4;
        notifymax = 6;
        notifypadding = 6;
        persistwindow = false;

        placeholdercolor = Color3.fromRGB(255, 255, 255);
        titlestrokecolor = Color3.fromRGB(0, 0, 0);
    }

    local function SetUnderlineRainbowState(Underline, UseRainbow, SolidColor)
        local ExistingIndex = nil;
        for Index = #Library.RainbowTable, 1, -1 do
            if Library.RainbowTable[Index] == Underline then
                ExistingIndex = Index;
                break;
            end
        end

        if UseRainbow then
            if not ExistingIndex then
                table.insert(Library.RainbowTable, Underline);
            end
            return;
        end

        if ExistingIndex then
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
        PreviewCamera.NearPlaneZ = CameraNearPlane;
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

        local function BuildPreviewModel(SourceInstance)
            if typeof(SourceInstance) ~= "Instance" then
                return nil, "source must be an Instance";
            end

            local OkClone, SourceClone = pcall(function()
                return SourceInstance:Clone();
            end);
            if (not OkClone) or (not SourceClone) then
                return nil, "failed to clone source (check Archivable)";
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
