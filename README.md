# Wally Modified UI Library

Wally Modified is a Roblox UI library focused on practical script UIs with:
- Window + section/control building
- Script-wide flags
- Advanced keybind modes
- Color picker with wheel + hex/rgb + shade + transparency
- Dependency-based visibility/enabled states
- Search/filtering
- Virtualized dropdown/list rendering for large datasets
- Script preset save/load/import/export
- Script-based window position persistence
- Toast notifications
- Built-in settings window generator

Current build in this repo: `2026-03-06.52`.

## Loadstring

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified.lua"))()
```

## Quick Start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/theneutral0ne/wally-modified/refs/heads/main/wally-modified.lua"))()

local Flags = {}

local Window = Library:CreateWindow("My Script", {
    underlinecolor = "rainbow",
    persistwindow = true,
    width = 230,
    autowidth = true,
    itemspacing = 2,
    togglestyle = "checkmark", -- or "fill"
})

Window:Section("Main")

Window:Toggle("Enabled", {
    location = Flags,
    flag = "Enabled",
    default = true,
}, function(Value)
    print("Enabled:", Value)
end)

Window:Slider("Speed", {
    location = Flags,
    flag = "Speed",
    min = 16,
    max = 120,
    default = 16,
    precise = true,
    decimals = 1,
    valueWidth = 44,
}, function(Value)
    print("Speed:", Value)
end)

Window:Bind("Toggle UI", {
    location = Flags,
    flag = "UiBind",
    default = Enum.KeyCode.P,
    mode = "press",
}, function()
    print("Pressed bind")
end)
```

## Core Concepts

### 1) Window Objects
`Library:CreateWindow(...)` returns a window object with control creation methods:
- `Section`
- `Label`
- `Button`
- `Toggle`
- `Slider`
- `Box`
- `Bind`
- `Dropdown`
- `SearchBox`
- `ColorPicker`
- `MultiSelectList`
- `SearchBar`
- `Tab` / `CreateTab`

Window objects also expose:
- `SetMinimized(IsMinimized, Animate?)`
- `SetExpanded(IsExpanded, Animate?)`
- `GetMinimized()`
- `SetWidth(NewWidth)`
- `GetWidth()`
- `SetAutoWidth(Boolean, RefreshNow?)`
- `GetAutoWidth()`
- `RefreshAutoWidth(Force?)`

### 2) Flags + Location
Most interactive controls support:
- `location`: table where values are stored (default: window `flags` table)
- `flag`: key name in that table

If `flag` is omitted, Wally auto-generates one.

### 3) Global Hide/Show Key
Press `RightControl` to toggle all windows visibility.

### 4) Common Control Features
All controls go through a common feature layer and usually support:
- Tooltip text: `tooltip` / `help` / `description` / `hint`
- Visibility: `visible`
- Enabled state: `enabled`
- Visibility dependency: `dependsOn` / `visibleWhen` / `showWhen`
- Enabled dependency: `enabledWhen` / `enableWhen`
- Search registration skip: `searchIgnore = true`

Every returned control API also gets common methods:
- `SetVisible(State)`
- `GetVisible()`
- `SetEnabled(State)`
- `GetEnabled()`
- `SetDependency(Rule)` (visibility rule)
- `SetVisibilityDependency(Rule)`
- `SetEnabledDependency(Rule)`
- `SetTooltip(Text)`
- `RefreshDependency()`

## Dependency Rule Shapes

Rule can be:
- `nil` -> always passes
- `string` -> flag name; truthy check
- `function(Location, Library) -> boolean`
- object rule with a `flag`
- array of rules with mode `all` or `any` (`operator` also accepted)

Object rule fields:
- `flag = "MyFlag"`
- `value` / `equals` / `is`
- `notValue` / `notEquals`
- `min` / `max` (numeric)
- `exists = true/false`
- `predicate = function(value, location, library) -> boolean`

Example:

