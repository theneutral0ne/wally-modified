# Wally Modified UI Library

Roblox UI library for script UIs with:
- Draggable windows and containerized controls
- Tabs and subtabs
- Shared styling system
- Keybind modes (`press`, `toggle`, `hold`, `always`)
- Color picker popup (wheel + shade + alpha + HEX + RGB)
- Dependency-based visibility/enabled rules
- Runtime control lookup by flag/object
- Script-wide preset save/load/import/export with schema migration
- Script-based window persistence
- Toast notifications
- Built-in settings window generator
- Dedicated image preview windows

Current build in this repo: `2026-03-06.57`

## Loadstring

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified.lua"))()
```

## Quick Start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified.lua"))()

local Flags = {}

local Window = Library:CreateWindow("Example", {
    persistwindow = true,
    itemspacing = 2,
    underlinecolor = "rainbow",
    togglestyle = "checkmark",
})

Window:Section("Main")

Window:Toggle("Enabled", {
    location = Flags,
    flag = "Enabled",
    default = true,
}, function(State)
    print("Enabled:", State)
end)

Window:Slider("WalkSpeed", {
    location = Flags,
    flag = "WalkSpeed",
    min = 16,
    max = 120,
    default = 16,
    precise = true,
    decimals = 1,
}, function(Value)
    print("WalkSpeed:", Value)
end)

Window:Bind("ESP Toggle Bind", {
    location = Flags,
    flag = "EspBind",
    default = Enum.KeyCode.P,
    mode = "toggle",
}, function(StateOrInput, Binding, Event)
    print("Bind callback:", StateOrInput, Binding, Event)
end)
```

## Image Preview Quick Example

```lua
local Preview = Library:CreateImagePreviewWindow("Avatar Preview", {
    windowOptions = {
        persistwindow = true,
    },
    image = "rbxassetid://0",
    caption = "Preview",
    previewHeight = 180,
    scaleType = Enum.ScaleType.Fit,
})

Preview:SetImage("rbxassetid://123456789")
Preview:SetCaption("Updated Asset")
Preview:SetVisible(true)
Preview:BringToFront()
```

## Complete Method Index

This index covers every current method defined with `function Library:...` and `function Types:...` in `wally-modified.lua`.

### Library Methods

- `Library:Create(ClassName, Data)`
- `Library:EnsureTooltipGui()`
- `Library:HideTooltip()`
- `Library:ShowTooltip(Source, TextResolver)`
- `Library:AttachTooltip(Target, TextOrResolver)`
- `Library:EnsureNotificationContainer()`
- `Library:Notify(Title, Text, Duration, Options)`
- `Library:CreateNotification(...)`
- `Library:Notification(...)`
- `Library:NotifyInfo(Title, Text, Duration, Options)`
- `Library:NotifySuccess(Title, Text, Duration, Options)`
- `Library:NotifyWarn(Title, Text, Duration, Options)`
- `Library:NotifyError(Title, Text, Duration, Options)`
- `Library:GetControlApiByFlag(FlagName)`
- `Library:GetControlApiByObject(Object)`
- `Library:OnFlagChanged(FlagName?, Callback, Options?)`
- `Library:EmitFlagChanged(FlagName, Location, NewValue, OldValue, Source?)`
- `Library:RefreshDependencies()`
- `Library:AreCallbacksSuspended()`
- `Library:SuspendCallbacks(State?)`
- `Library:ResumeCallbacks()`
- `Library:BeginBatchUpdate(Options?)`
- `Library:EndBatchUpdate(Context?, Options?)`
- `Library:BatchUpdate(Worker, Options?)`
- `Library:RegisterFlagLocation(Location)`
- `Library:RegisterFlag(Location, Flag)`
- `Library:RegisterFlagController(Location, Flag, Controller)`
- `Library:CollectScriptPresetData()`
- `Library:ApplyScriptPresetData(Data, ShouldClear?)`
- `Library:CreatePresetManager(ScriptKeyOrOptions?, MaybeOptions?)`
- `Library:CreateScriptPresetManager(ScriptKeyOrOptions?, MaybeOptions?)`
- `Library:GetWindowOptions()`
- `Library:ApplyWindowOptions()`
- `Library:SetWindowOptions(NewOptions, ApplyNow?)`
- `Library:UpdateWindowOptions(NewOptions, ApplyNow?)`
- `Library:SettingsWindow(Options?)`
- `Library:SettingsWindows(Options?)`
- `Library:GetAutoScriptStorageKey()`
- `Library:AttachWindowPersistence(WindowData, WindowName, Options?)`
- `Library:CreateWindow(Name, Options?)`
- `Library:CreateImagePreviewWindow(Name?, Options?)`
- `Library:ImagePreviewWindow(Name?, Options?)`
- `Library:Destroy()`

