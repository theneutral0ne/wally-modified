local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");
local CoreGui = game:GetService("CoreGui");

local Library = {Count = 0, Queue = {}, Callbacks = {}, RainbowTable = {}, Toggled = true, Binds = {}, Build = "2026-03-05.3"};
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
    
    local Types = {}; do
        Types.__index = Types;
        function Types.Window(Name, Options)
            Library.Count = Library.Count + 1
            local NewWindow = Library:Create('Frame', {
                Name = Name;
                Size = UDim2.new(0, 190, 0, 30);
                BackgroundColor3 = Options.topcolor;
                BorderSizePixel = 0;
                Parent = Library.Container;
                Position = UDim2.new(0, (15 + (200 * Library.Count) - 200), 0, 0);
                ZIndex = 3;
                Library:Create('TextLabel', {
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
                    Font = Options.titlefont;--Enum.Font.Code;
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
                toggled = true;
                flags   = {};
                OrderData = 0;
                order = 0;

            }, Types)

            table.insert(Library.Queue, {
                Window = WindowData.object;
                Position = WindowData.object.Position;
            })

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
        
        function Types:Toggle(Name, Options, Callback)
            Options = Options or {};
            local Default  = Options.default or false;
            local Location = Options.location or self.flags;
            local Flag     = Options.flag or "";
            local Callback = Callback or function() end;
            
            Location[Flag] = Default;

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
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
                    Library:Create('TextButton', {
                        Text = (Location[Flag] and utf8.char(10003) or "");
                        Font = Library.Options.font;
                        TextSize = Library.Options.fontsize;
                        Name = 'Checkmark';
                        Size = UDim2.new(0, 20, 0, 20);
                        Position = UDim2.new(1, -25, 0, 4);
                        TextColor3 = Library.Options.textcolor;
                        BackgroundColor3 = Library.Options.bgcolor;
                        BorderColor3 = Library.Options.bordercolor;
                        TextStrokeTransparency = Library.Options.textstroke;
                        TextStrokeColor3 = Library.Options.strokecolor;
                    })
                });
                Parent = self.container;
            });
                
            local function Click(Temp)
                Location[Flag] = not Location[Flag];
                Callback(Location[Flag])
                CheckData:FindFirstChild(Name).Checkmark.Text = Location[Flag] and utf8.char(10003) or "";
            end

            CheckData:FindFirstChild(Name).Checkmark.MouseButton1Click:Connect(Click)
            Library.Callbacks[Flag] = Click;

            if Location[Flag] == true then
                Callback(Location[Flag])
            end

            self:Resize();
            return {
                Set = function(self, b)
                    Location[Flag] = b;
                    Callback(Location[Flag])
                    CheckData:FindFirstChild(Name).Checkmark.Text = Location[Flag] and utf8.char(10003) or "";
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
        
        function Types:Box(Name, Options, Callback) --type, Default, Data, Location, Flag)
            Options = Options or {};
            local ValueType = Options.type or "";
            local Default = Options.default or "";
            local Location = Options.location or self.flags;
            local Flag     = Options.flag or "";
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
            BoxData.FocusLost:Connect(function(e)
                local Old = Location[Flag];
                if ValueType == "number" then
                    local Numeric = tonumber(BoxData.Text)
                    if (not Numeric) then
                        BoxData.Text = tostring(Old or "");
                    else
                        local Clamped = math.clamp(Numeric, Min, Max);
                        Location[Flag] = Clamped;
                        BoxData.Text = tostring(Clamped);
                    end
                else
                    Location[Flag] = tostring(BoxData.Text)
                end

                Callback(Location[Flag], Old, e)
            end)
            
            if ValueType == 'number' then
                BoxData:GetPropertyChangedSignal('Text'):Connect(function()
                    local Normalized = string.gsub(BoxData.Text, "[^%d%.%-]", "");
                    if BoxData.Text ~= Normalized then
                        BoxData.Text = Normalized;
                    end
                end)
            end
            
            self:Resize();
            return BoxData
        end
        
        function Types:Bind(Name, Options, Callback)
            Options = Options or {};
            local Location     = Options.location or self.flags;
            local KeyboardOnly = Options.kbonly or false
            local Flag         = Options.flag or "";
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

            local function GetBindingFromInputObject(InputObject)
                if typeof(InputObject) ~= "InputObject" then
                    return nil;
                end

                if InputObject.UserInputType == Enum.UserInputType.Keyboard then
                    local KeyCode = InputObject.KeyCode;
                    if KeyCode and KeyCode ~= Enum.KeyCode.Unknown and (not Banned[KeyCode.Name]) then
                        return KeyCode;
                    end
                    return nil;
                end

                if (not KeyboardOnly) and Allowed[InputObject.UserInputType.Name] then
                    return InputObject.UserInputType;
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
                    ButtonData.Text = "..."
                    while Library.Binding do
                        local InputObject = UserInputService.InputBegan:Wait();
                        if InputObject.UserInputType == Enum.UserInputType.Keyboard then
                            if InputObject.KeyCode == Enum.KeyCode.Escape then
                                break;
                            end
                            if InputObject.KeyCode == Enum.KeyCode.Backspace or InputObject.KeyCode == Enum.KeyCode.Delete then
                                Location[Flag] = nil;
                                break;
                            end
                        end

                        local Normalized = GetBindingFromInputObject(InputObject);
                        if Normalized then
                            Location[Flag] = Normalized;
                            break;
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
            local Flag = Options.flag or "";
            local Callback = Callback or function() end;
            local TransparencyLocation = Options.transparencylocation or Location;
            local TransparencyFlag = Options.transparencyflag;

            local Default = Options.default or Options.color or Color3.fromRGB(255, 0, 0);
            if typeof(Default) ~= "Color3" then
                Default = Color3.fromRGB(255, 0, 0);
            end
            local DefaultTransparency = math.clamp(tonumber(Options.transparency or Options.alpha or 0) or 0, 0, 1);

            local PickerSize = math.clamp(tonumber(Options.size) or 90, 70, 130);
            local WheelImage = Options.wheelImage or "rbxassetid://6020299385";
            local WheelTop = 24;
            local ShadeTop = WheelTop + PickerSize + 6;
            local AlphaTop = ShadeTop + 20;
            local HexTop = AlphaTop + 20;
            local RgbTop = HexTop + 22;
            local ControlHeight = RgbTop + 22 + 4;

            local CheckData = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, ControlHeight);
                LayoutOrder = self:GetOrder();
                Library:Create('TextLabel', {
                    Name = 'Title';
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size = UDim2.new(1, -5, 0, 22);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    TextStrokeTransparency = Library.Options.textstroke;
                    TextStrokeColor3 = Library.Options.strokecolor;
                    Library:Create('Frame', {
                        Name = 'Preview';
                        Size = UDim2.new(0, 22, 0, 14);
                        Position = UDim2.new(1, -28, 0, 4);
                        BackgroundColor3 = Default;
                        BorderColor3 = Library.Options.bordercolor;
                    });
                });
                Library:Create('Frame', {
                    Name = 'WheelContainer';
                    Position = UDim2.new(0.5, -math.floor(PickerSize * 0.5), 0, WheelTop);
                    Size = UDim2.new(0, PickerSize, 0, PickerSize);
                    BackgroundColor3 = Library.Options.bgcolor;
                    BorderColor3 = Library.Options.bordercolor;
                    Library:Create('ImageLabel', {
                        Name = 'Wheel';
                        BackgroundTransparency = 1;
                        Size = UDim2.new(1, 0, 1, 0);
                        Image = WheelImage;
                        ScaleType = Enum.ScaleType.Stretch;
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
                Parent = self.container;
            });

            local Title = CheckData:FindFirstChild("Title");
            local Preview = Title and Title:FindFirstChild("Preview");
            local WheelContainer = CheckData:FindFirstChild("WheelContainer");
            local Wheel = WheelContainer and WheelContainer:FindFirstChild("Wheel");
            local Selector = Wheel and Wheel:FindFirstChild("Selector");
            local ShadeBar = CheckData:FindFirstChild("ShadeBar");
            local ShadeTint = ShadeBar and ShadeBar:FindFirstChild("ShadeTint");
            local ShadeKnob = ShadeBar and ShadeBar:FindFirstChild("ShadeKnob");
            local AlphaBar = CheckData:FindFirstChild("AlphaBar");
            local AlphaTint = AlphaBar and AlphaBar:FindFirstChild("AlphaTint");
            local AlphaKnob = AlphaBar and AlphaBar:FindFirstChild("AlphaKnob");
            local HexInput = CheckData:FindFirstChild("HexRow") and CheckData.HexRow:FindFirstChild("Input");
            local RgbInput = CheckData:FindFirstChild("RgbRow") and CheckData.RgbRow:FindFirstChild("Input");

            local WheelDragging = false;
            local ShadeDragging = false;
            local AlphaDragging = false;

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
                return Radius;
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
                    local Angle = Hue * (math.pi * 2);
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

            local function UpdateFromWheelMouse()
                local MousePos = UserInputService:GetMouseLocation();
                local Center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize * 0.5);
                local Offset = MousePos - Center;
                local Radius = GetRadius();

                local Magnitude = Offset.Magnitude;
                if Magnitude > Radius and Magnitude > 0 then
                    Offset = Offset.Unit * Radius;
                    Magnitude = Radius;
                end

                local NewSaturation = (Radius > 0 and (Magnitude / Radius) or 0);
                local NewHue = (math.atan2(Offset.Y, Offset.X) / (2 * math.pi)) % 1;
                ApplyState(NewHue, NewSaturation, Value, CurrentTransparency, true);
            end

            local function UpdateFromShadeMouse()
                local MousePos = UserInputService:GetMouseLocation();
                local ShadeWidth = math.max(ShadeBar.AbsoluteSize.X, 1);
                local Percent = (MousePos.X - ShadeBar.AbsolutePosition.X) / ShadeWidth;
                Percent = math.clamp(Percent, 0, 1);
                ApplyState(Hue, Saturation, 1 - Percent, CurrentTransparency, true);
            end

            local function UpdateFromAlphaMouse()
                local MousePos = UserInputService:GetMouseLocation();
                local AlphaWidth = math.max(AlphaBar.AbsoluteSize.X, 1);
                local Percent = (MousePos.X - AlphaBar.AbsolutePosition.X) / AlphaWidth;
                Percent = math.clamp(Percent, 0, 1);
                ApplyState(Hue, Saturation, Value, Percent, true);
            end

            local function IsPointerInput(InputObject)
                return InputObject.UserInputType == Enum.UserInputType.MouseButton1 or InputObject.UserInputType == Enum.UserInputType.Touch;
            end

            Wheel.InputBegan:Connect(function(Input)
                if IsPointerInput(Input) then
                    WheelDragging = true;
                    UpdateFromWheelMouse();
                end
            end);

            ShadeBar.InputBegan:Connect(function(Input)
                if IsPointerInput(Input) then
                    ShadeDragging = true;
                    UpdateFromShadeMouse();
                end
            end);

            AlphaBar.InputBegan:Connect(function(Input)
                if IsPointerInput(Input) then
                    AlphaDragging = true;
                    UpdateFromAlphaMouse();
                end
            end);

            UserInputService.InputChanged:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if WheelDragging then
                        UpdateFromWheelMouse();
                    end
                    if ShadeDragging then
                        UpdateFromShadeMouse();
                    end
                    if AlphaDragging then
                        UpdateFromAlphaMouse();
                    end
                end
            end);

            UserInputService.InputEnded:Connect(function(Input)
                if IsPointerInput(Input) then
                    if WheelDragging then
                        WheelDragging = false;
                    end
                    if ShadeDragging then
                        ShadeDragging = false;
                    end
                    if AlphaDragging then
                        AlphaDragging = false;
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
            local Precise  = Options.precise  or false -- e.g 0, 1 vs 0, 0.1, 0.2, ...
            local Decimals = math.clamp(math.floor(tonumber(Options.decimals) or 2), 0, 6);
            local Flag     = Options.flag or "";
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
                    Text = "\r" .. Name;
                    BackgroundTransparency = 1;
                    TextColor3 = Library.Options.textcolor;
                    Position = UDim2.new(0, 5, 0, 2);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = Library.Options.font;
                    TextSize = Library.Options.fontsize;
                    Library:Create('Frame', {
                        Name = 'Container';
                        Size = UDim2.new(0, 60, 0, 20);
                        Position = UDim2.new(1, -65, 0, 3);
                        BackgroundTransparency = 1;
                        --BorderColor3 = Library.Options.bordercolor;
                        BorderSizePixel = 0;
                        Library:Create('TextLabel', {
                            Name = 'ValueLabel';
                            Text = Default;
                            BackgroundTransparency = 1;
                            TextColor3 = Library.Options.textcolor;
                            Position = UDim2.new(0, -10, 0, 0);
                            Size     = UDim2.new(0, 1, 1, 0);
                            TextXAlignment = Enum.TextXAlignment.Right;
                            Font = Library.Options.font;
                            TextSize = Library.Options.fontsize;
                            TextStrokeTransparency = Library.Options.textstroke;
                            TextStrokeColor3 = Library.Options.strokecolor;
                        });
                        Library:Create('TextButton', {
                            Name = 'Button';
                            Size = UDim2.new(0, 5, 1, -2);
                            Position = UDim2.new(0, 0, 0, 1);
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
                            Position = UDim2.new(0, 0, 0.5, 0);
                            Size     = UDim2.new(1, 0, 0, 1);
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

                Knob.Position = UDim2.new(math.clamp(Percent, 0, 0.99), 0, 0, 1);
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
                local Percent = (MousePos.X - SliderContainer.AbsolutePosition.X) / SliderContainer.AbsoluteSize.X;
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
            local Flag = Options.flag or "";
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
            self:Resize();
            return Reload, InputBox;
        end
        
        function Types:Dropdown(Name, Options, Callback)
            Options = Options or {};
            local Location = Options.location or self.flags;
            local Flag = Options.flag or "";
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
                        Location[Flag] = tostring(Btn.Text);
                        Callback(Location[Flag]);
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

            return {
                Refresh = Reload;
                Get = function()
                    return Location[Flag];
                end,
                Set = function(_, Value, FireCallback)
                    if Value ~= nil then
                        Location[Flag] = Value;
                        SelectionLabel.Text = tostring(Value);
                        SelectionLabel.TextColor3 = Library.Options.textcolor;
                        if FireCallback ~= false then
                            Callback(Location[Flag]);
                        end
                    end
                end
            }
        end

        function Types:MultiSelectList(Name, Options, Callback)
            Options = Options or {};

            local Location = Options.location or self.flags;
            local Flag = Options.flag or "";
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

        placeholdercolor = Color3.fromRGB(255, 255, 255);
        titlestrokecolor = Color3.fromRGB(0, 0, 0);
    }
	
    function Library:CreateWindow(Name, Options)
		
        if (not Library.Container) then
            local ParentGui = CoreGui;
            if type(gethui) == "function" then
                local Ok, Gui = pcall(gethui);
                if Ok and Gui then
                    ParentGui = Gui;
                end
            end
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
            if Bind.UserInputType == Enum.UserInputType.Keyboard then
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
                    BindsData.Callback()
                end
            end
        end
    end)
end

return Library
