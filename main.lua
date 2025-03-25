-- Grabbing the Rayfield UI library from the web. Careful with this!
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Checking if Rayfield even loaded. Gotta make sure it works!
if Rayfield then
    -- Creating the main window for the whole cheat.
    local Window = Rayfield:CreateWindow({
        Name = "Wave Client V1", -- Name of the window, pretty obvious.
        Icon = 0, -- No icon for now, can add one later.
        LoadingTitle = "Wave Utility GUI", -- Title when it's loading.
        LoadingSubtitle = "By wavezq", -- Gotta show who made it.
        Theme = "Ocean", -- Makes it look blue and stuff, pretty cool.
        DisableRayfieldPrompts = false, -- Get rid of the annoying prompts.
        DisableBuildWarnings = false, -- Warnings are for noobs.
        ConfigurationSaving = {
            Enabled = true, -- Save the settings so you don't have to redo everything.
            FolderName = nil, -- You can organize it if you want.
            FileName = "WC-Settings" -- Name of the settings file.
        },
        Discord = {
            Enabled = true, -- Get people to join your Discord server.
            Invite = "q2fwB2KMPX", -- Your Discord invite code.
            RememberJoins = true  -- Make 'em join every time, haha.
        },
        KeySystem = false, -- No key system, it's annoying.
        KeySettings = { -- Even if we don't use it, gotta have the settings ready.
            Title = "Untitled",
            Subtitle = "Key System",
            Note = "No method of obtaining the key is provided", -- LOL
            FileName = "Key",
            SaveKey = true,
            GrabKeyFromSite = false,
            Key = {"Hello"} -- This key does nothing.
        }
    })

    -- Making the "Combat" Tab - Where all the fighting stuff goes.
    local CombatTab = Window:CreateTab("Combat")

    -- Making the "Visuals" Tab - For the graphics tweaks.
    local VisualsTab = Window:CreateTab("Visuals")

    -- ======================================================================
    -- Auto Clicker Stuff Starts Here
    -- ======================================================================

    local AutoClicker = { Enabled = false } -- Is the autoclicker turned on or not?
    local CPS = {Min = 7, Max = 7} -- Clicks per second, gotta be fast!
    local BlockCPS = {Min = 12, Max = 12, Object = nil} -- How fast to place blocks.
    local PlaceBlocks = true -- Should we even be placing blocks?

    -- Grabbing these services, they're important for the code.
    local inputService = game:GetService("UserInputService") -- For detecting clicks.
    local bedwars = require(game:GetService("ReplicatedStorage").Assets.Modules.Bedwars) -- Bedwars stuff.
    local store = require(bedwars.AppController:getStoreModulePath()) -- The in-game store.
    local lplr = game.Players.LocalPlayer -- You, the player!

    -- The function that actually clicks for you!
    local function AutoClick() -- Pass in dependencies
        local Thread

        return function()
            Thread = task.delay(1 / 7, function()
                repeat
                    if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
                        local blockPlacer = bedwars.BlockPlacementController.blockPlacer
                        if PlaceBlocks and store.hand.toolType == 'block' and blockPlacer then
                            if (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) >= ((1 / 12) * 0.5) then
                                local mouseinfo = blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
                                if mouseinfo and mouseinfo.placementPosition == mouseinfo.placementPosition then
                                    task.spawn(blockPlacer.placeBlock, blockPlacer, mouseinfo.placementPosition)
                                end
                            end
                        elseif store.hand.toolType == 'sword' and bedwars.DaoController.chargingMaid == nil then
                            bedwars.SwordController:swingSwordAtMouse()
                        end
                    end

                    local randomCPS = math.random(CPS.Min, CPS.Max)
                    task.wait(1 / (store.hand.toolType == 'block' and BlockCPS or {Min = randomCPS, Max = randomCPS}).Min) -- Block CPS is also random
                until not AutoClicker.Enabled
            end)
        end
    end


    local autoClickFunction = AutoClick() -- Pass in dependencies

    -- Section for all the AutoClicker Settings
    local Section = CombatTab:CreateSection("AutoClicker Settings")

    -- Toggle to turn the AutoClicker on and off
    local Toggle = CombatTab:CreateToggle({
        Name = "AutoClicker",
        CurrentValue = false,
        Flag = "AutoClickerToggle",
        Callback = function(Value)
            AutoClicker.Enabled = Value
            if Value then
                print("Silent Auto Clicker Enabled")
                autoClickFunction()
            else
                print("Silent Auto Clicker Disabled")
            end
        end,
    })

     -- CPS SLIDERS - Control how fast it clicks.

     local SliderMin = CombatTab:CreateSlider({
        Name = "CPS Min",
        Range = {1, 20},
        Increment = 1,
        Suffix = "CPS",
        CurrentValue = CPS.Min,
        Flag = "CPSMin",
        Callback = function(Value)
           CPS.Min = Value
           print("CPS Min: ", Value)
        end
     })

    local SliderMax = CombatTab:CreateSlider({
       Name = "CPS Max",
        Range = {1, 20},
        Increment = 1,
        Suffix = "CPS",
        CurrentValue = CPS.Max,
        Flag = "CPSMax",
        Callback = function(Value)
           CPS.Max = Value
           print("CPS Max: ", Value)
        end
     })

    local BlockPlacementToggle = CombatTab:CreateToggle({
        Name = "Place Blocks",
        CurrentValue = true,
        Flag = "PlaceBlockToggle",
        Callback = function(Value)
            PlaceBlocks = Value -- Assign the slider value to a Lua variable
           print("Place Block: ", Value)
        end
    })

     local BlockCPSMinSlider = CombatTab:CreateSlider({
        Name = "Block CPS Min",
        Range = {1, 20},
        Increment = 1,
        Suffix = "CPS",
        CurrentValue = BlockCPS.Min,
        Flag = "BlockCPSMin",
        Callback = function(Value)
           BlockCPS.Min = Value
           print("Block CPS Min: ", Value)
        end
     })

     local BlockCPSMaxSlider = CombatTab:CreateSlider({
        Name = "Block CPS Max",
        Range = {1, 20},
        Increment = 1,
        Suffix = "CPS",
        CurrentValue = BlockCPS.Max,
        Flag = "BlockCPSMax",
        Callback = function(Value)
           BlockCPS.Max = Value
           print("Block CPS Max: ", Value)
        end
     })

     local Label = CombatTab:CreateLabel("Credits: TheWave")

    -- ======================================================================
    -- Visuals Tab Stuff Starts Here
    -- ======================================================================

    -- Default image ID for the crosshair
    local ImageId = 0

    -- Function to apply the crosshair, make sure it works!
    local function ApplyCrosshair()
        local success, err = pcall(function()
            debug.setconstant(bedwars.ViewmodelController.show, 25, ImageId)
            debug.setconstant(bedwars.ViewmodelController.show, 37, ImageId)
            if bedwars.CameraPerspectiveController:getCameraPerspective() == 0 then
                bedwars.ViewmodelController:hide()
                bedwars.ViewmodelController:show()
            end
        end)

        if not success then
            warn("Error applying crosshair: ", err)
        end
    end

    local CrosshairEnabled = false -- Is the crosshair on or off?

    -- Toggle to turn the crosshair on/off.
    local CrosshairToggle = VisualsTab:CreateToggle({
        Name = "Crosshair",
        CurrentValue = false,
        Flag = "CrosshairToggle",
        Callback = function(Value)
            CrosshairEnabled = Value
            if Value then
                ApplyCrosshair()
                print("Crosshair Enabled")
            else
                debug.setconstant(bedwars.ViewmodelController.show, 25, 0) -- Back to default
                debug.setconstant(bedwars.ViewmodelController.show, 37, 0)
                if bedwars.CameraPerspectiveController:getCameraPerspective() == 0 then
                    bedwars.ViewmodelController:hide()
                    bedwars.ViewmodelController:show()
                end
                print("Crosshair Disabled")
            end
        end,
    })

     -- Textbox for the Image ID - Where you put the Roblox ID.
        local ImageInput = VisualsTab:CreateInput({
        Name = "Image ID",
        CurrentValue = "",
        PlaceholderText = "Enter Image ID", -- Tells you what to put in.
        RemoveTextAfterFocusLost = false, -- Keep the text.
        Flag = "ImageIDInput", -- Gotta have a unique flag.
        Callback = function(Text)
           -- Try to turn the text into a number.
           local number = tonumber(Text)
           -- If it worked, set the ImageId to that number.
           if number then
               ImageId = number
               print("Image ID set to: ", ImageId)
           else
               print("Invalid input: Please enter a number for the Image ID") -- Tell 'em if it's wrong.
           end
           if CrosshairEnabled then -- Update the crosshair if it's on.
                ApplyCrosshair()
            end
        end,
     })

      -- Credits
      Tab:CreateParagraph({Title = "Credits", Content = "Created by: TheWave"})

     -- Display the credits in the top of the ui

     local Label = VisualsTab:CreateLabel("Created By TheWave")

    -- Button to destroy the UI
    local Button = VisualsTab:CreateButton({
        Name = "Destroy UI",
        Callback = function()
            Rayfield:Destroy() -- Get rid of it.
        end,
    })

     -- Load the UI
     Rayfield:LoadModule()

else
    -- If Rayfield didn't load, tell the world.
    warn("Rayfield UI library failed to load!")
end
