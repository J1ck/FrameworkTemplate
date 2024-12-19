local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceLoader = require(ReplicatedStorage.ServiceLoader)
	.InitializeClasses(ReplicatedStorage.Shared.Classes)
	.InitializeServices(ReplicatedStorage.Shared.Services)
	.InitializeClasses(ServerScriptService.Server.Classes)
	.InitializeServices(ServerScriptService.Server.Services)