```lua
enabledWhen = {
    flag = "AdvancedEnabled",
    value = true,
}
```

## Window API

### `Library:CreateWindow(Name, Options?)`
Creates a draggable window.

### `Library:GetWindowOptions()`
Returns copy of current window option table.

### `Library:SetWindowOptions(NewOptions, ApplyNow?)`
Merges options into current window options and updates existing windows.

### `Library:UpdateWindowOptions(NewOptions, ApplyNow?)`
Alias of `SetWindowOptions`.

### `Library:ApplyWindowOptions()`
Re-applies style options to all windows/registered controls.

## Window Options

Defaults:

| Option | Type | Default |
|---|---|---|
| `topcolor` | `Color3` | `Color3.fromRGB(30,30,30)` |
| `titlecolor` | `Color3` | `Color3.fromRGB(255,255,255)` |
| `underlinecolor` | `Color3` or `"rainbow"` | `Color3.fromRGB(0,255,140)` |
| `bgcolor` | `Color3` | `Color3.fromRGB(35,35,35)` |
| `boxcolor` | `Color3` | `Color3.fromRGB(35,35,35)` |
| `btncolor` | `Color3` | `Color3.fromRGB(25,25,25)` |
| `dropcolor` | `Color3` | `Color3.fromRGB(25,25,25)` |
| `sectncolor` | `Color3` | `Color3.fromRGB(25,25,25)` |
| `bordercolor` | `Color3` | `Color3.fromRGB(60,60,60)` |
| `font` | `Enum.Font` | `Enum.Font.SourceSans` |
| `titlefont` | `Enum.Font` | `Enum.Font.Code` |
| `fontsize` | `number` | `17` |
| `titlesize` | `number` | `18` |
| `textstroke` | `number` | `1` |
| `titlestroke` | `number` | `1` |
| `strokecolor` | `Color3` | `Color3.fromRGB(0,0,0)` |
| `textcolor` | `Color3` | `Color3.fromRGB(255,255,255)` |
| `titletextcolor` | `Color3` | `Color3.fromRGB(255,255,255)` |
| `autoscaletext` | `boolean` | `true` |
| `mintextsize` | `number` | `10` |
| `width` | `number` | `190` |
| `minwidth` | `number` | `170` |
| `maxwidth` | `number` | `420` |
| `autowidth` | `boolean` | `false` |
| `autowidthpadding` | `number` | `12` |
| `itemspacing` | `number` | `0` |
| `methodspacing` | `number` | alias for spacing |
| `controlspacing` | `number` | alias for spacing |
| `spacing` | `number` | alias for spacing |
| `togglestyle` | `"checkmark"` / `"fill"` | `"checkmark"` |
| `toggleoncolor` | `Color3` | `Color3.fromRGB(0,255,140)` |
| `toggleoffcolor` | `Color3` | `Color3.fromRGB(35,35,35)` |
| `notifybgcolor` | `Color3` | `Color3.fromRGB(28,28,28)` |
| `notifybordercolor` | `Color3` | `Color3.fromRGB(62,62,62)` |
| `notifyaccentcolor` | `Color3` | `Color3.fromRGB(0,255,140)` |
| `notifytitlecolor` | `Color3` | `Color3.fromRGB(255,255,255)` |
| `notifytextcolor` | `Color3` | `Color3.fromRGB(230,230,230)` |
| `notifywidth` | `number` | `280` |
| `notifyduration` | `number` | `4` |
| `notifymax` | `number` | `6` |
| `notifypadding` | `number` | `6` |
| `persistwindow` | `boolean` | `false` |
| `placeholdercolor` | `Color3` | `Color3.fromRGB(255,255,255)` |
| `titlestrokecolor` | `Color3` | `Color3.fromRGB(0,0,0)` |

## Tabs and Search

### `Window:Tab(Name, Options?)`
### `Window:CreateTab(Name, Options?)`
### `Tab:SubTab(Name, Options?)`
### `Tab:CreateSubTab(Name, Options?)`

