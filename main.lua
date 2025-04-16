-- Load Rayfield Library
local RayfieldSuccess, RayfieldLib = pcall(function()
    -- Load Rayfield library code, disable http caching with 'true'
    return loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
end)

-- Check if Rayfield loaded okay
if not RayfieldSuccess then
    warn("[Wave Client] Failed to load Rayfield UI Library. Check URL/connection.")
    warn("Error:", RayfieldLib or "Unknown loading error") -- RayfieldLib holds the error if load failed
    return
end
if type(RayfieldLib) ~= "table" then
     warn("[Wave Client] Rayfield loaded but isn't a table:", type(RayfieldLib))
     warn("Returned value:", RayfieldLib)
     return
end
print("[Wave Client] Rayfield Library Loaded.")
local Rayfield = RayfieldLib -- Use this variable for Rayfield functions

-- Roblox services we need
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- Need PlayerGui and VIM for macros to work properly
if not PlayerGui then warn("[Wave Client] PlayerGui not found, Macro button creation may fail.") end
if not VirtualInputManager then warn("[Wave Client] VirtualInputManager not found. Macro clicking WILL NOT work.") end

-- Create the main Rayfield window
local Window = Rayfield:CreateWindow({
    Name = "🌊 Wave Client Rewrite",
    LoadingTitle = "Wave Client Rewrite Loading...",
    LoadingSubtitle = "Please Contact Support if this doesnt load properly .gg/milyon",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "WaveRewrite", -- Settings saved here
        FileName = "UIConfig"
    },
    Discord = {
        Enabled = true,
        Invite = "https://discord.gg/q2fwB2KMPX",
        RememberJoins = true
    },
    KeySystem = false,
    Theme = "Midnight" -- Other themes: "Dark", "Light", "Midnight", etc.
})

-- Set up the main tabs
local placeholderIcon = 4483362458 -- Using a placeholder ID, find better ones if needed
local Tabs = {
    Main = Window:CreateTab("Main", placeholderIcon),
    Macro = Window:CreateTab("Macro", placeholderIcon),
    Extras = Window:CreateTab("Extras", placeholderIcon),
    Settings = Window:CreateTab("Settings", placeholderIcon)
}

-- Helper functions
-- Simple wrapper for Rayfield notifications
local function Notify(title, content, duration)
    if Rayfield and Rayfield.Notify then
        Rayfield:Notify({ Title = title, Content = content, Duration = duration or 3, Actions = {} })
    else
        warn("[Notify Error] Rayfield.Notify function missing.")
    end
end

-- File system stuff (delete folder, ensure folder exists)
local function DeleteFolder(folderName)
    if typeof(isfolder) ~= "function" or typeof(delfolder) ~= "function" then warn("[FileSys] isfolder/delfolder missing."); return false,"fs utils n/a" end
    local success, err = pcall(function() if isfolder(folderName) then delfolder(folderName) end end)
    if not success then warn("[FileSys Delete Error]", err) end
    return success, err
end
local function EnsureProfileFolder()
    if typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then warn("[FileSys] isfolder/makefolder missing."); return false,"fs utils n/a" end
    local success, err = pcall(function() if not isfolder("newvape") then makefolder("newvape") end; if not isfolder("newvape/profiles") then makefolder("newvape/profiles") end end)
    if not success then warn("[FileSys Ensure Error]", err) end
    return success, err
end

-- Main Tab Buttons
Tabs.Main:CreateButton({
    Name = "Launch Wave Client Core (Maintenance)",
    Interact = false, -- Disabled
    Tooltip = "This feature is temporarily unavailable.",
    Callback = function()
        -- TEMP: Disabled for maintenance
    end
})

Tabs.Main:CreateButton({
    Name = "Download/Update Profiles (Maintenance)",
    Interact = false, -- Disabled
    Tooltip = "This feature is temporarily unavailable.",
    Callback = function()
        -- TEMP: Disabled for maintenance
    end
})