### Container/Window Object Methods

Every window and tab container object is a `Types` object.

- `Container:Resize()`
- `Container:GetOrder()`
- `Container:ResolveFlag(ProvidedFlag, Name, Kind)`
- `Container:ApplyControlSearchFilter()`
- `Container:SetSearchQuery(Query)`
- `Container:AttachControlFeatures(Root, Options, Api, InteractiveTargets, SearchText)`
- `Container:Tab(Name, Options?)`
- `Container:CreateTab(Name, Options?)`
- `Container:SubTab(Name, Options?)`
- `Container:CreateSubTab(Name, Options?)`
- `Container:SearchBar(Name?, Options?, Callback?)`
- `Container:CreateSearchBar(Name?, Options?, Callback?)`
- `Container:Toggle(Name, Options?, Callback?)`
- `Container:Button(Name, Callback)`
- `Container:Button(Name, Options, Callback)`
- `Container:Box(Name, Options?, Callback?)`
- `Container:Bind(Name, Options?, Callback?)`
- `Container:Section(Name, Options?)`
- `Container:Label(Name, Options?)`
- `Container:ColorPicker(Name, Options?, Callback?)`
- `Container:Slider(Name, Options?, Callback?)`
- `Container:SearchBox(PlaceholderText, Options?, Callback?)`
- `Container:Dropdown(Name, Options?, Callback?)`
- `Container:MultiSelectList(Name, Options?, Callback?)`

### Extra WindowData Methods

Returned by `CreateWindow` (window object only):

- `Window:SetMinimized(IsMinimized, Animate?)`
- `Window:SetExpanded(IsExpanded, Animate?)`
- `Window:GetMinimized()`
- `Window:SetPosition(XOffset, YOffset)`
- `Window:GetPosition()`
- `Window:Center()`
- `Window:BringToFront()`
- `Window:Destroy()`

## Runtime Fields

Important runtime fields on the library object:

- `Library.Build` (`string`)
- `Library.BindDebug` (`boolean`, default `false`)
- `Library.Options` (active style table with defaults fallback)
- `Library.Container` (main root `Frame` under a `ScreenGui`)
- `Library.Windows` (active windows)
- `Library.Binds` (active bind registry)
- `Library.Toggled` (global visibility state toggled by `RightControl`)
- `Library.CallbackSuspendDepth`
- `Library.BatchUpdateDepth`

## Global Behavior

- Press `RightControl` to hide/show all created windows.
- Text controls are auto-scaled by default (`autoscaletext = true`) via `UITextSizeConstraint`.
- `flag` is optional on most controls. If omitted, Wally auto-generates a unique flag.
- Callback dispatch is suppressed when:
  - `FireCallback == false` was passed to a setter that supports it, or
  - callback suspension depth is above `0`.

## Window API

### `Library:CreateWindow(Name, Options?)`

Creates one draggable window and returns `WindowData`.

Important behavior:

- Passing `Options` updates `Library.Options` (global active style table for subsequent controls/windows).
- Calls `ApplyWindowOptions()` after creation.
- Calls `AttachWindowPersistence(...)` automatically based on persistence options.

### `Library:CreateImagePreviewWindow(Name?, Options?)`
### `Library:ImagePreviewWindow(Name?, Options?)`

Creates a standalone image preview window and returns a preview API object.

`ImagePreviewWindow(...)` is an alias for `CreateImagePreviewWindow(...)`.

Important behavior:

- Uses `CreateWindow(...)` internally.
- Restores previous `Library.Options` after creating the preview window, so one-off preview window options do not become the global default style.

Image preview options:

