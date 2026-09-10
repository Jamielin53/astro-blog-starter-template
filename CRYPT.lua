local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local Toggles = Library.Toggles
local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Dread",
    Center = true,
    AutoShow = true,
    Resizable = true,
    MobileButtonsSide = "Right"
})

local function Notify(text, duration)
    Library:Notify({ Title = "Dread", Description = text, Time = duration or 3 })
end

pcall(function()
    local ACBypass = {}
    ACBypass.__index = ACBypass

    local PlayersAC = cloneref(game:GetService("Players"))
    local ReplicatedStorageAC = cloneref(game:GetService("ReplicatedStorage"))
    local ReplicatedFirstAC = cloneref(game:GetService("ReplicatedFirst"))
    local ScriptContextAC = cloneref(game:GetService("ScriptContext"))
    local LocalPlayerAC = PlayersAC.LocalPlayer

    local stateAC = { bypassed = false, load_state = "Unloaded" }
    local kExpectedScripts = { [1914481512] = "Root", [1936447744] = "ReplicatedController", [3892767096] = "MiscellaneousController", [337076960] = "LocalScript3", [2191862192] = "ClientFighter" }

    local function SafeHook(hookfn, ...)
        local args = {...}
        local func, inst, metamethod, detour
        if hookfn == hookmetamethod then inst, metamethod, detour = args[1], args[2], args[3] else func, detour = args[1], args[2] end
        if hookfn == hookfunction and iscclosure(func) then detour = newcclosure(detour) end
        if not iscclosure(detour) then detour = newcclosure(detour) end
        local original
        pcall(function()
            if hookfn == hookmetamethod then original = hookfn(inst, metamethod, detour) else original = hookfn(func, detour) end
        end)
        return original
    end

    local function SafeCall(func, ...)
        if checkcaller() then return func(...) end
        local old = getthreadidentity()
        if old ~= 2 then setthreadidentity(2) end
        local r = { func(...) }
        if old ~= 2 then setthreadidentity(old) end
        return table.unpack(r)
    end

    local function VerifyScripts()
        local getscripts_fn, getbytecode_fn = pcall(function() return getscripts or getsenv end), pcall(function() return getscriptbytecode end)
        if not getscripts_fn or not getbytecode_fn then return true end
        local found = {}
        for _, script_instance in ipairs(getscripts_fn()) do
            local ok, bytecode = pcall(getbytecode_fn, script_instance)
            if ok and bytecode then
                for expected_id, _ in pairs(kExpectedScripts) do
                    if not found[expected_id] then
                        local source_ok, source = pcall(debug.info, script_instance, "s")
                        if source_ok and source and source ~= "=[C]" then found[expected_id] = true end
                    end
                end
            end
        end
        for id, _ in pairs(kExpectedScripts) do if not found[id] then return false end end
        return true
    end

    local function HookKickPrevention()
        for _, name in ipairs({"Kick", "kick"}) do
            local f = LocalPlayerAC[name]
            if type(f) == "function" then
                local old
                old = SafeHook(hookfunction, f, function(self, ...)
                    if self == LocalPlayerAC and not checkcaller() then return end
                    return old(self, ...)
                end)
            end
        end
    end

    local function HookACScript(ac_script)
        if not ac_script then return end
        local oldindex = SafeHook(hookmetamethod, ac_script, "__index", function(t, k)
            if t == ac_script and not checkcaller() and k == "Enabled" and not stateAC.bypassed then return false end
            if checkcaller() then return oldindex(t, k) end
            return SafeCall(oldindex, t, k)
        end)
        local oldnewindex = SafeHook(hookmetamethod, ac_script, "__newindex", function(t, k, v)
            if t == ac_script and not checkcaller() and k == "Enabled" and not stateAC.bypassed then return end
            if checkcaller() then return oldnewindex(t, k, v) end
            return SafeCall(oldnewindex, t, k, v)
        end)
    end

    if VerifyScripts() then
        local ac_script = ReplicatedFirstAC:WaitForChild("LocalScript3", 10)
        local ac_event = ReplicatedStorageAC:WaitForChild("Remotes", 10):WaitForChild("RemoteEvent", 10)
        if ac_script and ac_event then
            HookACScript(ac_script)
            HookKickPrevention()
            ac_script.Enabled = false
            stateAC.bypassed = true
            print("[Dread] AC Bypass loaded")
        end
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local rng = Random.new()
local char, root, hum
local conns = {}

local function killConn(key)
    if conns[key] then conns[key]:Disconnect(); conns[key] = nil end
end

local function getLocalRoot()
    return root
end

local function getClosest()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local d = (root.Position - hrp.Position).Magnitude
        if d < bestDist then bestDist = d; best = p end
    end
    return best
end

local function bindChar(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart", 5)
    hum = c:WaitForChild("Humanoid", 5)
    if riotEnabled then startRiot() end
    if riotAbuseEnabled then startRiotAbuse() end
end

if LocalPlayer.Character then bindChar(LocalPlayer.Character) end

LocalPlayer.CharacterAdded:Connect(function(c)
    bindChar(c)
    task.wait(0.3)
    if CFG.VOID_ENABLED then startVoid() end
    if cfg.orbitEnabled then startOrbit() end
    if cfgDodge.predEnabled then startPrediction() end
    if aaSettings.enabled then startAntiAim() end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    killConn("void"); killConn("orbit"); killConn("pred"); killConn("antiAim"); killConn("riot"); killConn("riotAbuse")
    root = nil; hum = nil; char = nil
end)

local CFG = {
    VOID_ENABLED = false, VOID_METHOD = "Quantum",
    SPEED = 1e9, CHAOS = 0.98, BASE_ALTITUDE = 1e10, RADIUS = 2e11,
    VOID_EVADE = true, VOID_EVADE_RADIUS = 8e9, VOID_EVADE_SPEED = 6e9, VOID_EVADE_VERT = 3e9, VOID_EVADE_FORCE_UP = false, VOID_EVADE_COOLDOWN = 0.05, VOID_EVADE_TRIGGER = 1.0, VOID_EVADE_STRENGTH = 1.0,
}
local elapsed, voidPos, voidDriftDir, basePos, voidEvadeCD, intendedVoidPos = 0, Vector3.new(0, CFG.BASE_ALTITUDE, 0), Vector3.new(1, 0, 0).Unit, Vector3.new(0, CFG.BASE_ALTITUDE, 0), 0, Vector3.new(0, CFG.BASE_ALTITUDE, 0)

local function computeVoidDriftDir3D(t)
    local nx, ny, nz, amp, freq = 0, 0, 0, 1, 0.0001
    for i=1,4 do nx = nx + math.noise(t*freq, 0, 0)*amp; ny = ny + math.noise(0, t*freq, 0)*amp; nz = nz + math.noise(0, 0, t*freq)*amp; freq = freq*2.37; amp = amp*0.5 end
    local sp, cp = t*0.00073, t*0.00213
    nx = nx + math.noise(sp+13.7, 7.3, 0)*0.3 + math.sin(cp)*math.cos(cp*1.618)*0.2
    ny = ny + math.noise(0, sp+31.1, 17.9)*0.3 + math.cos(cp*0.618)*math.sin(cp*2.718)*0.2
    nz = nz + math.noise(7.3, 0, sp+11.5)*0.3 + math.sin(cp*1.3)*math.cos(cp*0.7)*0.2
    local len = math.sqrt(nx*nx + ny*ny + nz*nz)
    if len < 0.001 then return 1, 0, 0 end
    return nx/len, ny/len, nz/len
end

local function stepVoidDrift(dt)
    local m = CFG.VOID_METHOD
    if m == "Drift" then
        local dx, dy, dz = computeVoidDriftDir3D(elapsed)
        voidDriftDir = voidDriftDir:Lerp(Vector3.new(dx, dy, dz).Unit, CFG.CHAOS * dt * 10)
        voidPos = voidPos + voidDriftDir * CFG.SPEED * dt
        if (voidPos - basePos).Magnitude > CFG.RADIUS then voidPos = basePos + (voidPos - basePos).Unit * CFG.RADIUS; voidDriftDir = -voidDriftDir end
        return voidPos
    elseif m == "Chaos" then
        voidPos = voidPos + Vector3.new((math.random()-0.5)*CFG.SPEED*dt*5, (math.random()-0.5)*CFG.SPEED*dt*5, (math.random()-0.5)*CFG.SPEED*dt*5)
        if (voidPos - basePos).Magnitude > CFG.RADIUS then voidPos = basePos + (voidPos - basePos).Unit * CFG.RADIUS end
        return voidPos
    elseif m == "Loop" then
        local r = math.min(CFG.RADIUS * 0.8, 1e9 + (elapsed % 100)*1e7)
        return basePos + Vector3.new(math.cos(elapsed*2)*r, math.sin(elapsed*1.3)*r*0.2, math.sin(elapsed*2)*r)
    elseif m == "Spiral" then
        local r = math.min(CFG.RADIUS * 0.9, (elapsed % 50)*2e9)
        return basePos + Vector3.new(math.cos(elapsed*3)*r, math.sin(elapsed*0.5)*r*0.3, math.sin(elapsed*3)*r)
    elseif m == "Quantum" then
        local r = CFG.RADIUS * (math.random()>0.5 and 1 or -1)
        return basePos + Vector3.new(r, (math.random()-0.5)*CFG.RADIUS*0.2, r) + Vector3.new((math.random()-0.5)*CFG.RADIUS, 0, (math.random()-0.5)*CFG.RADIUS)
    end
    return voidPos
end

local function checkVoidEvasion()
    if not CFG.VOID_EVADE or voidEvadeCD > 0 then return end
    local minDist, threatVec = math.huge, Vector3.new()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position + hrp.AssemblyLinearVelocity*0.5 - intendedVoidPos).Magnitude
                if d < minDist then minDist = d; threatVec = (hrp.Position + hrp.AssemblyLinearVelocity*0.5 - intendedVoidPos).Unit end
            end
        end
    end
    if minDist < (CFG.VOID_EVADE_RADIUS * CFG.VOID_EVADE_TRIGGER) then
        local strength = CFG.VOID_EVADE_STRENGTH
        voidPos = voidPos - threatVec * CFG.VOID_EVADE_SPEED * (1 + (1 - minDist/(CFG.VOID_EVADE_RADIUS*CFG.VOID_EVADE_TRIGGER))*2) * strength * 0.5
        if (voidPos - basePos).Magnitude > CFG.RADIUS then voidPos = basePos + (voidPos - basePos).Unit * CFG.RADIUS end
        voidEvadeCD = CFG.VOID_EVADE_COOLDOWN
    end
end

local function lockToVoid(dt)
    if voidEvadeCD > 0 then voidEvadeCD = voidEvadeCD - dt end
    checkVoidEvasion()
    intendedVoidPos = stepVoidDrift(dt)
    local hrp = getLocalRoot()
    if not hrp then return end
    pcall(function() hrp.CFrame = CFrame.new(intendedVoidPos); hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end)
    if math.random(1,10) == 1 then
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.new((math.random()-0.5)*2e7, (math.random()-0.5)*2e7, (math.random()-0.5)*2e7) end)
    end
