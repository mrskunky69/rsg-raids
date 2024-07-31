local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterServerEvent('rsg-bandits:server:robplayer')
AddEventHandler('rsg-bandits:server:robplayer', function()
	local src = source
	local Player = RSGCore.Functions.GetPlayer(src)
	Player.Functions.SetMoney('cash', 0)
end)

RegisterServerEvent('banditRaid:rewardPlayer')
AddEventHandler('banditRaid:rewardPlayer', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player then
        -- Add cash reward
        Player.Functions.AddMoney('cash', 50, "Bandit kill reward")
        
        -- Add diamond item
        local diamondItem = "diamond" -- Replace with your actual diamond item name
        local amount = 1 -- Number of diamonds to give
        
        -- Check if the player can carry the item
        if Player.Functions.AddItem(diamondItem, amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[diamondItem], "add")
            TriggerClientEvent('RSGCore:Notify', src, 'You received $50 and found a diamond for killing a bandit', 'success')
        else
            -- If the player can't carry the diamond, just notify about the cash
            TriggerClientEvent('RSGCore:Notify', src, 'You received $50 for killing a bandit, but your inventory is full for additional rewards', 'success')
        end
    end
end)

RegisterServerEvent('banditRaid:allBanditsKilled')
AddEventHandler('banditRaid:allBanditsKilled', function()
    TriggerClientEvent('RSGCore:Notify', src, 'nice work killing all bandits, keep safe out there', 'success')
    TriggerClientEvent('RSGCore:Notify', -1, 'The bandit raid has been defeated!', 'success')
end)