- `title` (fallback window title if `Name` is omitted)
- `windowOptions` (full options table forwarded to window creation)
- `windowItemSpacing`
- `persistwindow` / `persistWindow` / `persist`
- `windowPersistence`, `windowPersistenceOptions`
- `previewHeight` / `height` (default `180`)
- `previewWidth` / `imageWidth` (`nil` = auto width)
- `padding` (outer inset, default `5`)
- `caption` (default empty)
- `captionHeight` (default `20`)
- `image` / `imageId` / `asset` (string or numeric id)
- `scaleType` (`Enum.ScaleType` or string: `fit`, `crop`, `stretch`, `slice`, `tile`)
- `imageColor` / `color`
- `imageTransparency` / `transparency`
- `backgroundColor` / `bgColor`
- `borderColor`

Returned preview API:

- fields: `Window`, `Root`, `Frame`, `Image`, `CaptionLabel`
- `SetImage(Image)` / `GetImage()`
- `SetCaption(Text)` / `GetCaption()`
- `SetScaleType(ScaleType)` / `GetScaleType()`
- `SetColor(Color3)` / `GetColor()`
- `SetTransparency(Alpha)` / `GetTransparency()`
- `SetBackgroundColor(Color3)` / `GetBackgroundColor()`
- `SetBorderColor(Color3)` / `GetBorderColor()`
- `SetSize(Width, Height)` / `GetSize()`
- `SetVisible(State)` / `IsVisible()`
- `SetPosition(X, Y)` / `GetPosition()`
- `Center()`
- `BringToFront()`
- `Destroy()`

### `Library:GetWindowOptions()`

Returns a shallow copy of the currently active options table.

### `Library:SetWindowOptions(NewOptions, ApplyNow?)`

Merges keys into active options and into each existing window's options table.

- If `ApplyNow ~= false`, calls `ApplyWindowOptions()`.

### `Library:UpdateWindowOptions(NewOptions, ApplyNow?)`

Alias of `SetWindowOptions`.

### `Library:ApplyWindowOptions()`

Re-applies visual options to current windows and registered toggle visuals.

### `Library:Destroy()`

Destroys all windows and UI roots created by the library, disconnects tracked connections, clears binds/callback registries, closes active popups/tooltips/notifications, and resets runtime state.

### Window Options (Defaults + Aliases)

| Key | Type | Default | Notes |
|---|---|---|---|
| `topcolor` | `Color3` | `Color3.fromRGB(30,30,30)` | Window title bar color |
| `titlecolor` | `Color3` | `Color3.fromRGB(255,255,255)` | Legacy field |
| `underlinecolor` | `Color3` or `"rainbow"` | `Color3.fromRGB(0,255,140)` | Window underline |
| `bgcolor` | `Color3` | `Color3.fromRGB(35,35,35)` | Window content background |
| `boxcolor` | `Color3` | `Color3.fromRGB(35,35,35)` | Text box backgrounds |
| `btncolor` | `Color3` | `Color3.fromRGB(25,25,25)` | Button backgrounds |
| `dropcolor` | `Color3` | `Color3.fromRGB(25,25,25)` | Dropdown/search backgrounds |
| `sectncolor` | `Color3` | `Color3.fromRGB(25,25,25)` | Section/label backgrounds |
| `bordercolor` | `Color3` | `Color3.fromRGB(60,60,60)` | Border color |
| `font` | `Enum.Font` | `Enum.Font.SourceSans` | Base font |
| `titlefont` | `Enum.Font` | `Enum.Font.Code` | Window title font |
| `fontsize` | `number` | `17` | Base text size |
| `titlesize` | `number` | `18` | Title text size |
| `textstroke` | `number` | `1` | Text stroke transparency |
| `titlestroke` | `number` | `1` | Title stroke transparency |
| `strokecolor` | `Color3` | `Color3.fromRGB(0,0,0)` | Text stroke color |
| `textcolor` | `Color3` | `Color3.fromRGB(255,255,255)` | Base text color |
| `titletextcolor` | `Color3` | `Color3.fromRGB(255,255,255)` | Window title text color |
| `titlestrokecolor` | `Color3` | `Color3.fromRGB(0,0,0)` | Window title stroke color |
| `placeholdercolor` | `Color3` | `Color3.fromRGB(255,255,255)` | Placeholder color |
| `autoscaletext` | `boolean` | `true` | Auto text scaling in `Create()` |
| `mintextsize` | `number` | `10` | Min size for auto-scaled text |
| `itemspacing` | `number` | `0` | UIList padding between controls |
| `methodspacing` | alias | - | Alias of `itemspacing` |
| `controlspacing` | alias | - | Alias of `itemspacing` |
| `spacing` | alias | - | Alias of `itemspacing` |
| `togglestyle` | `"checkmark"` or `"fill"` | `"checkmark"` | Default toggle style |
| `toggleoncolor` | `Color3` | `Color3.fromRGB(0,255,140)` | Filled-style on color |
| `toggleoffcolor` | `Color3` | `Color3.fromRGB(35,35,35)` | Filled-style off color |
| `notifybgcolor` | `Color3` | `Color3.fromRGB(28,28,28)` | Notification background |
| `notifybordercolor` | `Color3` | `Color3.fromRGB(62,62,62)` | Notification border |
| `notifyaccentcolor` | `Color3` | `Color3.fromRGB(0,255,140)` | Notification accent |
| `notifytitlecolor` | `Color3` | `Color3.fromRGB(255,255,255)` | Notification title color |
| `notifytextcolor` | `Color3` | `Color3.fromRGB(230,230,230)` | Notification body color |
| `notifywidth` | `number` | `280` | Notification width |
| `notifyduration` | `number` | `4` | Default duration |
| `notifymax` | `number` | `6` | Max visible notifications |
| `notifypadding` | `number` | `6` | Notification list padding |
| `persistwindow` | `boolean` | `false` | Enables window persistence attach |

