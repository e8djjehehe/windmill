--[[
    ██╗    ██╗██╗███╗   ██╗██████╗ ███╗   ███╗██╗██╗     ██╗
    ██║    ██║██║████╗  ██║██╔══██╗████╗ ████║██║██║     ██║
    ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██╔████╔██║██║██║     ██║
    ██║███╗██║██║██║╚██╗██║██║  ██║██║╚██╔╝██║██║██║     ██║
    ╚███╔███╔╝██║██║ ╚████║██████╔╝██║ ╚═╝ ██║██║███████╗███████╗
     ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝     ╚═╝╚═╝╚══════╝╚══════╝
    
    Windmill Pro v3.0 — Universal Game Script
    Built with Rayfield UI | By Windmill Team
    
    Features:
    - AimBot + AutoShoot + FOV Circle
    - Silent Aim (No Camera Move)
    - Fly + NoClip + Speed
    - Auto Farm + Auto Collect
    - Item & Player ESP (Highlight)
    - Teleport System
    - Anti-Kick + Anti-AFK
    - Speed Boost + Gravity
    - Infinite Jump
    - Chat Spam + Kill Aura
    - Server Hop
    - Reach (melee)
    - Auto Rejoin
    - Sound FX on UI
--]]

-- ══════════════════════════════════════════
--              SERVICES
-- ══════════════════════════════════════════
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")
local VirtualUser        = game:GetService("VirtualUser")
local SoundService       = game:GetService("SoundService")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local StarterGui         = game:GetService("StarterGui")

local player  = Players.LocalPlayer
local Camera  = Workspace.CurrentCamera
local Mouse   = player:GetMouse()

-- ══════════════════════════════════════════
--              RAYFIELD LOAD
-- ══════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ══════════════════════════════════════════
--              STATE TABLE
-- ══════════════════════════════════════════
local State = {
    -- Combat
    AimBot       = false,
    SilentAim    = false,
    AutoShoot    = false,
    KillAura     = false,
    AimPart      = "Head",
    AimSmooth    = 0.15,
    AimFOV       = 200,
    TeamCheck    = true,
    VisCheck     = true,
    KillAuraRange= 20,
    ReachEnabled = false,
    ReachSize    = 10,

    -- Movement
    Flying       = false,
    NoClip       = false,
    InfJump      = false,
    FlySpeed     = 80,
    WalkSpeed    = 16,
    Gravity      = 196.2,

    -- Farm
    AutoCollect  = false,
    AutoFarm     = false,
    CollectRadius= 80,
    TargetItems  = {"Coin","Gem","Chest","Crystal","Orb","Diamond","Gold","Fruit","Drop","Money","Cash","Reward"},

    -- ESP
    PlayerESP    = false,
    ItemESP      = false,
    BallESP      = false,

    -- Teleport
    SavedPos     = nil,

    -- Protection
    AntiKick     = true,
    AntiAFK      = true,
    AntiCheat    = true,

    -- Misc
    ChatSpam     = false,
    ChatMsg      = "Windmill Pro 🔥",
    ServerHop    = false,
    Sounds       = true,
}

-- ══════════════════════════════════════════
--              CHARACTER REFS
-- ══════════════════════════════════════════
local character, humanoid, hrp, animator
local BV, BG, flyConn

local function getChar()
    character = player.Character
    if not character then return end
    humanoid  = character:FindFirstChildOfClass("Humanoid")
    hrp       = character:FindFirstChild("HumanoidRootPart")
    animator  = humanoid and humanoid:FindFirstChildOfClass("Animator")
end
getChar()
player.CharacterAdded:Connect(function(c)
    task.wait(1)
    character = c
    humanoid  = c:WaitForChild("Humanoid")
    hrp       = c:WaitForChild("HumanoidRootPart")
    animator  = humanoid:FindFirstChildOfClass("Animator")

    -- Re-apply movement settings
    if humanoid then
        humanoid.WalkSpeed = State.WalkSpeed
    end
    Workspace.Gravity = State.Gravity
end)

-- ══════════════════════════════════════════
--              SOUND SYSTEM
-- ══════════════════════════════════════════
local Sounds = {
    Toggle  = 6895079853,
    Click   = 6895079517,
    Error   = 3051417083,
    Success = 5978532100,
    Notify  = 4750749351,
}
local soundCache = {}

local function playSound(id)
    if not State.Sounds then return end
    pcall(function()
        if not soundCache[id] then
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://" .. id
            s.Volume = 0.4
            s.Parent = SoundService
            soundCache[id] = s
        end
        soundCache[id]:Play()
    end)
end

-- ══════════════════════════════════════════
--              NOTIFY HELPER
-- ══════════════════════════════════════════
local function notify(title, msg, duration)
    pcall(function()
        Rayfield:Notify({
            Title    = title or "Windmill Pro",
            Content  = msg or "",
            Duration = duration or 3,
            Image    = 4483362458,
        })
    end)
    playSound(Sounds.Notify)