`Tab` options:
- `headerHeight` or `tabHeaderHeight`: tab button row height

Tabs return another container object with the same control methods.

### `Container:SearchBar(Name?, Options?, Callback?)`
Adds a text search filter for controls in the current container/tab.

SearchBar API:
- `Set(Value, FireCallback?)`
- `Get()`
- `Clear(FireCallback?)`
- `Input` (`TextBox` instance)

## Control API Reference

### Section
`Container:Section(Name, Options?)`

### Label
`Container:Label(Name, Options?)`

Label options:
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

### Button
`Container:Button(Name, Callback)`
`Container:Button(Name, Options, Callback)`

Button API:
- `Fire()`

### Toggle
`Container:Toggle(Name, Options, Callback?)`

Toggle options:
- `default`
- `location`
- `flag`
- `togglestyle` / `toggleStyle`
- `toggleoncolor` / `oncolor`
- `toggleoffcolor` / `offcolor`

Toggle callback:
- `function(IsOn) end`

Toggle API:
- `Set(Boolean)`
- `Get()`

### Slider
`Container:Slider(Name, Options, Callback?)`

Slider options:
- `location`
- `flag`
- `min`
- `max`
- `default`
- `precise` (`true` for decimals, `false` for integer)
- `decimals` (0-6)
- `valueWidth` / `valuewidth` / `valueLabelWidth` (new)

Slider callback:
- `function(Value) end`

Slider API:
- `Set(Value)`
- `Get()`

### Box
`Container:Box(Name, Options, Callback?)`

Box options:
- `location`
- `flag`
- `type` = `"number"` or `"string"`
- `default`
- `min`
- `max`

Box callback:
- `function(NewValue, OldValue, FocusLostEventData) end`

Box return value:
- Wrapped API object + direct `TextBox` instance behavior
- Includes:
  - `Object` / `TextBox`
  - `Set(Value, FireCallback?)`
  - `Get()`

### Bind
`Container:Bind(Name, Options, Callback?)`

Bind options:
- `location`
- `flag`
- `default` (`Enum.KeyCode` or allowed `Enum.UserInputType`)
- `kbonly` (keyboard only)
- `mode` / `bindmode` / `keybindmode`: `"press"`, `"toggle"`, `"hold"`, `"always"`
- `modeflag` / `modeFlag` (where mode string is stored)

Bind behavior:
- Escape while rebinding cancels
- Backspace/Delete clears
- If `kbonly == false`, `MouseButton1` and `MouseButton2` are allowed

Bind API:
- `Set(NewBinding, FireCallback?)`
- `Clear(FireCallback?)`
- `Get()`
- `SetMode(NewMode, FireCallback?)`
- `GetMode()`
- `GetState()`
- `SetState(NewState, FireCallback?)`

Callback shape by mode:
- `press`: `Callback(Input, nil, "press")`
- `toggle`: `Callback(BooleanState, Binding, "toggle_*")`
- `hold`: `Callback(BooleanState, Binding, "hold_start"/"hold_end")`
- `always`: called with true on mode enter and false on exit

### Dropdown
`Container:Dropdown(Name, Options, Callback?)`

Dropdown options:
- `location`
- `flag`
- `list` (array of strings)

Dropdown callback:
- `function(SelectedText) end`

Dropdown API:
- `Refresh(NewList)`
- `Set(Value, FireCallback?)`
- `Get()`

Notes:
- Uses virtualized row pool for large datasets.

### SearchBox
`Container:SearchBox(PlaceholderText, Options, Callback?)`

SearchBox options:
- `location`
- `flag`
- `list` (array of suggestions)

SearchBox callback:
- `function(CurrentText) end`

SearchBox returns:
- `ReloadFunction`
- `InputTextBox`
- `ApiData`