### WindowData Fields

The window object also contains internal data fields used by the library:

- `object`, `container`, `list`, `options`, `flags`
- `ParentWindow`, `ParentTabOwner` (tabs)
- `AutoFlagPrefix`, `Controls`, `Tabs`, `ActiveTab`

## Container Shared Features

All control APIs pass through `AttachControlFeatures`, so controls generally support these option keys:

- `visible` (`boolean`, default true)
- `enabled` (`boolean`, default true)
- `dependsOn` / `visibleWhen` / `showWhen` (visibility rule)
- `enabledWhen` / `enableWhen` (enabled rule)
- `tooltip` / `help` / `description` / `hint` (tooltip text)
- `searchIgnore` (`true` to skip SearchBar filtering)

All returned control APIs also gain:

- `SetVisible(State)`
- `GetVisible()`
- `SetEnabled(State)`
- `GetEnabled()`
- `SetDependency(Rule)`
- `SetVisibilityDependency(Rule)`
- `SetEnabledDependency(Rule)`
- `SetTooltip(TextOrNil)`
- `RefreshDependency()`
- `SetSearchMatch(IsMatch)` (internal but available)
- `OnChanged(Function)`
- `EmitChanged(...)` (internal but available)

`OnChanged` returns a connection-like object with `Connected` and `Disconnect()`.

### Dependency Rule Shapes

A dependency rule can be:

- `nil` -> passes
- `string` -> truthy check of that flag
- `function(Location, Library) -> boolean`
- object rule with `flag` + constraints
- array of rules with `mode`/`operator` (`all` or `any`)
- plain map `{ FlagA = ExpectedValue, FlagB = ExpectedValue }`

Object rule fields:

- `flag`
- `predicate(value, location, library)`
- `exists` (`true`/`false`)
- `min`
- `max`
- `notValue`, `notEquals`
- `value`, `equals`, `is`

## Tabs and Search Filter

### `Container:Tab(Name, Options?)`
### `Container:CreateTab(Name, Options?)`
### `Container:SubTab(Name, Options?)`
### `Container:CreateSubTab(Name, Options?)`

Creates/returns a tab container (same control creation methods as a window).

`Options`:

- `headerHeight` / `tabHeaderHeight` (`16..30`, default `22`)

### `Container:SearchBar(Name?, Options?, Callback?)`
### `Container:CreateSearchBar(Name?, Options?, Callback?)`

Adds a control filter box for current container/tab.

`SearchBar` options:

- `default` (initial text)
- `placeholder` (fallback display text)

