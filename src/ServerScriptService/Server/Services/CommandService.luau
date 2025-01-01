local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceLoader = require(ReplicatedStorage.ServiceLoader)
local DataService = ServiceLoader.GetService("DataService")

local TextChatCommands = TextChatService:WaitForChild("TextChatCommands")

local Service = {}

function Service.OnInitialized()
	
end

function Service.CreateCommand(Name : string, Callback : (Player : Player, ...string) -> ())
	local Command = Instance.new("TextChatCommand")
	Command.Name = Name
	Command.PrimaryAlias = `/{string.lower(Name)}`
	Command.Parent = TextChatCommands
	
	Command.Triggered:Connect(function(TextSource : TextSource, Text : string)
		local Player = TextSource.UserId and Players:GetPlayerByUserId(TextSource.UserId)
		local Args = string.split(Text, " ")
		
		table.remove(Args, 1)
		
		if Player ~= nil then
			Callback(Player, Args)
		end
	end)
end

return Service