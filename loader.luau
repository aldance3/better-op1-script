if game.PlaceId ~= 72920620366355 then
    warn("Wrong game, not executing.")
    return
end


local code = "loadstring(game:HttpGet("https://raw.githubusercontent.com/aldance3/better-op1-script/refs/heads/main/Newop1script.luau"))()"
task.wait(1)
-- Step 2: Wrap the execution in a pcall
local success, errorMessage = pcall(function()
    -- Load the code string into a function, and execute it immediately
    local func = loadstring(code)
    if func then
        func() -- Run the code
    else
        error("loadstring failed: Invalid code syntax")
    end
end)

-- Step 3: Check if it failed. If so, create the hidden Critical Failure GUI.
if not success then
    -- Get the screen size so we can center the text
    local screenX, screenY = drawing.getScreenSize() -- or game:GetService("Workspace").CurrentCamera.ViewportSize

    -- Create a hidden Text object using the exploit's drawing API
    local failureText = drawing.new("Text")
    
    -- Configure the text to look like a Critical Failure warning
    failureText.Text = "FAILED TO LOAD SCRIPT"
    failureText.Color = Color3.fromRGB(255, 0, 0) -- Bright Red
    failureText.Size = 40                       -- Font size
    failureText.Center = true                  -- Centers the text on the X/Y coordinates
    failureText.Position = Vector2.new(screenX / 2, screenY / 2) -- Dead center of the screen
    failureText.Outline = true                 -- Makes it readable on bright backgrounds
    failureText.OutlineColor = Color3.fromRGB(0, 0, 0)
    failureText.Visible = true                 -- Make it appear instantly

    -- OPTIONAL: Print the actual error to the console for debugging purposes
    warn("Script crashed with error: " .. tostring(errorMessage))

    -- Keep the text on screen forever, or use a timer to remove it:
    task.wait(7.5)
    failureText.Visible = false
    failureText.Remove() -- Clean up the drawing object
end