`SearchBar` API:

- `Set(Value, FireCallback?)`
- `Get()`
- `Clear(FireCallback?)`
- `Input` (`TextBox`)

Behavior:

- Filters controls by search text registered in `AttachControlFeatures`.
- Created with `searchIgnore = true` automatically.

## Controls

### `Container:Section(Name, Options?)`

Visual section header. Returns API object with shared common feature methods only.

### `Container:Label(Name, Options?)`

Options:

- `text` / `Text`
- `textSize` / `TextSize`
- `textColor` / `TextColor`
- `bgColor` / `BgColor`
- `borderColor` / `BorderColor`
- `height` / `Height`
- `backgroundTransparency` / `BgTransparency`

Label API:

- `Refresh(NewText)`
- `SetColor(Color3)`
- `SetBackground(Color3)`

### `Container:Button(Name, Callback)`
### `Container:Button(Name, Options, Callback)`

Button API:

- `Fire()`

### `Container:Toggle(Name, Options?, Callback?)`

Options:

- `location` (default container/window `flags`)
- `flag`
- `default` (`boolean`)
- `togglestyle` / `toggleStyle` (`checkmark` or fill-style names)
- `toggleoncolor` / `oncolor`
- `toggleoffcolor` / `offcolor`

Callback:

- `function(IsOn) end`

Toggle API:

- `Set(Boolean)`
- `Get()`

Note:

- `Set` always fires callback unless callbacks are globally suspended.

### `Container:Slider(Name, Options?, Callback?)`

Options:

- `location`
- `flag`
- `min` (default `0`)
- `max` (default `1`)
- `default` (defaults to `min`)
- `precise` (`true` for decimals)
- `decimals` (`0..6`, default `2`)
- `step` (snaps value to interval; supports decimal steps)
- `valueWidth` / `valuewidth` / `valueLabelWidth` (`24..80`, default `40`)

Callback:

- `function(Value) end`

Slider API:

- `Set(Value)`
- `Get()`

Notes:

- If `min > max`, values are swapped.
- If `step` is provided, values snap to `min + n * step`.
- Without `step`, non-precise sliders are integer (`math.floor`).

### `Container:Box(Name, Options?, Callback?)`

Options:

- `location`
- `flag`
- `type` (`"number"` or `"string"`)
- `default`
- `min` (number mode)
- `max` (number mode)

Callback:

- `function(NewValue, OldValue, FocusLostEventData) end`

Box return:

- Wrapped API that also proxies to underlying `TextBox` members/methods.
- Exposes:
  - `Object` / `TextBox`
  - `Get()`
  - `Set(Value, FireCallback?)`

### `Container:Bind(Name, Options?, Callback?)`

Options:

- `location`
- `flag`
- `default` (`Enum.KeyCode`, allowed `Enum.UserInputType`, input-object/string forms)
- `kbonly` (`true` blocks mouse binds)
- `mode` / `bindmode` / `keybindmode` (`press`, `toggle`, `hold`, `always`)
- `modeflag` / `modeFlag` (storage key for mode string; default `<flag>_Mode`)

Bind UI rebind behavior:

- Click bind box -> capture mode (`...`)
- `Escape` cancels
- `Backspace`/`Delete` clears bind
- Keyboard keys are accepted except banned (`Return`, `Space`, `Tab`, `Unknown`)
- Mouse binds allowed only when `kbonly ~= true` (`MouseButton1`, `MouseButton2`)

Bind API:

- `Set(NewBinding, FireCallback?) -> (boolean, valueOrError)`
- `Clear(FireCallback?) -> boolean`
- `Get()`
- `SetMode(NewMode, FireCallback?) -> normalizedMode`
- `GetMode()`
- `GetState()`
- `SetState(NewState, FireCallback?)`

Bind callback payloads:

- `press`: `Callback(InputObject, nil, "press")`
- `toggle`: state events such as `"toggle_press"` / `"toggle_state"`
- `hold`: `"hold_start"` / `"hold_end"`
- `always`: `"always_start"` / `"always_end"`

Notes:

- Runtime bind processing is ignored while callbacks are suspended.
- Initial `always` mode invokes start callback once on creation.

### `Container:Dropdown(Name, Options?, Callback?)`