SearchBox API:
- `Refresh(NewList)` / `Reload(NewList)`
- `Set(Value, FireCallback?)`
- `Get()`
- `Input` / `Box` (TextBox)

### MultiSelectList
`Container:MultiSelectList(Name, Options, Callback?)`

MultiSelect options:
- `location`
- `flag`
- `list`
- `default` (array or map)
- `search` (default true)
- `sort` (default true)
- `caseSensitive` (default false)
- `rowHeight` (default 20)
- `maxVisibleRows` (default 8)
- `maxRows` (default 250, virtualized)
- `listHeight`
- `placeholder`

MultiSelect callback:
- `function(SelectedMap, SelectedArray) end`

MultiSelect API:
- `Get(asArray?)`
- `Set(ItemName, Enabled?, FireCallback?)`
- `SetMany(valuesTable, Enabled?, FireCallback?)`
- `Clear(FireCallback?)`
- `Refresh(NewList, PreserveSelected?, FireCallback?)`

### ColorPicker
`Container:ColorPicker(Name, Options, Callback?)`

ColorPicker options:
- `location`
- `flag`
- `default` / `color`
- `transparency` / `alpha`
- `transparencylocation`
- `transparencyflag` (default `<flag>_Transparency`)
- `size` (picker UI size)
- `wheelImage`
- `wheelRadiusScale`
- `wheelOutsidePadding`
- `drag` / `draggable` (default true)

ColorPicker callback:
- `function(Color3Value, Transparency0To1) end`

ColorPicker API:
- `Set(Color3, FireCallback?)`
- `Get()`
- `SetHSV(H, S, V, FireCallback?)`
- `GetHSV()`
- `SetTransparency(Alpha, FireCallback?)`
- `GetTransparency()`
- `SetAlpha(Alpha, FireCallback?)`
- `GetAlpha()`

## Notifications

### `Library:Notify(...)`
Supports:
- `Notify("Title", "Body", Duration, Options?)`
- `Notify({ title=..., text=..., ... })`

Notify options:
- `title`, `text`
- `duration` (`<=0` sticky)
- `level` / `kind` / `type`: `info`, `success`, `warn`, `error`
- `width`, `padding`, `maxNotifications`
- `font`, `titleSize`, `textSize`
- `backgroundColor` / `bgColor`
- `borderColor`
- `accentColor` / `levelColor`
- `titleColor`, `textColor`
- `cornerRadius`

Returns:
- object with `Close(Instant?)` and `Destroy(Instant?)`

Helpers:
- `Library:NotifyInfo(...)`
- `Library:NotifySuccess(...)`
- `Library:NotifyWarn(...)`
- `Library:NotifyError(...)`
- `Library:CreateNotification(...)` and `Library:Notification(...)` (aliases)

## Runtime Control Lookup

### `Library:GetControlApiByFlag(FlagName)`
Gets control API registered to a `flag`.

### `Library:GetControlApiByObject(Instance)`
Gets control API by root GUI object.

### `Library:RefreshDependencies()`
Forces dependency re-evaluation across controls.

## Batch Updates and Callback Suspension

### `Library:SuspendCallbacks(State?)`
- `true` (or no arg): increments suspend depth
- `false`: decrements suspend depth
- Returns: `(isSuspended, depth)`

### `Library:ResumeCallbacks()`
Alias for `SuspendCallbacks(false)`.

### `Library:AreCallbacksSuspended()`
Returns `true` when callback suspension depth > 0.

### `Library:BeginBatchUpdate(options?)`
Begins a batch context.

Options:
- `suspendCallbacks` (default `true`)
- `refreshDependencies` (default `true`)

Returns a batch context used by `EndBatchUpdate`.

### `Library:EndBatchUpdate(context?, options?)`
Ends a batch context and optionally refreshes dependencies.

### `Library:BatchUpdate(worker, options?)`
Convenience wrapper that:
1. begins batch
2. runs `worker(Library)`
3. ends batch safely

Example:

```lua
Library:BatchUpdate(function()
    SpeedSlider:Set(50)
    FlyToggle:Set(true)
    EspColor:Set(Color3.fromRGB(80, 170, 255), true)
end, {
    suspendCallbacks = true,
    refreshDependencies = true,
})
```

## Presets

### `Library:CreatePresetManager(ScriptKeyOrOptions?, MaybeOptions?)`
Generic preset manager.

Options:
- `location` (table) for local scope mode
- `scope` (`"script"` or other)
- `scriptWide` / `global`
- `scriptKey` / `scriptId`
- `rootFolder` (default `WallyModifiedPresets`)
- `extension` (default `.json`)
- `clearOnLoad` (default true)
- `separateByPlace` (default true)
- `schemaVersion` / `version`
- `migrations` (table of migration functions by version)

Manager API:
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
- `SetLocation(table)` (forces local location mode)
- `IsScriptScope()`
- `SetScriptKey(newKey)`
- `GetPresetPath(name)`
- `Save(name, SourceLocation?)`
- `Export(name)` -> raw json string
- `ExportCurrent(SourceLocation?)`
- `Import(name, JsonContent, Overwrite?)`
- `Load(name, TargetLocation?, OverrideClearOnLoad?)`
- `LoadInto(name, TargetLocation, OverrideClearOnLoad?)`
- `Exists(name)`
- `Delete(name)`
- `List()`

### `Library:CreateScriptPresetManager(...)`
Script-wide preset manager wrapper.

Notes:
- Forces script-wide scope (`scope = "script"`).
- Also seeds window persistence root/script key from manager settings.

## Built-In Settings Window

### `Library:SettingsWindows(options?)`
Alias of `Library:SettingsWindow(options?)`.

Creates a dedicated settings window with:
- Theme controls (toggle style, spacing, toggle colors, underline mode/color)
- Preset controls (save/load/delete/refresh/export/import)

Important behavior:
- Presets are script-wide.
- Persistence root/script key are aligned with this settings preset manager.

`options` highlights:
- `title`
- `windowOptions` (styles for settings window)
- `scriptFolder` (root folder name for this script)
- `presets` table:
  - `extension`
  - `clearOnLoad`
  - `separateByPlace`
  - `scriptFolder` / `folder` / `rootFolder`

Return shape:
- `Window`
- `Theme`
- `PresetManager`
- `Apply()`
- `Sync()`
- `RefreshPresets(preferredName?)`

## Window Persistence

### `Library:AttachWindowPersistence(WindowData, WindowName, Options?)`
Persists window position + minimized state to disk.

Enable via:
- window options `persistwindow = true`
- or `persist = true`
- or pass a `windowPersistence` table

`windowPersistence` fields:
- `enabled`
- `rootFolder` / `folder`
- `scriptFolder` / `scriptKey`
- `fileName` (default `windows.json`)
- `windowKey`

Default persistence path:
- Root from `WindowPersistenceRootFolder` or `WallyModifiedPresets`
- Script folder from `WindowPersistenceScriptKey` or auto script key
- File: `windows.json`

## Executor Requirements

Core UI works in Roblox/Luau environments with `loadstring`.

Preset/persistence features require common exploit file APIs:
- `isfolder`
- `makefolder`
- `isfile`
- `readfile`
- `writefile`
- `listfiles` (for listing presets)
- `delfile` (for deleting presets)

Clipboard import/export requires:
- `setclipboard`
- `getclipboard`

If unavailable, API returns a clear error string and settings window shows status.

## Debugging

Set:

```lua
Library.BindDebug = true
```

This enables bind capture/trigger diagnostics in output.

## Full Practical Example

See:
- [`wally-modified-example.lua`](./wally-modified-example.lua)

It demonstrates:
- 4 windows
- movement + ESP use case
- tabs/subtabs
- bind modes
- dependency API
- virtualized dropdown/list
- notifications
- settings window + script-wide presets + import/export
- persistence