end

function startVoid()
    killConn("void")
    local hrp = getLocalRoot()
    if hrp then
        voidPos = Vector3.new(hrp.Position.X, CFG.BASE_ALTITUDE, hrp.Position.Z)
        basePos = Vector3.new(0, CFG.BASE_ALTITUDE, 0)
        intendedVoidPos = voidPos
    end
    conns.void = RunService.Heartbeat:Connect(function(dt)
        if not CFG.VOID_ENABLED then killConn("void"); return end
        elapsed = elapsed + dt
        lockToVoid(dt)
    end)
end
function stopVoid() killConn("void") end

local cfg = { orbitEnabled = false, orbitSpeed = 90, orbitDist = 8, orbitHeight = 0, orbitLerp = 0.3, orbitMode = "Circle", orbitPredict = false, orbitPredStrength = 0.2, orbitFaceTarget = true, orbitAutoLockDist = 50 }
local orbitAngle = 0
local orbitLocalElapsed = 0
local orbitCurrentRadius = 0

function startOrbit()
    killConn("orbit")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
    orbitAngle = 0
    orbitLocalElapsed = 0
    orbitCurrentRadius = cfg.orbitDist

    conns.orbit = RunService.Heartbeat:Connect(function(dt)
        if not cfg.orbitEnabled or not root then 
            if not cfg.orbitEnabled then killConn("orbit") end
            return 
        end
        
        local target = getClosest()
        if not target or not target.Character then return end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if (root.Position - hrp.Position).Magnitude > cfg.orbitAutoLockDist then return end

        local targetPos = hrp.Position
        if cfg.orbitPredict then
            targetPos = targetPos + hrp.AssemblyLinearVelocity * cfg.orbitPredStrength
        end

        orbitAngle = orbitAngle + math.rad(cfg.orbitSpeed) * dt
        orbitLocalElapsed = orbitLocalElapsed + dt

        local r = cfg.orbitDist
        local h = cfg.orbitHeight
        local x, y, z = 0, 0, 0

        if cfg.orbitMode == "Circle" then
            x = math.cos(orbitAngle) * r
            z = math.sin(orbitAngle) * r
            y = h
        elseif cfg.orbitMode == "Figure 8" then
            x = math.sin(orbitAngle) * r
            z = math.sin(orbitAngle) * math.cos(orbitAngle) * r * 0.7
            y = h
        elseif cfg.orbitMode == "Spiral In" then
            orbitCurrentRadius = math.max(1, orbitCurrentRadius - (dt * 2))
            x = math.cos(orbitAngle) * orbitCurrentRadius
            z = math.sin(orbitAngle) * orbitCurrentRadius
            y = h
        elseif cfg.orbitMode == "Spiral Out" then
            orbitCurrentRadius = math.min(cfg.orbitDist * 2, orbitCurrentRadius + (dt * 2))
            x = math.cos(orbitAngle) * orbitCurrentRadius
            z = math.sin(orbitAngle) * orbitCurrentRadius
            y = h
        elseif cfg.orbitMode == "Bounce" then
            x = math.cos(orbitAngle) * r
            z = math.sin(orbitAngle) * r
            y = h + math.sin(orbitLocalElapsed * 3) * 5
        end

        local dst = targetPos + Vector3.new(x, y, z)
        local smooth = root.Position:Lerp(dst, cfg.orbitLerp)

        if cfg.orbitFaceTarget then
            root.CFrame = CFrame.new(smooth, Vector3.new(targetPos.X, smooth.Y, targetPos.Z))
        else
            root.CFrame = CFrame.new(smooth)
        end
    end)
end
function stopOrbit() killConn("orbit"); cfg.orbitEnabled = false end

local cfgDodge = {
    predEnabled = false,
    predRadius = 20,
    predDodgeDist = 30,
    predCooldown = 0.3,
    predThreshold = 800,
    predMult = 1,
}
local lastDodgeTick = 0

function startPrediction()
    killConn("pred")
    conns.pred = RunService.Heartbeat:Connect(function(dt)
        if not cfgDodge.predEnabled or not root then if not cfgDodge.predEnabled then killConn("pred") end return end
        if hum and hum.Health <= 0 then return end
        local myPos = root.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character then continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local vel = hrp and hrp.AssemblyLinearVelocity
            if hrp and vel and vel.Magnitude > cfgDodge.predThreshold then
                local predictedPos = hrp.Position + vel * (dt * 3 * cfgDodge.predMult)
                if (predictedPos - myPos).Magnitude < cfgDodge.predRadius and tick() - lastDodgeTick > cfgDodge.predCooldown then
                    lastDodgeTick = tick()
                    local perp = Vector3.new(-vel.Z, 0, vel.X).Unit
                    local dir = math.random(0,1) == 0 and perp or -perp
                    root.CFrame = CFrame.new(myPos + dir * cfgDodge.predDodgeDist)
                    Notify("dodged " .. p.Name, 1.5)
                    break
                end
            end
        end
    end)
end
function stopPrediction() killConn("pred"); cfgDodge.predEnabled = false end

local aaSettings = { enabled = false, mode = "Spin", speed = 5000, angle = 90, randomSpeed = true, jitterPitch = true }
local aaAngleAccum, aaJitterState, aaRandomTimer, aaRandomMultiplier = 0, 0, 0, 1
function startAntiAim()
    killConn("antiAim")
    conns.antiAim = RunService.Heartbeat:Connect(function(dt)
        if not aaSettings.enabled or not root then if not aaSettings.enabled then killConn("antiAim") end return end
        local speed = aaSettings.speed
        if aaSettings.randomSpeed then
            aaRandomTimer = aaRandomTimer + dt
            if aaRandomTimer > 0.1 then aaRandomTimer = 0; aaRandomMultiplier = 0.2 + math.random()*0.8 end
            speed = speed * aaRandomMultiplier
        end
        if aaSettings.mode == "Spin" then
            aaAngleAccum = aaAngleAccum + speed*dt
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(aaAngleAccum), 0)
        elseif aaSettings.mode == "Jitter" then
            root.CFrame = root.CFrame * CFrame.Angles(math.rad(aaJitterState==0 and aaSettings.angle or -aaSettings.angle), math.rad(aaJitterState==0 and aaSettings.angle or -aaSettings.angle), 0)
            aaJitterState = (aaJitterState + 1) % 2
        elseif aaSettings.mode == "Static" then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(aaSettings.angle), 0)
        end
    end)
end
function stopAntiAim() killConn("antiAim"); aaSettings.enabled = false end

local riotEnabled = false
local riotSpeed, riotRange, riotEvadeRange, riotTimer = 0.03, 50, 30, 0
local riotSpinSpeed = 180
local riotAngle = 0

function startRiot()
    killConn("riot")
    conns.riot = RunService.Heartbeat:Connect(function(dt)
        if not riotEnabled or not root then killConn("riot"); return end
        riotTimer = riotTimer + dt
        if riotTimer < riotSpeed then return end
        riotTimer = 0
        
        local currentPos = root.Position
        local target = getClosest()
        local newPos = currentPos

        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (currentPos - hrp.Position).Magnitude < riotEvadeRange then
                local dir = (currentPos - hrp.Position).Unit
                newPos = currentPos + dir * math.random(riotRange*0.5, riotRange*1.5)
            else
                local angle = math.random() * 2 * math.pi
                newPos = currentPos + Vector3.new(math.cos(angle)*math.random(riotRange*0.2, riotRange), math.random(-riotRange*0.5, riotRange*0.5), math.sin(angle)*math.random(riotRange*0.2, riotRange))
            end
        else
            local angle = math.random() * 2 * math.pi
            newPos = currentPos + Vector3.new(math.cos(angle)*math.random(riotRange*0.2, riotRange), math.random(-riotRange*0.5, riotRange*0.5), math.sin(angle)*math.random(riotRange*0.2, riotRange))
        end

        riotAngle = riotAngle + (riotSpinSpeed * dt)
        if riotAngle >= 360 then riotAngle = riotAngle - 360 end

        pcall(function()
            root.CFrame = CFrame.new(newPos) * CFrame.Angles(0, math.rad(riotAngle), 0)
            root.AssemblyLinearVelocity = Vector3.zero
        end)
    end)
end
function stopRiot() killConn("riot"); riotEnabled = false end

-- ========== RIOT ABUSE (3D OFFSETS) ==========
local riotAbuseEnabled = false
local riotAbuseHeight = 3      -- Up/Down from center
local riotAbuseForward = 0     -- Forward/Backward
local riotAbuseRight = 0       -- Left/Right
local riotAbuseDown = 0        -- Additional downward offset
local riotAbuseMode = "Stick"

function startRiotAbuse()
    killConn("riotAbuse")
    conns.riotAbuse = RunService.Heartbeat:Connect(function(dt)
        if not riotAbuseEnabled or not root then
            if not riotAbuseEnabled then killConn("riotAbuse") end
            return
        end
        
        local target = getClosest()
        if not target or not target.Character then return end
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        
        -- Apply 3D offsets
        local offset = Vector3.new(
            riotAbuseRight,
            riotAbuseHeight - riotAbuseDown,
            riotAbuseForward
        )
        local targetPos = targetRoot.Position + offset
        
        if riotAbuseMode == "Stick" then
            root.CFrame = CFrame.new(targetPos)
        elseif riotAbuseMode == "Bounce" then
            local bounceOffset = math.abs(math.sin(tick() * 8)) * math.abs(riotAbuseHeight)
            root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(
                riotAbuseRight,
                bounceOffset - riotAbuseDown,
                riotAbuseForward
            ))
        end
        
        root.AssemblyLinearVelocity = Vector3.zero
    end)
end
function stopRiotAbuse() killConn("riotAbuse"); riotAbuseEnabled = false end

local projBypass = { 
    enabled = false, 
    spoof = true, 
    pred = true, 
    expand = 0.18, 
    lerp = 0.88, 
    spd = 90,
    predMult = 1
}
local projSpoofed = nil

local function predictTarget(targetRoot, origin)
    local vel = targetRoot.AssemblyLinearVelocity
    local prevVel = targetRoot:GetAttribute("PrevVel") or vel
    local accel = (vel - prevVel) / 0.1
    targetRoot:SetAttribute("PrevVel", vel)
    local dist = (origin - targetRoot.Position).Magnitude
    local time = (dist / projBypass.spd) * projBypass.predMult
    return targetRoot.Position + vel * time + 0.5 * accel * time * time
end

local function expandPosition(pos)
    return pos + (pos - Camera.CFrame.Position).Unit * projBypass.expand
end