Options:

- `location`
- `flag`
- `list` (array)

Callback:

- `function(SelectedText) end`

Dropdown API:

- `Refresh(NewList)` (resets selected value to first item or empty)
- `Set(Value, FireCallback?)`
- `Get()`

Notes:

- Uses a pooled virtual row renderer while opened.
- Open list max visible height is `100` px.

### `Container:SearchBox(PlaceholderText, Options?, Callback?)`

Options:

- `location`
- `flag`
- `list` (array of suggestion rows)

Callback:

- `function(CurrentText) end`

Returns:

- `ReloadFunction`
- `InputTextBox`
- `ApiData`

`ApiData`:

- `Refresh(NewList)` / `Reload(NewList)`
- `Set(Value, FireCallback?)`
- `Get()`
- `Input` / `Box` (`TextBox`)

### `Container:MultiSelectList(Name, Options?, Callback?)`

Options:

- `location`
- `flag`
- `list` (array)
- `default` (array or map)
- `search` (`true` default)
- `sort` (`true` default)
- `caseSensitive` (`false` default)
- `rowHeight` (default `20`)
- `maxVisibleRows` (default `8`)
- `maxRows` (default `250`, virtualization cap)
- `listHeight` (clamped)
- `placeholder`

Callback:

- `function(SelectedMap, SelectedArray) end`

API:

- `Get(asArray?)`
- `Set(ItemName, Enabled?, FireCallback?)`
- `SetMany(values, Enabled?, FireCallback?)`
- `Clear(FireCallback?)`
- `Refresh(NewList, PreserveSelected?, FireCallback?)`

### `Container:ColorPicker(Name, Options?, Callback?)`

Accepted call styles:

- `ColorPicker(Name, Color3, Callback?)`
- `ColorPicker(Name, Options, Callback?)`

Options:

- `location`
- `flag`
- `default` / `color` (`Color3`)
- `transparency` / `alpha` (`0..1`)
- `transparencylocation` (table)
- `transparencyflag` (default `<flag>_Transparency`)
- `size` (`90..180`, default `120`)
- `wheelImage` (asset id)
- `wheelRadiusScale` (`0.6..1`, default `1`)
- `wheelOutsidePadding` (default `4`)
- `drag` / `draggable` (`true` default)

Callback:

- `function(Color3Value, Transparency0To1) end`

API:

- `Set(Color3, FireCallback?)`
- `Get()`
- `SetHSV(H, S, V, FireCallback?)`
- `GetHSV()`
- `SetTransparency(Alpha, FireCallback?)`
- `GetTransparency()`
- `SetAlpha(Alpha, FireCallback?)`
- `GetAlpha()`

UI behavior:

- Click preview swatch to open popup.
- Popup is modal-blocked with an invisible full-screen blocker.
- Shade/alpha bars, HEX input, and RGB input all sync to current color.

## Notifications

### `Library:Notify(...)`

Supported signatures:

- `Library:Notify("Title", "Body", Duration, Options?)`
- `Library:Notify({ title=..., text=..., ... })`

Notification config keys:

- `title`
- `text`
- `duration` (`<= 0` = sticky)
- `level` / `kind` / `type` (`info`, `success`, `warn`, `warning`, `error`)
- `width` / `size`
- `padding`
- `maxNotifications` / `maxnotifications`
- `font`
- `titleSize`
- `textSize`
- `backgroundColor` / `bgColor`
- `borderColor`
- `accentColor` / `levelColor`
- `titleColor`
- `textColor`
- `cornerRadius`

Returns:

- object with `Close(Instant?)` and `Destroy(Instant?)`

Aliases/helpers:

- `Library:CreateNotification(...)`
- `Library:Notification(...)`
- `Library:NotifyInfo(...)`
- `Library:NotifySuccess(...)`
- `Library:NotifyWarn(...)`
- `Library:NotifyError(...)`

### `Library:EnsureNotificationContainer()`

Advanced/internal helper that creates and returns the notification container frame.

## Tooltip API (Advanced)

- `Library:EnsureTooltipGui()`
- `Library:ShowTooltip(Source, TextResolver)`
- `Library:HideTooltip()`
- `Library:AttachTooltip(TargetGuiObject, TextOrResolver)`

