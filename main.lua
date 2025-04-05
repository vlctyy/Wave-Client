-- WAVE CLIENT 🌊 
-- MACRO MODULE (Credits to @New_qwertyui)

--[[ Services ]]
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Needed for click simulation
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService") -- Not used in provided snippet, but good practice to declare if potentially needed

--[[ Dependency Check & Loading ]]
local FluentSuccess, Fluent = pcall(function()
    local raw = game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", true)
    return loadstring(raw)()
end)

local SaveMgrSuccess, SaveManager = pcall(function()
    local raw = game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua", true)
    return loadstring(raw)()
end)

local InterfaceMgrSuccess, InterfaceManager = pcall(function()
    local raw = game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", true)
    return loadstring(raw)()
end)

-- Verify successful loading and type checking
if not FluentSuccess then
    warn("[Wave Client] Failed to load Fluent UI Library. Check the URL or your connection.")
    warn("Error:", Fluent or "Unknown loading error")
    return
end
if type(Fluent) ~= "table" then
     warn("[Wave Client] Fluent loaded but is not the expected type:", type(Fluent))
     warn("Returned value:", Fluent)
     return
end
print("[Wave Client] Fluent Library Loaded.")

-- Check and handle addon loading
if not SaveMgrSuccess then warn("[Wave Client] Failed to load Fluent SaveManager Addon. Error:", SaveManager or "Unknown loading error"); SaveManager = nil
elseif type(SaveManager) ~= "table" then warn("[Wave Client] SaveManager loaded but is not the expected type:", type(SaveManager)); SaveManager = nil
else print("[Wave Client] SaveManager Addon Loaded.") end

if not InterfaceMgrSuccess then warn("[Wave Client] Failed to load Fluent InterfaceManager Addon. Error:", InterfaceManager or "Unknown loading error"); InterfaceManager = nil
elseif type(InterfaceManager) ~= "table" then warn("[Wave Client] InterfaceManager loaded but is not the expected type:", type(InterfaceManager)); InterfaceManager = nil
else print("[Wave Client] InterfaceManager Addon Loaded.") end

-- Check for necessary components
if not PlayerGui then warn("[Wave Client] PlayerGui not found, Macro button creation may fail.") end
if not VirtualInputManager then warn("[Wave Client] VirtualInputManager not found. Macro clicking WILL NOT work.") end