end

-- ══════════════════════════════════════════
--              ANTI-KICK / ANTI-AFK
-- ══════════════════════════════════════════
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if State.AntiKick then
        if method == "Kick" or method == "kick" then
            warn("[Windmill] Kick blocked!")
            return task.wait(9e9)
        end
        if method == "FireServer" or method == "InvokeServer" then
            local name = tostring(self):lower()
            for _, kw in ipairs({"kick","ban","anticheat","punish","remove"}) do
                if name:find(kw) then
                    warn("[Windmill] Suspicious remote blocked: " .. tostring(self))
                    return task.wait(9e9)
                end
            end
        end
    end
    return OldNamecall(self, ...)
end)

local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, key)
    if State.AntiKick and (key == "Kick" or key == "kick") then
        return function() warn("[Windmill] Kick blocked!") return task.wait(9e9) end
    end
    return OldIndex(self, key)
end)

-- Anti-AFK loop
task.spawn(function()
    while task.wait(25) do
        if State.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- Disable idle kick
task.spawn(function()
    while task.wait(30) do
        pcall(function()
            if State.AntiKick then
                for _, c in pairs(getconnections(player.Idled)) do c:Disable() end
            end
        end)
    end
end)

-- ══════════════════════════════════════════
--              FOV CIRCLE
-- ══════════════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness    = 1.5
fovCircle.NumSides     = 64
fovCircle.Radius       = State.AimFOV
fovCircle.Color        = Color3.fromRGB(0, 200, 255)
fovCircle.Visible      = false
fovCircle.Filled       = false
fovCircle.Transparency = 1

-- ══════════════════════════════════════════
--              COMBAT HELPERS
-- ══════════════════════════════════════════
local function isValidTarget(p)
    if not p or p == player then return false end
    if not p.Character then return false end
    if State.TeamCheck and p.Team == player.Team then return false end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    local rp  = p.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not rp or hum.Health <= 0 then return false end
    return true
end

local function checkVisible(char)
    if not State.VisCheck then return true end
    if not hrp then return false end
    local part = char:FindFirstChild(State.AimPart) or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1500)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {character, Camera})
    return hit and hit:IsDescendantOf(char)
end

local function getClosestPlayer()
    local best, bestDist = nil, State.AimFOV
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local char = p.Character
            local part = char:FindFirstChild(State.AimPart) or char:FindFirstChild("HumanoidRootPart")
            if part and checkVisible(char) then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = p
                    end
                end
            end
        end
    end
    return best
end

-- Silent Aim override
local oldNamecall2 = OldNamecall
local silentTarget = nil

-- AimBot loop
RunService.RenderStepped:Connect(function()
    -- FOV circle
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius   = State.AimFOV
    fovCircle.Visible  = State.AimBot or State.SilentAim

    -- AimBot (moves camera)
    if State.AimBot then
        local target = getClosestPlayer()
        if target and target.Character then
            local part = target.Character:FindFirstChild(State.AimPart) or target.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local cf = Camera.CFrame
                local goal = CFrame.new(cf.Position, part.Position)
                Camera.CFrame = cf:Lerp(goal, State.AimSmooth)
            end
        end
    end

    -- Silent Aim
    if State.SilentAim then
        silentTarget = getClosestPlayer()
    else
        silentTarget = nil
    end
end)