Notes:

- Tooltips are shown near mouse (`+14, +12` offset).
- `AttachTooltip` automatically cleans connections when target is removed.

## Runtime Control Lookup and Dependencies

### `Library:GetControlApiByFlag(FlagName)`

Returns registered control API or `nil`.

### `Library:GetControlApiByObject(Instance)`

Returns registered control API for the control root object or `nil`.

### `Library:OnFlagChanged(FlagName?, Callback, Options?)`

Subscribes to flag changes emitted by Wally-controlled value writes.

Usage:

- `OnFlagChanged("WalkSpeed", function(NewValue, OldValue, Payload) ... end)`
- `OnFlagChanged(function(FlagName, NewValue, OldValue, Payload) ... end)` for all flags

`Options`:

- `location` / `scopeLocation` (optional table filter)

Returns a connection-like object with:

- `Connected`
- `Disconnect()`

### `Library:EmitFlagChanged(FlagName, Location, NewValue, OldValue, Source?)`

Manually emits a flag-change event to `OnFlagChanged` listeners. This is an advanced/runtime utility.

### `Library:RefreshDependencies()`

Re-evaluates dependency states for tracked controls. Returns count refreshed.

## Callback Suspension and Batch Updates

### `Library:AreCallbacksSuspended()`

Returns `true` when callback suspend depth > `0`.

### `Library:SuspendCallbacks(State?)`

- `nil`/`true`: increment depth
- `false`: decrement depth

Returns `(isSuspended, depth)`.

### `Library:ResumeCallbacks()`

Alias for `SuspendCallbacks(false)`.

### `Library:BeginBatchUpdate(options?)`

Begins a batch context.

Options:

- `suspendCallbacks` (`true` default)
- `refreshDependencies` (`true` default)

Returns context table.

### `Library:EndBatchUpdate(context?, options?)`

Ends a batch. Can also be called with boolean shorthand:

- `EndBatchUpdate(true)` means `refreshDependencies = true`

Returns:

- `true` on success
- `false, "batch already ended"` when ending same context twice

### `Library:BatchUpdate(worker, options?)`

Convenience wrapper:

1. Begin batch
2. `pcall(worker, Library)`
3. End batch
4. Re-throw worker error if any

If `worker` is not a function, returns `false, "worker must be a function"`.

## Flag Registry and Low-Level Flag APIs

### `Library:RegisterFlagLocation(Location)`

Registers a table location for fallback flag resolution.

### `Library:RegisterFlag(Location, Flag)`

Registers a flag name to one or more location tables.

### `Library:RegisterFlagController(Location, Flag, Controller)`

Registers controller table used for scripted apply operations.

Controller shape:

- must include `Set(Value, FireCallback?)` function

### `Library:CollectScriptPresetData()`

Collects script-wide values from all registered flags into one map.

### `Library:ApplyScriptPresetData(Data, ShouldClear?)`

Applies flag map script-wide by:

1. controller `Set` functions when available
2. registered flag locations fallback
3. first fallback flag location as final fallback

Returns:

- `true` on success
- `false, errorMessage` on invalid input

## Presets

### `Library:CreatePresetManager(ScriptKeyOrOptions?, MaybeOptions?)`

Creates a generic preset manager.

Constructor inputs:

- `CreatePresetManager("MyScriptKey", options?)`
- `CreatePresetManager(optionsTable)`

Options:

- `location` (table for local scope)
- `scope` (`"script"`, `"global"`, `"all"` -> script scope)
- `scriptWide` (`boolean`)
- `global` (`boolean`)
- `scriptKey` / `scriptId`
- `rootFolder` (default `WallyModifiedPresets`)
- `extension` (default `.json`)
- `clearOnLoad` (default `true`)
- `separateByPlace` (default `true`)
- `schemaVersion` / `version` (default `1`)
- `migrations` (table keyed by version)

Manager methods:

- `IsAvailable()`
- `GetScriptKey()`
- `GetFolder()`
- `GetRootFolder()`
- `GetExtension()`
- `GetSchemaVersion()`
- `SetSchemaVersion(version)`
- `GetMigrations()`
- `SetMigrations(table)`
- `GetLocation()`
- `SetLocation(table)`
- `IsScriptScope()`
- `SetScriptKey(newKey)`
- `GetPresetPath(name)`
- `Save(name, SourceLocation?)`
- `Export(name)`
- `ExportCurrent(SourceLocation?)`
- `Import(name, JsonContent, Overwrite?)`
- `Load(name, TargetLocation?, OverrideClearOnLoad?)`
- `LoadInto(name, TargetLocation?, OverrideClearOnLoad?)`
- `Exists(name)`
- `Delete(name)`
- `List()`

Serialization details:

- Stores non-primitive support for `Color3` and `EnumItem`.
- Payload includes:
  - `__wallyPreset = true`
  - `schemaVersion`
  - `savedAt`
  - `build`
  - `data`
- On load, schema migrations run from stored version up to current schema.

### `Library:CreateScriptPresetManager(ScriptKeyOrOptions?, MaybeOptions?)`

Wrapper over `CreatePresetManager` that forces script scope.

Behavior:

- `scope = "script"`
- `scriptWide = true`
- `location = nil`
- Sets library persistence defaults:
  - `WindowPersistenceRootFolder`
  - `WindowPersistenceScriptKey`
  - `WindowPersistenceFileName` (`windows.json` default)

## Built-In Settings Window

### `Library:SettingsWindow(options?)`

Creates a dedicated settings window and returns:

- `Window`
- `Theme`
- `PresetManager`
- `Apply()`
- `Sync()`
- `RefreshPresets(preferredName?)`

Settings window includes:

- Window theme controls
  - toggle style
  - item spacing
  - toggle on/off colors
  - underline mode and color
  - reset theme
- Script preset controls
  - save, load, delete, refresh
  - export to clipboard
  - import from clipboard
  - schema version display

`options`:

- `title`
- `windowOptions` (options passed to `CreateWindow` for this settings window)
- `scriptFolder` / `folder` / `rootFolder` (preset root folder)
- `defaultPresetName`
- `extension`
- `presets` table:
  - `scriptFolder` / `folder` / `rootFolder`
  - `extension`
  - `clearOnLoad`
  - `separateByPlace`

### `Library:SettingsWindows(options?)`

Alias/compat wrapper to `SettingsWindow(options?)`.

## Window Persistence

### `Library:GetAutoScriptStorageKey()`

Builds a stable script key from script identity + place id.

### `Library:AttachWindowPersistence(WindowData, WindowName, Options?)`

Attaches save/load of window position and minimized state.

Enable by either:

- window options include `persist = true` or `persistwindow = true`, or
- `windowPersistence = true` or `windowPersistence = { ... }`, or
- global `Library.Options.persistwindow == true`

`windowPersistence` options:

- `enabled`
- `rootFolder` / `folder`
- `scriptFolder` / `scriptKey`
- `fileName` (default `windows.json`)
- `windowKey`

Return values:

- `true, filePath` when attached
- `false, reason` when disabled/unavailable/invalid

Stored JSON entry shape per window key:

- `minimized`
- `position.xScale`
- `position.xOffset`
- `position.yScale`
- `position.yOffset`
- `savedAt`
- `build`

## Low-Level Create Helper

### `Library:Create(ClassName, Data)`

Internal helper used by the library to build GUI objects.

Behavior:

- Any `Instance` value inside `Data` is parented to the created object.
- Applies auto text scaling constraints to text classes based on settings.
- Returns created instance.

## Executor Requirements

Core UI requires Roblox Luau + `loadstring` support.

Preset/persistence APIs require file APIs:

- `isfolder`
- `makefolder`
- `isfile`
- `readfile`
- `writefile`
- `listfiles` (for listing presets)
- `delfile` (for deleting presets)

Clipboard preset import/export requires:

- `setclipboard`
- `getclipboard`

When unavailable, methods return `false, errorMessage` (or empty list + error for list calls).

## Debugging

Enable bind debug logs:

```lua
Library.BindDebug = true
```

This prints bind capture and trigger diagnostics.

## Practical Example

See:

- [`wally-modified-example.lua`](./wally-modified-example.lua)

The example demonstrates practical usage for windows, tabs, dependencies, presets, persistence, notifications, runtime APIs, and keybind modes.