Tabs.Main:CreateButton({
    Name = "Join Discord Server",
    Interact = true,
    Callback = function()
        local inviteURL = "https://discord.gg/q2fwB2KMPX"
        if typeof(setclipboard) == "function" then
            local success, err = pcall(setclipboard, inviteURL)
            if success then Notify("Discord", "Invite link copied!", 4)
            else Notify("Error", "Failed to copy link.", 3); warn("[WC] setclipboard error:", err); Notify("Discord Invite", inviteURL, 10) end
        else Notify("Discord Invite", inviteURL, 10); warn("[WC] setclipboard function not available. Link:", inviteURL) end
    end
})


-- Macro Tab Setup & Logic
local macroScreenGui = nil           -- Holds the ScreenGui for the macro buttons
local macroInstructionLabel = nil    -- Shows instructions during placement
local currentMacroAddState = 0       -- 0: Idle, 1: Wait Toggle Pos, 2: Wait Click Pos
local tempTogglePos = nil
local tempMacroName = ""
local activeMacroButtons = {}        -- Stores data for all active macro buttons

-- These hold current macro settings from the UI (updated by Rayfield callbacks)
local currentMacroCPS = 10
local currentMacroMode = "Toggle"
local showMacroButtons = true
local currentMacroNameValue = ""

-- Makes the little macro buttons draggable
local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    if not guiObject or not guiObject:IsA("GuiObject") then return end

    guiObject.InputBegan:Connect(function(input)
        -- Allow dragging only when not placing a macro
        if currentMacroAddState == 0 and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local mouseLoc, guiPos, guiSize = UserInputService:GetMouseLocation(), guiObject.AbsolutePosition, guiObject.AbsoluteSize
            -- Check if click is actually on the button, not transparent background
            if mouseLoc.X >= guiPos.X and mouseLoc.X <= guiPos.X + guiSize.X and mouseLoc.Y >= guiPos.Y and mouseLoc.Y <= guiPos.Y + guiSize.Y then
                dragging = true
                dragStart = input.Position
                startPos = guiObject.Position
                local connection -- Track the Changed connection to disconnect it later
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if connection then connection:Disconnect() end -- Clean up listener
                    end
                end)
            end
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input -- Keep track of the input object for position updates
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        -- If dragging and the input object matches the one we're tracking...
        if input == dragInput and dragging and guiObject.Parent then
            local delta = input.Position - dragStart
            local screen_size = (macroScreenGui and macroScreenGui.AbsoluteSize) or UserInputService:GetScreenSize() -- Fallback to screen size
            local button_size = guiObject.AbsoluteSize
            -- Calculate new position, clamped within screen bounds
            local newPos = UDim2.new(
                startPos.X.Scale, math.clamp(startPos.X.Offset + delta.X, 0, screen_size.X - button_size.X),
                startPos.Y.Scale, math.clamp(startPos.Y.Offset + delta.Y, 0, screen_size.Y - button_size.Y)
            )
            guiObject.Position = newPos
        end
    end)
    guiObject.Selectable = true -- Make sure it can receive input
    guiObject.Active = true     -- Make sure it's processed
end

-- Show/hide the 'Click here' instruction label at the top
local function showInstruction(text)
    if not PlayerGui then return end
    if not macroInstructionLabel or not macroInstructionLabel.Parent then
        macroInstructionLabel = Instance.new("TextLabel", PlayerGui)
        macroInstructionLabel.Name = "WaveClient_MacroInstruction"; macroInstructionLabel.Size = UDim2.new(1,0,0,50); macroInstructionLabel.Position = UDim2.new(0,0,0,0); macroInstructionLabel.BackgroundColor3 = Color3.fromRGB(0,0,0); macroInstructionLabel.BackgroundTransparency = 0.3; macroInstructionLabel.TextColor3 = Color3.fromRGB(255,255,0); macroInstructionLabel.Font = Enum.Font.SourceSansBold; macroInstructionLabel.TextSize = 20; macroInstructionLabel.TextWrapped = true; macroInstructionLabel.TextXAlignment = Enum.TextXAlignment.Center; macroInstructionLabel.TextYAlignment = Enum.TextYAlignment.Center; macroInstructionLabel.ZIndex = 10 -- Should be on top
    end
    macroInstructionLabel.Text = text; macroInstructionLabel.Visible = true