--[[ UI Creation ]]
local windowTitle = "🌊 Wave Client " .. (Fluent.Version or "v?")
local Window = Fluent:CreateWindow({
    Title = windowTitle,
    SubTitle = "Fluent Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 500), -- Adjusted height
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Options = Fluent.Options -- Centralized options table

--[[ Tabs Definition ]]
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "play" }),
    Macro = Window:AddTab({ Title = "Macro", Icon = "mouse-pointer-click" }),
    Extras = Window:AddTab({ Title = "Extras", Icon = "sliders-horizontal" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

--[[ Helper Functions ]]
local function Notify(title, content, duration)
    if not Fluent or not Fluent.Notify then return end
    Fluent:Notify({ Title = title, Content = content, Duration = duration or 3 })
end

-- File system functions (minified, kept for potential future use but unused by modified buttons)
local function DeleteFolder(folderName) if typeof(isfolder)~="function" or typeof(delfolder)~="function" then return false,"fs utils not available" end; local s,e=pcall(function() if isfolder(folderName) then delfolder(folderName) end end); return s,e end
local function EnsureProfileFolder() if typeof(isfolder)~="function" or typeof(makefolder)~="function" then return false,"fs utils not available" end; local s,e=pcall(function() if not isfolder("newvape") then makefolder("newvape") end; if not isfolder("newvape/profiles") then makefolder("newvape/profiles") end end); return s,e end

--[[ Main Tab Content ]]
Tabs.Main:AddButton({
    Title = "Launch Wave Client Core",
    Description = "Downloads and executes the main Wave Client script. (Temporarily Disabled)", -- Updated description
    Callback = function()
        -- *** MODIFIED: Replaced functionality with notification ***
        Notify("Temporarily Disabled", "The 'Launch Core' feature is currently under rewrite. Please check back later.", 5)
        warn("[Wave Client] 'Launch Core' button clicked, but feature is disabled for rewrite.")
    end
})

Tabs.Main:AddButton({
    Title = "Download/Update Profiles",
    Description = "Downloads the latest profile configurations. (Temporarily Disabled)", -- Updated description
    Callback = function()
        -- *** MODIFIED: Replaced functionality with notification ***
        Notify("Temporarily Disabled", "The 'Download Profiles' feature is currently under rewrite. Please check back later.", 5)
        warn("[Wave Client] 'Download Profiles' button clicked, but feature is disabled for rewrite.")
    end
})

Tabs.Main:AddButton({
    Title = "Join Discord Server",
    Description = "Click to copy the invite link.",
    Callback = function()
        local invite = "https://discord.gg/q2fwB2KMPX"
        if typeof(setclipboard) == "function" then
            local success, err = pcall(setclipboard, invite)
            if success then Notify("Discord", "Invite copied!", 4)
            else Notify("Error", "Failed copy.", 3); warn("[WC] setclipboard err:", err); Notify("Discord Invite", invite, 10) end
        else Notify("Discord Invite", invite, 10); warn("[WC] setclipboard n/a. Link:", invite) end
    end
})


--[[ Macro Tab Content & Logic ]] -- (Circular buttons, logic mostly unchanged)
local macroScreenGui = nil
local macroInstructionLabel = nil
local currentMacroAddState = 0
local tempTogglePos = nil
local tempMacroName = ""
local activeMacroButtons = {}

local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    if not guiObject or not guiObject:IsA("GuiObject") then return end
    guiObject.InputBegan:Connect(function(input)
        if (not Window.Visible or currentMacroAddState == 0) and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local mouseLocation = UserInputService:GetMouseLocation()
            local guiPos = guiObject.AbsolutePosition; local guiSize = guiObject.AbsoluteSize
            if mouseLocation.X >= guiPos.X and mouseLocation.X <= guiPos.X + guiSize.X and mouseLocation.Y >= guiPos.Y and mouseLocation.Y <= guiPos.Y + guiSize.Y then
                dragging = true; dragStart = input.Position; startPos = guiObject.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end
    end)
    guiObject.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local screen_size = (macroScreenGui and macroScreenGui.AbsoluteSize) or Vector2.new(10000, 10000); local button_size = guiObject.AbsoluteSize
            local newPos = UDim2.new(startPos.X.Scale, math.clamp(startPos.X.Offset + delta.X, 0, screen_size.X - button_size.X), startPos.Y.Scale, math.clamp(startPos.Y.Offset + delta.Y, 0, screen_size.Y - button_size.Y))
            guiObject.Position = newPos
        end
    end)
    guiObject.Selectable = true; guiObject.Active = true
end
local function showInstruction(text)
    if not PlayerGui then return end
    if not macroInstructionLabel or not macroInstructionLabel.Parent then macroInstructionLabel=Instance.new("TextLabel",PlayerGui);macroInstructionLabel.Name="WaveClient_MacroInstruction";macroInstructionLabel.Size=UDim2.new(1,0,0,50);macroInstructionLabel.Position=UDim2.new(0,0,0,0);macroInstructionLabel.BackgroundColor3=Color3.fromRGB(0,0,0);macroInstructionLabel.BackgroundTransparency=0.3;macroInstructionLabel.TextColor3=Color3.fromRGB(255,255,0);macroInstructionLabel.Font=Enum.Font.SourceSansBold;macroInstructionLabel.TextSize=20;macroInstructionLabel.TextWrapped=true;macroInstructionLabel.TextXAlignment=Enum.TextXAlignment.Center;macroInstructionLabel.TextYAlignment=Enum.TextYAlignment.Center;macroInstructionLabel.ZIndex=10 end
    macroInstructionLabel.Text = text; macroInstructionLabel.Visible = true
end
local function hideInstruction() if macroInstructionLabel then macroInstructionLabel.Visible = false end end
local function addMacroToggleButton(macroName, clickPositionVec2, togglePositionVec2)
    if not PlayerGui then Notify("Macro Error", "No PlayerGui.", 5); return end
    if not VirtualInputManager then Notify("Macro Error", "No VIM.", 5); return end
    if not macroScreenGui or not macroScreenGui.Parent then macroScreenGui = Instance.new("ScreenGui", PlayerGui); macroScreenGui.Name = "WaveClient_MacroToggles"; macroScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; macroScreenGui.ResetOnSpawn = false end
    local mouseEnterState=false; local toggleButton = Instance.new("TextButton",macroScreenGui); toggleButton.Name=macroName.."_Toggle"; toggleButton.Size=UDim2.fromOffset(50,50); toggleButton.Position=UDim2.fromOffset(togglePositionVec2.X,togglePositionVec2.Y); toggleButton.AnchorPoint=Vector2.new(0.5,0.5); toggleButton.BackgroundColor3=Color3.fromRGB(50,50,50); toggleButton.BorderSizePixel=0; toggleButton.TextColor3=Color3.fromRGB(255,255,255); toggleButton.Text=macroName; toggleButton.TextSize=10; toggleButton.TextWrapped=true; toggleButton.AutoButtonColor=false; toggleButton.ClipsDescendants=true; local uiCorner=Instance.new("UICorner",toggleButton); uiCorner.CornerRadius=UDim.new(0.5,0)
    local macroData = {button = toggleButton, clickPos = clickPositionVec2, state = false, clickRoutine = nil}
    table.insert(activeMacroButtons, macroData)
    local function stopClicking() macroData.state = false; toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50); if macroData.clickRoutine then task.cancel(macroData.clickRoutine); macroData.clickRoutine = nil end end
    local function startClicking(mode)
        if macroData.clickRoutine then return end
        macroData.clickRoutine = task.spawn(function()
            local cps=Options.MacroCPS and Options.MacroCPS.Value or 10; local waitTime=1/math.max(1,cps); local clickX,clickY=clickPositionVec2.X,clickPositionVec2.Y
            local function doClick() if VirtualInputManager then local s1,e1=pcall(VirtualInputManager.SendMouseButtonEvent,VirtualInputManager,clickX,clickY,0,true,game,1); task.wait(0.01); local s2,e2=pcall(VirtualInputManager.SendMouseButtonEvent,VirtualInputManager,clickX,clickY,0,false,game,1); if not s1 then warn("[Macro] Click Down Err:",e1) end; if not s2 then warn("[Macro] Click Up Err:",e2) end; return s1 and s2 else warn("[Macro] VIM lost!"); stopClicking(); return false end end
            if mode=="Toggle" then macroData.state=true; toggleButton.BackgroundColor3=Color3.fromRGB(0,180,0); while macroData.state do if not doClick() then break end; task.wait(waitTime) end; if not macroData.state then toggleButton.BackgroundColor3=Color3.fromRGB(50,50,50) end
            elseif mode=="Repeat While Holding" then toggleButton.BackgroundColor3=Color3.fromRGB(0,180,0); while mouseEnterState do if not doClick() then break end; task.wait(waitTime) end; toggleButton.BackgroundColor3=Color3.fromRGB(50,50,50)
            elseif mode=="No Repeat" then toggleButton.BackgroundColor3=Color3.fromRGB(0,180,0); doClick(); task.wait(0.1); toggleButton.BackgroundColor3=Color3.fromRGB(50,50,50) end
            macroData.clickRoutine = nil
        end)
    end
    toggleButton.MouseButton1Click:Connect(function() if currentMacroAddState~=0 then return end; local mode=Options.MacroMode and Options.MacroMode.Value or "Toggle"; if mode=="Toggle" then if macroData.state then stopClicking() else startClicking("Toggle") end elseif mode=="No Repeat" and not macroData.clickRoutine then startClicking("No Repeat") end end)
    toggleButton.MouseEnter:Connect(function() if currentMacroAddState~=0 then return end; mouseEnterState=true; local mode=Options.MacroMode and Options.MacroMode.Value or "Toggle"; if mode=="Repeat While Holding" then startClicking("Repeat While Holding") end end)
    toggleButton.MouseLeave:Connect(function() if currentMacroAddState~=0 then return end; mouseEnterState=false; local mode=Options.MacroMode and Options.MacroMode.Value or "Toggle"; if mode=="Repeat While Holding" then toggleButton.BackgroundColor3=Color3.fromRGB(50,50,50); if macroData.clickRoutine then task.cancel(macroData.clickRoutine); macroData.clickRoutine=nil end end end)
    makeDraggable(toggleButton)
    toggleButton.Destroying:Connect(function() stopClicking(); for i,data in ipairs(activeMacroButtons) do if data.button==toggleButton then table.remove(activeMacroButtons,i); break end end end)
    local function updateVisibility() toggleButton.Visible = Options.ShowMacroPositions and Options.ShowMacroPositions.Value or false end
    if Options.ShowMacroPositions then Options.ShowMacroPositions:OnChanged(updateVisibility); updateVisibility() else toggleButton.Visible = true end