local function hookRemoteEvents()
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    if not remotes then return end
    for _, r in ipairs(remotes:GetDescendants()) do
        if r:IsA("RemoteEvent") and not r:GetAttribute("_hooked") then
            r:SetAttribute("_hooked", true)
            local oldFire = r.FireServer
            r.FireServer = function(self, data, ...)
                if projBypass.enabled and projBypass.spoof and type(data) == "table" then
                    local sc = projSpoofed or Camera.CFrame
                    if data.Origin ~= nil then data.Origin = sc.Position end
                    if data.Position ~= nil then data.Position = sc.Position end
                    if data.CFrame ~= nil then data.CFrame = sc end
                    if data.LookDir ~= nil then data.LookDir = sc.LookVector end
                    if data.Source ~= nil then data.Source = sc.Position end
                    if data.Spread ~= nil then data.Spread = 0 end
                end
                return oldFire(self, data, ...)
            end
        end
    end
end

local function tickSpoof()
    if not projBypass.enabled then return end
    local target = getClosest()
    local orig = Camera.CFrame.Position
    if target then
        local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            local dist = (orig - tr.Position).Magnitude
            local pos = orig + (tr.Position - orig).Unit * (dist * 0.5)
            projSpoofed = CFrame.new(pos, tr.Position)
            return
        end
    end
    projSpoofed = CFrame.new(orig, Camera.CFrame.LookVector)
end

local function tickAim()
    if not projBypass.enabled then return end
    local target = getClosest()
    if not target then return end
    local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tr then return end
    
    local origin = Camera.CFrame.Position
    local aim = expandPosition(projBypass.pred and predictTarget(tr, origin) or tr.Position)
    local dir = (aim - origin).Unit
    
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(origin, origin + dir), projBypass.lerp)
end

RunService.RenderStepped:Connect(function()
    tickSpoof()
    tickAim()
end)

task.spawn(hookRemoteEvents)

local function AddBindableToggle(group, flag, text, default, callback)
    local toggle = group:AddToggle(flag, { Text = text, Default = default or false, Callback = callback })
    toggle:AddKeyPicker(flag .. 'Key', { Default = 'None', Mode = 'Toggle', Text = text, SyncToggleState = true, NoUI = false })
    return toggle
end

local Tabs = {
    VoidSpam        = Window:AddTab("VoidSpam"),
    Orbit           = Window:AddTab("Orbit"),
    Prediction      = Window:AddTab("Prediction"),
    AntiAim         = Window:AddTab("AntiAim"),
    Riot            = Window:AddTab("Riot"),
    ProjectileBypass= Window:AddTab("Proj Bypass"),
    Settings        = Window:AddTab("Settings"),
}

local VG = Tabs.VoidSpam:AddLeftGroupbox("Void Control")
AddBindableToggle(VG, "VoidToggle", "Enable Void", false, function(val) CFG.VOID_ENABLED = val; if val then startVoid() else stopVoid() end end)
VG:AddDropdown("VoidMethod", { Text = "Voidspam Methods", Default = "Quantum", Values = {"Drift", "Chaos", "Loop", "Spiral", "Quantum"}, Callback = function(v) CFG.VOID_METHOD = v end })
VG:AddSlider("Speed", { Text = "Speed (B/s)", Default = 1, Min = 1, Max = 2000, Rounding = 0, Callback = function(v) CFG.SPEED = v * 1e9 end })
VG:AddSlider("Chaos", { Text = "Chaos (%)", Default = 98, Min = 1, Max = 100, Rounding = 0, Callback = function(v) CFG.CHAOS = v * 0.01 end })
VG:AddSlider("BaseAltitude", { Text = "Base Altitude (B)", Default = 10, Min = 1, Max = 1000, Rounding = 0, Callback = function(v) CFG.BASE_ALTITUDE = v * 1e9 end })
VG:AddSlider("Radius", { Text = "Radius (B)", Default = 200, Min = 1, Max = 2000, Rounding = 0, Callback = function(v) CFG.RADIUS = v * 1e9 end })

local VG2 = Tabs.VoidSpam:AddRightGroupbox("Evasion & Advanced")
VG2:AddLabel("- evades enemys automaticly")
AddBindableToggle(VG2, "EvadeEnemies", "Evade Enemies", true, function(v) CFG.VOID_EVADE = v end)
VG2:AddSlider("EvadeRadius", { Text = "Evade Radius (B)", Default = 8, Min = 1, Max = 500, Rounding = 0, Callback = function(v) CFG.VOID_EVADE_RADIUS = v * 1e9 end })
VG2:AddSlider("EvadeSpeed", { Text = "Evade Speed (B/s)", Default = 6, Min = 1, Max = 500, Rounding = 0, Callback = function(v) CFG.VOID_EVADE_SPEED = v * 1e9 end })
VG2:AddSlider("EvadeVertical", { Text = "Evade Vertical (B)", Default = 3, Min = 1, Max = 500, Rounding = 0, Callback = function(v) CFG.VOID_EVADE_VERT = v * 1e9 end })
VG2:AddSlider("EvadeCooldown", { Text = "Evade Cooldown (x0.01s)", Default = 5, Min = 1, Max = 100, Rounding = 0, Callback = function(v) CFG.VOID_EVADE_COOLDOWN = v * 0.01 end })
VG2:AddSlider("EvadeTrigger", { Text = "Evade Trigger (%)", Default = 100, Min = 10, Max = 200, Rounding = 0, Callback = function(v) CFG.VOID_EVADE_TRIGGER = v * 0.01 end })
VG2:AddSlider("EvadeStrength", { Text = "Evade Strength (%)", Default = 100, Min = 10, Max = 300, Rounding = 0, Callback = function(v) CFG.VOID_EVADE_STRENGTH = v * 0.01 end })

local OG = Tabs.Orbit:AddLeftGroupbox("Orbit")
AddBindableToggle(OG, "OrbitToggle", "Enable Orbit", false, function(val) cfg.orbitEnabled = val; if val then startOrbit() else stopOrbit() end end)
OG:AddDropdown("OrbitMode", { Text = "Orbit Mode", Default = "Circle", Values = {"Circle", "Figure 8", "Spiral In", "Spiral Out", "Bounce"}, Callback = function(v) cfg.orbitMode = v; orbitCurrentRadius = cfg.orbitDist end })
OG:AddSlider("OrbitSpeed", { Text = "Speed (deg/s)", Default = 90, Min = 5, Max = 720, Rounding = 0, Callback = function(v) cfg.orbitSpeed = v end })
OG:AddSlider("OrbitDist", { Text = "Radius", Default = 8, Min = 1, Max = 200, Rounding = 0, Callback = function(v) cfg.orbitDist = v; orbitCurrentRadius = v end })
OG:AddSlider("OrbitHeight", { Text = "Height Offset", Default = 0, Min = -200, Max = 200, Rounding = 0, Callback = function(v) cfg.orbitHeight = v end })
OG:AddSlider("OrbitLerp", { Text = "Smoothing", Default = 30, Min = 1, Max = 100, Rounding = 0, Callback = function(v) cfg.orbitLerp = v / 100 end })

local OG2 = Tabs.Orbit:AddRightGroupbox("Advanced")
OG2:AddLabel("- auto targets closest player")
AddBindableToggle(OG2, "OrbitFaceTarget", "Face Target", true, function(v) cfg.orbitFaceTarget = v end)
AddBindableToggle(OG2, "OrbitPredict", "Enable Prediction", false, function(v) cfg.orbitPredict = v end)
OG2:AddSlider("OrbitPredStrength", { Text = "Prediction Strength", Default = 20, Min = 0, Max = 100, Rounding = 0, Suffix = "%", Callback = function(v) cfg.orbitPredStrength = v / 100 end })
OG2:AddSlider("OrbitAutoLockDist", { Text = "Max Auto-Lock Dist", Default = 50, Min = 10, Max = 500, Rounding = 0, Callback = function(v) cfg.orbitAutoLockDist = v end })

local PG = Tabs.Prediction:AddLeftGroupbox("Prediction Dodge")
AddBindableToggle(PG, "PredToggle", "Enable Prediction", false, function(val) cfgDodge.predEnabled = val; if val then startPrediction() else stopPrediction() end end)
PG:AddSlider("PredRadius", { Text = "Danger Radius", Default = 20, Min = 5, Max = 100, Rounding = 0, Callback = function(v) cfgDodge.predRadius = v end })
PG:AddSlider("PredDodge", { Text = "Dodge Distance", Default = 30, Min = 5, Max = 150, Rounding = 0, Callback = function(v) cfgDodge.predDodgeDist = v end })
PG:AddSlider("PredCooldown", { Text = "Cooldown (ms)", Default = 300, Min = 50, Max = 2000, Rounding = 0, Callback = function(v) cfgDodge.predCooldown = v / 1000 end })
PG:AddSlider("PredThreshold", { Text = "Speed Threshold", Default = 800, Min = 200, Max = 5000, Rounding = 0, Callback = function(v) cfgDodge.predThreshold = v end })
PG:AddSlider("PredMult", { Text = "Mega Prediction Mult.", Default = 1, Min = 0.5, Max = 10, Rounding = 1, Suffix = "x", Callback = function(v) cfgDodge.predMult = v end })
local PG2 = Tabs.Prediction:AddRightGroupbox("Settings")
PG2:AddLabel("- dodges incomin void spammers")

local AG = Tabs.AntiAim:AddLeftGroupbox("Extreme Anti-Aim")
AddBindableToggle(AG, "AaToggle", "Enable Anti-Aim", false, function(val) aaSettings.enabled = val; if val then startAntiAim() else stopAntiAim() end end)
AG:AddDropdown("AaMode", { Text = "Mode", Default = "Spin", Values = {"Spin", "Jitter", "Static"}, Callback = function(v) aaSettings.mode = v end })
AG:AddSlider("AaSpeed", { Text = "Speed (deg/s)", Default = 5000, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) aaSettings.speed = v end })
AG:AddSlider("AaAngle", { Text = "Jitter/Static Angle", Default = 90, Min = 10, Max = 180, Rounding = 0, Callback = function(v) aaSettings.angle = v end })
AddBindableToggle(AG, "AaRandomSpeed", "Randomize Speed", true, function(v) aaSettings.randomSpeed = v end)
AddBindableToggle(AG, "AaJitterPitch", "Jitter Pitch (2D)", true, function(v) aaSettings.jitterPitch = v end)
local AG2 = Tabs.AntiAim:AddRightGroupbox("Info")
AG2:AddLabel("- spin: rotats 360")
AG2:AddLabel("- jitter: alternats pitch + yaw")
AG2:AddLabel("- static: locks rotation")
AG2:AddLabel("- max speed: 5000 deg/s")

