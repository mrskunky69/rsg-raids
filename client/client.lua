local RSGCore = exports['rsg-core']:GetCoreObject()
local npcs = {}
local horses = {}
local activeRaid = false

Citizen.CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/startraid", "Start a bandit raid (outside valentine sheriffs office)")
    TriggerEvent("chat:addSuggestion", "/endraid", "End the current bandit raid ()")
end)

RegisterCommand("startraid", function(source, args)
    if not activeRaid then
        StartRaid()
    else
        print("A raid is already in progress.")
    end
end)

RegisterCommand("endraid", function(source, args)
    if activeRaid then
        EndRaid()
    else
        print("No active raid to end.")
    end
end)

function StartRaid()
    activeRaid = true
    local raidPath = Config.RaidPaths[math.random(#Config.RaidPaths)]
    SpawnBandits(raidPath.spawnPoint)
    Citizen.CreateThread(function()
        local currentPointIndex = 1
        while activeRaid do
            local nextPoint = raidPath.path[currentPointIndex]
            MovebanDitsToPoint(nextPoint)
            currentPointIndex = currentPointIndex % #raidPath.path + 1
            Citizen.Wait(Config.WaitTimeBetweenPoints)
        end
    end)
    -- Start the aggression thread
    Citizen.CreateThread(BanditAggressionThread)
end

function SpawnBandits(spawnPoint)
    for i = 1, Config.BanditsPerRaid do
        local banditModel = GetHashKey(Config.BanditsModel[math.random(#Config.BanditsModel)])
        local horseModel = GetHashKey(Config.HorseModels[math.random(#Config.HorseModels)])
        local banditWeapon = Config.Weapons[math.random(#Config.Weapons)]

        RequestModel(banditModel)
        RequestModel(horseModel)
        while not HasModelLoaded(banditModel) or not HasModelLoaded(horseModel) do
            Citizen.Wait(1)
        end

        local x = spawnPoint.x + math.random(-5, 5)
        local y = spawnPoint.y + math.random(-5, 5)
        local z = spawnPoint.z
		local isPedInCombat = IsPedInCombat(npcs[i], PlayerPedId())

        npcs[i] = CreatePed(banditModel, x, y, z, 0.0, true, true)
        horses[i] = CreatePed(horseModel, x, y, z, 0.0, true, true)
		
		if not NetworkGetEntityIsNetworked(npcs[i]) then
            NetworkRegisterEntityAsNetworked(npcs[i])
        end
        
        -- Network registration for horses
        if not NetworkGetEntityIsNetworked(horses[i]) then
            NetworkRegisterEntityAsNetworked(horses[i])
        end

        Citizen.InvokeNative(0x283978A15512B2FE, npcs[i], true)
        Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, npcs[i])

        Citizen.InvokeNative(0x283978A15512B2FE, horses[i], true)
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horses[i], 0x20359E53, true, true, true) -- saddle
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horses[i], 0x508B80B9, true, true, true) -- blanket
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horses[i], 0xF0C30271, true, true, true) -- bag
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horses[i], 0x12F0DF9F, true, true, true) -- bedroll
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horses[i], 0x67AF7302, true, true, true) -- stirrups
        Citizen.InvokeNative(0x028F76B6E78246EB, npcs[i], horses[i], -1)

        GiveWeaponToPed(npcs[i], banditWeapon, 50, true, true, 1, false, 0.5, 1.0, 1.0, true, 0, 0)
        SetCurrentPedWeapon(npcs[i], banditWeapon, true)

        -- Set the combat attributes
        SetPedCombatAttributes(npcs[i], 46, true)
        SetPedFleeAttributes(npcs[i], 0, false)
        SetPedCombatRange(npcs[i], 2)
        SetPedCombatMovement(npcs[i], 2)
		SetPedCanRagdoll(npcs, false)
		SetPedCanRagdollFromPlayerImpact(npcs, false)
		

        -- Set the accuracy for the NPC
        SetPedAccuracy(npcs[i], Config.BanditAccuracy or 50) -- Default to 50 if not specified
    end
end


function GetFormationPosition(leaderPos, index, totalNPCs)
    local angle = (index - 1) * (2 * math.pi / totalNPCs)
    local radius = 5.0 -- Adjust this value to change the spread of the formation
    local offsetX = math.cos(angle) * radius
    local offsetY = math.sin(angle) * radius
    return vector3(leaderPos.x + offsetX, leaderPos.y + offsetY, leaderPos.z)
end

function MovebanDitsToPoint(point)
    for i, npc in ipairs(npcs) do
        if DoesEntityExist(npc) then
            TaskGoToCoordAnyMeans(npc, point.x, point.y, point.z, 2.0, 0, false, 786603, 0xbf800000)
        end
    end
end

function MoveBanditsAlongPath(path)
    local currentPointIndex = 1

    while activeRaid do
        local nextPoint = path[currentPointIndex]

        -- Debug logging
        print("Moving to waypoint:", nextPoint.x, nextPoint.y, nextPoint.z)

        -- Move all NPCs and horses to the next point
        for i = 1, #npcs do
            local npc = npcs[i]
            local horse = horses[i]

            if DoesEntityExist(npc) then
                -- Ensure NPC is not in a combat task and has a movement task assigned
                ClearPedTasksImmediately(npc)
                TaskGoToCoordAnyMeans(npc, nextPoint.x, nextPoint.y, nextPoint.z, 2.0, 0, false, 786603, 0xbf800000)
            end

            if DoesEntityExist(horse) then
                -- Ensure horse is not in a combat task and has a movement task assigned
                ClearPedTasksImmediately(horse)
                TaskGoToCoordAnyMeans(horse, nextPoint.x, nextPoint.y, nextPoint.z, 2.0, 0, false, 786603, 0xbf800000)
            end
        end

        -- Wait until all NPCs and horses have reached the destination
        local allReached = false
        while not allReached do
            Citizen.Wait(500)  -- Check every 0.5 seconds

            allReached = true
            for i = 1, #npcs do
                local npc = npcs[i]
                local horse = horses[i]

                if DoesEntityExist(npc) and Vdist(GetEntityCoords(npc), nextPoint.x, nextPoint.y, nextPoint.z) > 1.5 then
                    allReached = false
                    break
                end

                if DoesEntityExist(horse) and Vdist(GetEntityCoords(horse), nextPoint.x, nextPoint.y, nextPoint.z) > 1.5 then
                    allReached = false
                    break
                end
            end
        end

        -- Clear tasks once they arrive at the waypoint
        for i = 1, #npcs do
            if DoesEntityExist(npcs[i]) then
                ClearPedTasks(npcs[i])
            end

            if DoesEntityExist(horses[i]) then
                ClearPedTasks(horses[i])
				EndRaid()
            end
        end

        currentPointIndex = (currentPointIndex % #path) + 1
        Citizen.Wait(Config.WaitTimeBetweenPoints)
    end
end


function MonitorPlayerHealth()
    while activeRaid do
        Citizen.Wait(500) -- Check every 0.5 seconds

        local playerPed = PlayerPedId()
        if DoesEntityExist(playerPed) then
            -- Check if player is dead
            if IsPedDeadOrDying(playerPed, true) then
                print("Player is dead. Ending raid.")
                EndRaid()
                break
            end
        end
    end
end



function BanditAggressionThread()
    while activeRaid do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHealth = GetEntityHealth(playerPed)
        
        for i, npc in ipairs(npcs) do
            if DoesEntityExist(npc) then
                local banditCoords = GetEntityCoords(npc)
                local distance = #(playerCoords - banditCoords)
                
                if playerHealth > 0 and distance <= Config.AggressionRange then
                    -- Player is alive and within aggression range
                    ClearPedTasks(npc)
                    TaskCombatPed(npc, playerPed, 0, 16)
                elseif playerHealth <= 0 then
                    -- Player is dead
                    -- Instead of clearing tasks, set NPCs to continue moving to the waypoint
                    ClearPedTasks(npc)
                    -- Example behavior: Resume path following or idle
                    if activeRaid then
                        -- Set NPCs to continue moving along the path or perform another task
                        -- Ensure that NPCs continue to move to the next waypoint if needed
                        local currentPath = Config.RaidPaths[math.random(#Config.RaidPaths)].path
                        local nextPoint = currentPath[1]  -- Set nextPoint based on your logic
                        TaskGoToCoordAnyMeans(npc, nextPoint.x, nextPoint.y, nextPoint.z, 2.0, 0, false, 786603, 0xbf800000)
                    end
                end
            end
        end
        
        Citizen.Wait(1000) -- Check every second
    end
end

function EndRaid()
    activeRaid = false
    for i, npc in ipairs(npcs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    for i, horse in ipairs(horses) do
        if DoesEntityExist(horse) then
            DeleteEntity(horse)
        end
    end
    npcs = {}
    horses = {}
    print("Raid ended.")
end


-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        EndRaid()
    end
end)