end
Tabs.Macro:AddParagraph({Title="Macro Setup",Content="1. Set Name, CPS, Mode.\n2. Click 'Add Macro'.\n3. Click screen for toggle position.\n4. Click screen for click position."})
Tabs.Macro:AddInput("MacroName", {Title="Macro Name", Placeholder="E.g., AutoFarm", Default=""});
Tabs.Macro:AddSlider("MacroCPS", {Title="Clicks Per Second (CPS)", Min=1, Max=100, Default=10, Rounding=0});
Tabs.Macro:AddDropdown("MacroMode", {Title="Macro Mode", Values={"Toggle", "Repeat While Holding", "No Repeat"}, Default="Toggle"});
local showMacrosToggle = Tabs.Macro:AddToggle("ShowMacroPositions", {Title="Show Macro Buttons", Default=true})
showMacrosToggle:OnChanged(function(value) if macroScreenGui then for _,c in ipairs(macroScreenGui:GetChildren()) do if c:IsA("GuiButton") then c.Visible=value end end end; if currentMacroAddState~=0 and not value then hideInstruction() elseif currentMacroAddState~=0 and value then if currentMacroAddState==1 then showInstruction("Click where you want the Macro TOGGLE button.") elseif currentMacroAddState==2 then showInstruction("Click where the Macro should CLICK.") end end end)
Tabs.Macro:AddButton({Title="Add New Macro", Description="Starts position selection.", Callback=function() tempMacroName = Options.MacroName and Options.MacroName.Value or ""; if not tempMacroName or tempMacroName:match("^%s*$") then Notify("Macro Error","Enter valid name.",4); return end; if currentMacroAddState~=0 then Notify("Macro Info","Already adding.",4); return end; if not VirtualInputManager then Notify("Macro Error","VIM not available.",5); return end; currentMacroAddState=1; Window:Minimize(); showInstruction("Click where you want the Macro TOGGLE button.") end })
Tabs.Macro:AddButton({Title="Reset All Macros", Description="Removes all macro buttons.", Callback=function() if #activeMacroButtons==0 then Notify("Macro Info","No macros to reset.",3); return end; Window:Dialog({Title="Confirm Reset",Content="Remove ALL macro buttons?", Buttons={{Title="Yes, Reset",Callback=function() for i=#activeMacroButtons,1,-1 do local d=activeMacroButtons[i]; if d and d.button and d.button.Parent then d.button:Destroy() else table.remove(activeMacroButtons,i) end end; Notify("Macro Reset","All toggles removed.",4) end},{Title="Cancel"}})} end)
Tabs.Macro:AddButton({Title="Cancel Add Macro", Description="Cancel current placement.", Callback=function() if currentMacroAddState==0 then Notify("Macro Info","Not adding.",3); return end; currentMacroAddState=0; tempTogglePos=nil; tempMacroName=""; hideInstruction(); Window:Appear(); Notify("Macro","Placement cancelled.",3) end })
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent) if gameProcessedEvent or currentMacroAddState==0 then return end; if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then local clickPos=input.Position; if currentMacroAddState==1 then tempTogglePos=clickPos; currentMacroAddState=2; showInstruction("Click where the Macro should CLICK.") elseif currentMacroAddState==2 then local finalClickPos=clickPos; local finalTogglePos=tempTogglePos; local finalMacroName=tempMacroName; currentMacroAddState=0; tempTogglePos=nil; tempMacroName=""; hideInstruction(); Window:Appear(); addMacroToggleButton(finalMacroName,finalClickPos,finalTogglePos); Notify("Macro","'"..finalMacroName.."' created!",4) end elseif input.UserInputType==Enum.UserInputType.MouseButton2 or input.KeyCode==Enum.KeyCode.Escape then currentMacroAddState=0; tempTogglePos=nil; tempMacroName=""; hideInstruction(); Window:Appear(); Notify("Macro","Placement cancelled.",3) end end)