-- ========== RIOT TAB (WITH NEW 3D RIOT ABUSE) ==========
local GG = Tabs.Riot:AddLeftGroupbox("Riot – Erratic + 360° Spin")
AddBindableToggle(GG, "RiotToggle", "Enable Riot (Erratic)", false, function(val) riotEnabled = val; if val then startRiot() else stopRiot() end end)
GG:AddSlider("RiotSpeed", { Text = "Teleport Delay (sec)", Default = 0.03, Min = 0.01, Max = 0.5, Rounding = 2, Callback = function(v) riotSpeed = v end })
GG:AddSlider("RiotRange", { Text = "Jump Range (studs)", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) riotRange = v end })
GG:AddSlider("RiotEvadeRange", { Text = "Evade Trigger (studs)", Default = 30, Min = 0, Max = 100, Rounding = 0, Callback = function(v) riotEvadeRange = v end })
GG:AddSlider("RiotSpinSpeed", { Text = "Spin Speed (deg/s)", Default = 180, Min = 0, Max = 720, Rounding = 0, Callback = function(v) riotSpinSpeed = v end })

local GG2 = Tabs.Riot:AddRightGroupbox("Info")
GG2:AddLabel("- erratic tp spam")
GG2:AddLabel("- auto evades close enemys")
GG2:AddLabel("- spins 360 during teleports")

-- ========== NEW: 3D RIOT ABUSE ==========
local RA = Tabs.Riot:AddLeftGroupbox("Riot Abuse (3D Offsets)")
AddBindableToggle(RA, "RiotAbuseToggle", "Enable Riot Abuse", false, function(val) 
    riotAbuseEnabled = val
    if val then 
        startRiotAbuse()
        Notify("Riot Abuse enabled", 2) 
    else 
        stopRiotAbuse()
        Notify("Riot Abuse disabled", 2)
    end
end)
RA:AddDropdown("RiotAbuseMode", { 
    Text = "Abuse Mode", 
    Default = "Stick", 
    Values = {"Stick", "Bounce"}, 
    Callback = function(v) riotAbuseMode = v end
})
RA:AddSlider("RiotAbuseHeight", { 
    Text = "Height Offset", 
    Default = 3, 
    Min = -50, 
    Max = 50, 
    Rounding = 1, 
    Suffix = "m", 
    Callback = function(v) riotAbuseHeight = v end
})
RA:AddSlider("RiotAbuseForward", { 
    Text = "Forward Offset", 
    Default = 0, 
    Min = -50, 
    Max = 50, 
    Rounding = 1, 
    Suffix = "m", 
    Callback = function(v) riotAbuseForward = v end
})
RA:AddSlider("RiotAbuseRight", { 
    Text = "Right Offset", 
    Default = 0, 
    Min = -50, 
    Max = 50, 
    Rounding = 1, 
    Suffix = "m", 
    Callback = function(v) riotAbuseRight = v end
})
RA:AddSlider("RiotAbuseDown", { 
    Text = "Down Offset", 
    Default = 0, 
    Min = 0, 
    Max = 50, 
    Rounding = 1, 
    Suffix = "m", 
    Callback = function(v) riotAbuseDown = v end
})

-- ========== PROJECTILE BYPASS TAB ==========
local PB = Tabs.ProjectileBypass:AddLeftGroupbox("Projectile Bypass (BETA)")
local projToggle = PB:AddToggle("ProjToggle", {
    Text = "Enable Bypass",
    Default = false,
    Callback = function(val) 
        projBypass.enabled = val
        if val then Notify("bypass on", 2) else Notify("bypass off", 2) end
    end
})
projToggle:AddKeyPicker("ProjKey", { Default = 'None', Mode = 'Toggle', Text = 'Toggle Bypass', SyncToggleState = true, NoUI = false })

