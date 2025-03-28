-- Initialize Rayfield UI Library local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Create the UI Window local Window = Rayfield:CreateWindow({ Name = "🌊 Wave Client", LoadingTitle = "Wave Client Loading...", LoadingSubtitle = "Powered by Rayfield", ConfigurationSaving = { Enabled = true, FolderName = "WaveClient", FileName = "UIConfig" }, Discord = { Enabled = false, Invite = "", RememberJoins = true }, KeySystem = false })

-- Create Main Tab local MainTab = Window:CreateTab("Main", 4483362458)

-- Function to Display Notifications local function Notify(title, content, duration) Rayfield:Notify({ Title = title, Content = content, Duration = duration or 3, Actions = {} }) end

-- Fetch and Run Main Script MainTab:CreateButton({ Name = "Launch Wave Client", Callback = function() local scriptUrl = "https://raw.githubusercontent.com/vlctyy/Wave-Client/main/script.lua" local success, response = pcall(game.HttpGet, game, scriptUrl) if success then loadstring(response)() Notify("Success", "Wave Client Loaded Successfully!", 4) else Notify("Error", "Failed to download Wave Client script.", 4) end end })

-- Download & Replace Profile File MainTab:CreateButton({ Name = "Download Profile", Callback = function() local profileUrl = "https://raw.githubusercontent.com/vlctyy/Wave-Client/refs/heads/main/cfg/newvape/profiles/default6872274481.txt" local success, profileContent = pcall(game.HttpGet, game, profileUrl)

if success then
        -- Define profile path
        local profilePath = "newvape/profiles/default6872274481.txt"
        
        -- Ensure the directory exists
        if not isfolder("newvape/profiles") then
            makefolder("newvape/profiles")
        end
        
        -- Overwrite the profile file
        writefile(profilePath, profileContent)
        Notify("Success", "Profile file replaced successfully!", 4)
    else
        Notify("Error", "Failed to download profile file.", 4)
    end
end

})

-- Create Extras Tab local ExtraTab = Window:CreateTab("Extras", 4483362458)

-- FPS Cap Slider ExtraTab:CreateSlider({ Name = "Set FPS Cap", Range = {30, 240}, Increment = 10, Suffix = "FPS", CurrentValue = 60, Callback = function(value) setfpscap(value) Notify("FPS Cap Set", "Your FPS cap is now " .. value, 3) end })

