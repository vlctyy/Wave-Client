local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Check if Rayfield loaded successfully
if Rayfield then
    local Window = Rayfield:CreateWindow({
        Name = "Wave Client V1",
        Icon = 0,
        LoadingTitle = "Wave Utility GUI",
        LoadingSubtitle = "By wavezq",
        Theme = "Ocean",
        DisableRayfieldPrompts = false,
        DisableBuildWarnings = false,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = nil,
            FileName = "WC-Settings"
        },
        Discord = {
            Enabled = true,
            Invite = "q2fwB2KMPX",
            RememberJoins = true
        },
        KeySystem = false,
        KeySettings = {
            Title = "Untitled",
            Subtitle = "Key System",
            Note = "No method of obtaining the key is provided",
            FileName = "Key",
            SaveKey = true,
            GrabKeyFromSite = false,
            Key = {"Hello"}
        }
    })

    -- Create the "Combat" Tab
    local CombatTab = Window:CreateTab("Combat")

    -- Create the "Visuals" Tab
    local VisualsTab = Window:CreateTab("Visuals")

    -- Silent Auto Code:

    local AutoClicker = { Enabled = false } -- Initialize AutoClicker table
    local CPS = {Min = 7, Max = 7} -- Default CPS values
    local BlockCPS = {Min = 12, Max = 12, Object = nil} -- Default block CPS
    local PlaceBlocks = true

    local inputService = game:GetService("UserInputService") -- define inputService
    local bedwars = require(game:GetService("ReplicatedStorage").Assets.Modules.Bedwars) -- define bedwars
    local store = require(bedwars.AppController:getStoreModulePath()) -- define store
    local lplr = game.Players.LocalPlayer -- define lplr

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

    local Section = CombatTab:CreateSection("AutoClicker Settings")

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

     -- CPS SLIDER

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

    --Tab:CreateParagraph({Title = "Credits", Content = "Created by: TheWave"})

     -- Example Label
     local Label = CombatTab:CreateLabel("Credits: TheWave")

    -- Example "Destroy UI" Button
    local Button = CombatTab:CreateButton({
        Name = "Destroy UI",
        Callback = function()
            Rayfield:Destroy()
        end,
    })

    -- Visuals Start Here

    local ImageId = 0 -- Default image ID

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

    local CrosshairEnabled = false

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
                debug.setconstant(bedwars.ViewmodelController.show, 25, 0) -- Set back to default
                debug.setconstant(bedwars.ViewmodelController.show, 37, 0)
                if bedwars.CameraPerspectiveController:getCameraPerspective() == 0 then
                    bedwars.ViewmodelController:hide()
                    bedwars.ViewmodelController:show()
                end
                print("Crosshair Disabled")
            end
        end,
    })


      -- Textbox for Image ID
        local ImageInput = VisualsTab:CreateInput({
        Name = "Image ID",
        CurrentValue = "",
        PlaceholderText = "Enter Image ID",
        RemoveTextAfterFocusLost = false,
        Flag = "ImageIDInput",
        Callback = function(Text)
           -- Attempt to convert the text to a number
           local number = tonumber(Text)
           -- If the conversion was successful, assign it to ImageId
           if number then
               ImageId = number
               print("Image ID set to: ", ImageId)
           else
               print("Invalid input: Please enter a number for the Image ID")
           end
           if CrosshairEnabled then
                ApplyCrosshair()
            end
        end,
     })

      Tab:CreateParagraph({Title = "Credits", Content = "Created by: TheWave"})

     -- Example Label
     local Label = VisualsTab:CreateLabel("Created By TheWave")

    -- Example "Destroy UI" Button
    local Button = VisualsTab:CreateButton({
        Name = "Destroy UI",
        Callback = function()
            Rayfield:Destroy()
        end,
    })

     Rayfield:LoadModule()

else
    warn("Rayfield UI library failed to load!")
end