-- ========== UNLOCK MODULE (migrated from aetherea source) ==========
do
        -- [0] 二次載入防護 + 跨執行共享狀態
        -- g 永遠複用；skinchanger_state / caches 表物件永不重建，確保舊 hooks（未 unload）能持續看到最新狀態
        local g = getgenv().CRYPT_UNLOCK
        if not g then
                g = {}
                getgenv().CRYPT_UNLOCK = g
        end

        if not g.skinchanger_state then
                g.skinchanger_state = {
                        constructing_weapon = nil,
                        viewing_profile = nil,
                        last_used_weapon = nil,
                        fake_owned = nil,
                        fake_weapon_owned = nil,
                        equipped = {},
                        placed_object_map = {},
                        favorites = nil,

                        general_unlocker = { unlock_type = "Skin", unlock_rarity = "Common" },
                        specific_unlocker = { unlock_type = "Skin", cosmetic_name = "", weapon_name = "" },
                        equip_unlocker = { unlock_type = "Skin", cosmetic_name = "", weapon_name = "", inverted = false },
                }
        end
        if not g.caches then
                g.caches = { objectid_to_weapon_cache = {} }
        end

        local S = g.skinchanger_state
        local caches = g.caches

        -- LPH 宏 fallback（部分執行器沒有這些宏）
        local LPH_JIT = (type(LPH_JIT_MAX) == "function") and LPH_JIT_MAX or function(f) return f end
        local LPH_NV = (type(LPH_NO_VIRTUALIZE) == "function") and LPH_NO_VIRTUALIZE or function(f) return f end

        -- UI 狀態標籤（前置宣告：讓上方 task.spawn 閉包正確捕獲 upvalue，UI 建立時再賦值）
        local LabelModules, LabelHooks, LabelData

        local kCosmeticTypes = { "Skin", "Wrap", "Charm", "Finisher" }
        local kCosmeticRarities = { "Common", "Rare", "Legendary", "Mythical", "Unique", "Unobtainable" }

        -- [1] 遊戲模組載入
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local modules = {}

        local function requireModule(parent, name, timeout)
                if not parent then return nil end
                local inst = parent:FindFirstChild(name) or parent:WaitForChild(name, timeout or 15)
                if not inst then return nil end
                local ok, result = pcall(require, inst)
                return ok and result or nil
        end

        local rsModules = ReplicatedStorage:FindFirstChild("Modules") or ReplicatedStorage:WaitForChild("Modules", 15)
        local psControllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers") or LocalPlayer.PlayerScripts:WaitForChild("Controllers", 15)

        modules.CosmeticLibrary = requireModule(rsModules, "CosmeticLibrary")
        modules.ItemLibrary = requireModule(rsModules, "ItemLibrary")
        modules.EnumLibrary = requireModule(rsModules, "EnumLibrary")
        modules.ShopLibrary = requireModule(rsModules, "ShopLibrary")
        modules.PlayerDataController = requireModule(psControllers, "PlayerDataController")

        -- 環境指紋：同一執行器環境 + 同一批遊戲模組表 → 重複執行時直接復用舊 hooks，不二次 hook / 不覆寫
        local fingerprint = table.concat({
                tostring(modules.CosmeticLibrary),
                tostring(modules.PlayerDataController),
                tostring(modules.ItemLibrary),
                tostring(modules.ShopLibrary),
                tostring(LocalPlayer),
        }, "|")
        local same_session = (g.fingerprint == fingerprint)
        g.fingerprint = fingerprint

        -- [2] 核心 hooks：假擁有 (fake ownership) — 每個目標模組表上有 marker，防重複覆寫
        local cl = modules.CosmeticLibrary
        if cl and not cl.__CRYPT_OWN_HOOKED then
                cl.__CRYPT_OWN_HOOKED = true

                local ownscosnorm_original = cl.OwnsCosmeticNormally
                cl.OwnsCosmeticNormally = LPH_JIT(function(p1, p2, p3)
                        local inv = S.fake_owned
                        if inv and inv[p3] then return true end
                        return ownscosnorm_original(p1, p2, p3)
                end)

                local ownscosuni_original = cl.OwnsCosmeticUniversally
                cl.OwnsCosmeticUniversally = LPH_JIT(function(p1, p2, p3)
                        local inv = S.fake_owned
                        if inv and inv[p3] then return true end
                        return ownscosuni_original(p1, p2, p3)
                end)

                local ownscosforsm_original = cl.OwnsCosmeticForSomething
                cl.OwnsCosmeticForSomething = LPH_JIT(function(p1, p2, p3)
                        local inv = S.fake_owned
                        if inv and inv[p3] then return true end
                        return ownscosforsm_original(p1, p2, p3)
                end)

                local ownscosforwp_original = cl.OwnsCosmeticForWeapon
                cl.OwnsCosmeticForWeapon = LPH_JIT(function(p1, p2, p3, p4)
                        local inv = S.fake_owned
                        if inv and inv[p3] then return true end
                        return ownscosforwp_original(p1, p2, p3, p4)
                end)

                local owns_cosmetic_original = cl.OwnsCosmetic
                cl.OwnsCosmetic = LPH_JIT(function(self, inventory, name, weapon)
                        local inv = S.fake_owned
                        if inv and inv[name] then return true end
                        return owns_cosmetic_original(self, inventory, name, weapon)
                end)
        end

        local pd = modules.PlayerDataController
        if pd and not pd.__CRYPT_DATA_HOOKED then
                pd.__CRYPT_DATA_HOOKED = true

                local dataget_original = pd.Get
                pd.Get = LPH_JIT(function(p1, ...)
                        local data = dataget_original(p1, ...)
                        local key = ({ ... })[1]

                        if key == "CosmeticInventory" then
                                return S.fake_owned or data
                        end
                        if key == "WeaponInventory" then
                                return S.fake_weapon_owned or data
                        end
                        if key == "FreeWeaponUnlockCheck" then
                                return S.fake_weapon_owned or data
                        end
                        if key == "FavoritedCosmetics" then
                                return S.favorites or data
                        end
                        return data
                end)

                local getweapondata_original = pd.GetWeaponData
                pd.GetWeaponData = LPH_JIT(function(p1, ...)
                        local weapon_name = ({ ... })[1]
                        local original_data, index = getweapondata_original(p1, ...)

                        local fake_owned = false
                        local fwo = S.fake_weapon_owned
                        if fwo then
                                for _, weapon in ipairs(fwo) do
                                        if weapon.Name == weapon_name then
                                                fake_owned = true
                                                break
                                        end
                                end
                        end

                        if fake_owned and not original_data then
                                local fake_data = {
                                        Name = weapon_name,
                                        Level = 1,
                                        XP = 0,
                                        IsFavorited = false,
                                        Skin = nil,
                                }

                                local eq = S.equipped[weapon_name]
                                if eq then
                                        for cos_type, cos_data in pairs(eq) do
                                                if type(cos_data) == "table" and (cos_data.Name == "NONE_COSMETIC" or cos_data.Name == "None") then
                                                        fake_data[cos_type] = nil
                                                else
                                                        fake_data[cos_type] = cos_data
                                                end
                                        end
                                end

                                return fake_data, index
                        end

                        if original_data and S.equipped[weapon_name] then
                                for cos_type, cos_data in pairs(S.equipped[weapon_name]) do
                                        if type(cos_data) == "table" and (cos_data.Name == "NONE_COSMETIC" or cos_data.Name == "None") then
                                                original_data[cos_type] = nil
                                        else
                                                original_data[cos_type] = cos_data
                                        end
                                end
                        end

                        return original_data, index
                end)
        end

        -- [3] 資料初始化（等待 PlayerData.CurrentData）+ CurrentData.Get 補丁
        task.spawn(function()
                local pdm = modules.PlayerDataController
                if not pdm then return end

                local t0 = os.clock()
                while not pdm.CurrentData and os.clock() - t0 < 60 do
                        task.wait(0.25)
                end
                if not pdm.CurrentData then return end

                -- PatchCurrentDataGet（沿用 ae src 的 _fakeWeaponOwnedPatched 標記）
                local current_data = pdm.CurrentData
                if not current_data._fakeWeaponOwnedPatched then
                        local old_get = current_data.Get
                        current_data.Get = function(self, ...)
                                local data = old_get(self, ...)
                                local key = ({ ... })[1]

                                if key == "CosmeticInventory" then
                                        return S.fake_owned or data
                                end
                                if key == "WeaponInventory" then
                                        return S.fake_weapon_owned or data
                                end
                                if key == "FreeWeaponUnlockCheck" then
                                        return S.fake_weapon_owned or data
                                end

                                return data
                        end
                        current_data._fakeWeaponOwnedPatched = true
                end

                -- 初始化 fake 表（重複執行時已有值 → 不覆蓋，保留已解鎖內容）
                if not S.fake_owned then
                        S.fake_owned = pdm:Get("CosmeticInventory") or {}
                end
                if not S.fake_weapon_owned then
                        S.fake_weapon_owned = pdm:Get("WeaponInventory") or {}
                end
                if not S.favorites then
                        S.favorites = pdm:Get("FavoritedCosmetics") or {}
                end

                if LabelData then
                        pcall(function() LabelData:SetText("Data: ready") end)
                end
        end)

        -- [4] NamecallDispatcher（整個執行器環境只 hook 一次 __namecall）
        local NamecallDispatcher = g.dispatcher
        if not NamecallDispatcher and hookmetamethod and newcclosure and getnamecallmethod then
                local ok = pcall(function()
                        NamecallDispatcher = {
                                Hooks = {},
                                Original = nil,
                        }

                        function NamecallDispatcher:Register(callback)
                                self.Hooks[#self.Hooks + 1] = callback
                                return #self.Hooks
                        end

                        function NamecallDispatcher:CallOriginal(object, ...)
                                if self.Original then
                                        return self.Original(object, ...)
                                end
                                return nil
                        end

                        NamecallDispatcher.Original = hookmetamethod(game, "__namecall", newcclosure(LPH_NV(function(object, ...)
                                local hooks = NamecallDispatcher.Hooks
                                local count = #hooks

                                if count == 0 then
                                        return NamecallDispatcher.Original(object, ...)
                                end

                                local method = getnamecallmethod()

                                for i = 1, count do
                                        local result = hooks[i](object, method, ...)
                                        if result ~= nil and result ~= false then
                                                if result == true then
                                                        return nil
                                                end
                                                return result
                                        end
                                end

                                return NamecallDispatcher.Original(object, ...)
                        end)))
                end)
                if ok then
                        g.dispatcher = NamecallDispatcher
                else
                        NamecallDispatcher = nil
                end
        end

        -- [5] Cosmetic 工具（原 ae src 全域函式改為 local，不汙染全域）
        local function CloneCosmetic(name, cosmetic_type, options)
                if not cl or not cl.Cosmetics then return nil end

                local base = cl.Cosmetics[name]
                if not base then return nil end

                local data = table.clone(base)
                data.Name = name
                data.Type = data.Type or cosmetic_type
                data.Seed = math.random(1, 1000000)

                if modules.EnumLibrary then
                        pcall(function()
                                local enum_id = modules.EnumLibrary:ToEnum(name)
                                if enum_id then
                                        data.Enum, data.ObjectID = enum_id, enum_id
                                end
                        end)
                end

                if options then
                        if options.inverted then
                                data.Inverted = true
                        end
                        if options.favorites_only then
                                data.OnlyUseFavorites = true
                        end
                end

                return data
        end

        local function GetRandomCosmetic(cosmetic_type, weapon_name, is_inverted, only_use_favorites)
                if not cl or not cl.Cosmetics or not modules.PlayerDataController then return nil end

                local available = {}
                for cosmetic_name, cosmetic_data in pairs(cl.Cosmetics) do
                        if cosmetic_type == "Skin" then
                                if cosmetic_data.Type == cosmetic_type and cl:OwnsCosmetic(modules.PlayerDataController:Get("CosmeticInventory"), cosmetic_name, weapon_name) and cosmetic_data.ItemName == weapon_name then
                                        table.insert(available, cosmetic_name)
                                end
                        else
                                if cosmetic_data.Type == cosmetic_type and cl:OwnsCosmetic(modules.PlayerDataController:Get("CosmeticInventory"), cosmetic_name, weapon_name) then
                                        table.insert(available, cosmetic_name)
                                end
                        end
                end

                if #available == 0 then
                        return nil
                end

                return CloneCosmetic(
                        available[math.random(#available)],
                        cosmetic_type,
                        {
                                inverted = is_inverted,
                                favorites_only = only_use_favorites,
                        }
                )
        end

        local function ResolveCosmetic(weaponName, cosmeticType)
                local equipped = S.equipped[weaponName] and S.equipped[weaponName][cosmeticType]

                if not equipped then
                        return nil
                end

                if equipped.Name == "None" or equipped.Name == "NONE_COSMETIC" then
                        return nil
                end

                if equipped.Name == "Random" or equipped.Name == "RANDOM_COSMETIC" then
                        return GetRandomCosmetic(
                                cosmeticType,
                                weaponName,
                                equipped.Inverted,
                                equipped.OnlyUseFavorites
                        )
                end

                return equipped
        end

        local function RebuildObjectIDMap()
                local fc = modules.FighterController
                if not fc then return end
                pcall(function()
                        local fighter = fc:GetFighter(LocalPlayer)
                        if not fighter or not fighter.Items then return end
                        for _, item in pairs(fighter.Items) do
                                local ok, oid = pcall(function()
                                        return item:Get("ObjectID")
                                end)
                                if ok and oid ~= nil then
                                        caches.objectid_to_weapon_cache[tostring(oid)] = item.Name
                                end
                        end
                end)
        end

        -- [6] FighterController（非同步載入）→ ObjectID 快取循環 + Namecall 攔截（UseItem / EquipCosmetic / FavoriteCosmetic）
        task.spawn(function()
                if not modules.FighterController then
                        local ps = LocalPlayer.PlayerScripts
                        local controllers = ps:FindFirstChild("Controllers") or ps:WaitForChild("Controllers", 30)
                        local fc_inst = controllers and (controllers:FindFirstChild("FighterController") or controllers:WaitForChild("FighterController", 30))
                        if fc_inst then
                                local ok, fc = pcall(require, fc_inst)
                                if ok then
                                        modules.FighterController = fc
                                end
                        end
                end
                if not modules.FighterController then return end

                -- ObjectID 快取循環：只在第一次執行時啟動（二次執行不重複跑 loop）
                if not g.objmap_loop then
                        g.objmap_loop = true
                        task.spawn(function()
                                while true do
                                        RebuildObjectIDMap()
                                        task.wait(5)
                                end
                        end)
                end

                -- Namecall handler：只註冊一次（dispatcher 物件本身存在 getgenv，重複執行直接復用）
                if NamecallDispatcher and not g.unlock_namecall_registered then
                        g.unlock_namecall_registered = true

                        local function HandleUseItem(args)
                                local fc = modules.FighterController
                                if not fc then return end

                                local oid_str = args[1] ~= nil and tostring(args[1]) or nil
                                if not oid_str then return end

                                local cached = caches.objectid_to_weapon_cache[oid_str]
                                if cached then
                                        S.last_used_weapon = cached
                                        return
                                end

                                task.spawn(function()
                                        pcall(function()
                                                local fighter = fc:GetFighter(LocalPlayer)
                                                if not fighter or not fighter.Items then return end
                                                for _, item in pairs(fighter.Items) do
                                                        local ok, oid = pcall(function() return item:Get("ObjectID") end)
                                                        if ok and oid ~= nil and tostring(oid) == oid_str then
                                                                S.last_used_weapon = item.Name
                                                                caches.objectid_to_weapon_cache[oid_str] = item.Name
                                                                break
                                                        end
                                                end
                                        end)
                                end)
                        end

                        local function HandleEquip(args)
                                local weapon_name = args[1]
                                local cosmetic_type = args[2]
                                local cosmetic_name = args[3]
                                local options = args[4] or {}

                                S.equipped[weapon_name] = S.equipped[weapon_name] or {}

                                if not cosmetic_name or cosmetic_name == "" or cosmetic_name == "None" or cosmetic_name == "NONE_COSMETIC" then
                                        S.equipped[weapon_name][cosmetic_type] = { Name = "NONE_COSMETIC" }
                                elseif cosmetic_name == "Random" or cosmetic_name == "RANDOM_COSMETIC" then
                                        local data = {}
                                        data.Name = cosmetic_name
                                        data.Type = cosmetic_type
                                        data.Inverted = options.IsInverted
                                        data.OnlyUseFavorites = options.OnlyUseFavorites
                                        data.Seed = math.random(1, 1000000)

                                        S.equipped[weapon_name][cosmetic_type] = data
                                else
                                        local cloned = CloneCosmetic(
                                                cosmetic_name,
                                                cosmetic_type,
                                                {
                                                        inverted = options.IsInverted,
                                                        favorites_only = options.OnlyUseFavorites,
                                                }
                                        )

                                        if cloned then
                                                S.equipped[weapon_name][cosmetic_type] = cloned
                                        end
                                end

                                task.spawn(function()
                                        task.wait(0.1)
                                        pcall(function()
                                                if modules.PlayerDataController and modules.PlayerDataController.CurrentData then
                                                        modules.PlayerDataController.CurrentData:Replicate("WeaponInventory")
                                                end
                                        end)
                                end)
                        end

                        local function HandleFavorite(args)
                                local weapon_name = args[1]
                                local cosmetic_name = args[2]
                                local state = args[3]

                                if not S.favorites then S.favorites = {} end
                                S.favorites[weapon_name] = S.favorites[weapon_name] or {}
                                S.favorites[weapon_name][cosmetic_name] = state or nil
                        end

                        NamecallDispatcher:Register(function(self, method, ...)
                                if method ~= "FireServer" then
                                        return false
                                end

                                local args = { ... }

                                if self.Name == "UseItem" then
                                        HandleUseItem(args)
                                        return NamecallDispatcher:CallOriginal(self, ...)
                                end

                                if self.Name == "EquipCosmetic" then
                                        HandleEquip(args)
                                        return true
                                end

                                if self.Name == "FavoriteCosmetic" then
                                        HandleFavorite(args)
                                        return true
                                end

                                return false
                        end)
                end
        end)

        -- [7] 皮膚套用視覺鏈（Layer B）— 延遲 3 秒等 Client 模組就緒，每個目標有 marker 防重複 hook
        task.spawn(function()
                task.wait(3)
                local ps = LocalPlayer.PlayerScripts

                -- 7a. ItemLibrary viewmodel 圖片
                if modules.ItemLibrary and not modules.ItemLibrary.__CRYPT_IMG_HOOKED then
                        local il = modules.ItemLibrary
                        local getviewmodelimage_original = il.GetViewModelImageFromWeaponData
                        if getviewmodelimage_original then
                                il.__CRYPT_IMG_HOOKED = true
                                il.GetViewModelImageFromWeaponData = function(p1, p2, p3)
                                        if not p2 then return getviewmodelimage_original(p1, p2, p3) end

                                        local weapon_name = p2.Name
                                        local should_show_skin = (p2.Skin and S.equipped[weapon_name] and p2.Skin == ResolveCosmetic(weapon_name, "Skin")) or (S.viewing_profile == LocalPlayer and S.equipped[weapon_name] and ResolveCosmetic(weapon_name, "Skin"))

                                        if should_show_skin and S.equipped[weapon_name] and ResolveCosmetic(weapon_name, "Skin") then
                                                local skin_info = p1.ViewModels[ResolveCosmetic(weapon_name, "Skin").Name]

                                                if skin_info then
                                                        return skin_info[p3 and "ImageHighResolution" or "Image"] or skin_info.Image
                                                end
                                        end
                                        return getviewmodelimage_original(p1, p2, p3)
                                end
                        end
                end

                -- 7b. ClientItem._CreateViewModel + ClientViewModel（skin / wrap / charm 實際套用）
                pcall(function()
                        local clientItemPath = ps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
                        local ClientItem = require(clientItemPath)

                        if ClientItem and not ClientItem.__CRYPT_HOOKED then
                                ClientItem.__CRYPT_HOOKED = true
                                if ClientItem._CreateViewModel then
                                        local orig = ClientItem._CreateViewModel
                                        ClientItem._CreateViewModel = function(self, viewmodelRef)
                                                local weaponName = self.Name
                                                local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                                                S.constructing_weapon = (weaponPlayer == LocalPlayer) and weaponName or nil

                                                if weaponPlayer == LocalPlayer and S.equipped[weaponName] and ResolveCosmetic(weaponName, "Skin") and viewmodelRef then
                                                        pcall(function()
                                                                local dataKey, skinKey, nameKey = self:ToEnum("Data"), self:ToEnum("Skin"), self:ToEnum("Name")

                                                                if viewmodelRef[dataKey] then
                                                                        viewmodelRef[dataKey][skinKey] = ResolveCosmetic(weaponName, "Skin")
                                                                        viewmodelRef[dataKey][nameKey] = ResolveCosmetic(weaponName, "Skin").Name
                                                                elseif viewmodelRef.Data then
                                                                        viewmodelRef.Data.Skin = ResolveCosmetic(weaponName, "Skin")
                                                                        viewmodelRef.Data.Name = ResolveCosmetic(weaponName, "Skin").Name
                                                                end
                                                        end)
                                                end

                                                local result = orig(self, viewmodelRef)
                                                S.constructing_weapon = nil

                                                return result
                                        end
                                end
                        end

                        local viewModelModule = clientItemPath:FindFirstChild("ClientViewModel")
                        if viewModelModule then
                                local ClientViewModel = require(viewModelModule)
                                if ClientViewModel and not ClientViewModel.__CRYPT_HOOKED then
                                        ClientViewModel.__CRYPT_HOOKED = true

                                        if ClientViewModel.GetWrap then
                                                local orig = ClientViewModel.GetWrap
                                                ClientViewModel.GetWrap = function(self)
                                                        local weaponName = self.ClientItem and self.ClientItem.Name
                                                        local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player

                                                        if weaponName and weaponPlayer == LocalPlayer and S.equipped[weaponName] and ResolveCosmetic(weaponName, "Wrap") then
                                                                return ResolveCosmetic(weaponName, "Wrap")
                                                        end
                                                        return orig(self)
                                                end
                                        end

                                        local origNew = ClientViewModel.new
                                        ClientViewModel.new = function(replicatedData, clientItem)
                                                local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
                                                local weaponName = S.constructing_weapon or clientItem.Name

                                                if weaponPlayer == LocalPlayer and S.equipped[weaponName] then
                                                        pcall(function()
                                                                local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
                                                                local dataKey = ReplicatedClass:ToEnum("Data")
                                                                replicatedData[dataKey] = replicatedData[dataKey] or {}

                                                                if ResolveCosmetic(weaponName, "Skin") then
                                                                        replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = ResolveCosmetic(weaponName, "Skin")
                                                                end

                                                                if ResolveCosmetic(weaponName, "Wrap") then
                                                                        replicatedData[dataKey][ReplicatedClass:ToEnum("Wrap")] = ResolveCosmetic(weaponName, "Wrap")
                                                                end

                                                                if ResolveCosmetic(weaponName, "Charm") then
                                                                        replicatedData[dataKey][ReplicatedClass:ToEnum("Charm")] = ResolveCosmetic(weaponName, "Charm")
                                                                end
                                                        end)
                                                end
                                                local result = origNew(replicatedData, clientItem)
                                                pcall(function()
                                                        local objectID = nil
                                                        pcall(function()
                                                                local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
                                                                local dataKey = ReplicatedClass:ToEnum("Data")
                                                                local objKey = ReplicatedClass:ToEnum("ObjectID")
                                                                if replicatedData[dataKey] then
                                                                        objectID = replicatedData[dataKey][objKey]
                                                                end
                                                        end)
                                                        if objectID == nil then
                                                                pcall(function() objectID = result:Get("ObjectID") or result.ObjectID end)
                                                        end
                                                        if objectID and weaponPlayer == LocalPlayer and S.equipped[weaponName] then
                                                                S.placed_object_map[objectID] = weaponName
                                                        end
                                                end)
                                                if weaponPlayer == LocalPlayer and S.equipped[weaponName] and ResolveCosmetic(weaponName, "Wrap") and result._UpdateWrap then
                                                        task.spawn(function()
                                                                result:_UpdateWrap()
                                                                task.wait(0.1)
                                                                if not result._destroyed then result:_UpdateWrap() end
                                                        end)
                                                end
                                                return result
                                        end
                                end
                        end
                end)

                -- 7c. ViewProfile.Fetch（觀看他人檔案追蹤）
                pcall(function()
                        local ViewProfile = require(ps.Modules.Pages.ViewProfile)
                        if ViewProfile and not ViewProfile.__CRYPT_HOOKED then
                                ViewProfile.__CRYPT_HOOKED = true
                                if ViewProfile.Fetch then
                                        local orig = ViewProfile.Fetch
                                        ViewProfile.Fetch = function(self, targetPlayer)
                                                S.viewing_profile = targetPlayer
                                                return orig(self, targetPlayer)
                                        end
                                end
                        end
                end)

                -- 7d. ClientEntity.ReplicateFromServer（Finisher 本地套用）
                pcall(function()
                        local ClientEntity = require(ps.ClientReplicatedClasses.ClientEntity)
                        if ClientEntity and not ClientEntity.__CRYPT_RFS_HOOKED then
                                if not ClientEntity.ReplicateFromServer then return end
                                ClientEntity.__CRYPT_RFS_HOOKED = true

                                local orig = ClientEntity.ReplicateFromServer

                                local function DecodeKillerArg(value)
                                        if value == nil then return nil end

                                        if typeof(value) == "Instance" then
                                                if value:IsA("Player") then
                                                        return value.Name
                                                end
                                                return nil
                                        end

                                        if type(value) == "number" then
                                                return value == LocalPlayer.UserId and LocalPlayer.Name or nil
                                        end

                                        if type(value) == "string" then
                                                return value
                                        end

                                        if type(value) == "userdata" then
                                                if modules.EnumLibrary and modules.EnumLibrary.FromEnum then
                                                        local ok, decoded = pcall(function() return modules.EnumLibrary:FromEnum(value) end)
                                                        if ok and decoded ~= nil then
                                                                return tostring(decoded)
                                                        end
                                                end
                                                return tostring(value)
                                        end

                                        return tostring(value)
                                end

                                local function IsLocalPlayerKiller(args)
                                        local lname_lower = LocalPlayer.Name:lower()
                                        local decoded = DecodeKillerArg(args[3])
                                        if decoded and decoded:lower() == lname_lower then
                                                return true
                                        end
                                        return false
                                end

                                local function ResolveFinisherWeapon()
                                        local primary = S.last_used_weapon
                                        if primary
                                                and S.equipped[primary]
                                                and ResolveCosmetic(primary, "Finisher")
                                        then
                                                return primary
                                        end

                                        for weaponName, _ in pairs(S.equipped) do
                                                if ResolveCosmetic(weaponName, "Finisher") then
                                                        return weaponName
                                                end
                                        end

                                        return nil
                                end

                                local function ResolveFinisherEnum(finisherData)
                                        if not finisherData then
                                                return nil, "finisherData is nil"
                                        end

                                        if finisherData.Enum ~= nil then
                                                return finisherData.Enum, nil
                                        end

                                        if modules.EnumLibrary then
                                                if modules.EnumLibrary.ToEnum then
                                                        local ok, result = pcall(function()
                                                                return modules.EnumLibrary:ToEnum(finisherData.Name)
                                                        end)
                                                        if ok and result ~= nil then
                                                                finisherData.Enum = result
                                                                return result, nil
                                                        end
                                                end
                                        end

                                        if finisherData.ObjectID ~= nil then
                                                finisherData.Enum = finisherData.ObjectID
                                                return finisherData.ObjectID, nil
                                        end

                                        return nil, "could not resolve enum for finisher: " .. tostring(finisherData.Name)
                                end

                                ClientEntity.ReplicateFromServer = function(self, action, ...)
                                        if action ~= "FinisherEffect" then
                                                return orig(self, action, ...)
                                        end

                                        local args = { ... }

                                        if not IsLocalPlayerKiller(args) then
                                                return orig(self, action, ...)
                                        end

                                        local weaponName = ResolveFinisherWeapon()
                                        if not weaponName then
                                                return orig(self, action, ...)
                                        end

                                        local finisherData = ResolveCosmetic(weaponName, "Finisher")
                                        local finisherEnum, _ = ResolveFinisherEnum(finisherData)

                                        if finisherEnum == nil then
                                                return orig(self, action, ...)
                                        end

                                        if not self:IsRendered() then return end

                                        local ok, decoded = pcall(function()
                                                return self:FromEnum(finisherEnum)
                                        end)
                                        if not ok or decoded == nil then
                                                decoded = finisherData.Name
                                        end

                                        if decoded == nil then
                                                return orig(self, action, ...)
                                        end

                                        local v2, v3, v4 = args[2], args[3], args[4]
                                        pcall(function()
                                                self:_PlayFinisher(decoded, v2, v3, v4)
                                        end)

                                        return
                                end
                        end
                end)

                -- 7e. FighterController.GetWrap（放置類 wrap 查詢）
                pcall(function()
                        local fc = modules.FighterController
                        if fc and fc.GetWrap and not fc.__CRYPT_WRAPHOOKED then
                                fc.__CRYPT_WRAPHOOKED = true
                                local orig_GetWrap = fc.GetWrap
                                fc.GetWrap = function(self, objectID)
                                        local result = orig_GetWrap(self, objectID)
                                        if result then return result end

                                        if objectID and S.placed_object_map then
                                                local weaponName = S.placed_object_map[objectID]
                                                if weaponName and S.equipped[weaponName] then
                                                        local wrap = ResolveCosmetic(weaponName, "Wrap")
                                                        if wrap then return wrap end
                                                end
                                        end
                                        return nil
                                end
                        end
                end)

                -- 7f. JumpPads（跳板皮膚）
                pcall(function()
                        local JumpPads = require(ps.Modules.GameComponents.JumpPads)
                        if JumpPads and not JumpPads.__CRYPT_HOOKED then
                                JumpPads.__CRYPT_HOOKED = true
                                if JumpPads.CreateJumpPadVisual then
                                        local orig_CreateVisual = JumpPads.CreateJumpPadVisual
                                        JumpPads.CreateJumpPadVisual = function(self, name, size)
                                                if S.equipped["Jump Pad"] then
                                                        pcall(function()
                                                                local skin = ResolveCosmetic("Jump Pad", "Skin")
                                                                if skin and skin.Name then
                                                                        name = skin.Name
                                                                end
                                                        end)
                                                end
                                                return orig_CreateVisual(self, name, size)
                                        end
                                end
                        end
                end)

                if LabelHooks then
                        pcall(function() LabelHooks:SetText("Visual chain: active") end)
                end
        end)

        -- [8] 查詢輔助函式
        local function Ready()
                return S.fake_owned ~= nil and S.fake_weapon_owned ~= nil and cl ~= nil and modules.PlayerDataController ~= nil
        end

        local function GetCosmeticsByRarity(rarity)
                local results = {}
                if not cl or not cl.Cosmetics then return results end
                for name, cosmetic in pairs(cl.Cosmetics) do
                        if cosmetic.Rarity == rarity then
                                table.insert(results, name)
                        end
                end
                return results
        end

        local function GetCosmeticsByType(type_name)
                local results = {}
                if not cl or not cl.Cosmetics then return results end
                for name, cosmetic in pairs(cl.Cosmetics) do
                        if cosmetic.Type == type_name then
                                table.insert(results, name)
                        end
                end
                return results
        end

        local function GetSpecificCosmetic(type_name, cos_name, weapon_name)
                local result
                if not cl or not cl.Cosmetics then return nil end
                for name, cosmetic in pairs(cl.Cosmetics) do
                        if type_name == "Skin" then
                                if name == cos_name and cosmetic.Type == type_name and cosmetic.ItemName == weapon_name then
                                        result = name
                                end
                        else
                                if name == cos_name and cosmetic.Type == type_name then
                                        result = name
                                end
                        end
                end
                return result
        end

        local function GetAllCosmeticsOfWeapon(weapon_name)
                local results = {}
                if not cl or not cl.Cosmetics then return results end
                for name, cosmetic in pairs(cl.Cosmetics) do
                        if cosmetic.Type == "Skin" then
                                if cosmetic.ItemName == weapon_name then
                                        table.insert(results, name)
                                end
                        else
                                table.insert(results, name)
                        end
                end
                return results
        end

        local function GetAllCosmetics()
                local results = {}
                if not cl or not cl.Cosmetics then return results end
                for name, _ in pairs(cl.Cosmetics) do
                        table.insert(results, name)
                end
                return results
        end

        -- [9] Unlock / Lock 函式群（回傳 boolean 供 UI 通知）
        local function UnlockSelectedRarity()
                if not Ready() then return false end
                local rarity = S.general_unlocker.unlock_rarity
                for _, cosmetic in ipairs(GetCosmeticsByRarity(rarity)) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = true
                        end
                end
                return true
        end

        local function LockSelectedRarity()
                if not Ready() then return false end
                local rarity = S.general_unlocker.unlock_rarity
                for _, cosmetic in ipairs(GetCosmeticsByRarity(rarity)) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = nil
                        end
                end
                return true
        end

        local function UnlockAllOfType()
                if not Ready() then return false end
                local type_name = S.general_unlocker.unlock_type
                for _, cosmetic in ipairs(GetCosmeticsByType(type_name)) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = true
                        end
                end
                return true
        end

        local function LockAllOfType()
                if not Ready() then return false end
                local type_name = S.general_unlocker.unlock_type
                for _, cosmetic in ipairs(GetCosmeticsByType(type_name)) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = nil
                        end
                end
                return true
        end

        local function UnlockSpecific()
                if not Ready() then return false end
                local type_name = S.specific_unlocker.unlock_type
                local cosmetic_name = S.specific_unlocker.cosmetic_name
                local weapon_name = S.specific_unlocker.weapon_name

                local cosmetic = GetSpecificCosmetic(type_name, cosmetic_name, weapon_name)
                if not cosmetic or cosmetic:find("MISSING_") then return false end
                S.fake_owned[cosmetic] = true
                return true
        end

        local function LockSpecific()
                if not Ready() then return false end
                local type_name = S.specific_unlocker.unlock_type
                local cosmetic_name = S.specific_unlocker.cosmetic_name
                local weapon_name = S.specific_unlocker.weapon_name

                local cosmetic = GetSpecificCosmetic(type_name, cosmetic_name, weapon_name)
                if not cosmetic or cosmetic:find("MISSING_") then return false end
                S.fake_owned[cosmetic] = nil
                return true
        end

        local function UnlockSpecificWeapon()
                if not Ready() then return false end
                local weapon_name = S.specific_unlocker.weapon_name
                local current_data = modules.PlayerDataController.CurrentData
                if not current_data then return false end

                local inventory = current_data:Get("WeaponInventory")
                local owned = {}
                if type(inventory) == "table" then
                        for _, weapon_data in pairs(inventory) do
                                if type(weapon_data) == "table" and weapon_data.Name then
                                        owned[weapon_data.Name] = true
                                end
                        end
                end

                if not owned[weapon_name] then
                        table.insert(S.fake_weapon_owned, {
                                Name = weapon_name,
                                Level = 1,
                                XP = 0,
                                IsFavorited = false,
                                Skin = nil,
                        })
                end
                return true
        end

        local function LockSpecificWeapon()
                if not S.fake_weapon_owned then return false end
                local weapon_name = S.specific_unlocker.weapon_name

                for i, weapon in ipairs(S.fake_weapon_owned) do
                        if weapon.Name == weapon_name then
                                table.remove(S.fake_weapon_owned, i)
                                break
                        end
                end
                return true
        end

        local function UnlockAllWeapons()
                if not Ready() then return false end
                if not modules.ShopLibrary or not modules.ShopLibrary.GetReleasedOwnableWeapons then return false end

                local current_data = modules.PlayerDataController.CurrentData
                if not current_data then return false end

                local inventory = current_data:Get("WeaponInventory")
                local owned = {}
                if type(inventory) == "table" then
                        for _, weapon_data in pairs(inventory) do
                                if type(weapon_data) == "table" and weapon_data.Name then
                                        owned[weapon_data.Name] = true
                                end
                        end
                end

                local ok, ownables = pcall(function()
                        return modules.ShopLibrary:GetReleasedOwnableWeapons()
                end)
                if not ok or not ownables then return false end

                for _, weapon_name in pairs(ownables) do
                        if not owned[weapon_name] then
                                table.insert(S.fake_weapon_owned, {
                                        Name = weapon_name,
                                        Level = 1,
                                        XP = 0,
                                        IsFavorited = false,
                                        Skin = nil,
                                })
                        end
                end
                return true
        end

        local function LockAllWeapons()
                if not S.fake_weapon_owned then return false end
                -- 修正 ae src 原版 bug：原寫法用 pairs 迭代陣列索引導致永遠清不掉，改為直接清空
                table.clear(S.fake_weapon_owned)
                return true
        end

        local function UnlockAllForWeapon()
                if not Ready() then return false end
                local weapon_name = S.specific_unlocker.weapon_name
                for _, cosmetic in ipairs(GetAllCosmeticsOfWeapon(weapon_name)) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = true
                        end
                end
                return true
        end

        local function LockAllForWeapon()
                if not Ready() then return false end
                local weapon_name = S.specific_unlocker.weapon_name
                for _, cosmetic in ipairs(GetAllCosmeticsOfWeapon(weapon_name)) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = nil
                        end
                end
                return true
        end

        local function UnlockAll()
                if not Ready() then return false end
                for _, cosmetic in ipairs(GetAllCosmetics()) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = true
                        end
                end
                return true
        end

        local function LockAll()
                if not Ready() then return false end
                for _, cosmetic in ipairs(GetAllCosmetics()) do
                        if not cosmetic:find("MISSING_") then
                                S.fake_owned[cosmetic] = nil
                        end
                end
                return true
        end

        local function GetEquipRemote()
                local rs = game:GetService("ReplicatedStorage")
                local remotes = rs:FindFirstChild("Remotes")
                if not remotes then return nil end
                local data_folder = remotes:FindFirstChild("Data")
                if not data_folder then return nil end
                return data_folder:FindFirstChild("EquipCosmetic")
        end

        local function EquipApply()
                if not Ready() then return false end
                local remote = GetEquipRemote()
                if not remote then return false end

                local unlock_type = S.equip_unlocker.unlock_type
                local cosmetic_name = S.equip_unlocker.cosmetic_name
                local weapon_name = S.equip_unlocker.weapon_name
                local is_inverted = S.equip_unlocker.inverted

                if typeof(weapon_name) ~= "string" or weapon_name == "" then
                        return false
                end

                local name_to_send = if cosmetic_name ~= nil and cosmetic_name ~= "" then cosmetic_name else nil

                local options = {}
                if unlock_type == "Wrap" then
                        options.IsInverted = if is_inverted then true else nil
                end

                remote:FireServer(weapon_name, unlock_type, name_to_send, options)
                return true
        end

        local function EquipApplyAll()
                if not Ready() then return false end
                if not modules.ItemLibrary or not modules.ItemLibrary.Items then return false end
                local remote = GetEquipRemote()
                if not remote then return false end

                local unlock_type = S.equip_unlocker.unlock_type
                local cosmetic_name = S.equip_unlocker.cosmetic_name
                local is_inverted = S.equip_unlocker.inverted

                if unlock_type == "Skin" then return false end

                for weapon_name, weapon_data in pairs(modules.ItemLibrary.Items) do
                        if unlock_type == "Finisher" and not weapon_data.CanEliminate then
                                continue
                        end

                        if typeof(weapon_name) ~= "string" or weapon_name == "" then
                                continue
                        end

                        local name_to_send = if cosmetic_name ~= nil and cosmetic_name ~= "" then cosmetic_name else nil

                        local options = {}
                        if unlock_type == "Wrap" then
                                options.IsInverted = if is_inverted then true else nil
                        end

                        remote:FireServer(weapon_name, unlock_type, name_to_send, options)
                end
                return true
        end

	-- [10] UI：Unlock 頁 + 四個區塊 Groupbox + Status（沿用 Obsidian 風格）
	local UnlockTab = Window:AddTab("Unlock")

	local function NotifyUnlock(ok, success_text)
		if ok then
			Library:Notify({ Title = "Unlock", Description = success_text, Time = 5 })
		else
			Notify("Unlock system not ready yet", 3)
		end
	end

	-- 左欄 1：Unlocker
	local UL = UnlockTab:AddLeftGroupbox("Unlocker")
	UL:AddDropdown("UnlockerType", {
		Text = "Type",
		Default = S.general_unlocker.unlock_type,
		Values = kCosmeticTypes,
		Callback = function(v) S.general_unlocker.unlock_type = v end,
	})
	UL:AddDropdown("UnlockerRarity", {
		Text = "Rarity",
		Default = S.general_unlocker.unlock_rarity,
		Values = kCosmeticRarities,
		Callback = function(v) S.general_unlocker.unlock_rarity = v end,
	})
	UL:AddButton({ Text = "Unlock Selected Rarity", Func = function() NotifyUnlock(UnlockSelectedRarity(), "Unlocked rarity! Please check weapons.") end })
	UL:AddButton({ Text = "Lock Selected Rarity", Func = function() NotifyUnlock(LockSelectedRarity(), "Locked rarity! Please check weapons.") end })
	UL:AddButton({ Text = "Unlock All of Type", Func = function() NotifyUnlock(UnlockAllOfType(), "Unlocked type! Please check weapons.") end })
	UL:AddButton({ Text = "Lock All of Type", Func = function() NotifyUnlock(LockAllOfType(), "Locked type! Please check weapons.") end })

	-- 左欄 2：Specific
	local US = UnlockTab:AddLeftGroupbox("Specific")
	US:AddDropdown("SpecificType", {
		Text = "Type",
		Default = S.specific_unlocker.unlock_type,
		Values = kCosmeticTypes,
		Callback = function(v) S.specific_unlocker.unlock_type = v end,
	})
	US:AddInput("SpecificCosmetic", {
		Text = "Cosmetic",
		Placeholder = "e.g. 10B Visits",
		Callback = function(v) S.specific_unlocker.cosmetic_name = v end,
	})
	US:AddInput("SpecificWeapon", {
		Text = "Weapon",
		Placeholder = "e.g. Assault Rifle",
		Callback = function(v) S.specific_unlocker.weapon_name = v end,
	})
	US:AddButton({ Text = "Unlock Specific", Func = function() NotifyUnlock(UnlockSpecific(), "Unlocked cosmetic! Please check weapons.") end })
	US:AddButton({ Text = "Lock Specific", Func = function() NotifyUnlock(LockSpecific(), "Locked cosmetic! Please check weapons.") end })
	US:AddButton({ Text = "Unlock Specific Weapon", Func = function() NotifyUnlock(UnlockSpecificWeapon(), "Unlocked weapon! Please check weapons.") end })
	US:AddButton({ Text = "Lock Specific Weapon", Func = function() NotifyUnlock(LockSpecificWeapon(), "Locked weapon! Please check weapons.") end })

	-- 右欄 1：Equip
	local UE = UnlockTab:AddRightGroupbox("Equip")
	UE:AddDropdown("EquipType", {
		Text = "Type",
		Default = S.equip_unlocker.unlock_type,
		Values = kCosmeticTypes,
		Callback = function(v) S.equip_unlocker.unlock_type = v end,
	})
	UE:AddInput("EquipCosmetic", {
		Text = "Cosmetic",
		Placeholder = "e.g. 10B Visits",
		Callback = function(v) S.equip_unlocker.cosmetic_name = v end,
	})
	UE:AddInput("EquipWeapon", {
		Text = "Weapon",
		Placeholder = "e.g. Assault Rifle",
		Callback = function(v) S.equip_unlocker.weapon_name = v end,
	})
	UE:AddToggle("EquipInverted", {
		Text = "Inverted (Wrap)",
		Default = S.equip_unlocker.inverted,
		Callback = function(v) S.equip_unlocker.inverted = v end,
	})
	UE:AddButton({ Text = "Apply", Func = function() NotifyUnlock(EquipApply(), "Applied! Please check weapons.") end })
	UE:AddButton({ Text = "Apply to all weapons", Func = function() NotifyUnlock(EquipApplyAll(), "Applied to all weapons!") end })

	-- 右欄 2：Bulk
	local UB = UnlockTab:AddRightGroupbox("Bulk")
	UB:AddButton({ Text = "Unlock All Weapons", Func = function() NotifyUnlock(UnlockAllWeapons(), "Unlocked all weapons!") end })
	UB:AddButton({ Text = "Lock All Weapons", Func = function() NotifyUnlock(LockAllWeapons(), "Locked all weapons!") end })
	UB:AddButton({ Text = "Unlock All for Weapon", Func = function() NotifyUnlock(UnlockAllForWeapon(), "Unlocked all for weapon!") end })
	UB:AddButton({ Text = "Lock All for Weapon", Func = function() NotifyUnlock(LockAllForWeapon(), "Locked all for weapon!") end })
	UB:AddButton({ Text = "Unlock All", Func = function() NotifyUnlock(UnlockAll(), "Unlocked all cosmetics!") end })
	UB:AddButton({ Text = "Lock All", Func = function() NotifyUnlock(LockAll(), "Locked all cosmetics!") end })

	-- 右欄 3：Status（除錯用狀態標籤）
	local UStat = UnlockTab:AddRightGroupbox("Status")
	LabelModules = UStat:AddLabel("Modules: ...")
	LabelHooks = UStat:AddLabel("Hooks: ...")
	LabelData = UStat:AddLabel("Data: ...")

	pcall(function()
		local core_ok = (cl ~= nil) and (pd ~= nil)
		LabelModules:SetText("Modules: " .. (core_ok and "loaded" or (cl or pd) and "partial" or "failed"))
	end)
	pcall(function()
		LabelHooks:SetText(same_session and "Hooks: reused (no re-hook)" or "Hooks: applied (fresh)")
	end)
	if modules.PlayerDataController and modules.PlayerDataController.CurrentData and S.fake_owned then
		pcall(function() LabelData:SetText("Data: ready") end)
	end

	if not cl or not pd then
		Notify("Unlock: core modules missing, features degraded", 5)
	end
end
-- ========== END UNLOCK MODULE ==========
-- ========== SETTINGS TAB ==========
local Menu = Tabs.Settings:AddLeftGroupbox("Menu")
Menu:AddToggle("KeybindMenu", { Text = "Keybind Menu", Default = false, Callback = function(Value) pcall(function() if Library.KeybindFrame then Library.KeybindFrame.Visible = Value end end) end })

local UI = Tabs.Settings:AddLeftGroupbox("UI")
UI:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", { Default = 'RightShift', Text = 'Menu Keybind', Mode = 'Toggle', NoUI = false })
Library.ToggleKeybind = Options.MenuKeybind

local autoLoadEnabled = true
UI:AddToggle("AutoLoad", { Text = "Auto Load Config", Default = true, Callback = function(val) autoLoadEnabled = val end })

UI:AddButton("Unload Script", function() Library:Unload() end)

local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder('Dread')
SaveManager:SetFolder('Dread/configs')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)


-- ========== UNLOCK CONFIG BRIDGE（合併進 SaveManager 配置系統）==========
-- UI 選項（Type/Rarity/Specific/Equip 輸入值）本來就透過 Obsidian Flags 由 SaveManager 存取；
-- 這裡再把 fake_owned / fake_weapon_owned / equipped / favorites 四張表寫進同一個配置的 sidecar 檔，
-- Save / Load / 自動載入 時同步還原，等同 ae src 的 CreateConfigFlag("fake_owned"...) 功能。
do
	local g = getgenv().CRYPT_UNLOCK
	local S = g and g.skinchanger_state
	if S and SaveManager then
		local HttpService = game:GetService("HttpService")

		local function UnlockSidecarPath(ConfigName)
			local folder = SaveManager.Folder
			if not folder or folder == "" then return nil end
			local sub = SaveManager.SubFolder
			return folder .. "/settings/" .. (sub and sub .. "/" or "") .. tostring(ConfigName) .. "_unlock.json"
		end

		local function SaveUnlockData(ConfigName)
			pcall(function()
				local path = UnlockSidecarPath(ConfigName)
				if not path or not writefile then return end
				if SaveManager.CheckFolderTree then
					pcall(function() SaveManager:CheckFolderTree() end)
				end
				writefile(path, HttpService:JSONEncode({
					fake_owned = S.fake_owned,
					fake_weapon_owned = S.fake_weapon_owned,
					equipped = S.equipped,
					favorites = S.favorites,
				}))
			end)
		end

		local function LoadUnlockData(ConfigName)
			pcall(function()
				local path = UnlockSidecarPath(ConfigName)
				if not path or not readfile or not isfile then return end
				if not isfile(path) then return end
				local data = HttpService:JSONDecode(readfile(path))
				if typeof(data) ~= "table" then return end
				-- 只在 sidecar 有值時覆蓋；表物件直接替換（hooks 都是動態讀 S.xxx，替換安全）
				if data.fake_owned then S.fake_owned = data.fake_owned end
				if data.fake_weapon_owned then S.fake_weapon_owned = data.fake_weapon_owned end
				if data.equipped then S.equipped = data.equipped end
				if data.favorites then S.favorites = data.favorites end
			end)
		end

		-- 包裝 Save / Load（LoadAutoloadConfig 內部走 self:Load，自動被涵蓋）
		local OldSave = SaveManager.Save
		function SaveManager:Save(ConfigName, ...)
			local r = { OldSave(self, ConfigName, ...) }
			if r[1] == true then
				SaveUnlockData(ConfigName)
			end
			return table.unpack(r)
		end

		local OldLoad = SaveManager.Load
		function SaveManager:Load(ConfigName, ...)
			local r = { OldLoad(self, ConfigName, ...) }
			if r[1] == true then
				LoadUnlockData(ConfigName)
			end
			return table.unpack(r)
		end
	end
end
-- ========== END UNLOCK CONFIG BRIDGE ==========
if autoLoadEnabled then pcall(function() SaveManager:LoadAutoloadConfig() end) end

-- 🔥 FINAL BOOT MESSAGE 🔥
Library:Notify({ Title = "Dread", Description = "Made by the Dread team with love", Time = 4 })