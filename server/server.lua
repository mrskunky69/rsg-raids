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
        Player.Functions.AddMoney('cash', 50, "Bandit kill reward")
        TriggerClientEvent('RSGCore:Notify', src, 'You received $50 for killing a bandit', 'success')
    end
end)
