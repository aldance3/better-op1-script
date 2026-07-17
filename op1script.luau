-- ==== Initialization ====
local RunService = game:GetService("RunService")
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
_G.ESPColor = _G.ESPColor or Color3.new(1, 1, 1)
_G.espSkeletons = false
_G.ESP_ENABLED = false

local Window = Rayfield:CreateWindow({
   Name = "⚔️ Operation One Script",
   Icon = 0,
   LoadingTitle = "⚔️ Operation One Scripts ⚔️",
   LoadingSubtitle = "By WillyBoy & Bread.",
   ShowText = "Rayfield",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "operation one scripts"
   },
})

Rayfield:Notify({
   Title = "Operation One Script Loaded!",
   Content = "All systems ready",
   Duration = 5,
})

-- ==================== NO RECOIL ====================
local NoRecoilSettings = {
    Enabled = false,
    ActiveKey = Enum.UserInputType.MouseButton1,
    Sens = 1.0,
    Smoothness = 0.12
}
local targetX, targetY, targetZ = 0, 0, 0
local isFiring = false
local recoveryTime = 0

local function syncCamera()
    local x, y, z = workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ()
    targetX, targetY, targetZ = x, y, z
end
syncCamera()

game:GetService("RunService"):BindToRenderStep("DynamicZeroRecoil", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not NoRecoilSettings.Enabled then return end
    
    local UIS = game:GetService("UserInputService")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local Camera = workspace.CurrentCamera
    
    if UIS.MouseBehavior == Enum.MouseBehavior.Default then syncCamera() return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then
         syncCamera()
         return 
     end

    local delta = UIS:GetMouseDelta()
    local _, _, realZ = Camera.CFrame:ToEulerAnglesYXZ()
    local flip = (Camera.CFrame.UpVector.Y < 0) and -1 or 1

    if UIS:IsMouseButtonPressed(NoRecoilSettings.ActiveKey) then
        isFiring = true
        recoveryTime = 0.35
        
        targetY = targetY - math.rad(delta.X * NoRecoilSettings.Sens * 0.48 * flip)
        targetX = targetX - math.rad(delta.Y * NoRecoilSettings.Sens * 0.48)
        targetX = math.clamp(targetX, math.rad(-85), math.rad(85))
        
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(targetX, targetY, realZ)
    else
        if isFiring then
            if recoveryTime > 0 then
                recoveryTime = recoveryTime - dt
                
                if delta.Magnitude > 0 then
                    targetY = targetY - math.rad(delta.X * NoRecoilSettings.Sens * 0.48 * flip)
                    targetX = targetX - math.rad(delta.Y * NoRecoilSettings.Sens * 0.48)
                    targetX = math.clamp(targetX, math.rad(-85), math.rad(85))
                end
                
                Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(targetX, targetY, targetZ)
            else
                syncCamera()
                isFiring = false
            end
        else
            syncCamera()
        end
    end
end)

-- ==================== TABS ====================
local RecoilTab = Window:CreateTab("🔫 Recoil", nil)
local RecoilSection = RecoilTab:CreateSection("No Recoil")

local NoRecoilToggle = RecoilTab:CreateToggle({
   Name = "No Recoil",
   CurrentValue = false,
   Callback = function(Value)
      NoRecoilSettings.Enabled = Value
      if Value then syncCamera() end
   end,
})

pl63 = game:GetService("Players")
if pl63.LocalPlayer.Name == "ninjamaster84321" then
   pl63.LocalPlayer:Kick("Banned permenantly for exploiting.")
end

local SensSlider = RecoilTab:CreateSlider({
   Name = "No Recoil Sensitivity",
   Range = {0.1, 2.0},
   Increment = 0.1,
   Suffix = "x",
   CurrentValue = 1.0,
   Callback = function(Value) NoRecoilSettings.Sens = Value end,
})

local SmoothSlider = RecoilTab:CreateSlider({
   Name = "No Recoil Smoothness",
   Range = {0.01, 0.5},
   Increment = 0.01,
   Suffix = "s",
   CurrentValue = 0.12,
   Callback = function(Value) NoRecoilSettings.Smoothness = Value end,
})

-- ==================== ESP TAB ====================
local tracerStartPos = "bottom"
local otherTab = Window:CreateTab("👁️ Esp", nil)
local Section = otherTab:CreateSection("Main")

_G.ESP_SETTINGS = {
    MainEnabled = false,
    Tracers = true,
    TracerStart = "Bottom",
    HealthBar = true,
    Color = Color3.new(1,1,1),
    Skeletons = false,
}

_G.ESP_Table = {}

