
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
                task.defer(function()
                    if Target.Parent then
                        return;
                    end

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
                end);
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