end
local function hideInstruction() if macroInstructionLabel then macroInstructionLabel.Visible = false end end

-- Creates a new draggable macro button on screen
local function addMacroToggleButton(macroName, clickPositionVec2, togglePositionVec2)
    if not PlayerGui then Notify("Macro Error", "PlayerGui not found.", 5); return end
    if not VirtualInputManager then Notify("Macro Error", "VirtualInputManager unavailable.", 5); return end

    -- Create the ScreenGui container if it doesn't exist
    if not macroScreenGui or not macroScreenGui.Parent then
        macroScreenGui = Instance.new("ScreenGui", PlayerGui); macroScreenGui.Name="WaveClient_MacroToggles"; macroScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; macroScreenGui.ResetOnSpawn=false
    end

    local toggledState, mouseEnterState = false, false

    -- Create the button appearance
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = macroName .. "_Toggle"; toggleButton.Size = UDim2.fromOffset(50, 50); toggleButton.Position = UDim2.fromOffset(togglePositionVec2.X-25, togglePositionVec2.Y-25); toggleButton.AnchorPoint = Vector2.new(0.5,0.5); toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50); toggleButton.BorderSizePixel = 0; toggleButton.TextColor3 = Color3.fromRGB(255,255,255); toggleButton.Text = macroName; toggleButton.TextSize = 10; toggleButton.TextWrapped = true; toggleButton.AutoButtonColor = false; toggleButton.ClipsDescendants = true; toggleButton.Parent = macroScreenGui
    local uiCorner = Instance.new("UICorner", toggleButton); uiCorner.CornerRadius = UDim.new(0.5,0) -- Make it circular
    toggleButton.Visible = showMacroButtons -- Set initial visibility

    -- Store button data for later reference
    local macroData = { button=toggleButton, clickPos=clickPositionVec2, name=macroName, clickThread=nil }
    table.insert(activeMacroButtons, macroData)

    -- Safely perform a virtual mouse click
    local function doClick(targetPos)
        if not VirtualInputManager then warn("[Macro] VIM lost!"); return false end
        local s1,e1=pcall(VirtualInputManager.SendMouseButtonEvent,VirtualInputManager,targetPos.X,targetPos.Y,0,true,game,1); task.wait(0.01)
        local s2,e2=pcall(VirtualInputManager.SendMouseButtonEvent,VirtualInputManager,targetPos.X,targetPos.Y,0,false,game,1)
        if not s1 then warn("[Macro] Click Down Err:",e1) end; if not s2 then warn("[Macro] Click Up Err:",e2) end; return s1 and s2
    end

    -- Handle clicks on the macro button itself
    toggleButton.MouseButton1Click:Connect(function()
        if currentMacroAddState ~= 0 then return end -- Ignore clicks during placement
        local mode = currentMacroMode

        if mode == 'Toggle' then
            toggledState = not toggledState -- Flip the toggle state
            toggleButton.BackgroundColor3 = toggledState and Color3.fromRGB(0,180,0) or Color3.fromRGB(50,50,50) -- Green = ON

            if toggledState then -- If turned ON
                if macroData.clickThread then task.cancel(macroData.clickThread) end -- Stop any previous clicking loop
                macroData.clickThread = task.spawn(function() -- Start the new clicking loop
                    repeat
                        if not doClick(clickPositionVec2) then break end -- Attempt click, stop if it fails
                        task.wait(1 / math.max(1, currentMacroCPS)) -- Wait according to CPS
                    until not toggledState or not toggleButton.Parent -- Stop if toggled off or button gone
                    if toggleButton.Parent and not toggledState then toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50) end -- Reset color if stopped normally
                    macroData.clickThread = nil -- Clear thread reference
                end)
            else -- If turned OFF
                if macroData.clickThread then task.cancel(macroData.clickThread); macroData.clickThread = nil end -- Stop the loop
            end

        elseif mode == 'No Repeat' then
            toggleButton.BackgroundColor3 = Color3.fromRGB(0,180,0); doClick(clickPositionVec2); task.wait(0.1) -- Flash green, click once
            if toggleButton.Parent then toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50) end -- Reset color
        end
        -- "Repeat While Holding" is handled below by MouseEnter/Leave
    end)

    -- Handle mouse entering the button area
    toggleButton.MouseEnter:Connect(function()
        if currentMacroAddState ~= 0 then return end
        mouseEnterState = true
        if currentMacroMode == 'Repeat While Holding' then
            if macroData.clickThread then task.cancel(macroData.clickThread) end -- Stop previous loop just in case
            toggleButton.BackgroundColor3 = Color3.fromRGB(0,180,0) -- Turn green
            macroData.clickThread = task.spawn(function() -- Start clicking loop
                repeat
                    if not doClick(clickPositionVec2) then break end
                    task.wait(1 / math.max(1, currentMacroCPS))
                until not mouseEnterState or not toggleButton.Parent -- Stop when mouse leaves or button removed
                if toggleButton.Parent and not mouseEnterState then toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50) end -- Reset color if stopped by mouse leaving
                macroData.clickThread = nil -- Clear thread reference
            end)
        end
    end)

    -- Handle mouse leaving the button area
    toggleButton.MouseLeave:Connect(function()
        if currentMacroAddState ~= 0 then return end
        mouseEnterState = false -- The loop above checks this flag to stop itself
        if currentMacroMode == 'Repeat While Holding' then
            if macroData.clickThread then task.cancel(macroData.clickThread); macroData.clickThread = nil end -- Explicitly stop thread too
            if toggleButton.Parent then toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50) end -- Reset color
        end
    end)

    -- Make the button draggable
    makeDraggable(toggleButton)

    -- Clean up when the button is destroyed
    toggleButton.Destroying:Connect(function()
        if macroData.clickThread then task.cancel(macroData.clickThread); macroData.clickThread = nil end -- Stop clicking loop
        for i, data in ipairs(activeMacroButtons) do if data.button == toggleButton then table.remove(activeMacroButtons, i); break end end -- Remove from our tracking table
    end)

    Notify("Macro Added", "'" .. macroName .. "' toggle created.", 3)