local function setupESP()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local ESP = _G.ESP_Table
    local TEAM_CHECK = true
    local MAX_STUCK_TIME = 1.5

    local function newDrawing(type, props)
        local obj = Drawing.new(type)
        for k,v in pairs(props) do obj[k] = v end
        return obj
    end

    local function hide(ui)
        ui.Box.Visible = false
        ui.Tracer.Visible = false
        ui.Health.Visible = false
        ui.Name.Visible = false
    end

    local function createESP(player)
        if player == LocalPlayer or ESP[player] then return end
        ESP[player] = {
            Player = player,
            Box = newDrawing("Square", {Thickness = 1, Filled = false, Color = _G.ESP_SETTINGS.Color, Visible = false}),
            Tracer = newDrawing("Line", {Thickness = 1, Color = _G.ESP_SETTINGS.Color, Visible = false}),
            Health = newDrawing("Line", {Thickness = 3, Visible = false}),
            Name = newDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2, Visible = false}),
            LastPosition = nil,
            StuckTime = 0
        }
    end

    for _,player in ipairs(Players:GetPlayers()) do createESP(player) end
    Players.PlayerAdded:Connect(createESP)

    local function findCharacter(player)
        for _,model in ipairs(workspace:GetChildren()) do
            if model:IsA("Model") and model.Name == player.Name then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart")
                if hum and root then return model, hum, root end
            end
        end
        return nil
    end

    local function getBox(character)
        local cf, size = character:GetBoundingBox()
        local top = cf.Position + Vector3.new(0, size.Y/2, 0)
        local bottom = cf.Position - Vector3.new(0, size.Y/2, 0)
        local topPos, vis1 = Camera:WorldToViewportPoint(top)
        local bottomPos, vis2 = Camera:WorldToViewportPoint(bottom)
        if not vis1 or not vis2 then return nil end
        local height = math.abs(topPos.Y - bottomPos.Y)
        local width = height / 2
        return Vector2.new(topPos.X - width/2, topPos.Y), width, height
    end

    local function getTracerStart()
        local viewport = Camera.ViewportSize
        local pos = tracerStartPos
        if pos == "bottom" then return Vector2.new(viewport.X/2, viewport.Y)
        elseif pos == "middle" then return Vector2.new(viewport.X/2, viewport.Y/2)
        elseif pos == "top" then return Vector2.new(viewport.X/2, 0)
        elseif pos == "left" then return Vector2.new(0, viewport.Y/2)
        elseif pos == "right" then return Vector2.new(viewport.X, viewport.Y/2)
        else return Vector2.new(viewport.X/2, viewport.Y)
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        if not (_G.ESP_SETTINGS.MainEnabled or _G.ESP_SETTINGS.Tracers or _G.ESP_SETTINGS.HealthBar) then
            for _,ui in pairs(ESP) do hide(ui) end
            return
        end

        for player,ui in pairs(ESP) do
            pcall(function()
                if TEAM_CHECK and player.Team == LocalPlayer.Team then hide(ui) return end
                local character, humanoid, root = findCharacter(player)
                if not character or not humanoid or humanoid.Health <= 0 then hide(ui) return end
                local pos, width, height = getBox(character)
                if not pos then hide(ui) return end
                if ui.LastPosition and (ui.LastPosition - pos).Magnitude < 1 then
                    ui.StuckTime = ui.StuckTime + dt
                else
                    ui.StuckTime = 0
                end
                if ui.StuckTime >= MAX_STUCK_TIME then hide(ui) return end
                ui.LastPosition = pos

                ui.Box.Visible = _G.ESP_SETTINGS.MainEnabled
                if _G.ESP_SETTINGS.MainEnabled then
                    ui.Box.Size = Vector2.new(width, height)
                    ui.Box.Position = pos
                    ui.Box.Color = _G.ESP_SETTINGS.Color
                end

                ui.Name.Visible = _G.ESP_SETTINGS.MainEnabled
                if _G.ESP_SETTINGS.MainEnabled then
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    ui.Name.Text = myRoot and player.Name .. " [" .. math.floor((myRoot.Position - root.Position).Magnitude) .. "m]" or player.Name
                    ui.Name.Position = Vector2.new(pos.X + width/2, pos.Y - 15)
                end

                if _G.ESP_SETTINGS.Tracers then
                    ui.Tracer.From = getTracerStart()
                    ui.Tracer.To = Vector2.new(pos.X + width/2, pos.Y)
                    ui.Tracer.Color = _G.ESP_SETTINGS.Color
                    ui.Tracer.Visible = true
                else
                    ui.Tracer.Visible = false
                end

                if _G.ESP_SETTINGS.HealthBar then
                    local hp = humanoid.Health / humanoid.MaxHealth
                    local healthHeight = height * hp
                    ui.Health.From = Vector2.new(pos.X - 5, pos.Y + height)
                    ui.Health.To = Vector2.new(pos.X - 5, pos.Y + height - healthHeight)
                    ui.Health.Color = Color3.fromRGB(255 - (255*hp), 255*hp, 0)
                    ui.Health.Visible = true
                else
                    ui.Health.Visible = false
                end
            end)
        end
    end)
end

setupESP()

local MainESPToggle = otherTab:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Callback = function(Value)
      _G.ESP_SETTINGS.MainEnabled = Value
   end,
})

local ESPOptionsSection = otherTab:CreateSection("ESP Options")

local TracersToggle = otherTab:CreateToggle({
   Name = "Tracers",
   CurrentValue = true,
   Callback = function(Value)
      _G.ESP_SETTINGS.Tracers = Value
   end,
})

