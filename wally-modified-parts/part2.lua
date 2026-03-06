
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
