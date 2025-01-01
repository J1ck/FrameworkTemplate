local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ServiceLoader = require(ReplicatedStorage.ServiceLoader)
local DataService = ServiceLoader.GetService("DataService")
local NumberUtilService = ServiceLoader.GetService("NumberUtilService")

local UserIdToNameCache = {}
local ActiveLeaderboards = {}

local Service = {}

function Service.OnInitialized()
	
end

function Service.CreateLeaderboard(Name : string, DataPath : {string}, Scope : string?)
	if ActiveLeaderboards[Name] then
		return warn(`[LeaderboardService] leaderboard with name '{Name}' already exists`)
	end
	
	local DataStore = DataStoreService:GetOrderedDataStore(Name, Scope)
	
	ActiveLeaderboards[Name] = {
		DataStore = DataStore,
		DataPath = DataPath
	}
end

function Service.GetTopPlayersAsync(Name : string, Amount : number) : {[number] : {key : string, value : number}}
	if not ActiveLeaderboards[Name] then
		warn(`[LeaderboardService] leaderboard with name '{Name}' does not exist`)
		
		return {}
	end
	
	local Status, Result = pcall(function()
		return ActiveLeaderboards[Name].DataStore:GetSortedAsync(false, Amount, 1):GetCurrentPage()
	end)
	
	if Status == false then
		warn(`[LeaderboardService] {Result}`)
		
		return {}
	end
	
	return Result
end

function Service.UpdatePlayerOnLeaderboardAsync(Player : Player, Name : string)
	local Leaderboard = ActiveLeaderboards[Name]
	
	if not Leaderboard then
		return warn(`[LeaderboardService] leaderboard with name '{Name}' does not exist`)
	end
	
	local Profile = DataService.GetProfileAsync(Player)

	if not Profile then
		return warn(`[LeaderBoardService] {Player.Name} profile does not exist`)
	end

	local Value = DataService.GetDataFromPath(Profile.Data, Leaderboard.DataPath)
	
	local Status, Result = pcall(function()
		Leaderboard.DataStore:SetAsync(`{Player.UserId}`, Value)
	end)
	
	if Status == false then
		warn(`[LeaderboardService] {Result}`)
	end
end

function Service.UpdatePlayerOnAllLeaderboards(Player : Player)
	for Name in ActiveLeaderboards do
		task.spawn(Service.UpdatePlayerOnLeaderboardAsync, Player, Name)
	end
end

function Service.StartUpdatingPlayerEveryInterval(Player : Player, Interval : number) : thread
	return task.spawn(function()
		while Player.Parent ~= nil and DataService.GetProfile(Player) ~= nil do
			Service.UpdatePlayerOnAllLeaderboards(Player)
			
			task.wait(Interval)
		end
	end)
end

function Service.GetNameFromUserId(UserId : string | number) : string
	if UserIdToNameCache[tonumber(UserId)] then
		return UserIdToNameCache[tonumber(UserId)]
	end
	
	local Status, Result = pcall(function()
		return Players:GetNameFromUserIdAsync(tonumber(UserId))
	end)
	
	if Status == false then
		warn(`[LeaderboardService] {Result}`)
		
		return "N/A"
	end
	
	UserIdToNameCache[tonumber(UserId)] = Result
	
	return Result
end

return Service