local TracerPosSection = otherTab:CreateSection("Tracer Start Position")

otherTab:CreateParagraph({
    Title = "Slider Mapping",
    Content = "0 = Bottom | 1 = Middle | 2 = Top | 3 = Left | 4 = Right"
})

otherTab:CreateSlider({
    Name = "Tracer Position",
    Range = {0, 4},
    Increment = 1,
    Suffix = "",
    CurrentValue = 0,
    Callback = function(Value)
        local positions = {"bottom", "middle", "top", "left", "right"}
        local index = math.floor(Value + 0.5) + 1
        tracerStartPos = positions[index] or "bottom"
        _G.ESP_SETTINGS.TracerStart = tracerStartPos
        print("Tracer start set to:", tracerStartPos)
    end,
})

local HealthToggle = otherTab:CreateToggle({
   Name = "Health Bars",
   CurrentValue = true,
   Callback = function(Value)
      _G.ESP_SETTINGS.HealthBar = Value
   end,
})

-- ==================== Viewmodel ESP & Skeletons ====================
local ViewmodelSection = otherTab:CreateSection("Viewmodel ESP")

local SkeletonsToggle = otherTab:CreateToggle({
   Name = "Skeletons",
   CurrentValue = false,
   Callback = function(Value)
      _G.espSkeletons = Value
      _G.ESP_ENABLED = Value
      _G.ESP_SETTINGS.Skeletons = Value
   end,
})

local cloneref_support = cloneref ~= nil
local gethui_support = gethui ~= nil
local runservice = cloneref_support and cloneref(game:GetService("RunService")) or game:GetService("RunService")

local bones = {
    { "torso", "head" }, { "torso", "shoulder1" }, { "torso", "shoulder2" },
    { "shoulder1", "arm1" }, { "shoulder2", "arm2" }, { "torso", "hip1" },
    { "torso", "hip2" }, { "hip1", "leg1" }, { "hip2", "leg2" }
}
local required_bones = { "torso", "head", "shoulder1", "shoulder2", "arm1", "arm2", "hip1", "hip2", "leg1", "leg2" }

_G.esp_list = {}
_G.skeleton_list = {}

local viewmodels = workspace:FindFirstChild("Viewmodels")
local camera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() camera = workspace.CurrentCamera end)

_G.TeammateHighlights = _G.TeammateHighlights or {}
workspace.ChildAdded:Connect(function(child)
    if child:IsA("Highlight") then
        _G.TeammateHighlights[child] = true
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child:IsA("Highlight") then
        _G.TeammateHighlights[child] = nil
    end
end)

local function is_teammate(model)
     for highlight in pairs(_G.TeammateHighlights) do
        if highlight.Adornee == model then return true end
    end
    return false
end

local function is_valid(model)
    if not model or not model.Parent or model.Name == "LocalViewmodel" or not viewmodels or model.Parent ~= viewmodels then return false end
    local torso = model:FindFirstChild("torso")
    return torso and torso:IsA("BasePart")
end

