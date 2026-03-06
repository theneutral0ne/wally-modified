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
    Build = "2026-03-06.61",
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
                    TextWrapped = false;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ClearTextOnFocus = false;
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
