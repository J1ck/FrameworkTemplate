local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServiceLoader = require(ReplicatedStorage.ServiceLoader).WaitUntilLoaded()
local DataService = ServiceLoader.GetService("DataService")
local LeaderstatsService = ServiceLoader.GetService("LeaderstatsService")
local LeaderboardService = ServiceLoader.GetService("LeaderboardService")

local function OnCharacterAdded(Player : Player, Character : Model)
    while not Character:IsDescendantOf(workspace) do
		task.wait()
	end

    
end

local function OnPlayerAdded(Player : Player)
    DataService.StartSessionAsync(Player)

    LeaderstatsService.CreateLeaderstats(Player, {
		
	})
	
	LeaderboardService.StartUpdatingPlayerEveryInterval(Player, 120)

    if Player.Character ~= nil then
		task.spawn(OnCharacterAdded, Player, Player.Character)
	end

	Player.CharacterAdded:Connect(function(Character)
		OnCharacterAdded(Player, Character)
	end)
end

local function OnPlayerRemoving(Player : Player)
    DataService.EndSessionAsync(Player)
end

for _, Player in Players:GetPlayers() do
    task.spawn(OnPlayerAdded, Player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)