end

-- Rayfield UI Elements for Macro Config
Tabs.Macro:CreateLabel("Macro Setup: Set options, click Add, place toggle, place click.")
Tabs.Macro:CreateTextbox({ Name = "Macro Name", Text = "", Placeholder = "E.g., AutoFarm", Numbers = false, Flag = "MacroName", Callback = function(text) currentMacroNameValue = text end }) -- Updates local var
Tabs.Macro:CreateSlider({ Name = "Clicks Per Second (CPS)", Range = {1, 100}, Increment = 1, Suffix = " CPS", CurrentValue = 10, Flag = "MacroCPS", Callback = function(value) currentMacroCPS = tonumber(value) or 10 end }) -- Updates local var
Tabs.Macro:CreateDropdown({ Name = "Macro Mode", Options = {"Toggle", "Repeat While Holding", "No Repeat"}, Default = "Toggle", Flag = "MacroMode", Callback = function(selectedMode) currentMacroMode = selectedMode end }) -- Updates local var
Tabs.Macro:CreateToggle({ Name = "Show Macro Buttons", CurrentValue = true, Flag = "ShowMacroPositions", -- Updates local var & button visibility
    Callback = function(value)
        showMacroButtons = value
        if macroScreenGui then for _, data in ipairs(activeMacroButtons) do if data.button and data.button.Parent then data.button.Visible = value end end end
        if currentMacroAddState ~= 0 then if not value then hideInstruction() else if currentMacroAddState == 1 then showInstruction("Click screen for Macro TOGGLE button.") elseif currentMacroAddState == 2 then showInstruction("Click screen where Macro should CLICK.") end end end
    end
})
Tabs.Macro:CreateButton({ Name = "Add New Macro", Interact = true, Tooltip = "Starts position selection.",
    Callback = function() local name = currentMacroNameValue; if not name or name:match("^%s*$") then Notify("Macro Error","Enter valid name.",4); return end; if currentMacroAddState ~= 0 then Notify("Macro Info","Already adding.",4); return end; if not VirtualInputManager then Notify("Macro Error","VIM unavailable.",5); return end; tempMacroName = name; currentMacroAddState = 1; showInstruction("Click screen for Macro TOGGLE button.") end })
