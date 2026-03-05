local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");
local CoreGui = game:GetService("CoreGui");
local HttpService = game:GetService("HttpService");
local TextService = game:GetService("TextService");
local GuiService = game:GetService("GuiService");

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
    Build = "2026-03-05.43",
    BindDebug = false
};
local Defaults; do
    local Dragger = {}; do
        function Dragger.New(Frame)
            Frame.Active = true;

            local Dragging = false;
            local DragInput;
            local DragStart;
            local StartPos;

            Frame.InputBegan:Connect(function(Input)
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

            Frame.InputChanged:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement then
                    DragInput = Input;
                end
            end)

            UserInputService.InputChanged:Connect(function(Input)
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
        end

        UserInputService.InputBegan:Connect(function(Key, Gpe)
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
        end)
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
	            local NewWindow = Library:Create('Frame', {
                Name = Name;
                Size = UDim2.new(0, 190, 0, 30);
                BackgroundColor3 = Options.topcolor;
                BorderSizePixel = 0;
                Parent = Library.Container;
                Position = UDim2.new(0, (15 + (200 * Library.Count) - 200), 0, 0);
                ZIndex = 3;
                Library:Create('TextLabel', {
                    Name = "window_title";
                    Text = Name;
                    Size = UDim2.new(1, -45, 1, 0);
                    Position = UDim2.new(0, 5, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Enum.Font.Code;
                    TextSize = Options.titlesize;
                    Font = Options.titlefont;
                    TextColor3 = Options.titletextcolor;
                    TextStrokeTransparency = Library.Options.titlestroke;
                    TextStrokeColor3 = Library.Options.titlestrokecolor;
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

            }, Types)

            table.insert(Library.Queue, {
                Window = WindowData.object;
                Position = WindowData.object.Position;
            })
            table.insert(Library.Windows, WindowData);

            if ListLayout then
                ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if WindowData.toggled then
                        WindowData.container.Size = UDim2.new(1, 0, 0, GetContentHeight());
                    end
                end)
            end

            WindowToggle.MouseButton1Click:Connect(function()
                WindowData.toggled = not WindowData.toggled;
                WindowToggle.Text = (WindowData.toggled and "-" or "+");
                if (not WindowData.toggled) then
                    WindowData.container.ClipsDescendants = true;
                end
                local TargetSize = WindowData.toggled and UDim2.new(1, 0, 0, GetContentHeight()) or UDim2.new(1, 0, 0, 0);
                local TargetDirection = WindowData.toggled and "In" or "Out"

                WindowData.container:TweenSize(TargetSize, TargetDirection, "Quint", .3, true)
                task.wait(.3)
                if WindowData.toggled then
                    WindowData.container.ClipsDescendants = false;
                end
            end)

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
            local InitialOptions = self.options or Library.Options or {};

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = Name;
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = InitialOptions.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = InitialOptions.font;
                    TextSize = InitialOptions.fontsize;
                    TextStrokeTransparency = InitialOptions.textstroke;
                    TextStrokeColor3 = InitialOptions.strokecolor;
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
                    })
                });
                Parent = self.container;
            });

            local ToggleLabel = CheckData:FindFirstChild(Name);
            local ToggleButton = CheckData:FindFirstChild(Name).Checkmark;
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
                Location[Flag] = (NewValue == true);
                if FireCallback ~= false then
                    Callback(Location[Flag]);
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
                    SetToggleState(Value, FireCallback ~= false);
                end
            });

            if Location[Flag] == true then
                Callback(Location[Flag])
            end

            self:Resize();
            return {
                Set = function(self, b)
                    SetToggleState(b, true);
                end,
                Get = function()
                    return Location[Flag];
                end
            }
        end
        
        function Types:Button(Name, Callback)
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
            
            CheckData:FindFirstChild(Name).MouseButton1Click:Connect(Callback)
            self:Resize();

            return {
                Fire = function()
                    Callback();
                end
            }
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

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = Name;
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
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
                    })
                });
                Parent = self.container;
            });
        
            local BoxData = CheckData:FindFirstChild(Name):FindFirstChild('Box');

            local function SetBoxValue(NewValue, FireCallback, EventData)
                local Old = Location[Flag];
                if ValueType == "number" then
                    local Numeric = tonumber(NewValue);
                    if (not Numeric) then
                        Location[Flag] = "";
                        BoxData.Text = "";
                    else
                        local Clamped = math.clamp(Numeric, Min, Max);
                        Location[Flag] = Clamped;
                        BoxData.Text = tostring(Clamped);
                    end
                else
                    local TextValue = tostring(NewValue or "");
                    Location[Flag] = TextValue;
                    BoxData.Text = TextValue;
                end

                if FireCallback ~= false then
                    Callback(Location[Flag], Old, EventData);
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
                    SetBoxValue(Value, FireCallback ~= false, nil);
                end
            });
            
            self:Resize();
            return BoxData
        end
        
        function Types:Bind(Name, Options, Callback)
            Options = Options or {};
            local Location     = Options.location or self.flags;
            local KeyboardOnly = Options.kbonly or false
            local Flag         = self:ResolveFlag(Options.flag, Name, "Bind");
            local Callback     = Callback or function() end;
            local Default      = Options.default;

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

            local NormalizedDefault = NormalizeBinding(Default);
            if NormalizedDefault then
                Location[Flag] = NormalizedDefault;
            end

            local DisplayName = GetInputName(Location[Flag]);
            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 30);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = Name;
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    BorderColor3     = Library.Options.bordercolor;
                    BorderSizePixel  = 1;
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
                    })
                });
                Parent = self.container;
            });
             
            local ButtonData = CheckData:FindFirstChild(Name).Keybind;
            ButtonData.MouseButton1Click:Connect(function()
                Library.Binding = true

                local Ok, ErrorData = pcall(function()
                    local FocusedTextBox = UserInputService:GetFocusedTextBox();
                    if FocusedTextBox then
                        FocusedTextBox:ReleaseFocus();
                    end

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
                                Location[Flag] = nil;
                                DebugBindLog("Binding cleared with Backspace/Delete");
                                break;
                            end
                        end

                        local Normalized = GetBindingFromInputObject(InputObject);
                        if Normalized then
                            Location[Flag] = Normalized;
                            DebugBindLog("Binding changed to " .. tostring(Normalized.Name));
                            break;
                        else
                            DebugBindLog("Input ignored (not a bindable key/mouse)");
                        end
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
                Location[Flag] = NormalizeBinding(Location[Flag]);
            end
            ButtonData.Text = GetInputName(Location[Flag]);

	            Library.Binds[Flag] = {
	                Location = Location;
	                Callback = Callback;
	            };

	            self:Resize();

	            local ApiData = {};

	            function ApiData:Set(NewBinding, FireCallback)
	                local Normalized = NormalizeBinding(NewBinding);
	                if NewBinding ~= nil and (not Normalized) then
	                    return false, "invalid binding";
	                end

	                Location[Flag] = Normalized;
	                ButtonData.Text = GetInputName(Location[Flag]);

	                if FireCallback == true then
	                    Callback(Location[Flag]);
	                end

	                return true, Location[Flag];
	            end

	            function ApiData:Clear(FireCallback)
	                Location[Flag] = nil;
	                ButtonData.Text = GetInputName(Location[Flag]);

	                if FireCallback == true then
	                    Callback(Location[Flag]);
	                end

	                return true;
	            end

	            function ApiData:Get()
	                return Location[Flag];
	            end

                Library:RegisterFlagController(Location, Flag, {
                    Set = function(NewBinding, FireCallback)
                        ApiData:Set(NewBinding, FireCallback == true);
                    end
                });

	            return ApiData;
	        end
    
        function Types:Section(Name)
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

            return {
                Refresh = function(_, NewText)
                    LabelObject.Text = tostring(NewText);
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
                    Size = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Library:Create('TextButton', {
                        Name = 'Preview';
                        Text = "";
                        AutoButtonColor = false;
                        Size = UDim2.new(0, 22, 0, 14);
                        Position = UDim2.new(1, -28, 0, 4);
                        BackgroundColor3 = Default;
                        BorderColor3 = Library.Options.bordercolor;
                    });
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

            local ModalBlocker = Library:Create('Frame', {
                Name = 'ColorPickerModalBlocker';
                Visible = false;
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Active = false;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 39;
                Parent = PopupParent;
            });

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

            local Title = CheckData:FindFirstChild("Title");
            local Preview = Title and Title:FindFirstChild("Preview");
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
            local DragUpdateConnection;
            local WheelPointerOffset = Vector2.new(0, 0);
            local ShadePointerOffset = Vector2.new(0, 0);
            local AlphaPointerOffset = Vector2.new(0, 0);

            local Hue, Saturation, Value = Default:ToHSV();
            local CurrentColor = Default;
            local CurrentTransparency = DefaultTransparency;

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

            local function GetPointerCandidates(InputObject)
                local Candidates = {};
                local function Push(Point)
                    if typeof(Point) == "Vector2" then
                        Candidates[#Candidates + 1] = Point;
                    end
                end

                local MousePos = UserInputService:GetMouseLocation();
                Push(MousePos);

                local TopLeftInset = select(1, GuiService:GetGuiInset());
                if typeof(TopLeftInset) == "Vector2" then
                    Push(MousePos - TopLeftInset);
                    Push(MousePos + TopLeftInset);
                end

                if InputObject and typeof(InputObject.Position) == "Vector3" then
                    local InputPos = Vector2.new(InputObject.Position.X, InputObject.Position.Y);
                    Push(InputPos);
                    if typeof(TopLeftInset) == "Vector2" then
                        Push(InputPos - TopLeftInset);
                        Push(InputPos + TopLeftInset);
                    end
                end

                return Candidates;
            end

            local function ResolvePointerPosition(InputObject, TargetGui)
                local Candidates = GetPointerCandidates(InputObject);
                if #Candidates == 0 then
                    return UserInputService:GetMouseLocation();
                end

                if (not TargetGui) or (not TargetGui.Parent) then
                    return Candidates[1];
                end

                local Center = TargetGui.AbsolutePosition + (TargetGui.AbsoluteSize * 0.5);
                local BestPoint = Candidates[1];
                local BestDistance = (BestPoint - Center).Magnitude;
                local BestInside = IsPointInsideGui(TargetGui, BestPoint);

                for Index = 2, #Candidates do
                    local Candidate = Candidates[Index];
                    local Inside = IsPointInsideGui(TargetGui, Candidate);
                    local Distance = (Candidate - Center).Magnitude;
                    if (Inside and (not BestInside)) or (Inside == BestInside and Distance < BestDistance) then
                        BestInside = Inside;
                        BestDistance = Distance;
                        BestPoint = Candidate;
                    end
                end

                return BestPoint;
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

                Location[Flag] = CurrentColor;
                if TransparencyFlag ~= nil and tostring(TransparencyFlag) ~= "" then
                    TransparencyLocation[TransparencyFlag] = CurrentTransparency;
                end

                UpdateVisuals();
                UpdateInputs();

                if FireCallback ~= false then
                    Callback(CurrentColor, CurrentTransparency);
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
                    ModalBlocker.Visible = false;

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
                WheelPointerOffset = Vector2.new(0, 0);
                ShadePointerOffset = Vector2.new(0, 0);
                AlphaPointerOffset = Vector2.new(0, 0);
                if DragUpdateConnection then
                    DragUpdateConnection:Disconnect();
                    DragUpdateConnection = nil;
                end

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
                local MousePos = PointerPos or ResolvePointerPosition(ActiveWheelInput, WheelContainer);
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
                local SafeX = Offset.X;
                if math.abs(SafeX) < 1e-5 then
                    SafeX = (SafeX >= 0 and 1e-5 or -1e-5);
                end

                local Angle = math.atan(Offset.Y / SafeX) + (math.pi * 0.5);
                if Offset.X <= 0 then
                    Angle = Angle + math.pi;
                end
                Angle = Angle % (2 * math.pi);

                -- DevForum-tested wheel math, shifted so hue=0 (red) aligns on the left side of this wheel texture.
                local NewHue = ((Angle / (2 * math.pi)) + 0.25) % 1;
                ApplyState(NewHue, NewSaturation, 1, CurrentTransparency, true);
            end

            local function UpdateFromShadePointer(PointerPos)
                local MousePos = PointerPos or ResolvePointerPosition(ActiveShadeInput, ShadeBar);
                local ShadeWidth = math.max(ShadeBar.AbsoluteSize.X, 1);
                local Percent = (MousePos.X - ShadeBar.AbsolutePosition.X) / ShadeWidth;
                Percent = math.clamp(Percent, 0, 1);
                ApplyState(Hue, Saturation, 1 - Percent, CurrentTransparency, true);
            end

            local function UpdateFromAlphaPointer(PointerPos)
                local MousePos = PointerPos or ResolvePointerPosition(ActiveAlphaInput, AlphaBar);
                local AlphaWidth = math.max(AlphaBar.AbsoluteSize.X, 1);
                local Percent = (MousePos.X - AlphaBar.AbsolutePosition.X) / AlphaWidth;
                Percent = math.clamp(Percent, 0, 1);
                ApplyState(Hue, Saturation, Value, Percent, true);
            end

            local function IsPointerInput(InputObject)
                return InputObject.UserInputType == Enum.UserInputType.MouseButton1 or InputObject.UserInputType == Enum.UserInputType.Touch;
            end

            local function ComputePointerOffset(ResolvedPoint, InputObject)
                if InputObject and InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                    return ResolvedPoint - UserInputService:GetMouseLocation();
                end
                return Vector2.new(0, 0);
            end

            local function StopDragUpdaterIfIdle()
                if WheelDragging or ShadeDragging or AlphaDragging then
                    return;
                end
                if DragUpdateConnection then
                    DragUpdateConnection:Disconnect();
                    DragUpdateConnection = nil;
                end
            end

            local function EnsureDragUpdater()
                if (not EnableDrag) or DragUpdateConnection then
                    return;
                end

                DragUpdateConnection = RunService.RenderStepped:Connect(function()
                    if (not PopupOpen) then
                        return;
                    end

                    local MousePos = UserInputService:GetMouseLocation();
                    if WheelDragging and ActiveWheelInput and ActiveWheelInput.UserInputType == Enum.UserInputType.MouseButton1 then
                        UpdateFromWheelPointer(MousePos + WheelPointerOffset);
                    end
                    if ShadeDragging and ActiveShadeInput and ActiveShadeInput.UserInputType == Enum.UserInputType.MouseButton1 then
                        UpdateFromShadePointer(MousePos + ShadePointerOffset);
                    end
                    if AlphaDragging and ActiveAlphaInput and ActiveAlphaInput.UserInputType == Enum.UserInputType.MouseButton1 then
                        UpdateFromAlphaPointer(MousePos + AlphaPointerOffset);
                    end
                end);
            end

            local function BeginWheelDrag(Input)
                if (not PopupOpen) or (not IsPointerInput(Input)) then
                    return;
                end

                local PointerPos = ResolvePointerPosition(Input, WheelContainer);

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
                    WheelPointerOffset = ComputePointerOffset(PointerPos, Input);
                    ShadePointerOffset = Vector2.new(0, 0);
                    AlphaPointerOffset = Vector2.new(0, 0);
                    EnsureDragUpdater();
                else
                    WheelDragging = false;
                    ShadeDragging = false;
                    AlphaDragging = false;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = nil;
                    WheelPointerOffset = Vector2.new(0, 0);
                    ShadePointerOffset = Vector2.new(0, 0);
                    AlphaPointerOffset = Vector2.new(0, 0);
                    StopDragUpdaterIfIdle();
                end
            end

            local function BeginShadeDrag(Input)
                if (not PopupOpen) or (not IsPointerInput(Input)) then
                    return;
                end

                local PointerPos = ResolvePointerPosition(Input, ShadeBar);
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
                    WheelPointerOffset = Vector2.new(0, 0);
                    ShadePointerOffset = ComputePointerOffset(PointerPos, Input);
                    AlphaPointerOffset = Vector2.new(0, 0);
                    EnsureDragUpdater();
                else
                    WheelDragging = false;
                    ShadeDragging = false;
                    AlphaDragging = false;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = nil;
                    WheelPointerOffset = Vector2.new(0, 0);
                    ShadePointerOffset = Vector2.new(0, 0);
                    AlphaPointerOffset = Vector2.new(0, 0);
                    StopDragUpdaterIfIdle();
                end
            end

            local function BeginAlphaDrag(Input)
                if (not PopupOpen) or (not IsPointerInput(Input)) then
                    return;
                end

                local PointerPos = ResolvePointerPosition(Input, AlphaBar);
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
                    WheelPointerOffset = Vector2.new(0, 0);
                    ShadePointerOffset = Vector2.new(0, 0);
                    AlphaPointerOffset = ComputePointerOffset(PointerPos, Input);
                    EnsureDragUpdater();
                else
                    WheelDragging = false;
                    ShadeDragging = false;
                    AlphaDragging = false;
                    ActiveWheelInput = nil;
                    ActiveShadeInput = nil;
                    ActiveAlphaInput = nil;
                    WheelPointerOffset = Vector2.new(0, 0);
                    ShadePointerOffset = Vector2.new(0, 0);
                    AlphaPointerOffset = Vector2.new(0, 0);
                    StopDragUpdaterIfIdle();
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
                    -- Blocker is disabled while popup is open to avoid stealing input from picker controls.
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

                if (not EnableDrag) or (Input.UserInputType ~= Enum.UserInputType.Touch) then
                    return;
                end

                if WheelDragging and ActiveWheelInput and ActiveWheelInput.UserInputType == Enum.UserInputType.Touch and Input == ActiveWheelInput then
                    UpdateFromWheelPointer(ResolvePointerPosition(Input, WheelContainer));
                end
                if ShadeDragging and ActiveShadeInput and ActiveShadeInput.UserInputType == Enum.UserInputType.Touch and Input == ActiveShadeInput then
                    UpdateFromShadePointer(ResolvePointerPosition(Input, ShadeBar));
                end
                if AlphaDragging and ActiveAlphaInput and ActiveAlphaInput.UserInputType == Enum.UserInputType.Touch and Input == ActiveAlphaInput then
                    UpdateFromAlphaPointer(ResolvePointerPosition(Input, AlphaBar));
                end
            end);

            UserInputService.InputEnded:Connect(function(Input)
                if IsPointerInput(Input) then
                    if Input == ActiveWheelInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and ActiveWheelInput and ActiveWheelInput.UserInputType == Enum.UserInputType.MouseButton1) then
                        WheelDragging = false;
                        ActiveWheelInput = nil;
                        WheelPointerOffset = Vector2.new(0, 0);
                    end
                    if Input == ActiveShadeInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and ActiveShadeInput and ActiveShadeInput.UserInputType == Enum.UserInputType.MouseButton1) then
                        ShadeDragging = false;
                        ActiveShadeInput = nil;
                        ShadePointerOffset = Vector2.new(0, 0);
                    end
                    if Input == ActiveAlphaInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and ActiveAlphaInput and ActiveAlphaInput.UserInputType == Enum.UserInputType.MouseButton1) then
                        AlphaDragging = false;
                        ActiveAlphaInput = nil;
                        AlphaPointerOffset = Vector2.new(0, 0);
                    end
                    StopDragUpdaterIfIdle();
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
                    ApplyColor(NewColor, FireCallback ~= false, CurrentTransparency);
                end
            });
            if TransparencyFlag ~= nil and tostring(TransparencyFlag) ~= "" then
                Library:RegisterFlagController(TransparencyLocation, TransparencyFlag, {
                    Set = function(NewTransparency, FireCallback)
                        ApplyState(Hue, Saturation, Value, NewTransparency, FireCallback ~= false);
                    end
                });
            end

            self:Resize();
            return {
                Set = function(_, NewColor, FireCallback)
                    ApplyColor(NewColor, FireCallback ~= false, CurrentTransparency);
                end,
                Get = function()
                    return Location[Flag];
                end,
                SetHSV = function(_, NewHue, NewSaturation, NewValue, FireCallback)
                    ApplyState(NewHue, NewSaturation, NewValue, CurrentTransparency, FireCallback ~= false);
                end,
                GetHSV = function()
                    return Hue, Saturation, Value;
                end,
                SetTransparency = function(_, NewTransparency, FireCallback)
                    ApplyState(Hue, Saturation, Value, NewTransparency, FireCallback ~= false);
                end,
                GetTransparency = function()
                    return CurrentTransparency;
                end,
                SetAlpha = function(_, NewTransparency, FireCallback)
                    ApplyState(Hue, Saturation, Value, NewTransparency, FireCallback ~= false);
                end,
                GetAlpha = function()
                    return CurrentTransparency;
                end
            };
        end

        function Types:Slider(Name, Options, Callback)
            Options = Options or {};
            local Default = Options.default or Options.min;
            local Min = Options.min or 0;
            local Max = Options.max or 1;
            local Location = Options.location or self.flags;
            local Precise  = Options.precise  or false
            local Decimals = math.clamp(math.floor(tonumber(Options.decimals) or 2), 0, 6);
            local Flag     = self:ResolveFlag(Options.flag, Name, "Slider");
            local Callback = Callback or function() end

            if Min > Max then
                Min, Max = Max, Min;
            end

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
                        Size     = UDim2.new(1, -95, 1, 0);
                        TextXAlignment = Enum.TextXAlignment.Left;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                    });
                    Library:Create('Frame', {
                        Name = 'Container';
                        Size = UDim2.new(0, 60, 0, 20);
                        Position = UDim2.new(1, -65, 0, 3);
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        Library:Create('TextLabel', {
                            Name = 'ValueLabel';
                            Text = Default;
                            BackgroundTransparency = 1;
                            TextColor3 = Library.Options.textcolor;
                            Position = UDim2.new(0, 0, 0, 0);
                            Size     = UDim2.new(0, 22, 1, 0);
                            TextXAlignment = Enum.TextXAlignment.Right;
                            Font = Library.Options.font;
                            TextSize = Library.Options.fontsize;
                            TextScaled = false;
                            TextStrokeTransparency = Library.Options.textstroke;
                            TextStrokeColor3 = Library.Options.strokecolor;
                        });
                        Library:Create('TextButton', {
                            Name = 'Button';
                            Size = UDim2.new(0, 5, 1, -2);
                            Position = UDim2.new(0, 24, 0, 1);
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
                            Position = UDim2.new(0, 24, 0.5, 0);
                            Size     = UDim2.new(1, -24, 0, 1);
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
            local TrackInset = 24;

            local function NormalizeValue(Raw)
                local Value = math.clamp(tonumber(Raw) or Min, Min, Max);
                if Precise then
                    return math.floor((Value * PrecisionFactor) + 0.5) / PrecisionFactor;
                end
                return math.floor(Value);
            end

            local function FormatValue(Value)
                if Precise then
                    return string.format("%." .. tostring(Decimals) .. "f", Value);
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
                Location[Flag] = Value;

                if CurrentValue ~= Value then
                    CurrentValue = Value;
                    if FireCallback ~= false then
                        Callback(Value);
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
                    SetValue(NewValue, FireCallback ~= false);
                end
            });

            self:Resize();
            return {
                Set = function(self, Value)
                    SetValue(Value, true);
                end,
                Get = function()
                    return Location[Flag];
                end
            }
        end 

        function Types:SearchBox(Text, Options, Callback)
            Options = Options or {};
            local ListData = Options.list or {};
            local Flag = self:ResolveFlag(Options.flag, Text, "SearchBox");
            local Location = Options.location or self.flags;
            local Callback = Callback or function() end;

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

                                Location[Flag] = ButtonData.Text;
                                Callback(Location[Flag]);

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

                Location[Flag] = TextValue;
                Rebuild(TextValue);
                if FireCallback ~= false then
                    Callback(Location[Flag]);
                end
            end

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewValue, FireCallback)
                    SetSearchValue(NewValue, FireCallback ~= false);
                end
            });

            self:Resize();
            return Reload, InputBox;
        end
        
        function Types:Dropdown(Name, Options, Callback)
            Options = Options or {};
            local Location = Options.location or self.flags;
            local Flag = self:ResolveFlag(Options.flag, Name, "Dropdown");
            local Callback = Callback or function() end;
            local ListData = (type(Options.list) == "table" and Options.list or {});
            local DefaultSelection = ListData[1] or "";

            Location[Flag] = DefaultSelection
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
                        Size = UDim2.new(1, 0, 1, 0);
                        Text = (DefaultSelection ~= "" and tostring(DefaultSelection) or Name);
                        TextColor3 = Library.Options.textcolor;
                        BackgroundTransparency = 1;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
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

            local function SetDropdownValue(NewValue, FireCallback)
                if NewValue ~= nil then
                    Location[Flag] = tostring(NewValue);
                    SelectionLabel.Text = tostring(Location[Flag]);
                    SelectionLabel.TextColor3 = Library.Options.textcolor;
                    if FireCallback ~= false then
                        Callback(Location[Flag]);
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

                local TotalHeight = #ListData * 20;
                local Size = UDim2.new(1, 0, 0, TotalHeight);

                local ClampedSize;
                local ScrollSize = 0;
                if Size.Y.Offset > 100 then
                    ClampedSize = UDim2.new(1, 0, 0, 100)
                    ScrollSize = 5;
                end
                
                local GoSize = (ClampedSize ~= nil and ClampedSize) or Size;    
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
                    CanvasSize = UDim2.new(0, 0, 0, Size.Y.Offset);
                    ZIndex = 5;
                    ClipsDescendants = true;
                    Library:Create('UIListLayout', {
                        Name = 'List';
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                });
                ActiveContainer = ContainerData;

                for Index, ValueData in next, ListData do
                    local OptionText = tostring(ValueData);
                    local Btn = Library:Create('TextButton', {
                        Size = UDim2.new(1, 0, 0, 20);
                        BackgroundColor3 = Library.Options.btncolor;
                        BorderColor3 = Library.Options.bordercolor;
                        Text = OptionText;
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        LayoutOrder = Index;
                        Parent = ContainerData;
                        ZIndex = 5;
                        TextColor3 = Library.Options.textcolor;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    })
                    
                    Btn.MouseButton1Click:Connect(function()
                        SetDropdownValue(Btn.Text, true);
                        CloseDropdown(true);
                    end)
                end
                
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
                Location[Flag] = ListData[1] or "";
                CloseDropdown(true);
                SelectionLabel.Text = ((Location[Flag] ~= nil and Location[Flag] ~= "") and tostring(Location[Flag]) or Name);
                SelectionLabel.TextColor3 = Library.Options.textcolor;
            end

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewValue, FireCallback)
                    SetDropdownValue(NewValue, FireCallback ~= false);
                end
            });

            return {
                Refresh = Reload;
                Get = function()
                    return Location[Flag];
                end,
                Set = function(_, Value, FireCallback)
                    SetDropdownValue(Value, FireCallback ~= false);
                end
            }
        end

        function Types:MultiSelectList(Name, Options, Callback)
            Options = Options or {};

            local Location = Options.location or self.flags;
            local Flag = self:ResolveFlag(Options.flag, Name, "MultiSelect");
            local Callback = Callback or function() end;
            local ListData = Options.list or {};

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

            Location[Flag] = SelectedData;

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
                    Library:Create('UIListLayout', {
                        Name = 'ListLayout';
                        SortOrder = Enum.SortOrder.LayoutOrder;
                    })
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
            local ListLayout = ContainerData:FindFirstChild('ListLayout');
            local InfoLabel = CheckData:FindFirstChild('Info');
            local SelectAllButton = CheckData:FindFirstChild('SelectAll');
            local ClearButton = CheckData:FindFirstChild('ClearAll');

            ListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                ContainerData.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 2);
            end);

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
                Location[Flag] = SelectedData;
                if DoCallback ~= false then
                    Callback(GetSelectedMap(), GetSelectedArray());
                end
            end

            local function IsMatch(Item, QueryData)
                if QueryData == "" then
                    return true;
                end

                local Source = (CaseSensitive and Item or string.lower(Item));
                return string.find(Source, QueryData, 1, true) ~= nil;
            end

            local function ClearListRows()
                for _, Child in next, ContainerData:GetChildren() do
                    if (not Child:IsA('UIListLayout')) then
                        Child:Destroy();
                    end
                end
            end

            local function ReadQuery()
                if not SearchEnabled then
                    return "";
                end
                return Normalize(SearchBox.Text);
            end

            local function Render()
                ClearListRows();

                local QueryData = ReadQuery();
                local Matched = 0;
                local ShownData = 0;

                for _, Item in next, ListData do
                    if IsMatch(Item, QueryData) then
                        Matched = Matched + 1;

                        if ShownData < MaxRows then
                            ShownData = ShownData + 1;
                            local Enabled = SelectedData[Item] == true;
                            local Row = Library:Create('TextButton', {
                                Name = 'Option_' .. tostring(ShownData);
                                Text = (Enabled and "[x] " or "[ ] ") .. Item;
                                TextXAlignment = Enum.TextXAlignment.Left;
                                Font = Library.Options.font;
                                TextSize = Library.Options.fontsize;
                                TextColor3 = Library.Options.textcolor;
                                TextStrokeTransparency = Library.Options.textstroke;
                                TextStrokeColor3 = Library.Options.strokecolor;
                                BorderColor3 = Library.Options.bordercolor;
                                BackgroundColor3 = (Enabled and Color3.fromRGB(40, 95, 40) or Library.Options.btncolor);
                                AutoButtonColor = false;
                                Size = UDim2.new(1, -4, 0, RowHeight);
                                Position = UDim2.new(0, 2, 0, 0);
                                LayoutOrder = ShownData;
                                Parent = ContainerData;
                            });

                            Row.MouseButton1Click:Connect(function()
                                if SelectedData[Item] then
                                    SelectedData[Item] = nil;
                                else
                                    SelectedData[Item] = true;
                                end

                                UpdateSelection();
                                Render();
                            end);
                        end
                    end
                end

                if Matched == 0 then
                    Library:Create('TextLabel', {
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
                        LayoutOrder = 1;
                        Parent = ContainerData;
                    });
                elseif Matched > MaxRows then
                    Library:Create('TextLabel', {
                        Name = 'RefineHint';
                        Text = ('Refine search (%d matches, showing %d)'):format(Matched, MaxRows);
                        Font = Library.Options.font;
                        TextSize = math.max(Library.Options.fontsize - 2, 12);
                        TextColor3 = Color3.fromRGB(180, 180, 180);
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                        BackgroundTransparency = 1;
                        Size = UDim2.new(1, -4, 0, 18);
                        Position = UDim2.new(0, 2, 0, 0);
                        TextXAlignment = Enum.TextXAlignment.Left;
                        LayoutOrder = ShownData + 1;
                        Parent = ContainerData;
                    });
                end

                local Text = string.format("%d selected | %d matches", GetSelectedCount(), Matched);
                if Matched > ShownData then
                    Text = Text .. string.format(" (showing %d)", ShownData);
                end
                InfoLabel.Text = Text;
            end

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

            local ApiData = {};

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

                UpdateSelection(FireCallback ~= false);
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

                UpdateSelection(FireCallback ~= false);
                Render();
            end

            function ApiData:Clear(FireCallback)
                for Item in next, SelectedData do
                    SelectedData[Item] = nil;
                end

                UpdateSelection(FireCallback ~= false);
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

                Location[Flag] = SelectedData;
                UpdateSelection(FireCallback ~= false);
                Render();
            end

            local function SetMultiSelectValue(NewValue, FireCallback)
                for Item in next, SelectedData do
                    SelectedData[Item] = nil;
                end

                if type(NewValue) == "table" then
                    ApplySelectionData(NewValue);
                end

                UpdateSelection(FireCallback ~= false);
                Render();
            end

            Library:RegisterFlagController(Location, Flag, {
                Set = function(NewValue, FireCallback)
                    SetMultiSelectValue(NewValue, FireCallback ~= false);
                end
            });

            return ApiData;
        end
    end
    
    function Library:Create(ClassName, Data)
        local Obj = Instance.new(ClassName);
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
        
        Obj.Parent = Data.Parent;
        return Obj
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

        local NotifyBackground = Config.backgroundColor or Config.bgColor or (self.Options and self.Options.notifybgcolor) or Color3.fromRGB(28, 28, 28);
        local NotifyBorder = Config.borderColor or (self.Options and self.Options.notifybordercolor) or Color3.fromRGB(62, 62, 62);
        local NotifyAccent = Config.accentColor or (self.Options and self.Options.notifyaccentcolor) or (self.Options and self.Options.underlinecolor) or Color3.fromRGB(0, 255, 140);
        local NotifyTitleColor = Config.titleColor or (self.Options and self.Options.notifytitlecolor) or (self.Options and self.Options.titletextcolor) or Color3.fromRGB(255, 255, 255);
        local NotifyTextColor = Config.textColor or (self.Options and self.Options.notifytextcolor) or (self.Options and self.Options.textcolor) or Color3.fromRGB(230, 230, 230);

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
                                Location[FlagName] = nil;
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
                                Location[FlagName] = Value;
                                Applied = true;
                            end
                        end
                    end
                end

                if not Applied then
                    local FallbackLocations = self.FlagLocations or {};
                    local FirstLocation = FallbackLocations[1];
                    if type(FirstLocation) == "table" then
                        FirstLocation[FlagName] = Value;
                    end
                end
            end
        end

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

            local Data = DeserializeValue(Decoded);
            if type(Data) ~= "table" then
                return false, "preset data is invalid";
            end

            return true, Data;
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
                Encoded = HttpService:JSONEncode(SerializeValue(Source));
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

        function Manager:Load(PresetName, TargetLocation, OverrideClearOnLoad)
            local OkRead, DataOrError = ReadPresetData(PresetName);
            if not OkRead then
                return false, DataOrError;
            end

            local ShouldClear = (OverrideClearOnLoad ~= nil and OverrideClearOnLoad) or (OverrideClearOnLoad == nil and ClearOnLoad);
            if type(TargetLocation) == "table" then
                MergeInto(TargetLocation, DataOrError, ShouldClear);
                return true, DataOrError;
            end

            if UseScriptScope then
                local OkApply, ApplyError = Library:ApplyScriptPresetData(DataOrError, ShouldClear);
                if not OkApply then
                    return false, ApplyError;
                end
                return true, DataOrError;
            end

            local Target = Location;
            if type(Target) ~= "table" then
                return false, "target location must be a table";
            end

            MergeInto(Target, DataOrError, ShouldClear);
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
        return self:CreatePresetManager(Options);
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

                WindowObject.BackgroundColor3 = WindowOptions.topcolor;

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

        SyncControlsFromState();
        PresetInfoLabel:Refresh("Preset Folder: " .. tostring(PresetManager:GetFolder()));

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
		
    function Library:CreateWindow(Name, Options)
			
        if (not Library.Container) then
            local ParentGui = ResolveGuiParent();
            Library.Container = self:Create("ScreenGui", {
                self:Create('Frame', {
                    Name = 'Container';
                    Size = UDim2.new(1, -30, 1, 0);
                    Position = UDim2.new(0, 20, 0, 20);
                    BackgroundTransparency = 1;
                    Active = false;
                });
                Parent = ParentGui;
            }):FindFirstChild('Container');
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
        Dragger.New(WindowData.object);
        self:ApplyWindowOptions();
        return WindowData
    end

    Library.Options = setmetatable({}, {__index = Defaults})

    local RainbowHue = 0;
    RunService.RenderStepped:Connect(function(dt)
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
    end)

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

    UserInputService.InputBegan:Connect(function(Input,Gpe)
        if (not Library.Binding) and (not Gpe) then
            for Index, BindsData in next, Library.Binds do
                local RealBinding = BindsData.Location[Index];
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
                    BindsData.Callback()
                end
            end
        end
    end)
end

return Library