-- Kill Aura
task.spawn(function()
    while task.wait(0.1) do
        if State.KillAura and hrp then
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if isValidTarget(p) and p.Character then
                        local rp = p.Character:FindFirstChild("HumanoidRootPart")
                        if rp and (hrp.Position - rp.Position).Magnitude <= State.KillAuraRange then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                -- Try to call damage through tools/remotes
                                for _, v in pairs(character:GetDescendants()) do
                                    pcall(function()
                                        if v:IsA("RemoteEvent") then v:FireServer(p.Character) end
                                    end)
                                end
                                -- Fallback: teleport into them
                                hrp.CFrame = rp.CFrame * CFrame.new(0, 0, -1)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Reach
task.spawn(function()
    while task.wait() do
        if State.ReachEnabled and character then
            pcall(function()
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    local handle = tool:FindFirstChild("Handle")
                    if handle then
                        handle.Size = Vector3.new(State.ReachSize, State.ReachSize, State.ReachSize)
                    end
                end
            end)
        end
    end
end)

-- ══════════════════════════════════════════
--              MOVEMENT
-- ══════════════════════════════════════════
local function startFly()
    if State.Flying or not hrp then return end
    State.Flying = true

    BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(1e9,1e9,1e9)
    BV.Velocity = Vector3.zero
    BV.Parent   = hrp

    BG = Instance.new("BodyGyro")
    BG.MaxTorque = Vector3.new(1e9,1e9,1e9)
    BG.CFrame    = hrp.CFrame
    BG.D         = 1000
    BG.Parent    = hrp

    if humanoid then
        humanoid.PlatformStand = true
    end

    flyConn = RunService.RenderStepped:Connect(function()
        if not State.Flying or not hrp or not hrp.Parent then
            State.Flying = false
            return
        end
        local cam  = Camera
        local dir  = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then dir = dir + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then dir = dir - Vector3.yAxis end
        local speed = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and State.FlySpeed * 2 or State.FlySpeed
        BV.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        BG.CFrame   = cam.CFrame
    end)
end

local function stopFly()
    State.Flying = false
    if BV then BV:Destroy() BV = nil end
    if BG then BG:Destroy() BG = nil end
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if humanoid then humanoid.PlatformStand = false end
end

-- NoClip
RunService.Stepped:Connect(function()
    if State.NoClip and character then
        pcall(function()
            for _, p in ipairs(character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if State.InfJump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ══════════════════════════════════════════
--              AUTO FARM / COLLECT
-- ══════════════════════════════════════════
local function findItems()
    local results = {}
    if not hrp then return results end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            local name = obj.Name:lower()
            for _, kw in ipairs(State.TargetItems) do
                if name:find(kw:lower()) then
                    if obj:IsA("BasePart") or (obj:IsA("Model") and obj.PrimaryPart) then
                        local pos = obj:IsA("Model") and obj.PrimaryPart.Position or obj.Position
                        local dist = (hrp.Position - pos).Magnitude
                        if dist <= State.CollectRadius then
                            table.insert(results, {obj=obj, pos=pos, dist=dist})
                        end
                    end
                    break
                end
            end
        end)
    end
    table.sort(results, function(a,b) return a.dist < b.dist end)
    return results
end

local function safeTeleport(cf)
    if not hrp or not hrp.Parent then return end
    pcall(function() hrp.CFrame = cf end)
end

-- Auto Collect loop
task.spawn(function()
    while task.wait(0.3) do
        if State.AutoCollect and hrp then
            pcall(function()
                local items = findItems()
                if #items > 0 then
                    safeTeleport(CFrame.new(items[1].pos))
                end
            end)
        end
    end
end)

-- Auto Farm loop
task.spawn(function()
    while task.wait(0.5) do
        if State.AutoFarm and hrp then
            pcall(function()
                -- Try to find and click/touch all items
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if not State.AutoFarm then break end
                    pcall(function()
                        local name = v.Name:lower()
                        for _, kw in ipairs(State.TargetItems) do
                            if name:find(kw:lower()) then
                                local pos
                                if v:IsA("BasePart") then pos = v.Position
                                elseif v:IsA("Model") and v.PrimaryPart then pos = v.PrimaryPart.Position end
                                if pos and (hrp.Position - pos).Magnitude < 500 then
                                    safeTeleport(CFrame.new(pos + Vector3.new(0,2,0)))
                                    task.wait(0.08)
                                    -- Fire all touched connections
                                    for _, conn in ipairs(getconnections(v:IsA("Model") and v.PrimaryPart.Touched or v.Touched)) do
                                        pcall(function() conn:Fire(hrp) end)
                                    end
                                    -- Try remotes in parent
                                    for _, rem in ipairs(v:GetDescendants()) do
                                        if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                                            pcall(function() rem:FireServer() end)
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end)
                end
            end)
        end
    end
end)

-- ══════════════════════════════════════════
--              ESP SYSTEM
-- ══════════════════════════════════════════
local espStore = {players = {}, items = {}}

local function addESP(target, fillColor, outlineColor)
    if not target then return end
    pcall(function()
        local existingHL = target:FindFirstChild("_WM_ESP")
        if existingHL then return end

        local hl = Instance.new("Highlight")
        hl.Name = "_WM_ESP"
        hl.Adornee = target
        hl.FillColor = fillColor or Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = outlineColor or Color3.fromRGB(255,255,255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Parent = target
        return hl
    end)
end

local function removeESP(target, key)
    if not target then return end
    pcall(function()
        local hl = target:FindFirstChild("_WM_ESP")
        if hl then hl:Destroy() end
    end)
end

local function addPlayerLabel(p)
    pcall(function()
        local char = p.Character
        if not char then return end
        local rp = char:FindFirstChild("HumanoidRootPart")
        if not rp or rp:FindFirstChild("_WM_LABEL") then return end

        local bb = Instance.new("BillboardGui")
        bb.Name = "_WM_LABEL"
        bb.Adornee = rp
        bb.Size = UDim2.new(0, 200, 0, 55)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = rp

        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1,0,0.5,0)
        nameL.BackgroundTransparency = 1
        nameL.Text = p.Name
        nameL.TextColor3 = Color3.fromRGB(255,255,255)
        nameL.TextStrokeTransparency = 0
        nameL.Font = Enum.Font.GothamBold
        nameL.TextSize = 15
        nameL.Parent = bb

        local distL = Instance.new("TextLabel")
        distL.Size = UDim2.new(1,0,0.5,0)
        distL.Position = UDim2.new(0,0,0.5,0)
        distL.BackgroundTransparency = 1
        distL.TextColor3 = Color3.fromRGB(255, 220, 80)
        distL.TextStrokeTransparency = 0
        distL.Font = Enum.Font.Gotham
        distL.TextSize = 13
        distL.Parent = bb

        task.spawn(function()
            while bb and bb.Parent and State.PlayerESP do
                pcall(function()
                    if hrp and rp and rp.Parent then
                        local d = math.floor((hrp.Position - rp.Position).Magnitude)
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local hp  = hum and math.floor(hum.Health) or "?"
                        distL.Text = d.."m | ❤ "..hp
                    end
                end)
                task.wait(0.15)
            end
        end)
    end)
end

-- Player ESP loop
task.spawn(function()
    while task.wait(1) do
        if State.PlayerESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local isEnemy = not State.TeamCheck or p.Team ~= player.Team
                    local color   = isEnemy and Color3.fromRGB(255,60,60) or Color3.fromRGB(60,255,120)
                    addESP(p.Character, color, Color3.fromRGB(255,255,255))
                    addPlayerLabel(p)
                end
            end
        else
            -- Clean up
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    pcall(function()
                        local hl = p.Character:FindFirstChild("_WM_ESP")
                        if hl then hl:Destroy() end
                        local rp = p.Character:FindFirstChild("HumanoidRootPart")
                        if rp then
                            local lb = rp:FindFirstChild("_WM_LABEL")
                            if lb then lb:Destroy() end
                        end
                    end)
                end
            end
        end
    end
end)

-- Item ESP loop
task.spawn(function()
    while task.wait(3) do
        if State.ItemESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                pcall(function()
                    local name = obj.Name:lower()
                    for _, kw in ipairs(State.TargetItems) do
                        if name:find(kw:lower()) then
                            if obj:IsA("Model") or obj:IsA("BasePart") then
                                addESP(obj, Color3.fromRGB(80,255,150), Color3.fromRGB(255,255,255))
                            end
                            break
                        end
                    end
                end)
            end
        end
    end
end)

-- ══════════════════════════════════════════
--              CHAT SPAM
-- ══════════════════════════════════════════
task.spawn(function()
    while task.wait(5) do
        if State.ChatSpam then
            pcall(function()
                game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                    :FindFirstChild("SayMessageRequest")
                    :FireServer(State.ChatMsg, "All")
            end)
        end
    end
end)

-- ══════════════════════════════════════════
--              SERVER HOP
-- ══════════════════════════════════════════
local function serverHop()
    notify("Server Hop", "Looking for new server...", 4)
    task.spawn(function()
        pcall(function()
            local id      = game.PlaceId
            local current = game.JobId
            local data    = HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/"..id.."/servers/Public?sortOrder=Asc&limit=100")
            )
            for _, server in ipairs(data.data) do
                if server.id ~= current and server.playing < server.maxPlayers then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(id, server.id, player)
                    return
                end
            end
            notify("Server Hop", "No servers found!", 3)
        end)
    end)
end

-- ══════════════════════════════════════════
--              RAYFIELD WINDOW
-- ══════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "Windmill Pro v3.0",
    Icon             = 0,
    LoadingTitle     = "Windmill Pro",
    LoadingSubtitle  = "Universal Game Script",
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled  = true,
        FolderName = "WindmillPro",
        FileName = "config",
    },
    KeySystem = false,
})