local function rand_str(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, len do result[i] = chars:sub(math.random(1, #chars), math.random(1, #chars)) end
    return table.concat(result)
end

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = rand_str(12)
screen_gui.Parent = gethui_support and gethui() or game:GetService("CoreGui")

local function remove_skeleton(character)
    local data = _G.skeleton_list[character]
    if not data then return end
    for _, line in ipairs(data.lines) do line:Remove() end
    _G.skeleton_list[character] = nil
end

local function create_skeleton(character)
    if not character or _G.skeleton_list[character] or not is_valid(character) then return end
    local char_bones = {}
    for _, name in ipairs(required_bones) do
        local b = character:FindFirstChild(name)
        if not b or not b:IsA("BasePart") then return end
        char_bones[name] = b
    end
    
    local lines = {}
    for i = 1, #bones do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = _G.ESPColor
        line.Thickness = 1
        line.Transparency = 1
        lines[i] = line
    end
    _G.skeleton_list[character] = { lines = lines, bones = char_bones }
end

local function create_esp(character)
    if not character or not is_valid(character) or _G.esp_list[character] then return end
    
    local folder = Instance.new("Folder", screen_gui)
    local box = Instance.new("Frame", folder)
    local stroke = Instance.new("UIStroke", box)
    
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    stroke.Color = _G.ESPColor
    stroke.Thickness = 1
    
    _G.esp_list[character] = { folder = folder, box = box }
end

runservice.RenderStepped:Connect(function()
    for character, data in pairs(_G.esp_list) do
        local box = data.box
        local folder = data.folder
        
        if not character or not character.Parent or not is_valid(character) then
            box.Visible = false
            folder:Destroy()
            _G.esp_list[character] = nil
            remove_skeleton(character)
            continue
        end
        
        local torso = character:FindFirstChild("torso")
        if not torso or torso.Transparency >= 1 or is_teammate(character) then
            box.Visible = false
            continue
        end
        
        local pos, on_screen = camera:WorldToScreenPoint(torso.Position)
        
        if on_screen and (camera.CFrame.Position - torso.Position).Magnitude <= 3571.4 then
            if _G.espSkeletons then
                if not _G.skeleton_list[character] then create_skeleton(character) end
                local skel = _G.skeleton_list[character]
                
                if skel then
                    local min_x, min_y = math.huge, math.huge
                    local max_x, max_y = -math.huge, -math.huge
                    
                    for i, conn in ipairs(bones) do
                        local b1, b2 = skel.bones[conn[1]], skel.bones[conn[2]]
                        if b1 and b2 then
                            local p1 = camera:WorldToViewportPoint(b1.Position)
                            local p2 = camera:WorldToViewportPoint(b2.Position)
                            local s1 = camera:WorldToScreenPoint(b1.Position)
                            local s2 = camera:WorldToScreenPoint(b2.Position)
                            
                            if s1.Z > 0 then
                                if s1.X < min_x then min_x = s1.X end
                                if s1.X > max_x then max_x = s1.X end
                                if s1.Y < min_y then min_y = s1.Y end
                                if s1.Y > max_y then max_y = s1.Y end
                            end
                            if s2.Z > 0 then
                                if s2.X < min_x then min_x = s2.X end
                                if s2.X > max_x then max_x = s2.X end
                                if s2.Y < min_y then min_y = s2.Y end
                                if s2.Y > max_y then max_y = s2.Y end
                            end
                            
                            if p1.Z > 0 and p2.Z > 0 then
                                skel.lines[i].From = Vector2.new(p1.X, p1.Y)
                                skel.lines[i].To = Vector2.new(p2.X, p2.Y)
                                skel.lines[i].Visible = true
                            else
                                skel.lines[i].Visible = false
                            end
                        else
                            skel.lines[i].Visible = false
                        end
                    end
                    
                    if _G.ESP_ENABLED and min_x ~= math.huge then
                        local pad = 4
                        box.Visible = true
                        box.Position = UDim2.fromOffset(min_x - pad, min_y - pad)
                        box.Size = UDim2.fromOffset(max_x - min_x + pad * 2, max_y - min_y + pad * 2)
                    else
                        box.Visible = false
                    end
                end
            else
                remove_skeleton(character)
                box.Visible = false
            end
        else
            box.Visible = false
            remove_skeleton(character)
        end
    end
end)

if viewmodels then
    for _, v in ipairs(viewmodels:GetChildren()) do
        if v:IsA("Model") then task.delay(0.1, create_esp, v) end
    end
    viewmodels.ChildAdded:Connect(function(v)
        if v:IsA("Model") then task.delay(0.2, create_esp, v) end
    end)
    viewmodels.ChildRemoved:Connect(function(v)
        if _G.esp_list[v] then _G.esp_list[v].folder:Destroy() _G.esp_list[v] = nil end
        remove_skeleton(v)
    end)
end

-- ==================== ESP COLOUR PICKER ====================
_G.ESPColor = _G.ESPColor or Color3.new(1, 1, 1)

local ColorSection = otherTab:CreateSection("ESP Color")

local ESPColorPicker = otherTab:CreateColorPicker({
   Name = "ESP Color",
   Color = _G.ESPColor,
   Callback = function(Value)
      _G.ESPColor = Value
      _G.ESP_SETTINGS.Color = Value
      for _, ui in pairs(_G.ESP_Table) do
         if ui.Box then ui.Box.Color = Value end
         if ui.Tracer then ui.Tracer.Color = Value end
      end
      for _, skel in pairs(_G.skeleton_list) do
         for _, line in ipairs(skel.lines) do
            line.Color = Value
         end
      end
      for _, data in pairs(_G.esp_list) do
         data.box.UIStroke.Color = Value
      end
   end,
})

-- ==================== OPTIMIZATIONS TAB ====================
local OptimizationsTab = Window:CreateTab("Optimizations", nil)
local OptSection = OptimizationsTab:CreateSection("Performance & Visuals")

OptimizationsTab:CreateParagraph({
    Title = "⚠️ WARNING",
    Content = "Optimize will break scoped weapons!\nUse at your own risk."
})

-- Brightness slider (0-4)
local fullbrightBrightness = 2

OptimizationsTab:CreateSlider({
    Name = "Fullbright Brightness",
    Range = {0, 4},
    Increment = 1,
    Suffix = "",
    CurrentValue = 2,
    Callback = function(Value)
        fullbrightBrightness = Value
    end,
})

OptimizationsTab:CreateButton({
    Name = "💡 Fullbright",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        Lighting.Brightness = fullbrightBrightness
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Rayfield:Notify({
            Title = "Fullbright",
            Content = "Brightness set to: " .. fullbrightBrightness,
            Duration = 3
        })
    end
})

local optimizeConnection = nil

OptimizationsTab:CreateButton({
    Name = "⚡ Optimize",
    Callback = function()
        Rayfield:Notify({
            Title = "⚠️ Disclaimer",
            Content = "This WILL break scoped weapons! Proceeding...",
            Duration = 4
        })
        task.wait(1)
        if optimizeConnection then
            optimizeConnection:Disconnect()
            optimizeConnection = nil
        end
        
        local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
        local Lighting = game:GetService("Lighting")
        
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        settings().Rendering.QualityLevel = 1
        
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CastShadow = false
                v.Material = "Plastic"
                v.Reflectance = 0
                v.BackSurface = "SmoothNoOutlines"
                v.BottomSurface = "SmoothNoOutlines"
                v.FrontSurface = "SmoothNoOutlines"
                v.LeftSurface = "SmoothNoOutlines"
                v.RightSurface = "SmoothNoOutlines"
                v.TopSurface = "SmoothNoOutlines"
            elseif v:IsA("Decal") then
                v.Transparency = 1
                v.Texture = ""
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            end
        end
        
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end
        
        optimizeConnection = workspace.DescendantAdded:Connect(function(child)
            task.spawn(function()
                if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                    RunService.Heartbeat:Wait()
                    child:Destroy()
                elseif child:IsA("BasePart") then
                    child.CastShadow = false
                end
            end)
        end)
        
        print("game optimized")
        warn("this WILL break some scopes")
        
        Rayfield:Notify({
            Title = "Optimization",
            Content = "Game optimized! (Scopes may be broken)",
            Duration = 4
        })
    end
})

-- ==================== COMBAT TAB ====================
local CombatTab = Window:CreateTab("⚔️ Combat", nil)
local CombatSection = CombatTab:CreateSection("Triggerbot")

local TriggerbotSettings = {
    Enabled = false,
    TeamCheck = false,
    AutoGunMode = false,
    Delay = 0,
    Connection = nil,
    IsWaiting = false,
    WaitStartTime = 0,
    IsFiring = false,
    IsPressed = false,
    LastClick = 0,
    ClickInterval = 0.05,
}

local function findCharacter(player)
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name == player.Name then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root then
                return model, hum, root
            end
        end
    end
    return nil
end

local function getPlayerScreenBox(character)
    local camera = workspace.CurrentCamera
    local cf, size = character:GetBoundingBox()
    local top = cf.Position + Vector3.new(0, size.Y/2, 0)
    local bottom = cf.Position - Vector3.new(0, size.Y/2, 0)
    local topPos, vis1 = camera:WorldToViewportPoint(top)
    local bottomPos, vis2 = camera:WorldToViewportPoint(bottom)
    if not vis1 or not vis2 then return nil end
    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height / 2
    return Vector2.new(topPos.X - width/2, topPos.Y), width, height
end

local function pointInBox(point, boxPos, boxWidth, boxHeight)
    local padding = 5
    return point.X >= boxPos.X - padding
       and point.X <= boxPos.X + boxWidth + padding
       and point.Y >= boxPos.Y - padding
       and point.Y <= boxPos.Y + boxHeight + padding
end

local function releaseMouse()
    if TriggerbotSettings.IsPressed then
        mouse1release()
        TriggerbotSettings.IsPressed = false
    end
end

local function triggerbotLoop()
    local UIS = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")

    TriggerbotSettings.Connection = RunService.RenderStepped:Connect(function(dt)
        if not TriggerbotSettings.Enabled then
            releaseMouse()
            TriggerbotSettings.IsWaiting = false
            TriggerbotSettings.IsFiring = false
            return
        end
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            releaseMouse()
            TriggerbotSettings.IsWaiting = false
            TriggerbotSettings.IsFiring = false
            return
        end

        if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            releaseMouse()
            TriggerbotSettings.IsWaiting = false
            TriggerbotSettings.IsFiring = false
            return
        end

        local mousePos = UIS:GetMouseLocation()
        local validEnemy = false

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if TriggerbotSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end

            local character, humanoid, root = findCharacter(player)
            if not character or not humanoid or humanoid.Health <= 0 then continue end

            local boxPos, boxWidth, boxHeight = getPlayerScreenBox(character)
            if not boxPos then continue end

            if pointInBox(mousePos, boxPos, boxWidth, boxHeight) then
                validEnemy = true
                break
            end
        end

        if not validEnemy then
            releaseMouse()
            TriggerbotSettings.IsWaiting = false
            TriggerbotSettings.IsFiring = false
        else
            if not TriggerbotSettings.IsFiring then
                if not TriggerbotSettings.IsWaiting then
                    TriggerbotSettings.IsWaiting = true
                    TriggerbotSettings.WaitStartTime = tick()
                else
                    local elapsed = (tick() - TriggerbotSettings.WaitStartTime) * 1000
                    if elapsed >= TriggerbotSettings.Delay then
                        TriggerbotSettings.IsWaiting = false
                        TriggerbotSettings.IsFiring = true
                    end
                end
            end

            if TriggerbotSettings.IsFiring then
                if TriggerbotSettings.AutoGunMode then
                    if not TriggerbotSettings.IsPressed then
                        mouse1press()
                        TriggerbotSettings.IsPressed = true
                    end
                else
                    releaseMouse()
                    local now = tick()
                    if now - TriggerbotSettings.LastClick >= TriggerbotSettings.ClickInterval then
                        TriggerbotSettings.LastClick = now
                        mouse1click()
                    end
                end
            end
        end
    end)
end

local TriggerbotToggle = CombatTab:CreateToggle({
    Name = "Triggerbot",
    CurrentValue = false,
    Callback = function(Value)
        TriggerbotSettings.Enabled = Value
        if Value then
            if not TriggerbotSettings.Connection then
                triggerbotLoop()
            end
            Rayfield:Notify({
                Title = "Triggerbot",
                Content = "ON (hold RMB) – delay: " .. tostring(TriggerbotSettings.Delay) .. " ms",
                Duration = 2
            })
        else
            if TriggerbotSettings.Connection then
                TriggerbotSettings.Connection:Disconnect()
                TriggerbotSettings.Connection = nil
            end
            releaseMouse()
            TriggerbotSettings.IsWaiting = false
            TriggerbotSettings.IsFiring = false
            Rayfield:Notify({
                Title = "Triggerbot",
                Content = "OFF",
                Duration = 2
            })
        end
    end,
})

local TeamCheckToggle = CombatTab:CreateToggle({
    Name = "Don't Shoot Teammates",
    CurrentValue = false,
    Callback = function(Value)
        TriggerbotSettings.TeamCheck = Value
    end,
})

local AutoGunToggle = CombatTab:CreateToggle({
    Name = "Automatic or Semi gun",
    CurrentValue = false,
    Callback = function(Value)
        TriggerbotSettings.AutoGunMode = Value
        releaseMouse()
        TriggerbotSettings.IsFiring = false
        TriggerbotSettings.IsWaiting = false
    end,
})

local DelaySlider = CombatTab:CreateSlider({
    Name = "Delay (MS)",
    Range = {0, 400},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 0,
    Callback = function(Value)
        TriggerbotSettings.Delay = Value
    end,
})

-- ==================== AIMBOT ====================
-- MODIFICATION: Mobile aim key – detect touch-enabled devices
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled

local AimbotSettings = {
    Enabled = false,
    Smoothness = 0,
    FOV = 150,
    AimOffsetY = 0,
    TeamCheck = false,
    AimPart = "Head",
    RandomPart = nil,
    FOVCircle = nil,
    Connection = nil,
    WasRMBPressed = false,
    AlwaysOn = false,
    UseCameraAim = false,
    MobileScopeActive = false,  -- MODIFICATION: toggle state for mobile scope button
}

-- Mode indicator text (Drawing)
local AimbotModeText = Drawing.new("Text")
AimbotModeText.Text = ""
AimbotModeText.Size = 18
AimbotModeText.Center = true
AimbotModeText.Outline = true
AimbotModeText.Color = Color3.new(1, 1, 1)
AimbotModeText.Visible = false
AimbotModeText.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, 50)

-- MODIFICATION: update indicator to show mobile toggle mode
local function updateAimbotIndicator()
    local mode
    if AimbotSettings.AlwaysOn then
        mode = "Always Active"
    elseif isMobile then
        mode = AimbotSettings.MobileScopeActive and "Scope Toggle (ON)" or "Scope Toggle (OFF)"
    else
        mode = "Hold RMB"
    end
    local method = AimbotSettings.UseCameraAim and " (Camera)" or " (Mouse)"
    AimbotModeText.Text = "Aimbot: " .. mode .. method
    AimbotModeText.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, 50)
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- MODIFICATION: Connect mobile buttons (scope, reload, backpack items)
if isMobile then
    -- Helper to deactivate aimbot toggle (used by reload & backpack items)
    local function deactivateAimbotIfActive()
        if AimbotSettings.Enabled and AimbotSettings.MobileScopeActive then
            AimbotSettings.MobileScopeActive = false
            AimbotSettings.WasRMBPressed = false
            updateAimbotIndicator()
        end
    end

    -- Scope button: toggles aimbot on/off
    pcall(function()
        local scopeButton = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Game", 5):WaitForChild("Right", 5):WaitForChild("Center", 5):WaitForChild("ScopeButton", 5)
        scopeButton.Activated:Connect(function()
            AimbotSettings.MobileScopeActive = not AimbotSettings.MobileScopeActive
            if AimbotSettings.MobileScopeActive then
                AimbotSettings.WasRMBPressed = false
            end
            updateAimbotIndicator()
        end)
    end)

    -- Reload button: turns aimbot off if active
    pcall(function()
        local reloadButton = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Game", 5):WaitForChild("Right", 5):WaitForChild("Center", 5):WaitForChild("ReloadButton", 5)
        reloadButton.Activated:Connect(deactivateAimbotIfActive)
    end)

    -- Backpack items: each of the 4 Item buttons turns aimbot off if active
    pcall(function()
        local backpackItems = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Game", 5):WaitForChild("Right", 5):WaitForChild("Bottom", 5):WaitForChild("BackpackItems", 5)
        -- Connect existing items
        for _, item in ipairs(backpackItems:GetChildren()) do
            if item:IsA("ImageButton") or item:IsA("TextButton") then
                item.Activated:Connect(deactivateAimbotIfActive)
            end
        end
        -- Connect future items (if they are added dynamically)
        backpackItems.ChildAdded:Connect(function(item)
            if item:IsA("ImageButton") or item:IsA("TextButton") then
                item.Activated:Connect(deactivateAimbotIfActive)
            end
        end)
    end)
end

local function isLocalViewmodel(model)
    return model.Name == LocalPlayer.Name and model:IsA("Model") and model.Parent == workspace:FindFirstChild("Viewmodels")
end

local function isTeammate(model)
    local player = Players:FindFirstChild(model.Name)
    return player and player.Team == LocalPlayer.Team
end

local function getPartPosition(model, partName)
    if partName == "Head" then
        local head = model:FindFirstChild("head")
        if head and head:IsA("BasePart") then return head.Position end
    elseif partName == "Torso" then
        local torso = model:FindFirstChild("torso")
        if torso and torso:IsA("BasePart") then return torso.Position end
    elseif partName == "Feet" then
        local left = model:FindFirstChild("LeftFoot")
        local right = model:FindFirstChild("RightFoot")
        if left and left:IsA("BasePart") then return left.Position end
        if right and right:IsA("BasePart") then return right.Position end
        local torso = model:FindFirstChild("torso")
        if torso and torso:IsA("BasePart") then return torso.Position end
    end
    return nil
end

local aimPartOptions = {"Head", "Torso", "Feet"}

local function getClosestPartToCenter(partName)
    local Camera = workspace.CurrentCamera
    local center = Camera.ViewportSize / 2
    local bestDist = AimbotSettings.FOV
    local bestTarget = nil
    local bestWorldPos = nil
    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not viewmodels then return nil, nil end

    for _, model in ipairs(viewmodels:GetChildren()) do
        if not model:IsA("Model") or isLocalViewmodel(model) then continue end
        if AimbotSettings.TeamCheck and isTeammate(model) then continue end

        local partPos = getPartPosition(model, partName)
        if not partPos then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(partPos)
        if not onScreen then continue end

        screenPos = Vector2.new(screenPos.X, screenPos.Y + AimbotSettings.AimOffsetY)

        local dist = (screenPos - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestTarget = screenPos
            bestWorldPos = partPos
        end
    end
    return bestTarget, bestWorldPos
end

local function aimbotLoop()
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera

    AimbotSettings.Connection = RunService.RenderStepped:Connect(function(dt)
        if not AimbotSettings.Enabled then return end

        -- MODIFICATION: aim activation source depends on platform
        local rmbPressed
        if AimbotSettings.AlwaysOn then
            rmbPressed = true
        elseif isMobile then
            rmbPressed = AimbotSettings.MobileScopeActive
        else
            rmbPressed = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end

        if not rmbPressed then
            AimbotSettings.WasRMBPressed = false
            AimbotSettings.RandomPart = nil
            return
        end

        if not AimbotSettings.WasRMBPressed then
            AimbotSettings.WasRMBPressed = true
            if AimbotSettings.AimPart == "Random" then
                AimbotSettings.RandomPart = aimPartOptions[math.random(#aimPartOptions)]
            else
                AimbotSettings.RandomPart = nil
            end
        end

        local currentPart = (AimbotSettings.AimPart == "Random" and AimbotSettings.RandomPart) or AimbotSettings.AimPart
        local screenTarget, worldTarget = getClosestPartToCenter(currentPart)
        if not screenTarget then return end

        local center = Camera.ViewportSize / 2
        local smoothness = AimbotSettings.Smoothness
        local factor = (smoothness <= 0) and 1 or math.clamp(1 - (smoothness / 10), 0.05, 1)

        if AimbotSettings.UseCameraAim and worldTarget then
            -- Silent camera rotation
            local desiredLook = CFrame.lookAt(Camera.CFrame.Position, worldTarget)
            local newCF = Camera.CFrame:Lerp(desiredLook, factor)
            Camera.CFrame = newCF
        else
            -- Original mouse movement
            local delta = screenTarget - center
            mousemoverel(delta.X * factor, delta.Y * factor)
        end
    end)
end

local function updateFOVCircle()
    if AimbotSettings.FOVCircle then
        AimbotSettings.FOVCircle.Radius = AimbotSettings.FOV
        AimbotSettings.FOVCircle.Visible = AimbotSettings.Enabled
    end
end

local AimbotSection = CombatTab:CreateSection("Aimbot")

local AimbotToggle = CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(Value)
        AimbotSettings.Enabled = Value
        if Value then
            if not AimbotSettings.Connection then
                aimbotLoop()
            end
            if not AimbotSettings.FOVCircle then
                AimbotSettings.FOVCircle = Drawing.new("Circle")
                AimbotSettings.FOVCircle.Visible = false
                AimbotSettings.FOVCircle.Color = Color3.new(1,1,1)
                AimbotSettings.FOVCircle.Thickness = 1
                AimbotSettings.FOVCircle.Filled = false
                AimbotSettings.FOVCircle.Transparency = 1
                AimbotSettings.FOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
                AimbotSettings.FOVCircle.Radius = AimbotSettings.FOV
            end
            AimbotSettings.FOVCircle.Visible = true
            AimbotModeText.Visible = true
            updateAimbotIndicator()
        else
            if AimbotSettings.Connection then
                AimbotSettings.Connection:Disconnect()
                AimbotSettings.Connection = nil
            end
            if AimbotSettings.FOVCircle then
                AimbotSettings.FOVCircle.Visible = false
            end
            AimbotSettings.WasRMBPressed = false
            AimbotSettings.RandomPart = nil
            AimbotModeText.Visible = false
        end
    end,
})

local AlwaysOnToggle = CombatTab:CreateToggle({
    Name = "Always On",
    CurrentValue = false,
    Callback = function(Value)
        AimbotSettings.AlwaysOn = Value
        updateAimbotIndicator()
    end,
})

local CameraAimToggle = CombatTab:CreateToggle({
    Name = "Camera Aim (Silent)",
    CurrentValue = false,
    Callback = function(Value)
        AimbotSettings.UseCameraAim = Value
        updateAimbotIndicator()
    end,
})

local AimPartSection = CombatTab:CreateSection("Aim Part (Body Lock)")

local aimParts = {"Head", "Torso", "Random"}
for _, part in ipairs(aimParts) do
    CombatTab:CreateButton({
        Name = "🎯 " .. part,
        Callback = function()
            AimbotSettings.AimPart = part
            if part ~= "Random" then
                AimbotSettings.RandomPart = nil
            end
            Rayfield:Notify({
                Title = "Aim Part",
                Content = "Locking onto: " .. part,
                Duration = 1.5,
            })
        end,
    })
end

local SmoothnessSlider = CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 10},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0,
    Callback = function(Value)
        AimbotSettings.Smoothness = Value
    end,
})

