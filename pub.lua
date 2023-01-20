local Saturn = {functions = {}}

local Vector2New, Cam, Mouse, client, find, Draw, Inset, players, RunService =
    Vector2.new,
    workspace.CurrentCamera,
    game.Players.LocalPlayer:GetMouse(),
    game.Players.LocalPlayer,
    table.find,
    Drawing.new,
    game:GetService("GuiService"):GetGuiInset().Y,
    game.Players, 
    game.RunService


local mf, rnew = math.floor, Random.new

local Targetting
local lockedCamTo

local Circle = Draw("Circle")
Circle.Thickness = 1
Circle.Transparency = 0.7
Circle.Color = Color3.new(1,1,1)

Saturn.functions.update_FOVs = function ()
    if not (Circle) then
        return Circle
    end
    Circle.Radius =  getgenv().Saturn.SilentAim.FOVData.Radius * 3
    Circle.Visible = getgenv().Saturn.SilentAim.FOVData.Visibility
    Circle.Filled = getgenv().Saturn.SilentAim.FOVData.Filled
    Circle.Position = Vector2New(Mouse.X, Mouse.Y + (Inset))
    return Circle
end

Saturn.functions.onKeyPress = function(inputObject)
    if inputObject.KeyCode == Enum.KeyCode[getgenv().Saturn.SilentAim.Key:upper()] then
        getgenv().Saturn.SilentAim.Enabled = not getgenv().Saturn.SilentAim.Enabled
    end

    if inputObject.KeyCode == Enum.KeyCode[getgenv().Saturn.Tracing.Key:upper()] then
        if not lockedCamTo then
            lockedCamTo = true
            lockedCamTo = Saturn.functions.returnClosestPlayer()
        else
            lockedCamTo = false
            lockedCamTo = nil
        end
    end
end

game:GetService("UserInputService").InputBegan:Connect(Saturn.functions.onKeyPress)

Saturn.functions.wallCheck = function(direction, ignoreList)
    if not getgenv().Saturn.SilentAim.AimingData.CheckWalls then
        return true
    end

    local ray = Ray.new(Cam.CFrame.p, direction - Cam.CFrame.p)
    local part, _, _ = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(ray, ignoreList)

    return not part
end

Saturn.functions.pointDistance = function(part)
    local OnScreen = Cam.WorldToScreenPoint(Cam, part.Position)
    if OnScreen then
        return (Vector2New(OnScreen.X, OnScreen.Y) - Vector2New(Mouse.X, Mouse.Y)).Magnitude
    end
end

Saturn.functions.returnClosestPart = function(Character)
    local data = {
        dist = math.huge,
        part = nil,
        classes = {"Part", "BasePart", "MeshPart"}
    }
    if not (Character and Character:IsA("Model")) then
        return data.part
    end
    local children = Character:GetChildren()
    for _, child in pairs(children) do
        if table.find(data.classes, child.ClassName) then
            local dist = Saturn.functions.pointDistance(child)
            if dist < data.dist then
                data.part = child
                data.dist = dist
            end
        end
    end
    return data.part
end



Saturn.functions.returnClosestPlayer = function (amount)
    local closestDistance = 1/0
    local closestPlayer = nil
    amount = amount or nil

    for _, player in pairs(players:GetPlayers()) do
        if (player.Character and player ~= client) then
            local charPosition = player.Character:GetBoundingBox().Position
            if charPosition then
                local viewPoint = Cam.WorldToViewportPoint(Cam, charPosition)
        
                if viewPoint then

                    local Magnitude = (Vector2New(Mouse.X, Mouse.Y) - Vector2New(viewPoint.X, viewPoint.Y)).Magnitude

                    if Circle.Radius > Magnitude and Magnitude < closestDistance and
                    Saturn.functions.wallCheck(player.Character.Head.Position,{client, player.Character}) 
                    then
                        closestDistance = Magnitude
                        closestPlayer = player
                    end
                end
            end
        end
    end

    local Calc = mf(rnew().NextNumber(rnew(), 0, 1) * 100) / 100
    local Use = getgenv().Saturn.SilentAim.ChanceData.UseChance
    if Use and Calc <= mf(amount) / 100 then
        return Calc and closestPlayer
    else
        return closestPlayer
    end
end

Saturn.functions.returnClosestPoint = function (player)

end

Saturn.functions.setAimingType = function (player, type)
    local previousSilentAimPart = getgenv().Saturn.SilentAim.AimPart
    local previousTracingPart = getgenv().Saturn.Tracing.AimPart
    if type == "Closest Part" then
        getgenv().Saturn.SilentAim.AimPart = tostring(Saturn.functions.returnClosestPart(player.Character))
        getgenv().Saturn.Tracing.AimPart = tostring(Saturn.functions.returnClosestPart(player.Character))
    elseif type == "Closest Point" then
        Saturn.functions.returnClosestPoint(player.Character)
    elseif type == "Default" then
        getgenv().Saturn.SilentAim.AimPart = previousSilentAimPart
        getgenv().Saturn.Tracing.AimPart = previousTracingPart
    else
        getgenv().Saturn.SilentAim.AimPart = previousSilentAimPart
        getgenv().Saturn.Tracing.AimPart = previousTracingPart
    end
end

Saturn.functions.aimingCheck = function (player)
    if getgenv().Saturn.SilentAim.AimingData.CheckKnocked == true and player and player.Character then
        if player.Character.BodyEffects["K.O"].Value then
            return true
        end
    end
    if getgenv().Saturn.SilentAim.AimingData.CheckGrabbed == true and player and player.Character then
        if player.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            return true
        end
    end
    return false
end

local lastRender = 0
local interpolation = 0.01

RunService.RenderStepped:Connect(function(delta)
    lastRender = lastRender + delta
    while lastRender > interpolation do
        lastRender = lastRender - interpolation
    end
    if getgenv().Saturn.Tracing.Enabled and lockedCamTo then
        local Vel =  lockedCamTo.Character[getgenv().Saturn.Tracing.AimPart].Velocity / getgenv().Saturn.Tracing.Prediction
        local Main = CFrame.new(Cam.CFrame.p, lockedCamTo.Character[getgenv().Saturn.Tracing.AimPart].Position + (Vel))
        Cam.CFrame = Cam.CFrame:Lerp(Main ,getgenv().Saturn.Tracing.TracingOptions.Smoothness , Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        Saturn.functions.setAimingType(lockedCamTo, getgenv().Saturn.Tracing.TracingOptions.AimingType) 
    end
end)

task.spawn(function ()
    while task.wait() do
        if Targetting then
            Saturn.functions.setAimingType(Targetting, getgenv().Saturn.SilentAim.AimingType)
        end
        Saturn.functions.update_FOVs()
    end
end)

local __index
__index = hookmetamethod(game,"__index", function(Obj, Property)
    if Obj:IsA("Mouse") and Property == "Hit" then
        Targetting = Saturn.functions.returnClosestPlayer(getgenv().Saturn.SilentAim.ChanceData.Chance)
        if Targetting and getgenv().Saturn.SilentAim.Enabled and not Saturn.functions.aimingCheck(Targetting) then
            local currentVelocity = Targetting.Character[getgenv().Saturn.SilentAim.AimPart].Velocity * getgenv().Saturn.SilentAim.Prediction
            local predictedPosition = Targetting.Character[getgenv().Saturn.SilentAim.AimPart].CFrame + (currentVelocity)
            return predictedPosition
        end
    end
    return __index(Obj, Property)
end)