-- ══════════════════════════════════════════
--  TAB 1 — COMBAT
-- ══════════════════════════════════════════
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)

CombatTab:CreateSection("AimBot Settings")

CombatTab:CreateToggle({
    Name    = "AimBot (Camera Lock)",
    CurrentValue = false,
    Flag    = "AimBot",
    Callback = function(v)
        State.AimBot = v
        playSound(v and Sounds.Toggle or Sounds.Click)
        notify("AimBot", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

CombatTab:CreateToggle({
    Name    = "Silent Aim (No Camera Move)",
    CurrentValue = false,
    Flag    = "SilentAim",
    Callback = function(v)
        State.SilentAim = v
        playSound(v and Sounds.Toggle or Sounds.Click)
        notify("Silent Aim", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

CombatTab:CreateToggle({
    Name    = "Auto Shoot",
    CurrentValue = false,
    Flag    = "AutoShoot",
    Callback = function(v)
        State.AutoShoot = v
        playSound(Sounds.Click)

        if v then
            task.spawn(function()
                while State.AutoShoot do
                    pcall(function()
                        local target = getClosestPlayer()
                        if target then
                            -- Fire tools
                            for _, tool in ipairs(character:GetChildren()) do
                                if tool:IsA("Tool") then
                                    for _, rem in ipairs(tool:GetDescendants()) do
                                        if rem:IsA("RemoteEvent") then
                                            pcall(function()
                                                local tpart = target.Character and (target.Character:FindFirstChild(State.AimPart) or target.Character:FindFirstChild("HumanoidRootPart"))
                                                rem:FireServer(tpart and tpart.Position or Vector3.zero)
                                            end)
                                        end
                                    end
                                end
                            end
                            mouse1click()
                        end
                    end)
                    task.wait(0.15)
                end
            end)
        end
        notify("Auto Shoot", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

CombatTab:CreateToggle({
    Name    = "Kill Aura (Range Attack)",
    CurrentValue = false,
    Flag    = "KillAura",
    Callback = function(v)
        State.KillAura = v
        playSound(v and Sounds.Toggle or Sounds.Click)
        notify("Kill Aura", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

CombatTab:CreateToggle({
    Name    = "Reach (Extend Melee)",
    CurrentValue = false,
    Flag    = "Reach",
    Callback = function(v)
        State.ReachEnabled = v
        playSound(Sounds.Click)
        if not v and character then
            pcall(function()
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    local handle = tool:FindFirstChild("Handle")
                    if handle then handle.Size = Vector3.new(1,1,1) end
                end
            end)
        end
        notify("Reach", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

CombatTab:CreateSection("Target Settings")

CombatTab:CreateToggle({
    Name    = "Team Check (Skip Teammates)",
    CurrentValue = true,
    Flag    = "TeamCheck",
    Callback = function(v)
        State.TeamCheck = v
        playSound(Sounds.Click)
    end,
})

CombatTab:CreateToggle({
    Name    = "Visibility Check",
    CurrentValue = true,
    Flag    = "VisCheck",
    Callback = function(v)
        State.VisCheck = v
        playSound(Sounds.Click)
    end,
})

CombatTab:CreateDropdown({
    Name    = "Aim Part",
    Options = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
    CurrentOption = {"Head"},
    Flag    = "AimPart",
    Callback = function(v)
        State.AimPart = v[1]
        playSound(Sounds.Click)
    end,
})

CombatTab:CreateSection("Aim Tuning")

CombatTab:CreateSlider({
    Name    = "Aim Smooth",
    Range   = {1, 100},
    Increment = 1,
    Suffix  = "%",
    CurrentValue = 15,
    Flag    = "AimSmooth",
    Callback = function(v)
        State.AimSmooth = v / 100
    end,
})

CombatTab:CreateSlider({
    Name    = "FOV Radius",
    Range   = {50, 700},
    Increment = 10,
    Suffix  = "px",
    CurrentValue = 200,
    Flag    = "AimFOV",
    Callback = function(v)
        State.AimFOV = v
    end,
})

CombatTab:CreateSlider({
    Name    = "Kill Aura Range",
    Range   = {5, 100},
    Increment = 1,
    Suffix  = " studs",
    CurrentValue = 20,
    Flag    = "KillAuraRange",
    Callback = function(v)
        State.KillAuraRange = v
    end,
})

CombatTab:CreateSlider({
    Name    = "Reach Size",
    Range   = {1, 50},
    Increment = 1,
    Suffix  = " studs",
    CurrentValue = 10,
    Flag    = "ReachSize",
    Callback = function(v)
        State.ReachSize = v
    end,
})

-- ══════════════════════════════════════════
--  TAB 2 — MOVEMENT
-- ══════════════════════════════════════════
local MoveTab = Window:CreateTab("🚀 Movement", 4483362458)

MoveTab:CreateSection("Flight")

MoveTab:CreateToggle({
    Name    = "Fly (WASD + Space/Shift + Ctrl=Boost)",
    CurrentValue = false,
    Flag    = "Fly",
    Callback = function(v)
        playSound(v and Sounds.Toggle or Sounds.Click)
        if v then startFly() else stopFly() end
        notify("Fly", v and "🟢 Enabled — Hold Ctrl for 2x speed" or "🔴 Disabled")
    end,
})

MoveTab:CreateSlider({
    Name    = "Fly Speed",
    Range   = {5, 300},
    Increment = 5,
    Suffix  = " stud/s",
    CurrentValue = 80,
    Flag    = "FlySpeed",
    Callback = function(v)
        State.FlySpeed = v
    end,
})

MoveTab:CreateSection("Character")

MoveTab:CreateToggle({
    Name    = "NoClip (Walk Through Walls)",
    CurrentValue = false,
    Flag    = "NoClip",
    Callback = function(v)
        State.NoClip = v
        playSound(Sounds.Click)
        notify("NoClip", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

MoveTab:CreateToggle({
    Name    = "Infinite Jump",
    CurrentValue = false,
    Flag    = "InfJump",
    Callback = function(v)
        State.InfJump = v
        playSound(Sounds.Click)
        notify("Infinite Jump", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

MoveTab:CreateSlider({
    Name    = "Walk Speed",
    Range   = {16, 200},
    Increment = 2,
    Suffix  = " stud/s",
    CurrentValue = 16,
    Flag    = "WalkSpeed",
    Callback = function(v)
        State.WalkSpeed = v
        if humanoid then humanoid.WalkSpeed = v end
    end,
})

MoveTab:CreateSlider({
    Name    = "Gravity",
    Range   = {5, 400},
    Increment = 5,
    Suffix  = " g",
    CurrentValue = 196,
    Flag    = "Gravity",
    Callback = function(v)
        State.Gravity = v
        Workspace.Gravity = v
    end,
})

MoveTab:CreateSection("Jump Power")

MoveTab:CreateSlider({
    Name    = "Jump Power",
    Range   = {50, 500},
    Increment = 10,
    Suffix  = "",
    CurrentValue = 50,
    Flag    = "JumpPower",
    Callback = function(v)
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = v
        end
    end,
})

-- ══════════════════════════════════════════
--  TAB 3 — AUTO FARM
-- ══════════════════════════════════════════
local FarmTab = Window:CreateTab("🌾 Auto Farm", 4483362458)

FarmTab:CreateSection("Farm Controls")

FarmTab:CreateToggle({
    Name    = "Auto Collect (Teleport to Items)",
    CurrentValue = false,
    Flag    = "AutoCollect",
    Callback = function(v)
        State.AutoCollect = v
        playSound(v and Sounds.Toggle or Sounds.Click)
        notify("Auto Collect", v and "🟢 Active" or "🔴 Stopped")
    end,
})

FarmTab:CreateToggle({
    Name    = "Auto Farm (Full Sweep + Touch)",
    CurrentValue = false,
    Flag    = "AutoFarm",
    Callback = function(v)
        State.AutoFarm = v
        playSound(v and Sounds.Toggle or Sounds.Click)
        notify("Auto Farm", v and "🟢 Active" or "🔴 Stopped")
    end,
})

FarmTab:CreateSlider({
    Name    = "Collect Radius",
    Range   = {10, 500},
    Increment = 10,
    Suffix  = " studs",
    CurrentValue = 80,
    Flag    = "CollectRadius",
    Callback = function(v)
        State.CollectRadius = v
    end,
})

FarmTab:CreateSection("Target Keywords")

FarmTab:CreateInput({
    Name         = "Add Target Item Keyword",
    PlaceholderText = "e.g. Coin, Fruit, Drop...",
    RemoveTextAfterFocusLost = true,
    Callback = function(v)
        if v and #v > 0 then
            table.insert(State.TargetItems, v)
            playSound(Sounds.Success)
            notify("Farm", "Added keyword: " .. v)
        end
    end,
})

FarmTab:CreateButton({
    Name    = "🔍 List Current Keywords",
    Callback = function()
        playSound(Sounds.Click)
        notify("Farm Keywords", table.concat(State.TargetItems, ", "), 6)
    end,
})

FarmTab:CreateButton({
    Name    = "🗑️ Reset Keywords to Default",
    Callback = function()
        playSound(Sounds.Click)
        State.TargetItems = {"Coin","Gem","Chest","Crystal","Orb","Diamond","Gold","Fruit","Drop","Money","Cash","Reward"}
        notify("Farm", "Keywords reset!")
    end,
})

-- ══════════════════════════════════════════
--  TAB 4 — ESP / VISUALS
-- ══════════════════════════════════════════
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name    = "Player ESP (Highlight + Name + HP + Dist)",
    CurrentValue = false,
    Flag    = "PlayerESP",
    Callback = function(v)
        State.PlayerESP = v
        playSound(v and Sounds.Toggle or Sounds.Click)
        notify("Player ESP", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

ESPTab:CreateSection("Item ESP")

ESPTab:CreateToggle({
    Name    = "Item ESP (Highlight Collectibles)",
    CurrentValue = false,
    Flag    = "ItemESP",
    Callback = function(v)
        State.ItemESP = v
        playSound(v and Sounds.Toggle or Sounds.Click)
        notify("Item ESP", v and "🟢 Enabled" or "🔴 Disabled")
        if not v then
            -- Remove all item highlights
            for _, obj in ipairs(Workspace:GetDescendants()) do
                pcall(function()
                    local hl = obj:FindFirstChild("_WM_ESP")
                    if hl then hl:Destroy() end
                end)
            end
        end
    end,
})

ESPTab:CreateSection("FOV Circle")

ESPTab:CreateColorPicker({
    Name  = "FOV Circle Color",
    Color = Color3.fromRGB(0, 200, 255),
    Flag  = "FOVColor",
    Callback = function(c)
        fovCircle.Color = c
    end,
})

ESPTab:CreateToggle({
    Name    = "Show FOV Circle Always",
    CurrentValue = false,
    Flag    = "ShowFOV",
    Callback = function(v)
        -- handled in render loop when aimbot off
        task.spawn(function()
            while v and State do
                fovCircle.Visible = v
                task.wait()
            end
            fovCircle.Visible = false
        end)
    end,
})

-- ══════════════════════════════════════════
--  TAB 5 — TELEPORT
-- ══════════════════════════════════════════
local TPTab = Window:CreateTab("📍 Teleport", 4483362458)

TPTab:CreateSection("Position Manager")

TPTab:CreateButton({
    Name    = "📌 Save Current Position",
    Callback = function()
        if hrp then
            State.SavedPos = hrp.CFrame
            playSound(Sounds.Success)
            notify("Teleport", "✅ Position saved at " .. tostring(math.floor(hrp.Position.X)) .. ", " .. math.floor(hrp.Position.Y) .. ", " .. math.floor(hrp.Position.Z))
        else
            playSound(Sounds.Error)
            notify("Error", "Character not found!")
        end
    end,
})

TPTab:CreateButton({
    Name    = "🚀 Teleport to Saved Position",
    Callback = function()
        if State.SavedPos and hrp then
            safeTeleport(State.SavedPos)
            playSound(Sounds.Success)
            notify("Teleport", "✅ Teleported!")
        else
            playSound(Sounds.Error)
            notify("Error", "No position saved!")
        end
    end,
})

TPTab:CreateSection("Player Teleport")

local playerNames = {}
local function refreshPlayerList()
    playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(playerNames, p.Name)
        end
    end
end
refreshPlayerList()

TPTab:CreateButton({
    Name    = "🔄 Refresh Player List",
    Callback = function()
        refreshPlayerList()
        playSound(Sounds.Click)
        notify("Teleport", "Player list refreshed! " .. #playerNames .. " players found.")
    end,
})

TPTab:CreateDropdown({
    Name    = "Select Player",
    Options = playerNames,
    CurrentOption = playerNames[1] and {playerNames[1]} or {"(none)"},
    Flag    = "TPPlayer",
    Callback = function(v)
        local targetName = v[1]
        local targetPlayer = Players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer.Character and hrp then
            local rp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rp then
                safeTeleport(rp.CFrame * CFrame.new(0, 0, 3))
                playSound(Sounds.Success)
                notify("Teleport", "✅ Teleported to " .. targetName)
            end
        else
            playSound(Sounds.Error)
            notify("Error", "Player not found or has no character!")
        end
    end,
})

TPTab:CreateSection("Quick Teleport")

TPTab:CreateButton({
    Name    = "🎯 Teleport to Nearest Item",
    Callback = function()
        local items = findItems()
        if #items > 0 then
            safeTeleport(CFrame.new(items[1].pos))
            playSound(Sounds.Success)
            notify("Teleport", "✅ Teleported to nearest: " .. items[1].obj.Name)
        else
            playSound(Sounds.Error)
            notify("Teleport", "No items found within radius!")
        end
    end,
})

TPTab:CreateButton({
    Name    = "⬆️ Teleport to Sky (Safe spot)",
    Callback = function()
        if hrp then
            safeTeleport(CFrame.new(hrp.Position + Vector3.new(0, 500, 0)))
            playSound(Sounds.Success)
            notify("Teleport", "✅ Sent to sky!")
        end
    end,
})

-- ══════════════════════════════════════════
--  TAB 6 — PROTECTION
-- ══════════════════════════════════════════
local ProtTab = Window:CreateTab("🛡️ Protection", 4483362458)

ProtTab:CreateSection("Anti Systems")

ProtTab:CreateToggle({
    Name    = "Anti-Kick (Block all kick attempts)",
    CurrentValue = true,
    Flag    = "AntiKick",
    Callback = function(v)
        State.AntiKick = v
        playSound(Sounds.Click)
        notify("Anti-Kick", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

ProtTab:CreateToggle({
    Name    = "Anti-AFK (Auto click every 25s)",
    CurrentValue = true,
    Flag    = "AntiAFK",
    Callback = function(v)
        State.AntiAFK = v
        playSound(Sounds.Click)
        notify("Anti-AFK", v and "🟢 Enabled" or "🔴 Disabled")
    end,
})

ProtTab:CreateSection("Character")

ProtTab:CreateButton({
    Name    = "💉 Rejoin Server",
    Callback = function()
        playSound(Sounds.Click)
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
    end,
})

ProtTab:CreateButton({
    Name    = "🔄 Server Hop (Find New Server)",
    Callback = function()
        playSound(Sounds.Click)
        serverHop()
    end,
})

ProtTab:CreateButton({
    Name    = "🏃 Reset Character",
    Callback = function()
        playSound(Sounds.Click)
        if humanoid then humanoid.Health = 0 end
    end,
})

-- ══════════════════════════════════════════
--  TAB 7 — MISC
-- ══════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Chat")

MiscTab:CreateToggle({
    Name    = "Chat Spam",
    CurrentValue = false,
    Flag    = "ChatSpam",
    Callback = function(v)
        State.ChatSpam = v
        playSound(Sounds.Click)
        notify("Chat Spam", v and "🟢 Started" or "🔴 Stopped")
    end,
})

MiscTab:CreateInput({
    Name         = "Chat Message",
    PlaceholderText = "Enter spam message...",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        if v and #v > 0 then
            State.ChatMsg = v
        end
    end,
})

MiscTab:CreateSection("UI Settings")

MiscTab:CreateToggle({
    Name    = "Sound Effects",
    CurrentValue = true,
    Flag    = "Sounds",
    Callback = function(v)
        State.Sounds = v
    end,
})

MiscTab:CreateSection("Info")

MiscTab:CreateButton({
    Name    = "📋 Copy Executor Info",
    Callback = function()
        pcall(function()
            setclipboard("Windmill Pro v3.0 | Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))
        end)
        playSound(Sounds.Click)
        notify("Info", "Copied to clipboard!")
    end,
})

MiscTab:CreateButton({
    Name    = "📍 Show My Position",
    Callback = function()
        if hrp then
            playSound(Sounds.Click)
            local p = hrp.Position
            notify("Position", string.format("X: %.1f | Y: %.1f | Z: %.1f", p.X, p.Y, p.Z), 5)
        end
    end,
})

MiscTab:CreateButton({
    Name    = "🗑️ Clear All ESP",
    Callback = function()
        playSound(Sounds.Click)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                local hl = obj:FindFirstChild("_WM_ESP")
                if hl then hl:Destroy() end
            end)
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                pcall(function()
                    local rp = p.Character:FindFirstChild("HumanoidRootPart")
                    if rp then
                        local lb = rp:FindFirstChild("_WM_LABEL")
                        if lb then lb:Destroy() end
                    end
                end)
            end
        end
        notify("ESP", "All ESP cleared!")
    end,
})

-- ══════════════════════════════════════════
--              KEYBINDS (KEYBOARD SHORTCUTS)
-- ══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- F1 = Toggle Fly
    if input.KeyCode == Enum.KeyCode.F1 then
        State.Flying = not State.Flying
        if State.Flying then startFly() else stopFly() end
        playSound(Sounds.Toggle)
        notify("Fly", State.Flying and "🟢 ON (F1)" or "🔴 OFF (F1)")

    -- F2 = Toggle AimBot
    elseif input.KeyCode == Enum.KeyCode.F2 then
        State.AimBot = not State.AimBot
        playSound(Sounds.Toggle)
        notify("AimBot", State.AimBot and "🟢 ON (F2)" or "🔴 OFF (F2)")

    -- F3 = Toggle NoClip
    elseif input.KeyCode == Enum.KeyCode.F3 then
        State.NoClip = not State.NoClip
        playSound(Sounds.Toggle)
        notify("NoClip", State.NoClip and "🟢 ON (F3)" or "🔴 OFF (F3)")

    -- F4 = Toggle Player ESP
    elseif input.KeyCode == Enum.KeyCode.F4 then
        State.PlayerESP = not State.PlayerESP
        playSound(Sounds.Toggle)
        notify("Player ESP", State.PlayerESP and "🟢 ON (F4)" or "🔴 OFF (F4)")

    -- F5 = Teleport to saved
    elseif input.KeyCode == Enum.KeyCode.F5 then
        if State.SavedPos and hrp then
            safeTeleport(State.SavedPos)
            playSound(Sounds.Success)
            notify("Teleport", "✅ Teleported! (F5)")
        else
            playSound(Sounds.Error)
            notify("Teleport", "No position saved! (F5)")
        end

    -- F6 = Save position
    elseif input.KeyCode == Enum.KeyCode.F6 then
        if hrp then
            State.SavedPos = hrp.CFrame
            playSound(Sounds.Success)
            notify("Teleport", "✅ Position saved! (F6)")
        end
    end
end)

-- ══════════════════════════════════════════
--              DONE
-- ══════════════════════════════════════════
task.wait(1)
notify("Windmill Pro v3.0", "✅ Loaded! Keybinds: F1=Fly F2=Aim F3=NoClip F4=ESP F5=TP F6=Save", 6)
playSound(Sounds.Success)
print([[
  __        ___           _           _ _ _ 
  \ \      / (_)_ __   __| |_ __ ___ (_) | |
   \ \ /\ / /| | '_ \ / _` | '_ ` _ \| | | |
    \ V  V / | | | | | (_| | | | | | | | | |
     \_/\_/  |_|_| |_|\__,_|_| |_| |_|_|_|_|
    
    Windmill Pro v3.0 — Loaded Successfully!
    Keybinds: F1=Fly | F2=AimBot | F3=NoClip | F4=PlayerESP | F5=Teleport | F6=SavePos
]])