--[[ Extras Tab Content ]]
Tabs.Extras:AddSlider("FPSCap", {
    Title = "FPS Cap", Description = "Adjust the maximum frames per second.", Min = 30, Max = 240, Default = 60, Rounding = 0,
    Callback = function(value)
        if typeof(setfpscap) == "function" then
            local success, err = pcall(setfpscap, value)
            if success then Notify("FPS Cap Set", "FPS cap is now " .. value, 3)
            else Notify("Error", "Failed set FPS cap.", 3); warn("[WC] setfpscap error:", err) end
        else Notify("Error", "'setfpscap' n/a.", 4); warn("[WC] setfpscap function not found.") end
    end
})


--[[ Addons Configuration ]] -- (Unchanged)
if SaveManager and InterfaceManager then SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent); SaveManager:SetFolder("WaveClient"); InterfaceManager:SetFolder("WaveClient"); SaveManager:IgnoreThemeSettings(); InterfaceManager:BuildInterfaceSection(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings); print("[WC] Save/Interface Mgrs configured.")
elseif SaveManager then warn("[WC] InterfaceMgr failed load, Settings incomplete."); SaveManager:SetLibrary(Fluent); SaveManager:SetFolder("WaveClient"); SaveManager:IgnoreThemeSettings(); SaveManager:BuildConfigSection(Tabs.Settings); print("[WC] SaveMgr configured (InterfaceMgr missing).")
else warn("[WC] SaveMgr/InterfaceMgr failed load. Config saving disabled."); if Tabs.Settings then Tabs.Settings:AddParagraph({Title="Load Error",Content="Save/Interface Mgr failed load. Config disabled."}) end end


--[[ Finalization ]] -- (Unchanged)
Window:SelectTab(1)
if SaveManager then local s,e=pcall(function()SaveManager:LoadAutoloadConfig()end); if s then print("[WC] Autoload config loaded.") else warn("[WC] Failed load autoload config:",e);Notify("Config Error","Failed load saved settings.",4) end else print("[WC] Skipping config load (SaveMgr n/a).") end
Notify("Wave Client","UI Loaded Successfully!",5)
task.wait(1); if Options and Options.FPSCap and Options.FPSCap.Value and typeof(setfpscap)=="function" then local c=Options.FPSCap.Value; local s,e=pcall(setfpscap,c); if s then print("[WC] Applied saved FPS Cap:",c) else warn("[WC] Failed apply saved FPS cap:",e) end end
if Options.ShowMacroPositions then task.wait(0.1); if macroScreenGui then for _,c in ipairs(macroScreenGui:GetChildren()) do if c:IsA("GuiButton") then c.Visible=Options.ShowMacroPositions.Value end end end end