local FOVSlider = CombatTab:CreateSlider({
    Name = "FOV",
    Range = {50, 300},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 150,
    Callback = function(Value)
        AimbotSettings.FOV = Value
        if AimbotSettings.FOVCircle then
            AimbotSettings.FOVCircle.Radius = Value
        end
    end,
})

local AimOffsetYSlider = CombatTab:CreateSlider({
    Name = "Aim Offset Y",
    Range = {-60, 60},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 0,
    Callback = function(Value)
        AimbotSettings.AimOffsetY = Value
    end,
})

local TeamCheckToggle = CombatTab:CreateToggle({
    Name = "Don't Aim at Teammates",
    CurrentValue = false,
    Callback = function(Value)
        AimbotSettings.TeamCheck = Value
    end,
})

RunService.RenderStepped:Connect(function()
    if AimbotSettings.FOVCircle and AimbotSettings.FOVCircle.Visible then
        AimbotSettings.FOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
    end
end)

-- ==================== UTILITY TAB ====================
local UtilityTab = Window:CreateTab("🛠️ Utilities", nil)
local UtilitySection = UtilityTab:CreateSection("Lobby Check")

UtilityTab:CreateButton({
    Name = "🔍 Check Account Ages",
    Callback = function()
        local Players = game:GetService("Players")
        local allPlayers = Players:GetPlayers()
        if #allPlayers == 0 then
            Rayfield:Notify({
                Title = "Lobby Check",
                Content = "No players in the server.",
                Duration = 3
            })
            return
        end

        for _, player in ipairs(allPlayers) do
            local ageDays = player.AccountAge
            local ageDisplay = ""
            if ageDays >= 365 then
                ageDisplay = string.format("%.1f years", ageDays / 365)
            else
                ageDisplay = ageDays .. " days"
            end

            local classification = ""
            if ageDays < 20 then
                classification = " ⚠️ POSSIBLE CHEATER"
            elseif ageDays < 40 then
                classification = " 🔶 VERY SUSPICIOUS"
            elseif ageDays < 60 then
                classification = " 🔸 SUSPICIOUS"
            end

            Rayfield:Notify({
                Title = player.Name,
                Content = "Account age: " .. ageDisplay .. classification,
                Duration = 5
            })
            task.wait(2)
        end
    end,
})

-- ==================== BREAKABLE TRANSPARENCY ====================
local BreakableSection = UtilityTab:CreateSection("Breakable Transparency")

UtilityTab:CreateParagraph({
    Title = "⚠️ Performance Warning",
    Content = "Applying transparency to many breakable objects may cause a brief lag spike."
})

local transparencyValue = 50  -- default percentage

local TransparencySlider = UtilityTab:CreateSlider({
    Name = "Transparency",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 50,
    Callback = function(Value)
        transparencyValue = Value
    end,
})

UtilityTab:CreateButton({
    Name = "Apply Transparency to Breakables",
    Callback = function()
        Rayfield:Notify({
            Title = "Applying...",
            Content = "Setting breakable transparency to " .. transparencyValue .. "%. This may cause slight lag.",
            Duration = 3
        })

        local allDescendants = workspace:GetDescendants()
        local count = 0
        for _, obj in ipairs(allDescendants) do
            if obj:IsA("BasePart") and obj:FindFirstChild("Breakable") then
                obj.Transparency = transparencyValue / 100
                count = count + 1
            end
        end

        Rayfield:Notify({
            Title = "Done",
            Content = "Updated " .. count .. " breakable objects.",
            Duration = 3
        })
    end,
})