Tabs.Macro:CreateButton({ Name = "Reset All Macros", Interact = true, Tooltip = "Removes all macro buttons.",
    Callback = function() if #activeMacroButtons == 0 then Notify("Macro Info","No macros to reset.",3); return end; print("Resetting macros..."); for i = #activeMacroButtons, 1, -1 do local d = activeMacroButtons[i]; if d and d.button and d.button.Parent then d.button:Destroy() else table.remove(activeMacroButtons, i) end end; Notify("Macro Reset","All toggles removed.",4) end })
Tabs.Macro:CreateButton({ Name = "Cancel Add Macro", Interact = true, Tooltip = "Cancel placement process.",
    Callback = function() if currentMacroAddState == 0 then Notify("Macro Info","Not adding.",3); return end; currentMacroAddState = 0; tempTogglePos = nil; tempMacroName = ""; hideInstruction(); Notify("Macro","Placement cancelled.",3) end })

-- Listen for clicks anywhere to place the macro (Toggle Pos -> Click Pos)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or currentMacroAddState == 0 then return end -- Ignore processed input or if not placing

    -- Handle left click or touch for placement steps
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if currentMacroAddState == 1 then -- Step 1: Place Toggle Button
            tempTogglePos = input.Position
            currentMacroAddState = 2 -- Go to next step
            showInstruction("Click screen where Macro should CLICK.")
        elseif currentMacroAddState == 2 then -- Step 2: Place Click Location & Create
            local finalClickPos, finalTogglePos, finalMacroName = input.Position, tempTogglePos, tempMacroName
            currentMacroAddState = 0; tempTogglePos = nil; tempMacroName = ""; hideInstruction() -- Reset state first
            addMacroToggleButton(finalMacroName, finalClickPos, finalTogglePos) -- Create the button
        end
    -- Handle right click or escape to cancel placement
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.Escape then
        if currentMacroAddState ~= 0 then -- Only cancel if actually placing
            currentMacroAddState = 0; tempTogglePos = nil; tempMacroName = ""; hideInstruction(); Notify("Macro","Placement cancelled.",3)
        end
    end
end)

-- Extras Tab Content
Tabs.Extras:CreateSlider({ Name = "Set FPS Cap", Range = {30, 240}, Increment = 10, Suffix = " FPS", CurrentValue = 60, Flag = "FPSCap",
    Callback = function(value) if typeof(setfpscap) == "function" then local s,e=pcall(setfpscap,value); if s then Notify("FPS Cap Set","Cap is now "..value,3) else Notify("Error","Failed set FPS cap.",3); warn("[WC] setfpscap err:",e) end else Notify("Error","'setfpscap' n/a.",4); warn("[WC] setfpscap n/a.") end end })

-- Settings Tab Content
Tabs.Settings:CreateLabel("Configuration is saved automatically when changed.")
Tabs.Settings:CreateLabel("Config File Path:")
Tabs.Settings:CreateLabel("YourExecutorFolder/WaveClient/UIConfig.json") -- Generic path

-- Finalization
Rayfield:LoadConfiguration() -- Load saved settings from UIConfig.json
Notify("Wave Client", "UI Loaded Successfully!", 5)

-- Apply initial states after loading config (needs slight delay)
task.wait(1.2) -- Increased delay slightly just in case LoadConfig takes time/triggers callbacks slowly
if showMacroButtons ~= nil and macroScreenGui then
    for _, data in ipairs(activeMacroButtons) do
        if data.button and data.button.Parent then data.button.Visible = showMacroButtons end
    end
end
