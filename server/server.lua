local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterServerEvent('rsg-bandits:server:robplayer')
AddEventHandler('rsg-bandits:server:robplayer', function()
	local src = source
	local Player = RSGCore.Functions.GetPlayer(src)
	Player.Functions.SetMoney('cash', 0)
end)