local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceLoader = require(ReplicatedStorage.ServiceLoader)
local DataService = ServiceLoader.GetService("DataService")

export type LeaderstatData = {
	Name : string,
	ValueType : string,
	DataPath : {string},
	MutatorCallback : (any) -> (any)?
}

local Service = {}

function Service.CreateLeaderstats(Player : Player, Data : {LeaderstatData})
	local Leaderstats = Player:FindFirstChild("leaderstats")
	
	if Leaderstats == nil then
		Leaderstats = Instance.new("Folder")
		Leaderstats.Name = "leaderstats"
		Leaderstats.Parent = Player
	end
	
	for _, LeaderstatData in Data do
		local Value = Instance.new(LeaderstatData.ValueType)
		Value.Name = LeaderstatData.Name
		Value.Parent = Leaderstats
		
		DataService.ListenToValueChanged(Player, LeaderstatData.DataPath, function(NewValue)
			Value.Value = LeaderstatData.MutatorCallback and LeaderstatData.MutatorCallback(NewValue) or NewValue
		end)
	end
end

return Service